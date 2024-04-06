using Dates, TimeZones, TOML, Printf
import Base: ==, print

for m in readdir(abspath(@__DIR__, "modules"), join=true)
    include(m)
end

for m in readdir(abspath(@__DIR__, "modules"), join=true)
    include(m)
end

global settings = TOML.parsefile(abspath(@__DIR__, "setting.toml"))

# if isdir(settings["repository_path"])
#     open_repo!(settings["repository_path"])
# end
