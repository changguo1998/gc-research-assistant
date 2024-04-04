GALLERY_DIR_NAME_JOURNAL = "Journal"

if @isdefined REPOSITORY_MODULE_DIR_RM
    if GALLERY_DIR_NAME_JOURNAL ∉ REPOSITORY_MODULE_DIR_RM
        push!(REPOSITORY_MODULE_DIR_RM, GALLERY_DIR_NAME_JOURNAL)
    end
end

TIME_PRECISION_JOURNAL = Day(1)

if !@isdefined open_with_editor
    function open_with_editor(path::AbstractString)
        if Sys.iswindows()
            run(Cmd([settings["editor"], path]); wait=false)
        else
            run(Cmd([settings["editor"], path, "&"]))
        end
    end
end

function open_journal()
    if !isdir(settings["repository_path"])
        @error("repository not opened")
        return nothing
    end
    current_time = today(TimeZone(settings["timezone"]))
    jfilepath = joinpath(settings["repository_path"], GALLERY_DIR_NAME_JOURNAL,
        @sprintf("%04d-%02d-%02d.md", year(current_time), month(current_time), day(current_time)))
    if !isfile(jfilepath)
        t = readlines(joinpath(settings["repository_path"],
            REPOSITORY_SETTING_DIR_NAME_RM, "templates", "journal.md"))
        t[1] = replace(t[1], "{{yyyy}}"=>@sprintf("%04d", year(current_time)))
        t[1] = replace(t[1], "{{mm}}"=>@sprintf("%02d", month(current_time)))
        t[1] = replace(t[1], "{{dd}}"=>@sprintf("%02d", day(current_time)))
        open(io->foreach(l->println(io, l), t), jfilepath, "w")
    end
    open_with_editor(jfilepath)
    return nothing
end

function open_journal_template()
    jfilepath = joinpath(settings["repository_path"], REPOSITORY_SETTING_DIR_NAME_RM, "templates", "journal.md")
    open_with_editor(jfilepath)
    return nothing
end
