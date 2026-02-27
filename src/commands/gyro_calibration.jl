"""
    GyroCalibrate(; wait_before::Float64 = 2.0, wait_after::Float64 = 15.0, verbose = true)

Sends a command to re-calibrate the gyro. The `wait_before` and `wait_after` arguments 
are in seconds. The `verbose` setting controls whether to print informational 
messages or not.

**Note**: This command should be executed from a "resting" state. An example of a 
resting state might be calibration posture or rest posture. 
Either use the [`PetoiBittle.Skill`](@ref) command or [`PetoiBittle.Rest`](@ref) 
before calibrating the gyro.

It is advised to wait a little bit before starting the calibration process (especially 
after executing a [`PetoiBittle.Skill`](@ref)). By default waits for 2 seconds. 
The entire process also takes some time, but it is possible to configure it.
By default calibrates for 15 seconds. Uses `sleep` under the hood.
"""
Base.@kwdef struct GyroCalibrate <: Command
    wait_before::Float64 = 2.0
    wait_after::Float64 = 15.0
    verbose::Bool = true
end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, ::GyroCalibrate, startidx::Int)
    bytes[startidx] = 'g'
    bytes[startidx + 1] = 'c'
    return bytes, startidx + 2
end

function before_command(::Connection, command::GyroCalibrate)
    if command.verbose
        @info lazy"Calibrating gyro begins in $(command.wait_before) seconds"
    end
    sleep(command.wait_before)
end

function after_command(connection::Connection, command::GyroCalibrate)
    if command.verbose
        @info lazy"Calibrating gyro for $(command.wait_after) seconds"
    end
    sleep(command.wait_after)
    send_command(connection, GyroCalibrateSave())
    if command.verbose 
        @info "Gyro has been calibrated"
    end
end

struct GyroCalibrateSave <: Command end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, ::GyroCalibrateSave, startidx::Int)
    bytes[startidx] = 's'
    return bytes, startidx + 1
end
