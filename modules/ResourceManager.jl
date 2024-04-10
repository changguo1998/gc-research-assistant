@include_without REPOSITORY_SETTING_DIR_NAME_RM const REPOSITORY_SETTING_DIR_NAME_RM = ".gcra"

@include_without REPOSITORY_MODULE_DIR_RM REPOSITORY_MODULE_DIR_RM = String[]

repo_setting_file(p::String) = abspath(p, REPOSITORY_SETTING_DIR_NAME_RM, "setting.toml")

# =================================
#       repository management
# =================================

function _repopath()
    @repoisopened
    return SETTING["repository_path"]
end

_repoprefix(path...) = joinpath(_repopath(), path...)

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
        if (f != "setting.toml") && (!isfile(joinpath(path, REPOSITORY_SETTING_DIR_NAME_RM, "templates", f)))
            cp(joinpath(@__DIR__, "..", "templates", f),
            joinpath(path, REPOSITORY_SETTING_DIR_NAME_RM, "templates", f))
        end
    end
    # tsetting = deepcopy(SETTING)
    # tsetting["repository_path"] = abspath(path)
    # open(io->TOML.print(io, tsetting), repo_setting_file(path), "w")
    return nothing
end

function open_repo!(path::String)
    global SETTING
    if !isdir(path)
        error("repository $path not exist")
        return nothing
    end
    SETTING["repository_path"] = abspath(path)
    # SETTING = TOML.parsefile(repo_setting_file(path))
    return nothing
end

function close_repo()
    @repoisopened
    close_prj()
    varpath = _repoprefix(REPOSITORY_SETTING_DIR_NAME_RM, "var")
    if isdir(varpath)
        @info "cleaning temporary files"
        rm(varpath, recursive=true)
    end
    SETTING["repository_path"] = ""
    return nothing
end

# =================================
#       project management
# =================================

if "Projects" ∉ REPOSITORY_MODULE_DIR_RM
    push!(REPOSITORY_MODULE_DIR_RM, "Projects")
end

function _prjpath()
    @prjisopened
    return _repoprefix("Projects", SETTING["project_name"])
end

_prjprefix(path...) = joinpath(_prjpath(), path...)

function list_projects()
    @repoisopened
    prjlist = readdir(_repoprefix("Projects"))
    return prjlist
end

function init_project(prjname::AbstractString=randstr(8); git::Bool=false)
    @repoisopened
    prjroot = _repoprefix("Projects", prjname)
    mkpath(joinpath(prjroot, ".ra"))
    touch(joinpath(prjroot, ".ra", "log.md"))
    if git
        run(Cmd(Cmd(["git", "init", "."]); dir=prjroot))
        run(Cmd(Cmd(["git", "add", "."]); dir=prjroot))
    end
    return nothing
end

function open_prj_by_name!(prjname::AbstractString)
    @repoisopened
    prjroot = _repoprefix("Projects", prjname)
    if isdir(prjroot)
        SETTING["project_name"] = prjname
    else
        @error "project $prjname not exist"
    end
    return nothing
end

function open_prj_by_id!()
    @repoisopened
    prjlist = list_projects()
    for i = eachindex(prjlist)
        println(i, "\t", prjlist[i])
    end
    i = parse(Int, readline())
    if (i > 0) && (i <= length(prjlist))
        open_prj_by_name!(prjlist[i])
    else
        @error "number not exist"
    end
    return nothing
end

function close_prj()
    @prjisopened
    SETTING["project_name"] = ""
    return nothing
end

function open_prj_dir_with_editor()
    @prjisopened
    open_with_editor(_prjpath())
end
