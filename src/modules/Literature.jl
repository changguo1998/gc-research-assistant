@include_with REPOSITORY_MODULE_DIR_RM begin
    for d in ("Library", "Library/Authors", "Library/Documents", "Library/Publications")
        if d ∉ REPOSITORY_MODULE_DIR_RM
            push!(REPOSITORY_MODULE_DIR_RM, d)
        end
    end
end

# = =====================
#        Author
# = =====================
_libauthorpath() = _repoprefix("Library/Authors")
_libauthorprefix(p...) = _abspath(_libauthorpath(), p...)

struct LibAuthor
    firstname::String
    lastname::String
    fnamecn::String
    lnamecn::String
end

function LibAuthor(fname::AbstractString = "", lname::AbstractString = "",
    fnamecn::AbstractString = "", lnamecn::AbstractString = "")
    return LibAuthor(String(fname), String(lname), String(fnamecn), String(lnamecn))
end

function _load_lib_author_from_file(f::AbstractString)
    t = TOML.parsefile(f)
    return LibAuthor(t["firstname"], t["lastname"], t["firstname_cn"], t["lastname_cn"])
end

function _save_lib_author_to_file(f::AbstractString, au::LibAuthor)
    tdict = Dict{String,String}()
    tdict["firstname"] = au.firstname
    tdict["lastname"] = au.lastname
    tdict["firstname_cn"] = au.fnamecn
    tdict["lastname_cn"] = au.lnamecn
    open(io->TOML.print(io, tdict), f, "w")
    return nothing
end

export list_lib_authors

function list_lib_authors()
    fs = readdir(_libauthorpath())
    return map(f->_load_lib_author_from_file(_libauthorprefix(f)), fs)
end

export add_literater_author

function add_literater_author(name::AbstractString, lastname::AbstractString="";
    firstnamecn::AbstractString="", lastnamecn::AbstractString="")
    _firstname = name
    _lastname = lastname
    if isempty(lastname)
        t = split(name, " ", keepempty=false)
        _firstname = join(t[1:end-1], " ")
        _lastname = String(t[end])
    end
    au = LibAuthor(_firstname, _lastname, firstnamecn, lastnamecn)
    authorlist =
    fname = _randfilename(_libauthorpath(), 4; postfix=".toml")
    _save_lib_author_to_file(_libauthorprefix(fname), au)
    return nothing
end

_libpubpath() = _repoprefix("Library/Publications")
_libpubprefix(p...) = _abspath(_libpubpath(), p...)
_libdocpath() = _repoprefix("Library/Documents")
_libdocprefix(p...) = _abspath(_libdocpath(), p...)
