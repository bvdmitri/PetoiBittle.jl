module PetoiBittle
include("constants.jl")
include("parsers.jl")
include("serializers.jl")
include("connection.jl")

include("commands.jl")
include("commands/move_joints.jl")
include("commands/gyro_stats.jl")
include("commands/gyro_calibration.jl")
include("commands/rest.jl")
include("commands/skills.jl")
end
