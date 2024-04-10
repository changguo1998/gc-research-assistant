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

@include_with REPOSITORY_SETTING_DIR_NAME_RM function exit_gcra()
    open(io->TOML.print(io, SETTING), _SETTING_FILE, "w")
    close_repo()
    exit()
end


@include_without CHARPOOL const CHARPOOL = [collect('a':'z'); collect('A':'Z'); collect('0':'9')]

@include_without randstr function randstr(n::Int=8)
    return String(rand(CHARPOOL, n))
end

@include_without open_with_editor function open_with_editor(path::AbstractString)
    if Sys.iswindows()
        run(Cmd([SETTING["editor"], path]); wait=false)
    else
        run(Cmd([SETTING["editor"], path, "&"]))
    end
end

@include_without open_with_pdf_viewer function open_with_pdf_viewer(path::AbstractString)
    if Sys.iswindows()
        run(Cmd([SETTING["pdf_viewer"], path]); wait=false)
    else
        run(Cmd([SETTING["pdf_viewer"], path, "&"]))
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
