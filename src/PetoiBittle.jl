module PetoiBittle
include("constants.jl")
include("preferences.jl")
include("parsers.jl")
include("serializers.jl")
include("connection.jl")

include("commands.jl")
include("commands/move_joints.jl")
include("commands/gyro_stats.jl")
include("commands/gyro_calibration.jl")
include("commands/rest.jl")
include("commands/skills.jl")
include("commands/control.jl")
include("commands/joints_sequence.jl")
include("commands/joints_binary.jl")
include("commands/sound.jl")

# Built-in named skills (gaits, postures, behaviors): a data table plus a generator that
# turns each row into a singleton command, a convenience verb, and their docstrings.
include("commands/generated/skills_table.jl")
include("commands/generated/skills_generator.jl")

# Mark the public API. Nothing is `export`ed on purpose: names like `connect` would clash
# when `using` PetoiBittle alongside other packages, so the API is meant to be accessed as
# `PetoiBittle.connect` etc. The `public` keyword records these as public API without
# importing them into the caller's namespace. `@compat` from Compat.jl lets us use it on
# Julia 1.10 (the bare `public` keyword is only available on 1.11+).
using Compat
@compat public connect, disconnect, find_bittle_port, is_bittle_port
@compat public send_command, before_command, after_command, command_terminator
@compat public Connection, Command, NoResponse, NO_TERMINATOR
@compat public MoveJoints, MoveJointSpec, MoveJointSequence, GyroStats, GyroStatsOutput, GyroCalibrate, Rest, Skill
@compat public Pause, SwitchGyro, Calibrate, Recover
@compat public SetAllJoints, PlayMelody, PlayMusic, Tone
@compat public BUFFER_CAPACITY, BAUD_RATE, MAX_RETRIES, DEFAULT_TIMEOUT
end
