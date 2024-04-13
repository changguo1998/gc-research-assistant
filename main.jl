using Dates, TimeZones, TOML, Printf
import Base: ==, print

include(joinpath(@__DIR__, "modules", "Basic.jl"))

for m in readdir(abspath(@__DIR__, "modules"), join=true)
    include(m)
end

# reload code for interaction between modules
for m in readdir(abspath(@__DIR__, "modules"), join=true)
    include(m)
end

global _SETTING_FILE = abspath(homedir(), ".gcra", "setting.toml")

if isfile(_SETTING_FILE)
    if mtime(abspath(@__DIR__, "setting.toml")) > mtime(_SETTING_FILE)
        global SETTING = TOML.parsefile(abspath(@__DIR__, "setting.toml"))
    else
        global SETTING = TOML.parsefile(_SETTING_FILE)
    end
else
    global SETTING = TOML.parsefile(abspath(@__DIR__, "setting.toml"))
    mkpath(abspath(homedir(), ".gcra"))
    open(io->TOML.print(io, SETTING), _SETTING_FILE, "w")
end

# if isdir(SETTING["repository_path"])
#     open_repo!(SETTING["repository_path"])
# end
