CROSSLINK_DB = "crosslink.txt"
BACK_LINK_PREFIX = "<!-- BACKLINK -->"

function _keep_file_in_database(p::String)
    (dir, fn) = splitdir(_abspath(p))
    if any(postfix->endswith(fn, postfix), [".md", ".txt", ".pdf"]) &&
        (!startswith(fn, "http"))
        return true
    else
        return false
    end
end

function _scan_brace_pair(brace_list::Vector{Tuple{Int,Char,Int}})
    if length(brace_list) < 4
        return Tuple{Int,Int,Int,Int}[]
    end
    x = Tuple{Int,Int,Int,Int}[]
    for starti = findall(p->p[2] == '[', brace_list)
        leveli = brace_list[starti][3]
        startj = findnext(p->(p[2] == ']') && (p[3]==leveli), brace_list, starti)
        if isnothing(startj)
            break
        end
        startk = startj + 1
        if startk > length(brace_list)
            break
        end
        if !((brace_list[startk][2] == '(') && (brace_list[startk][3]==leveli))
            break
        end
        startl = findnext(p->(p[2]==')') && (p[3]==leveli), brace_list, startk)
        if isnothing(startl)
            break
        end
        push!(x, (starti, startj, startk, startl))
    end
    return x
end

function _get_link_to(str::String)
    buf = collect(str)
    level = zeros(Int, length(buf))
    l = 0
    for i = eachindex(buf)
        if buf[i] in ['[', '(']
            l += 1
        end
        level[i] = l
        if buf[i] in [']', ')']
            l -= 1
        end
    end
    braces = Tuple{Int, Char, Int}[]
    for i = eachindex(buf)
        if buf[i] in ['[', ']', '(', ')']
            push!(braces, (i, buf[i], level[i]))
        end
    end
    linkbuffer = String[]
    pairidx = _scan_brace_pair(braces)
    for pair in pairidx
        linkstart = braces[pair[3]][1] + 1
        linkstop = braces[pair[4]][1]  - 1
        # println(linkstart, " ", linkstop, " ", String(buf[linkstart:linkstop]))
        push!(linkbuffer, String(buf[linkstart:linkstop]))
    end
    return linkbuffer
end

function _get_links_in_file(file::AbstractString)
    buffer = readlines(file)
    possible_line = String[]
    for l in buffer
        if all(c->c in l, ['[', ']', '(', ')']) && !startswith(l, BACK_LINK_PREFIX)
            push!(possible_line, l)
        end
    end
    linkto = String[]
    (fdir, _) = splitdir(file)
    for l in possible_line
        for str in _get_link_to(l)
            if !_keep_file_in_database(str)
                continue
            end
            if isabspath(str)
                str = _abspath(str)
            else
                str = _abspath(fdir, str)
            end
            if !isfile(str)
                continue
            end
            push!(linkto, str)
        end
    end
    return unique(linkto)
end

function _build_cross_link_db()
    @repoisopened
    mdfiles = String[]
    for rdir in REPOSITORY_MODULE_DIR_RM
        for (r, ds, fs) in walkdir(_repoprefix(rdir))
            for f in fs
                if endswith(f, ".md")
                    push!(mdfiles, _abspath(r, f))
                end
            end
        end
    end

    linkpair = Tuple{String,String}[]
    for mdfile in mdfiles
        lks = _get_links_in_file(mdfile)
        for lk in lks
            push!(linkpair, (mdfile, lk))
        end
    end
    return linkpair
end

@include_with _repoprefix begin
"""
```
dump_crosslink_db_file(filepath)
```
Update crosslink database file. Default is crosslink.txt in repository hidden path.
"""
function dump_crosslink_db_file(filepath::String=_repohiddendirprefix(CROSSLINK_DB))
    @repoisopened
    open(filepath, "w") do io
        for p in _build_cross_link_db()
            println(io, p[1], ';', p[2])
        end
    end
end
end

function _abspath_in_repository(path::String)
    if isfile(path)
        return _abspath(path)
    elseif isfile(_repoprefix(path))
        return _repoprefix(path)
    else
        return ""
    end
end

"""
```
links_to_file(file::String)
```
Get file list that have links to the specified file
"""
function links_to_file(file::String)
    @repoisopened
    db = _build_cross_link_db()
    fpath = _abspath_in_repository(file)
    lkto = String[]
    for p in db
        if p[2] == fpath
            push!(lkto, p[1])
        end
    end
    return lkto
end

"""
```
links_from_file(file::String)
```
Get file list that have links from the specified file
"""
function links_from_file(file::String)
    @repoisopened
    db = _build_cross_link_db()
    fpath = _abspath_in_repository(file)
    lkfrom = String[]
    for p in db
        if p[1] == fpath
            push!(lkfrom, p[2])
        end
    end
    return lkfrom
end

function _file_in_path(file::String, path::String)
    f = splitpath(_abspath(file))
    p = splitpath(_abspath(path))
    if length(f) <= length(p)
        return false
    end
    flag = true
    for i = eachindex(p)
        flag &= f[i] == p[i]
    end
    return flag
end

"""
```
update_backlink(file::String)
```

At the end of `file`, update links to files that link to the specified `file`
"""
function update_backlink(file::String)
    @repoisopened
    blinks = links_to_file(_abspath_in_repository(file))
    repopathlen = length(splitpath(_repopath()))
    buffer = readlines(file)
    bufend = ""
    open(file, "w") do io
        for l in buffer
            if !startswith(l, BACK_LINK_PREFIX)
                println(io, l)
                bufend = l
            end
        end
    end
    open(file, "a") do io
        if !isempty(bufend)
            println(io, "\n")
        end
        println(io, BACK_LINK_PREFIX, "---")
        println(io, BACK_LINK_PREFIX)
        println(io, BACK_LINK_PREFIX, "Links to this file:")
        for lk in blinks
            lkpaths = splitpath(lk)
            if _file_in_path(lk, _repopath())
                println(io, BACK_LINK_PREFIX, "[", join(lkpaths[repopathlen+1:end], '/'),
                    "](", _abspath(lk), ')')
            else
                println(io, BACK_LINK_PREFIX, "[(ext) ", lkpaths[end], "](", _abspath(lk), ')')
            end
        end
    end
end
