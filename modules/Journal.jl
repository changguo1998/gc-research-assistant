
if @isdefined REPOSITORY_MODULE_DIR_RM
    if GALLERY_DIR_NAME_JOURNAL ∉ REPOSITORY_MODULE_DIR_RM
        push!(REPOSITORY_MODULE_DIR_RM, GALLERY_DIR_NAME_JOURNAL)
    end
end

if !@isdefined GALLERY_DIR_NAME_JOURNAL

GALLERY_DIR_NAME_JOURNAL = "Journal"

TIME_PRECISION_JOURNAL = Day(1)

function open_with_editor(path::AbstractString)
    if Sys.iswindows()
        run(Cmd([settings["editor"], path]); wait=false)
    else
        run(Cmd([settings["editor"], path, "&"]))
    end
end

function open_daily_journal(date::Date=today(TimeZone(settings["timezone"])))
    if !isdir(settings["repository_path"])
        @error("repository not opened")
        return nothing
    end

    jfilepath = joinpath(settings["repository_path"], GALLERY_DIR_NAME_JOURNAL,
        @sprintf("daily_%04d-%02d-%02d.md", year(date), month(date), day(date)))
    if !isfile(jfilepath)
        t = readlines(joinpath(settings["repository_path"],
            REPOSITORY_SETTING_DIR_NAME_RM, "templates", "journal_daily.md"))
        t[1] = replace(t[1], "{{date}}"=>string(date))
        open(io->foreach(l->println(io, l), t), jfilepath, "w")
    end
    open_with_editor(jfilepath)
    return nothing
end

function open_weekly_journal(date::Date=today(TimeZone(settings["timezone"])))
    if !isdir(settings["repository_path"])
        @error("repository not opened")
        return nothing
    end
    d1 = firstdayofweek(date)
    d2 = lastdayofweek(date)
    jfilepath = joinpath(settings["repository_path"], GALLERY_DIR_NAME_JOURNAL,
        @sprintf("weekly_%04d-%02d.md", year(date), week(date)))
    if !isfile(jfilepath)
        t = readlines(joinpath(settings["repository_path"],
            REPOSITORY_SETTING_DIR_NAME_RM, "templates", "journal_weekly.md"))
        s = String[]
        t[1] = replace(t[1],
            "{{yyyy}}"=>@sprintf("%04d", year(d1)),
            "{{ww}}"=>@sprintf("%02d", week(date)),
            "{{date1}}"=>@sprintf("%s", string(d1)),
            "{{date2}}"=>@sprintf("%s", string(d2)))
        i = findfirst(==("REPEAT"), t)
        j = findfirst(==("END"), t)
        append!(s, deepcopy(t[1:i-1]))
        for d = d1:Day(1):d2
            local tmp = t[i+1:j-1]
            dailyfilepath = joinpath(settings["repository_path"],
                GALLERY_DIR_NAME_JOURNAL,
                @sprintf("daily_%04d-%02d-%02d.md", year(d), month(d), day(d)))
            tmp[1] = replace(tmp[1],
                "{{dayofweek}}"=>dayname(d),
                "{{date}}"=>string(d),
                "{{pathtodailyjournal}}"=>dailyfilepath)
            push!(s, "")
            append!(s, deepcopy(tmp))
        end
        open(io->foreach(l->println(io, l), s), jfilepath, "w")
    end
    open_with_editor(jfilepath)
    return nothing
end

function open_monthly_journal(date::Date=today(TimeZone(settings["timezone"])))
    if !isdir(settings["repository_path"])
        @error("repository not opened")
        return nothing
    end
    jfilepath = joinpath(settings["repository_path"], GALLERY_DIR_NAME_JOURNAL,
        @sprintf("monthly_%04d-%02d.md", year(date), month(date)))
    if !isfile(jfilepath)
        t = readlines(joinpath(settings["repository_path"],
            REPOSITORY_SETTING_DIR_NAME_RM, "templates", "journal_monthly.md"))
        s = String[]
        t[1] = replace(t[1], "{{yearmonth}}"=>@sprintf("%04d-%02d", year(date), month(date)))
        i = findfirst(==("REPEAT"), t)
        j = findfirst(==("END"), t)
        append!(s, deepcopy(t[1:i-1]))
        m1 = firstdayofmonth(date)
        m31= lastdayofmonth(date)
        d1 = firstdayofweek(m1)
        d2 = firstdayofweek(m31)
        for d = d1:Day(7):d2
            local tmp = t[i+1:j-1]
            wfilepath = joinpath(settings["repository_path"], GALLERY_DIR_NAME_JOURNAL,
                @sprintf("weekly_%04d-%02d.md", year(d), week(d)))
            tmp[1] = replace(tmp[1],
                "{{weekofyear}}"=>week(d),
                "{{date1}}"=>string(firstdayofweek(d)),
                "{{date2}}"=>string(lastdayofweek(d)),
                "{{pathtoweeklyjournal}}"=>wfilepath)
            push!(s, "")
            append!(s, deepcopy(tmp))
        end
        open(io->foreach(l->println(io, l), s), jfilepath, "w")
    end
    open_with_editor(jfilepath)
    return nothing
