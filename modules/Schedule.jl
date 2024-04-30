
TODO_STATUS_LIST_SCHEDULE = (:ongoing, :noted, :finished, :failed)
TODO_STATUS_COLOR = Dict(:ongoing=>:yellow, :noted=>:normal, :finished=>:green, :failed=>:red)
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
mutable struct Todo
    content::String
    start::DateTime
    stop::DateTime
    status::Symbol
    subitem::Vector{Todo}
end
```
"""
mutable struct Todo
    content::String
    start::DateTime
    stop::DateTime
    status::Symbol
    subitem::Vector{Todo}
end

"""
```
Todo(content1, start1, stop1, status1, subitem1;
     content, start, stop, status, subitem) -> Todo
```
init a `Todo` object in a more general way. keywork variable will overwrite the same name positioned variable.
"""
function Todo(  content1::AbstractString="",
                start1::DateTime=LONG_AFTER_SCHEDULE,
                stop1::DateTime=LONG_AFTER_SCHEDULE,
                status1::Union{Symbol,AbstractString}=TODO_STATUS_LIST_SCHEDULE[1],
                subitem1::Vector{Todo}=Todo[];
                content::AbstractString="",
                start::DateTime=LONG_AFTER_SCHEDULE,
                stop::DateTime=LONG_AFTER_SCHEDULE,
                status::Union{Symbol,AbstractString}=TODO_STATUS_LIST_SCHEDULE[1],
                subitem::Vector{Todo}=Todo[])
    _c = String(isempty(content1) ? content : content1)
    _start = (start1 == LONG_AFTER_SCHEDULE) ? start : start1
    _stop = (stop1 == LONG_AFTER_SCHEDULE) ? stop : stop1
    _status = (Symbol(status1) == TODO_STATUS_LIST_SCHEDULE[1]) ? Symbol(status) : Symbol(status1)
    _sub = isempty(subitem1) ? subitem : subitem1

    if !(_status in TODO_STATUS_LIST_SCHEDULE)
        error("status must be one of $TODO_STATUS_LIST_SCHEDULE")
    end
    return Todo(String(_c), _start, _stop, _status, _sub)
end

function print(io::IO, todo::Todo)
    Base.print(io, '(', todo.content, "%")
    Base.print(io, todo.start, "%")
    Base.print(io, todo.stop, "%")
    Base.print(io, todo.status, "%")
    for t in todo.subitem
        print(io, t)
    end
    Base.print(io, ")")
    return nothing
end

"""
```
parseTodo_string(s)
```
parse a string into `Todo` object
"""
function parseTodo_string(s::AbstractString)
    level = zeros(Int, length(s))
    lcurrent = 0
    for i = eachindex(s)
        if s[i] == '('
            lcurrent += 1
        end
        level[i] = lcurrent
        if s[i] == ')'
            lcurrent -= 1
        end
    end
    # println(s)
    tl = split(s[findall(level.==1)][2:end-1], '%', keepempty=false)
    c = String(tl[1])
    start = DateTime(tl[2])
    stop = DateTime(tl[3])
    st = Symbol(tl[4])
    isubstart = findall( (level .== 2) .& (collect(s) .== '('))
    isubend = findall( (level .== 2) .& (collect(s) .== ')'))
    if !isempty(isubend)
        subs = map((i, j)->parseTodo_string(s[i:j]), isubstart, isubend)
    else
        subs = Todo[]
    end
    return Todo(c, start, stop, st, subs)
end

==(a::Todo, b::Todo) = string(a) == string(b)

_todopath()= _repoprefix(GALLERY_DIR_NAME_TODO)

_todoprefix(p...) = _repoprefix(GALLERY_DIR_NAME_TODO, p...)

_todoarchivepath() = _repoprefix(GALLERY_DIR_NAME_TODO_ARCHIVE)

_todoarchiveprefix(p...) = _repoprefix(GALLERY_DIR_NAME_TODO_ARCHIVE, p...)

function _todo_printcmd(todo::Todo, indent::String="", indent_n::Integer=4)
    if todo.start < LONG_AFTER_SCHEDULE
        Base.print(indent, todo.start)
    else
        Base.print(indent, "?")
    end
    Base.print("  -->  ")
    if todo.stop < LONG_AFTER_SCHEDULE
        println(todo.stop)
    else
        println("?")
    end
    printstyled(indent, String(todo.status), "\n", color=TODO_STATUS_COLOR[todo.status])
    buf = split(todo.content, '\n', keepempty=true)
    for l in buf
        println(indent, "  ", l)
    end
    for s in todo.subitem
        _todo_printcmd(s, indent*" "^indent_n, indent_n)
    end
    return nothing
end

function _scan_todo_from_file(filename::String)
    l = readlines(filename)
    start = let
        b = split(l[1], " ", keepempty=false)
        DateTime(b[2])
    end
    stop = let
        b = split(l[2], " ", keepempty=false)
        DateTime(b[2])
    end
    status = let
        b = split(l[3], " ", keepempty=false)
        Symbol(b[2])
    end
    contents = join(l[4:end], '\n')
    return Todo(contents, start, stop, status)
end

function _dump_todo_to_file(filename::String, todo::Todo)
    open(filename, "w") do io
        println(io, "START ", todo.start)
        println(io, "STOP ", todo.stop)
        println(io, "STATUS ", todo.status)
        println(io, todo.content)
    end
    return nothing
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
            push!(buf, (f, _scan_todo_from_file(_todoprefix(f))))
        end
        buf = sort(buf, by=x->x[2].stop, rev=true)
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
function printall_todo(tl::Union{Vector{Tuple{String,Todo}},Nothing}=nothing)
    if isnothing(tl)
        tl = list_todo()
    end
    for i = eachindex(tl)
        println("-"^8)
        println(i, "\t", tl[i][1])
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
    Base.print("\n\nNo.> ")
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
    Base.print("\n\nNo.> ")
    i = parse(Int, readline())
    if (i > 0) && (i <= length(tl))
        open_with_program("code_editor", _todoprefix(tl[i][1]))
    else
        @error "number not exist"
    end
    return nothing
end
