"""
    RawCommand(token::AbstractString)

A low-level [`PetoiBittle.Command`](@ref) that sends `token` verbatim (newline-terminated)
without interpreting it. This is the escape hatch for any firmware command that does not yet
have a dedicated typed command in this package, including sensor, pin, and other
device-specific commands whose exact protocol is hardware-dependent.

```julia
# equivalent to sending "p\\n" to the robot
PetoiBittle.send_command(connection, PetoiBittle.RawCommand("p"))
```

For a command that expects a response back, use [`PetoiBittle.RawQuery`](@ref).
"""
struct RawCommand{S <: AbstractString} <: Command
    token::S
end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, command::RawCommand, startidx::Int)
    return _serialize_token!(bytes, command.token, startidx)
end

"""
    RawResponse(line::String)

The result of a [`PetoiBittle.RawQuery`](@ref): the raw response `line` the robot sent back,
trimmed of its trailing carriage return / newline. Parse it yourself according to whatever the
queried command returns.
"""
struct RawResponse
    line::String
end

"""
    RawQuery(token::AbstractString)

A low-level [`PetoiBittle.Command`](@ref) that sends `token` (newline-terminated) and returns
the robot's raw response as a [`PetoiBittle.RawResponse`](@ref). Use this to read sensor, pin,
or status values whose wire format is not (yet) modelled by a dedicated command: you receive
the raw line and parse it as needed (see [`PetoiBittle.parse_number`](@ref)).
"""
struct RawQuery{S <: AbstractString} <: Command
    token::S
end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, command::RawQuery, startidx::Int)
    return _serialize_token!(bytes, command.token, startidx)
end

command_return_type(::Type{<:RawQuery}) = RawResponse

# Any complete line is a valid raw response: the reader has already stopped at a newline.
validate_return_type(bytes, ::Type{RawResponse}, _, _) = true

function deserialize_from_bytes(bytes, ::Type{RawResponse}, firstindex, lastindex)
    last = lastindex
    while last >= firstindex && (bytes[last] === Constants.char.newline || bytes[last] === Constants.char.caret)
        last -= 1
    end
    return RawResponse(String(@inbounds @view bytes[firstindex:last]))
end
