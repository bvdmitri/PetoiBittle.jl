"""
    Pause()

A [`PetoiBittle.Command`](@ref) that pauses the robot's current motion. Sending it again
typically resumes motion. Serializes to the token `"p"`.

See also: [`PetoiBittle.Rest`](@ref) (the firmware's lie-down / rest command, token `"d"`).
"""
struct Pause <: Command end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, ::Pause, startidx::Int)
    return _serialize_token!(bytes, "p", startidx)
end

"""
    SwitchGyro()

A [`PetoiBittle.Command`](@ref) that toggles whether the robot uses its IMU (gyroscope) for
balance and self-recovery. Serializes to the token `"g"`.

To calibrate the gyroscope instead, use [`PetoiBittle.GyroCalibrate`](@ref); to read its
current values, use [`PetoiBittle.GyroStats`](@ref).
"""
struct SwitchGyro <: Command end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, ::SwitchGyro, startidx::Int)
    return _serialize_token!(bytes, "g", startidx)
end

"""
    Calibrate()

A [`PetoiBittle.Command`](@ref) that puts the robot into calibration mode. Serializes to the
token `"c"`. While in calibration mode you can fine-tune the neutral angles of each joint.

See also: [`PetoiBittle.CalibrationPose`](@ref) for the matching standing pose.
"""
struct Calibrate <: Command end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, ::Calibrate, startidx::Int)
    return _serialize_token!(bytes, "c", startidx)
end

"""
    Recover()

A [`PetoiBittle.Command`](@ref) that toggles the robot's automatic posture-recovery behaviour
(getting back up after falling). Serializes to the token `"krc"`.
"""
struct Recover <: Command end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, ::Recover, startidx::Int)
    return _serialize_token!(bytes, "krc", startidx)
end
