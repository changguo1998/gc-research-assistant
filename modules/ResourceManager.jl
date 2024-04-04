
REPOSITORY_SETTING_DIR_NAME_RM = ".gcra"

REPOSITORY_MODULE_DIR_RM = String[]
if @isdefined GALLERY_DIR_NAME_JOURNAL
    push!(REPOSITORY_MODULE_DIR_RM, GALLERY_DIR_NAME_JOURNAL)
end

if !@isdefined open_with_pdf_viewer
    function open_with_pdf_viewer(path::AbstractString)
        if Sys.iswindows()
            run(Cmd([settings["pdf_viewer"], path]); wait=false)
        else
            run(Cmd([settings["pdf_viewer"], path, "&"]))
        end
    end
end

repo_setting_file(p::String) = abspath(p, REPOSITORY_SETTING_DIR_NAME_RM, "setting.toml")

function init_repo(path::String)
    global REPOSITORY_SETTING_DIR_NAME_RM
    if !ispath(path)
        @error "$path not exist"
        return nothing
    end
    mkpath(joinpath(path, REPOSITORY_SETTING_DIR_NAME_RM))
    for dir in REPOSITORY_MODULE_DIR_RM
        mkpath(joinpath(path, dir))
    end
    mkpath(joinpath(path, REPOSITORY_SETTING_DIR_NAME_RM, "templates"))
    for f in readdir(abspath(@__DIR__, "..", "templates"))
        if f != "setting.toml"
            cp(joinpath(@__DIR__, "..", "templates", f),
            joinpath(path, REPOSITORY_SETTING_DIR_NAME_RM, "templates", f))
        end
    end
    tsetting = deepcopy(settings)
    tsetting["repository_path"] = abspath(path)
    open(io->TOML.print(io, tsetting), repo_setting_file(path), "w")
    return nothing
end

function open_repo!(path::String)
    global settings
    if !isfile(repo_setting_file(path))
        error("repository $path not exist")
    end
    settings = TOML.parsefile(repo_setting_file(path))
    return nothing
end

function open_pdf_file(path::String)
    open_with_pdf_viewer(path)
    return nothing
end
