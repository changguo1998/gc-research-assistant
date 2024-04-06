if @isdefined REPOSITORY_SETTING_DIR_NAME_RM

function exit_gc_ra()
    if isdir(settings["repository_path"])
        varpath = joinpath(settings["repository_path"], REPOSITORY_SETTING_DIR_NAME_RM, "var")
        if isdir(varpath)
            @info "cleaning temporary files"
            rm(varpath, recursive=true)
        end
    end
    return exit()
end

end
