MODIFIED_DATE_DB = "mdate.txt"

function repo_modified_date()
    @repoisopened
    allfiles = listdirinpattern((x::String,)->true, _repopath())
    mdates = map(f->unix2datetime(mtime(f)), allfiles)
    return (allfiles, mdates)
end

function dump_modified_date(fp::String=_repohiddendirprefix(MODIFIED_DATE_DB))
    (files, dates) = repo_modified_date()
    open(fp, "w") do io
        for i = eachindex(files)
            println(io, files[i], ";", dates[i])
        end
    end
    return nothing
end

function load_modified_date(fp::String=_repohiddendirprefix(MODIFIED_DATE_DB))
    buffer = readlines(fp)
    files = String[]
    dates = DateTime[]
    for l in buffer
        t = split(l, ';', keepempty=false)
        push!(files, t[1])
        push!(dates, DateTime(t[2]))
    end
    return (files, dates)
end
