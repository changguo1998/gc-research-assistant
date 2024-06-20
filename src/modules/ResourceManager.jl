@include_without REPOSITORY_SETTING_DIR_NAME_RM const REPOSITORY_SETTING_DIR_NAME_RM = ".gcra"

@include_without REPOSITORY_MODULE_DIR_RM REPOSITORY_MODULE_DIR_RM = String[]

# =================================
#       repository management
# =================================

function _repopath()
    @repoisopened
    return _abspath(SETTING["repository_path"])
end

_repoprefix(path...) = _abspath(_repopath(), path...)

_repohiddendirprefix(path...) = _repoprefix(REPOSITORY_SETTING_DIR_NAME_RM, path...)

"""
```
init_repo(dirc::String)
```

Initialize repository at given directory
"""
function init_repo(dirc::String)
    global REPOSITORY_SETTING_DIR_NAME_RM
    if !isdir(dirc)
        @error "$dirc not exist"
        return nothing
    end
    mkpath(joinpath(dirc, REPOSITORY_SETTING_DIR_NAME_RM))
    for dir in REPOSITORY_MODULE_DIR_RM
        mkpath(joinpath(dirc, dir))
    end
    # mkpath(joinpath(dirc, REPOSITORY_SETTING_DIR_NAME_RM, "templates"))
    # for f in readdir(abspath(@__DIR__, "..", "templates"))
    #     if (f != "setting.toml") && (!isfile(joinpath(dirc, REPOSITORY_SETTING_DIR_NAME_RM, "templates", f)))
    #         cp(joinpath(@__DIR__, "..", "templates", f),
    #         joinpath(dirc, REPOSITORY_SETTING_DIR_NAME_RM, "templates", f))
    #     end
    # end
    return nothing
end

export init_repo

"""
```
open_repo!(path::String)
```

Open repository at given path
"""
function open_repo!(path::String)
    global SETTING
    if !isdir(path)
        error("repository $path not exist")
        return nothing
    end
    SETTING["repository_path"] = _abspath(path)
    return nothing
end

export open_repo!

"""
```
close_repo()
```

Close current repository if any repository is opened
"""
function close_repo()
    @repoisopened
    close_prj()
    update_note_link_to_zotero_pdfs()
    update_repo_backlink()
    dump_crosslink_db_file()
    varpath = _repoprefix(REPOSITORY_SETTING_DIR_NAME_RM, "var")
    if isdir(varpath)
        @info "cleaning temporary files"
        rm(varpath, recursive=true)
    end
    dump_modified_date()
    SETTING["repository_path"] = ""
    return nothing
end

export close_repo

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

_prjprefix(path...) = _abspath(_prjpath(), path...)

"""
```
list_projects()
```

Return available projects in currently opened repository
"""
function list_projects()
    @repoisopened
    prjlist = readdir(_repoprefix("Projects"))
    return prjlist
end

export list_projects

"""
```
init_project(prjname; git::Bool=false)
```

Initialize a project in current repository. if no project name is given, using a random string instead
"""
function init_project(prjname::AbstractString=_randstr(8); git::Bool=false)
    @repoisopened
    prjroot = _repoprefix("Projects", prjname)
    mkpath(joinpath(prjroot, ".ra"))
    if !isfile(joinpath(prjroot, ".ra", "log.md"))
        buffer = template_project_log_content(prjname)
        open(io->foreach(l->println(io, l), buffer), _abspath(prjroot, ".ra", "log.md"), "w")
    end
    if git
        run(Cmd(Cmd(["git", "init", "."]); dir=prjroot))
        run(Cmd(Cmd(["git", "add", "."]); dir=prjroot))
    end
    return nothing
end

export init_project

"""
```
open_prj_name!(prjname)
```

Open project specified by name in current opened repository
"""
function open_prj_name!(prjname::AbstractString)
    @repoisopened
    prjroot = _repoprefix("Projects", prjname)
    if isdir(prjroot)
        SETTING["project_name"] = prjname
    else
        @error "project $prjname not exist"
    end
    return nothing
end

export open_prj_name!

"""
```
open_prj_id!()
```

Print out project list in opened repository, and open project specified by number
"""
function open_prj_id!()
    @repoisopened
    prjlist = list_projects()
    for i = eachindex(prjlist)
        istr = @sprintf("%3d", i)
        if !isempty(SETTING["project_name"])
            if prjlist[i] == SETTING["project_name"]
                println(istr, "*", "\t", prjlist[i])
            else
                println(istr, "\t", prjlist[i])
            end
        else
            println(istr, "\t", prjlist[i])
        end
    end
    print("No.> ")
    i = parse(Int, readline())
    if (i > 0) && (i <= length(prjlist))
        open_prj_name!(prjlist[i])
    else
        @error "number not exist"
    end
    return nothing
end

export open_prj_id!

"""
```
close_prj()
```

Close opened project
"""
function close_prj()
    @prjisopened
    SETTING["project_name"] = ""
    return nothing
end

export close_prj

"""
```
open_prj_dir_with_editor()
```

Open project directory using code editor
"""
function open_prj_dir_with_editor()
    @prjisopened
    open_with_program("code_editor", _prjpath())
end

export open_prj_dir_with_editor
