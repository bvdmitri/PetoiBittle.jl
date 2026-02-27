"""
    GyroCalibrate()

A command without arguments. Sends a command to re-calibrate the gyro. 

**Note**: This command should be executed from a "resting" state. An example of a 
resting state might be calibration posture or rest posture. 
Either use the [`PetoiBittle.Skill`](@ref) command or [`PetoiBittle.Rest`](@ref) 
before calibrating the gyro.
"""
struct GyroCalibrate <: Command end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, command::GyroCalibrate, startidx::Int)
    bytes[startidx] = 'g'
    bytes[startidx + 1] = 'c'
    return bytes, startidx + 2
end
