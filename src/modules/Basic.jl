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
loadsetting!()
```
"""
function loadsetting!()
    global SETTING
    _SETTING_FILE = abspath(homedir(), ".gcra", "setting.toml")
    DEFAULT_SETTING_PATH=abspath(@__DIR__, "..", "..", "setting.toml")

    @debug "_SETTING_FILE: $_SETTING_FILE"
    @debug "DEFAULT_SETTING_PATH: $DEFAULT_SETTING_PATH"
    
    if isfile(_SETTING_FILE)
        if mtime(DEFAULT_SETTING_PATH) > mtime(_SETTING_FILE)
            global SETTING = TOML.parsefile(DEFAULT_SETTING_PATH)
        else
            global SETTING = TOML.parsefile(_SETTING_FILE)
        end
    else
        global SETTING = TOML.parsefile(DEFAULT_SETTING_PATH)
        mkpath(abspath(homedir(), ".gcra"))
        open(io->TOML.print(io, SETTING), _SETTING_FILE, "w")
    end
    return nothing
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

export raexit, raquit

_randstr(n::Int=8) = String(rand([collect('a':'z'); collect('A':'Z'); collect('0':'9')], n))

"""
```
_randfilename(dir, strlen; prefix="", postfix="", issame::Function=(::String)->false)
```
return a new filename that is not exist. additional rule can be set by `issame`
"""
function _randfilename(dir::AbstractString, strlen::Integer;
    prefix::AbstractString="", postfix::AbstractString="",
    issame::Function=(::String)->false)
    fname = prefix*_randstr(strlen)*postfix
    while isfile(joinpath(dir, fname)) || issame(fname)
        fname = prefix*_randstr(strlen)*postfix
    end
    return fname
end

function _printstyledstringlen(s::String, n::Integer=0; align::Symbol=:left, color=:white)
    if iszero(n)
        printstyled(s, color=color)
        return nothing
    end
    if length(s) > n
        printstyled(s[1:n], color=color)
        return nothing
    end
    spaces = " "^(n-length(s))
    if align == :left
        printstyled(s, spaces, color=color)
    elseif align == :right
        printstyled(spaces, s, color=color)
    end
    return nothing
end

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

export rastatus

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

export listdirinpattern

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
