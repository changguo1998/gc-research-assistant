
TODO_STATUS_LIST_SCHEDULE = (:none, :ongoing, :noted, :finished, :failed)
TODO_STATUS_COLOR = Dict(:none=>:white, :ongoing=>:yellow, :noted=>:blue, :finished=>:green, :failed=>:red)
TIME_PRECISION_SCHEDULE = Second(1)
LONG_AGO_SCHEDULE = DateTime(1000)
LONG_AFTER_SCHEDULE = DateTime(3000)
GALLERY_DIR_NAME_TODO = "Todos"
GALLERY_DIR_NAME_TODO_ARCHIVE = "TodoArchive"

@include_with REPOSITORY_MODULE_DIR_RM begin
    if GALLERY_DIR_NAME_TODO ∉ REPOSITORY_MODULE_DIR_RM
        push!(REPOSITORY_MODULE_DIR_RM, GALLERY_DIR_NAME_TODO)
    end
    if GALLERY_DIR_NAME_TODO_ARCHIVE ∉ REPOSITORY_MODULE_DIR_RM
        push!(REPOSITORY_MODULE_DIR_RM, GALLERY_DIR_NAME_TODO_ARCHIVE)
    end
end

function after_period(t::Period)
    global SETTING
    return round(now(), TIME_PRECISION_SCHEDULE) + t
end

"""
```
struct PeriodicInterval
    type::Symbol
    period::Int
end
```
"""
struct PeriodicInterval
    type::Symbol
    period::Int
end

function PeriodicInterval(type::Union{Symbol,AbstractString}, period::Integer)
    _type = Symbol(lowercase(type))
    if _type == :day
        if period < 1
            @error "daily period must be larger than 0"
            return nothing
        end
    elseif _type == :week
        if (period < 1) || (period > 7)
            @error "weekly period must beteen 1 and 7"
            return nothing
        end
    elseif _type == :month
        if (period < 1) || (period > 31)
            @error "monthly period must beteen 1 and 31"
            return nothing
        end
    else
        @error "type of period must be one of :day, :week, :month"
        return nothing
    end
    return PeriodicInterval(_type, Int(period))
end

function is_scheduled_on_date(date::Date, refdate::Date, period::PeriodicInterval)
    if period.type == :day
        itvl = mod(round(date-refdate, Day), Day(period.period))
        if itvl == Day(0)
            return true
        end
    elseif period.type == :week
        if dayofweek(date) == period.period
            return true
        end
    elseif period.type == :month
        if dayofmonth(date) == period.period
            return true
        end
    end
    return false
end

"""
```
struct Todo
    content::String
    start::DateTime
    stop::DateTime
    status::Symbol
    period::Vector{PeriodicInterval}
end
```
"""
struct Todo
    content::String
    start::DateTime
    stop::DateTime
    status::Symbol
    period::Vector{PeriodicInterval}
end

"""
```
Todo(content1, start1, stop1, status1, subitem1, period1;
     content, start, stop, status, period) -> Todo
```
init a `Todo` object in a more general way. keywork variable will overwrite the same name positioned variable.
"""
function Todo(  content1::AbstractString="",
                start1::DateTime=LONG_AGO_SCHEDULE,
                stop1::DateTime=LONG_AFTER_SCHEDULE,
                status1::Union{Symbol,AbstractString}=TODO_STATUS_LIST_SCHEDULE[1],
                period1::Vector{PeriodicInterval}=PeriodicInterval[];
                content::AbstractString="",
                start::DateTime=LONG_AGO_SCHEDULE,
                stop::DateTime=LONG_AFTER_SCHEDULE,
                status::Union{Symbol,AbstractString}=TODO_STATUS_LIST_SCHEDULE[1],
                period::Vector{PeriodicInterval}=PeriodicInterval[])
    _c = String(isempty(content1) ? content : content1)
    _start = (start1 == LONG_AGO_SCHEDULE) ? start : start1
    _stop = (stop1 == LONG_AFTER_SCHEDULE) ? stop : stop1
    _status = (Symbol(status1) == TODO_STATUS_LIST_SCHEDULE[1]) ? Symbol(status) : Symbol(status1)
    _period = isempty(period1) ? period : period1

    if !(_status in TODO_STATUS_LIST_SCHEDULE)
        error("status must be one of $TODO_STATUS_LIST_SCHEDULE")
    end
    return Todo(String(_c), _start, _stop, _status, _period)
