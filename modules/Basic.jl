macro include_without(tag, expr)
    return quote
        if !@isdefined $(tag)
            $(esc(expr))
        end
    end
end

macro include_with(tag, expr)
    return quote
        if @isdefined $(tag)
            $(esc(expr))
        end
    end
end

"""
```
raexit(),raquit()
```

Exit program and clean temporary file
"""
function raexit()
    open(io->TOML.print(io, SETTING), _SETTING_FILE, "w")
    close_repo()
    exit()
end

raquit = raexit


_randstr(n::Int=8) = String(rand([collect('a':'z'); collect('A':'Z'); collect('0':'9')], n))

_abspath(ps...) = replace(abspath(ps...), "\\"=>"/")

"""
```
open_with_program(prog_key, filepath)
```
"""
function open_with_program(prog::String, file::AbstractString)
    if isempty(prog)
        @error "$prog is not specified in setting file"
        return nothing
    end
    if Sys.iswindows()
        run(Cmd([SETTING[prog], file]); wait=false)
    else
        run(Cmd([SETTING[prog], file, "&"]); wait=false)
    end
end

macro repoisopened()
    return quote
        if !isdir(SETTING["repository_path"])
            @error "repository not opened"
            return nothing
        end
    end
end

macro prjisopened()
    return quote
        @repoisopened
        if isempty(SETTING["project_name"])
            @error "project not opened"
            return nothing
        end
    end
end

"""
```
rastatus()
```
print current repository and project if they are opened
"""
function rastatus()
    if !isempty(SETTING["repository_path"])
        println("Opened repository: ", _repopath())
    end
    if !isempty(SETTING["project_name"])
        println("Opened project: ", _prjpath())
    end
end

"""
```
listdirinpattern(pattern, dir)
```
"""
function listdirinpattern(pat::Function, dir::String)
    list = String[]
    for (r, ds, fs) in walkdir(dir)
        for f in fs
            if pat(f)
                push!(list, _abspath(r, f))
            end
        end
    end
    return list
end

"""
```
_file_in_path(file::String, path::String)
```
check if `file` in `path` or subdirectories of `path`
"""
function _file_in_path(file::String, path::String)
    f = splitpath(_abspath(file))
    p = splitpath(_abspath(path))
    if length(f) <= length(p)
        return false
    end
    flag = true
    for i = eachindex(p)
        flag &= f[i] == p[i]
    end
    return flag
end
