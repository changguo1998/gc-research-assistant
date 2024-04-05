current_setting = abspath(@__DIR__, "..", "setting.toml")
template_path = abspath(@__DIR__, "..", "templates", "setting.toml")

io_in = open(current_setting, "r")
io_out = open(template_path, "w")

while !eof(io_in)
    l = readline(io_in)
    i_comment = findfirst('#', l)
    i_string_start = findfirst('"', l)
    i_string_stop = isnothing(i_string_start) ? nothing : findnext('"', l, i_string_start+1)
    if isnothing(i_string_start)
        println(io_out, l)
    else
        newl = String(l[1:i_string_start]*l[i_string_stop:end])
        println(io_out, newl)
    end
end

close(io_in)
close(io_out)