end

function open_journal_template()
    jfilepath = joinpath(settings["repository_path"], REPOSITORY_SETTING_DIR_NAME_RM, "templates", "journal.md")
    open_with_editor(jfilepath)
    return nothing
end

const charpool = [collect('a':'z'); collect('A':'Z'); collect('0':'9')]

function randstr(n::Int)
    return String(rand(charpool, n))
end

year_template(d::Date) = @sprintf("# Year %04d", year(d))

month_template(d::Date) = @sprintf("## %s %04d", monthname(d), year(d))

function week_template(d::Date)
    md1 = monthday(firstdayofweek(d))
    md2 = monthday(lastdayofweek(d))
    return @sprintf("### Week %d, (%02d-%02d ~ %02d-%02d)",
        week(d), md1[1], md1[2], md2[1], md2[2])
end

function update_seperator!(s::Vector{String}, d::Date)
    if dayofyear(d) == 1
        push!(s, year_template(d))
    end
    if dayofmonth(d) == 1
        push!(s, month_template(d))
    end
    if dayofweek(d) == 1
        push!(s, week_template(d))
    end
    return nothing
end

function gather_journal(d1::Date, d2::Date)
    s = String[]
    if dayofyear(d1) != 1
        update_seperator!(s, firstdayofyear(d1))
    end
    if dayofmonth(d1) != 1
        update_seperator!(s, firstdayofmonth(d1))
    end
    if dayofweek(d1) != 1
        update_seperator!(s, firstdayofweek(d1))
    end
    for d = d1:Day(1):d2
        update_seperator!(s, d)
        dfile = joinpath(settings["repository_path"],
            GALLERY_DIR_NAME_JOURNAL,
            @sprintf("daily_%04d-%02d-%02d.md",year(d),month(d),day(d))
        )
        if isfile(dfile)
            append!(s, readlines(dfile))
        end
    end

    level = zeros(Int, length(s))
    for i = eachindex(level)
        if startswith(s[i], "# ")
            level[i] = 1
        elseif startswith(s[i], "## ")
            level[i] = 2
        elseif startswith(s[i], "### ")
            level[i] = 3
        elseif startswith(s[i], "#### ")
            level[i] = 4
        else
            level[i] = 7
        end
    end
    plevel = 3
    remain_flag = falses(length(s))
    while plevel > 0
        local flags = level .== plevel
        local i = findfirst(flags)
        while true
            if isnothing(i)
                break
            end
            j = findnext(flags, i+1)
            if isnothing(j)
                if maximum(level[i:end]) <= plevel
                    flags[i] = false
                    i = findfirst(flags)
                else
                    break
                end
            else
                if maximum(level[i:j]) <= plevel
                    flags[i] = false
                    i = findfirst(flags)
                else
                    i = j
                end
            end
        end
        remain_flag .|= flags
        level[(level .== plevel) .& (.!flags)] .= 0
        plevel -= 1
    end
    remain_flag .|= (level .> 3)
    s = s[remain_flag]
    mkpath(joinpath(settings["repository_path"], REPOSITORY_SETTING_DIR_NAME_RM, "var"))
    tmpfile = joinpath(settings["repository_path"], REPOSITORY_SETTING_DIR_NAME_RM, "var", "journal_"*randstr(8)*".md")
    open(tmpfile, "w") do io
        for _l in s
            if startswith(_l, "#")
                println(io, "")
            end
            println(io, _l)
        end
    end
    open_with_editor(tmpfile)
    return nothing
end

end
