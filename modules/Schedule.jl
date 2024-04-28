if !@isdefined TIME_PRECISION_SCHEDULE

TODO_STATUS_LIST_SCHEDULE = (:noted, :processing, :finished, :failed)
TIME_PRECISION_SCHEDULE = Second(1)
LONG_AGO_SCHEDULE = DateTime(1000)
LONG_AFTER_SCHEDULE = DateTime(3000)

function after_period(t::Period)
    global SETTING
    return round(now(), TIME_PRECISION_SCHEDULE) + t
end

"""
```
struct Todo
    content::String
    start::DateTime
    stop::DateTime
    status::Symbol
    subitem::Vector{Todo}
end
```
"""
struct Todo
    content::String
    start::DateTime
    stop::DateTime
    status::Symbol
    subitem::Vector{Todo}
end

"""
```
Todo(content1, start1, stop1, status1, subitem1;
     content, start, stop, status, subitem)
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

end
