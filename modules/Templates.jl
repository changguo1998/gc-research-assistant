# Journal

template_journal_daily_file(date::Date) =  @sprintf("daily_%04d-%02d-%02d.md", year(date), month(date), day(date))

function template_journal_daily_content(date::Date)
    return [string(date), "", "- [ ] item1", "- [ ] item2", "- [ ] ..."]
end

template_journal_weekly_file(date::Date) = @sprintf("weekly_%04d-%02d.md", year(date), week(date))

function template_journal_weekly_content(date::Date)
    d1 = firstdayofweek(date)
    d2 = lastdayofweek(date)
    buffer = String[]
    push!(buffer, @sprintf("### %04d week %d (%s - %s)", year(d1), week(d1), string(d1), string(d2)))
    for d in d1:Day(1):d2
        push!(buffer, "")
        push!(buffer, @sprintf("#### [%s, %s](%s)", dayname(d), string(d),
            _repoprefix(GALLERY_DIR_NAME_JOURNAL, template_journal_daily_file(d))))
    end
    return buffer
end

template_journal_monthly_file(date::Date) = @sprintf("monthly_%04d-%02d.md", year(date), month(date))

function template_journal_monthly_content(date::Date)
    buffer = String[]
    push!(buffer, @sprintf("## %4d-%02d", year(date), month(date)))
    m1 = firstdayofmonth(date)
    m31= lastdayofmonth(date)
    d1 = firstdayofweek(m1)
    d2 = firstdayofweek(m31)
    for d = d1:Day(7):d2
        push!(buffer, "")
        push!(buffer, @sprintf("### [week %d (%s - %s)](%s)", week(d),
            string(firstdayofweek(d)), string(lastdayofweek(d)),
            template_journal_weekly_file(d)))
    end
    return buffer
end

function template_project_log_content(prjname::String)
    return ["# Project Log: "*prjname]
end