end

_todopath()= _repoprefix(GALLERY_DIR_NAME_TODO)

_todoprefix(p...) = _repoprefix(GALLERY_DIR_NAME_TODO, p...)

_todoarchivepath() = _repoprefix(GALLERY_DIR_NAME_TODO_ARCHIVE)

_todoarchiveprefix(p...) = _repoprefix(GALLERY_DIR_NAME_TODO_ARCHIVE, p...)

function _todo_printcmd(todo::Todo, indent::String="", indent_n::Integer=4)
    if SETTING["todo_print_format"] ∉ ("long", "short")
        @error "set global SETTING[\"todo_print_format\"] to \"long\" or \"short\""
        return nothing
    end
    statw= maximum(length, String.(TODO_STATUS_LIST_SCHEDULE))
    printstyled(indent, String(todo.status), " "^(statw-length(String(todo.status))+1),
        color=TODO_STATUS_COLOR[todo.status])
    if todo.start > LONG_AGO_SCHEDULE
        print(todo.start)
    else
        print(" "^9, "?", " "^9)
    end
    print(" -> ")
    if todo.stop < LONG_AFTER_SCHEDULE
        print(todo.stop)
    else
        print(" "^9, "?", " "^9)
    end
    buf = split(todo.content, '\n', keepempty=true)
    if SETTING["todo_print_format"] == "long"
        if !isempty(todo.period)
            print('\n')
            for p in todo.period
                print(" ", p.type, p.period)
            end
        end
        print('\n')
        for l in buf
            println(indent, "  ", l)
        end
    elseif SETTING["todo_print_format"] == "short"
        println(" ", buf[1])
    end
    return nothing
end

function _scan_keyword(buf::Vector{String}, keyword::String)
    bufl = String[]
    for l = buf
        if startswith(l, keyword)
            i = findfirst(' ', l)
            push!(bufl, String(l[i+1:end]))
        end
    end
    return bufl
end

function _scan_todo_from_file(filename::String)
    l = readlines(filename)
    start = let
        b = _scan_keyword(l, "START")
        DateTime(b[1])
    end
    stop = let
        b = _scan_keyword(l, "STOP")
        DateTime(b[1])
    end
    status = let
        b = _scan_keyword(l, "STATUS")
        Symbol(b[1])
    end
    period = let
        b = _scan_keyword(l, "PERIOD")
        map(b) do pl
            t = split(pl, " ", keepempty=false)
            PeriodicInterval(t[1], parse(Int, t[2]))
        end
    end
    contents = join(filter(_l->!any(startswith.(_l, ["START", "STOP", "STATUS", "PERIOD"])), l), '\n')
    return Todo(contents, start, stop, status, period)
end

function _dump_todo_to_file(filename::String, todo::Todo)
    open(filename, "w") do io
        println(io, "START ", todo.start)
        println(io, "STOP ", todo.stop)
        println(io, "STATUS ", todo.status)
        for p in todo.period
            println(io, "PERIOD ", p.type, " ", p.period)
        end
        println(io, todo.content)
    end
    return nothing
end

function _todo_sort_by(t::Todo)
    if t.start > LONG_AGO_SCHEDULE
        return Date(t.start)
    else
        return Date(t.stop)
    end
end

