struct GyroStats <: Command end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, command::GyroStats, startidx::Int)
    bytes[startidx] = convert(UInt8, 'v')
    return bytes, startidx + 1
end

struct GyroStatsOutput
    yaw::Float64
    pitch::Float64
    roll::Float64
    acceleration_x::Int
    acceleration_y::Int
    acceleration_z::Int
end

command_return_type(::Type{GyroStats}) = GyroStatsOutput

Base.@propagate_inbounds function validate_return_type(bytes, ::Type{GyroStatsOutput}, firstindex, lastindex)
    return bytes[firstindex] === Constants.char.tab
end

Base.@propagate_inbounds function deserialize_from_bytes(bytes, ::Type{GyroStatsOutput}, firstindex, lastindex)
    nextind::Int = firstindex + 1 # the output starts with a `\t` symbol
    yaw, nextind = parse_number(Float64, bytes, nextind, lastindex)
    pitch, nextind = parse_number(Float64, bytes, nextind, lastindex)
    roll, nextind = parse_number(Float64, bytes, nextind, lastindex)
    acceleration_x, nextind = parse_number(Int, bytes, nextind, lastindex)
    acceleration_y, nextind = parse_number(Int, bytes, nextind, lastindex)
    acceleration_z, nextind = parse_number(Int, bytes, nextind, lastindex)
    return GyroStatsOutput(yaw, pitch, roll, acceleration_x, acceleration_y, acceleration_z)
end
