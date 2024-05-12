@include_with REPOSITORY_MODULE_DIR_RM begin
    for d in ("Library", "Library/Authors", "Library/Documents", "Library/Publications")
        if d ∉ REPOSITORY_MODULE_DIR_RM
            push!(REPOSITORY_MODULE_DIR_RM, d)
        end
    end
end
