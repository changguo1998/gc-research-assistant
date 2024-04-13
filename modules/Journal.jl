
@include_with REPOSITORY_MODULE_DIR_RM begin
    if GALLERY_DIR_NAME_JOURNAL ∉ REPOSITORY_MODULE_DIR_RM
        push!(REPOSITORY_MODULE_DIR_RM, GALLERY_DIR_NAME_JOURNAL)
    end
end

GALLERY_DIR_NAME_JOURNAL = "Journal"

TIME_PRECISION_JOURNAL = Day(1)

"""
```
open_daily_journal(date::Date=today(UTC))
```

Open daily format journal in `date`, default is the current time
"""
function open_daily_journal(date::Date=today(UTC))
    @repoisopened
    jfilepath = _repoprefix(GALLERY_DIR_NAME_JOURNAL,
        @sprintf("daily_%04d-%02d-%02d.md", year(date), month(date), day(date)))
    if !isfile(jfilepath)
        t = readlines(_repoprefix(REPOSITORY_SETTING_DIR_NAME_RM, "templates", "journal_daily.md"))
        t[1] = replace(t[1], "{{date}}"=>string(date))
        open(io->foreach(l->println(io, l), t), jfilepath, "w")
    end
    open_with_program("markdown_editor", jfilepath)
end

"""
```
open_weekly_journal(date::Date=today(UTC))
```

Open weekly format journal in `date`, default is the current time
"""
function open_weekly_journal(date::Date=today(UTC))
    @repoisopened
    d1 = firstdayofweek(date)
    d2 = lastdayofweek(date)
    jfilepath = _repoprefix(GALLERY_DIR_NAME_JOURNAL,
        @sprintf("weekly_%04d-%02d.md", year(date), week(date)))
    if !isfile(jfilepath)
        t = readlines(_repoprefix(REPOSITORY_SETTING_DIR_NAME_RM, "templates", "journal_weekly.md"))
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
            dailyfilepath = _repoprefix(GALLERY_DIR_NAME_JOURNAL,
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
    open_with_program("markdown_editor", jfilepath)
end

"""
```
open_monthly_journal(date::Date=today(UTC))
```

Open monthly format journal in `date`, default is the current time
"""
function open_monthly_journal(date::Date=today(UTC))
    @repoisopened
    jfilepath = _repoprefix(GALLERY_DIR_NAME_JOURNAL,
        @sprintf("monthly_%04d-%02d.md", year(date), month(date)))
    if !isfile(jfilepath)
        t = readlines(_repoprefix(REPOSITORY_SETTING_DIR_NAME_RM, "templates", "journal_monthly.md"))
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
            wfilepath = _repoprefix(GALLERY_DIR_NAME_JOURNAL,
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
    open_with_program("markdown_editor", jfilepath)
end

"""
```
open_journal_template_dir()
```

Open directory storing templates
"""
function open_journal_template_dir()
    @repoisopened
    jfilepath = _repoprefix(REPOSITORY_SETTING_DIR_NAME_RM, "templates")
    open_with_program("code_editor", jfilepath)
end

_year_template(d::Date) = @sprintf("# Year %04d", year(d))

_month_template(d::Date) = @sprintf("## %s %04d", monthname(d), year(d))

function _week_template(d::Date)
    md1 = monthday(firstdayofweek(d))
    md2 = monthday(lastdayofweek(d))
    return @sprintf("### Week %d, (%02d-%02d ~ %02d-%02d)",
        week(d), md1[1], md1[2], md2[1], md2[2])
end

function _update_seperator!(s::Vector{String}, d::Date)
    if dayofyear(d) == 1
        push!(s, _year_template(d))
    end
    if dayofmonth(d) == 1
        push!(s, _month_template(d))
    end
    if dayofweek(d) == 1
        push!(s, _week_template(d))
    end
end

"""
```
gather_journal(d1::Date=today(UTC)-Day(7), d2::Date=today(UTC))
```

Gather daily journal from `d1` to `d2` into a temporary file
"""
function gather_journal(d1::Date=today(UTC)-Day(7), d2::Date=today(UTC))
    s = String[]
    if dayofyear(d1) != 1
        _update_seperator!(s, firstdayofyear(d1))
    end
    if dayofmonth(d1) != 1
        _update_seperator!(s, firstdayofmonth(d1))
    end
    if dayofweek(d1) != 1
        _update_seperator!(s, firstdayofweek(d1))
    end
    for d = d1:Day(1):d2
        _update_seperator!(s, d)
        dfile = _repoprefix(
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
    mkpath(_repoprefix(REPOSITORY_SETTING_DIR_NAME_RM, "var"))
    tmpfile = _repoprefix(REPOSITORY_SETTING_DIR_NAME_RM, "var", "journal_"*_randstr(8)*".md")
    open(tmpfile, "w") do io
        for _l in s
            if startswith(_l, "#")
                println(io, "")
            end
            println(io, _l)
        end
    end
    open_with_program("markdown_editor", tmpfile)
    return nothing
end

# =================================
#       project management
# =================================
"""
```
open_prj_log()
```

Open log file belong to current project without any change
"""
function open_prj_log()
    @prjisopened
    open_with_program("markdown_editor", _prjprefix(".ra", "log.md"))
end

"""
```
write_prj_log()
```

Open log file belong to current project, add daily log template
"""
function write_prj_log()
    @prjisopened
    logfilepath = _prjprefix(".ra", "log.md")
    buffer = readlines(logfilepath)
    ct = today(TimeZone(SETTING["timezone"]))
    newline = "# DATE "*string(ct)
    inewline = findfirst(startswith("# DATE "), buffer)
    if isnothing(inewline)
        open(logfilepath, "w") do io
            foreach(l->println(io, l), buffer)
            println(io, "---")
            println(io, newline)
        end
    elseif newline != buffer[inewline]
        open(logfilepath, "w") do io
            foreach(l->println(io, l), buffer[1:newline-1])
            println(io, newline)
            println(io, "---")
            foreach(l->println(io, l), buffer[newline:end])
        end
    end
    open_with_program("markdown_editor", logfilepath)
    return nothing
end
