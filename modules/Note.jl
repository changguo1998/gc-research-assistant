
GALLERY_DIR_NAME_NOTE = "Notes"

@include_with REPOSITORY_MODULE_DIR_RM begin
    if GALLERY_DIR_NAME_NOTE ∉ REPOSITORY_MODULE_DIR_RM
        push!(REPOSITORY_MODULE_DIR_RM, GALLERY_DIR_NAME_NOTE)
    end
end

function update_note_link_pattern(file::String, patstart::String, patstop::String, rep::Function)
    buffer1 = readlines(file)
    buffer2 = String[]
    for l in buffer1
        if contains(l, patstart) && contains(l, patstop)
            m = deepcopy(l)
            while true
                i = findfirst(patstart, m)
                if isnothing(i)
                    break
                end
                j = findnext(patstop, m, i[end])
                if isnothing(j)
                    break
                end
                hsh = String(m[i[end]+1:j[1]-1])
                m = replace(m, m[i[1]:j[end]]=>rep(hsh))
            end
            push!(buffer2, m)
        else
            push!(buffer2, l)
        end
    end
    open(io->foreach(l->println(io, l), buffer2), file, "w")
    return nothing
end

function update_note_link_to_zotero_pdfs()
    @repoisopened
    notelist = list_notes()
    for f in notelist
        update_note_link_pattern(f, LINK_TO_ZOTERO_START, LINK_TO_ZOTERO_STOP, template_zotero_link)
    end
    return nothing
end

_notepath() = _repoprefix(GALLERY_DIR_NAME_NOTE)

_noteprefix(p...) = _repoprefix(GALLERY_DIR_NAME_NOTE, p...)

function list_notes(pat::String="")
    @repoisopened
    list1 = listdirinpattern(endswith(".md"), _notepath())
    if isempty(pat)
        return list1
    else
        return filter(contains(pat), list1)
    end
end

function open_note_name(tag::String)
    @repoisopened
    if endswith(tag, ".md")
        open_with_program("markdown_editor", _noteprefix(tag))
    else
        @warn "note name must end with .md"
    end
end

function open_note_id(pat::String="")
    list = list_notes(pat)
    N = length(splitpath(_notepath()))
    for i = eachindex(list)
        p = splitpath(list[i])
        println(@sprintf("%3d", i), "\t", join(p[N+1:end], "/"))
    end
    print("No.> ")
    i = parse(Int, readline())
    if (i > 0) && (i <= length(list))
        open_note_name(list[i])
    else
        @error "number not exist"
    end
    return nothing
end
