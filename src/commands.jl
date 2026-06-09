"""
    Command

An abstract type that encapsulates all available commands. A command may customize
its behaviour by implementing the following interface related functions:
- [`PetoiBittle.command_return_type`](@ref) - specifies the return type of the command

Use
```julia
julia> subtypes(PetoiBittle.Command)
```
to get the list of all available commands.

See also: [`PetoiBittle.send_command`](@ref), [`before_command`](@ref), [`after_command`](@ref)
"""
abstract type Command end

"""
A simple command response, indicating that the command has no response.
"""
struct NoResponse end

"""
A sentinel value returned by [`PetoiBittle.command_terminator`](@ref) to indicate that a
command should be sent without any trailing terminator byte. `0xff` is never a valid
terminator in the Petoi serial protocol, so it is safe as a sentinel.
"""
const NO_TERMINATOR = 0xff

"""
    command_terminator(::Type{<:Command})

Returns the single byte appended after the serialized command bytes when writing to the
robot. The Petoi firmware expects one of three terminators depending on the command:

- [`Constants.char.newline`](@ref PetoiBittle.Constants) (`'\\n'`, the default) for ASCII
  text commands such as skills and `MoveJoints`.
- [`Constants.char.tilde`](@ref PetoiBittle.Constants) (`'~'`) for raw-binary commands that
  carry packed byte arguments (for example a transform-to-frame / set-all-joints command).
- [`PetoiBittle.NO_TERMINATOR`](@ref) for the few commands that take no terminator at all.

Note that this concerns only the *outgoing* command. Responses coming back from the robot
are always newline-terminated regardless of the command terminator, so the response reader
in [`PetoiBittle.send_command`](@ref) always keys on a newline.
"""
command_terminator(::Type{T}) where {T <: Command} = Constants.char.newline

"""
    command_return_type(::Type{<:Command})

Different commands may have different response (return) types while some commands 
don't imply any response. 

If a command has a specific response type, it should implement
```julia
PetoiBittle.command_return_type(::Type{<:MySpecificCommand}) = MySpecificCommandResponse
```
as well as 
```julia
function PetoiBittle.deserialize_from_bytes(bytes, ::Type{MySpecificCommandResponse}, startidx, endidx)
    # ...
    return MySpecificCommandResponse(...)
end
```
to deserialize the response from raw bytes. The `bytes` will contain everything 
that has been captured after the command has been sent until the `\n` symbol.

In this case, a command should also implement
```julia
function PetoiBittle.validate_return_type(bytes, ::Type{MySpecificCommandResponse}, startidx, endidx)
    return true # false
end
```
to validate the content in `bytes`. The [`PetoiBittle.validate_return_type`](@ref) will
be called before [`PetoiBittle.deserialize_from_bytes`](@ref). If the validate function 
returns `false`, the [`PetoiBittle.send_command`](@ref) discards the content in 
`bytes` and read the output again. 

Default return type is assumed to be [`PetoiBittle.NoResponse`](@ref), which is a convention
that the command does not have any response. In this case the return value of the 
[`PetoiBittle.send_command`](@ref) is `nothing` and the deserialization procedure 
is not being called. That also means everything the Petoi Bittle sends after the command 
has been executed is being ignored.

See also: [`PetoiBittle.deserialize_from_bytes`](@ref)
"""
command_return_type(::Type{T}) where {T <: Command} = NoResponse

"""
    validate_return_type(bytes, ::Type, startidx, endidx)

Validates that the content in `bytes` between `startidx` and `endidx` can be 
deserialized into the specified `Type`. See [`PetoiBittle.command_return_type`](@ref)
for more details.
"""
validate_return_type(bytes, ::Type{NoResponse}, _, _) = true

"""
    deserialize_from_bytes(bytes, ::Type, startidx, endidx)

Deserializes the content in `bytes` between `startidx` and `endidx` into `Type`.
See [`PetoiBittle.command_return_type`](@ref) for more details.
"""
deserialize_from_bytes(bytes, ::Type{NoResponse}, _, _) = nothing

"""
    before_command(connection::Connection, command::Command)

A callback that is being called right before sending the command over the `connection`.
A more specific `Command` can add custom logic that needs to be executed 
right before sending the command. By default does nothing.

See also: [`after_command`](@ref)
"""
before_command(::Connection, ::Command) = nothing

"""
    after_command(connection::Connection, command::Command)

A callback that is being called right after sending the command over the `connection`
but before reading the output. A more specific `Command` can add custom logic that needs to be executed 
right after sending the command. By default does nothing.

See also: [`before_command`](@ref)
"""
after_command(::Connection, ::Command) = nothing

"""
    send_command(connection::Connection, command::Command)

A function to send a command to a Bittle robot through opened [`PetoiBittle.Connection`](@ref).

Use
```julia
julia> subtypes(PetoiBittle.Command)
```
to get the list of all available commands.

See also: [`PetoiBittle.Command`](@ref), [`before_command`](@ref), [`after_command`](@ref)
"""
function send_command(connection::Connection, command::Command)
    _transport_drain!(connection.sp)
    _transport_flush!(connection.sp)
    buffer::Vector{UInt8} = connection.buffer
    # `payload_end` is one-past the last serialized command byte.
    buffer, payload_end = serialize_to_bytes!(buffer, command, 1)
    # Append the per-command terminator (newline / '~' / none). `command_terminator` is pure
    # type-dispatch returning a `UInt8` constant, so this stays type-stable and allocation-free.
    terminator::UInt8 = command_terminator(typeof(command))
    write_len::Int = payload_end - 1 # number of bytes to transmit (payload, terminator added below)
    if terminator !== NO_TERMINATOR
        if payload_end > length(buffer)
            error(lazy"The serialized command does not fit into the $(length(buffer))-byte connection buffer")
        end
        @inbounds buffer[payload_end] = terminator
        write_len = payload_end
    end
    @debug "Sending command to Petoi Bittle" command = BufferedString(buffer, 1, write_len)
    before_command(connection, command)
    ntransmitted = _transport_write!(connection.sp, buffer, write_len)
    @assert ntransmitted == write_len "The amount of transmitted bytes is not equal to the buffer size"
    _transport_drain!(connection.sp)
    after_command(connection, command)

    R = command_return_type(typeof(command))
    if R === NoResponse
        return nothing
    else
        # Is a simple guard to avoid infinite loops
        # technically we should just timeout on read and never reach this
        maximum_nr_of_retries::Int = MAX_RETRIES
        current_attempt::Int = 1
        stop_reading_output::Bool = false
        readind::Int = 0
        capacity::Int = length(buffer)
        while !stop_reading_output && current_attempt <= maximum_nr_of_retries
            if readind >= capacity
                error(lazy"The response exceeded the $(capacity)-byte connection buffer before a newline was received")
            end
            nread = _transport_read_byte!(connection.sp, buffer, readind + 1)
            @assert nread >= 1 "The amount of read bytes is less than 1 after timeout"
            readind += nread
            @inbounds last_character = buffer[readind]
            if last_character === Constants.char.newline
                if validate_return_type(buffer, R, 1, readind)
                    stop_reading_output = true
                else
                    @debug "Discarding output" output = BufferedString(buffer, 1, readind)
                    current_attempt += 1
                    readind = 0
                end
            end
        end
        @assert current_attempt <= maximum_nr_of_retries "The output of the command could not be read"
        @debug "Read output" output = BufferedString(buffer, 1, readind)
        return @inbounds deserialize_from_bytes(buffer, R, 1, readind)
    end
end