@include_with _utctoday begin
function _update_periodic_date(t::Todo, dateslater::Period=Month(2))
    _cont = t.content
    _start = t.start
    _stop = t.stop
    todaydate = _utctoday()
    refd = _todo_sort_by(t)
    if !isempty(t.period)
        test_array = range(todaydate, todaydate+dateslater, step=Day(1))
        flagispicked = map(test_array) do td
            any(t.period) do p
                is_scheduled_on_date(td, refd, p)
            end
        end
        i = findfirst(flagispicked)
        if isnothing(i)
            return t
        end
        # println(t, " ", i)
        dshift = Day(test_array[i]-refd)
        _start = (t.start > LONG_AGO_SCHEDULE) ? t.start + dshift : LONG_AGO_SCHEDULE
        _stop = (t.stop < LONG_AFTER_SCHEDULE) ? t.stop + dshift : LONG_AFTER_SCHEDULE
    end
    _status = t.status
    if _status == :none
        if todaydate < _start
            _status = :noted
        elseif (todaydate >= _start) && (todaydate <= _stop)
            _status = :ongoing
        elseif todaydate > _stop
            _status = :finished
        end
    end
    return Todo(_cont, _start, _stop, _status, t.period)
end
end

"""
```
list_todo() -> [(filename, Todo)...]
```
read todo dir and parse file into `Todo`
"""
function list_todo()
    @repoisopened
    if isdir(_todopath())
        todofiles = readdir(_todopath())
        buf = Tuple{String,Todo}[]
        for f in todofiles
            loaded_todo = _scan_todo_from_file(_todoprefix(f))
            push!(buf, (f, _update_periodic_date(loaded_todo)))
        end
        buf = sort(buf, by=x->_todo_sort_by(x[2]), rev=true)
        return buf
    else
        return Tuple{String,Todo}[]
    end
end

"""
```
printall_todo(tl)
```

print todo list `tl`. Default is all todos in `Todos` dir
"""
function printall_todo(tl::Union{Vector{Tuple{String,Todo}},Nothing}=nothing;
    print_finished::Bool=true, print_date_before::Bool=true)
    if isnothing(tl)
        tl = list_todo()
    end
    tday = _utctoday()
    for i = eachindex(tl)
        if !print_finished
            if tl[i][2].status == :finished
                continue
            end
        end
        if !print_date_before
            if _todo_sort_by(tl[i][2]) < tday
                continue
            end
        end
        if i > 1
            if (_todo_sort_by(tl[i-1][2]) >= tday) && (_todo_sort_by(tl[i][2]) < tday)
                printstyled("-"^8, " now ", "-"^8, '\n', color=:red)
            end
        end
        if SETTING["todo_print_format"] == "long"
            println("-"^8)
            println(i, "\t", tl[i][1])
        elseif SETTING["todo_print_format"] == "short"
            print(@sprintf("%3d ", i))
        end
        _todo_printcmd(tl[i][2])
    end
    return nothing
end

"""
```
add_todo(;content, start, stop, status)
```

create a new todo file using input variable, then open the todo file with code editor
"""
function add_todo(;content::String="",
    start::DateTime=LONG_AFTER_SCHEDULE,
    stop::DateTime=LONG_AFTER_SCHEDULE,
    status::Symbol=TODO_STATUS_LIST_SCHEDULE[1])
    @repoisopened
    t_todo = Todo(content, start, stop, status)
    fname = "TODO"*_randstr(16)*".md"
    while isfile(_todoprefix(fname)) || isfile(_todoarchiveprefix(fname))
        fname = "TODO"*_randstr(16)*".md"
    end
    _dump_todo_to_file(_todoprefix(fname), t_todo)
    open_with_program("code_editor", _todoprefix(fname))
    return nothing
end

"""
```
archive_todo_id()
```
move todo file to archive dir, and no longer print it
"""
function archive_todo_id()
    tl = list_todo()
    printall_todo(tl)
    print("\n\nNo.> ")
    i = parse(Int, readline())
    if (i > 0) && (i <= length(tl))
        mv(_todoprefix(tl[i][1]), _todoarchiveprefix(tl[i][1]))
    else
        @error "number not exist"
    end
    return nothing
end

"""
```
open_todo_id()
```
list todos with id, and then open the picked id with code editor
"""
function open_todo_id()
    tl = list_todo()
    printall_todo(tl)
    print("\n\nNo.> ")
    i = parse(Int, readline())
    if (i > 0) && (i <= length(tl))
        open_with_program("code_editor", _todoprefix(tl[i][1]))
    else
        @error "number not exist"
    end
    return nothing
end
