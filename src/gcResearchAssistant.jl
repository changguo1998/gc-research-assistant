
module gcResearchAssistant

using Dates, TimeZones, TOML, Printf
import Base: ==, print

include(joinpath(@__DIR__, "modules", "Basic.jl"))
include(joinpath(@__DIR__, "modules", "ResourceManager.jl"))
include(joinpath(@__DIR__, "modules", "Schedule.jl"))
include(joinpath(@__DIR__, "modules", "Templates.jl"))
include(joinpath(@__DIR__, "modules", "Backup.jl"))
include(joinpath(@__DIR__, "modules", "Crosslink.jl"))
include(joinpath(@__DIR__, "modules", "Journal.jl"))
include(joinpath(@__DIR__, "modules", "Note.jl"))
include(joinpath(@__DIR__, "modules", "ZoteroAdapter.jl"))
include(joinpath(@__DIR__, "modules", "Literature.jl"))

global SETTING = Dict{String,String}()

# if isdir(SETTING["repository_path"])
#     open_repo!(SETTING["repository_path"])
# end

end
