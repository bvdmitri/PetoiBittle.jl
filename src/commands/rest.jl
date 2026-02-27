"""
    Rest()

A command without arguments. Sends a command to get into resting position.

"""
struct Rest <: Command end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, command::Rest, startidx::Int)
    bytes[startidx] = 'd'
    return bytes, startidx + 1
end
