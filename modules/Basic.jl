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
exit_gcra()
```

Exit program and clean temporary file
"""
function exit_gcra()
    open(io->TOML.print(io, SETTING), _SETTING_FILE, "w")
    close_repo()
    exit()
end


_randstr(n::Int=8) = String(rand([collect('a':'z'); collect('A':'Z'); collect('0':'9')], n))

_abspath(p) = replace(abspath(p), "\\"=>"/")

_abspath(p, ps...) = replace(abspath(p, ps...), "\\"=>"/")

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

function rastatus()
    if !isempty(SETTING["repository_path"])
        println("Opened repository: ", _repopath())
    end
    if !isempty(SETTING["project_name"])
        println("Opened project: ", _prjpath())
    end
end
