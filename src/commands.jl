"""
    Command

An abstract type incapsulated all available commands. A command may customize 
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

Default return type is assumed to be [`PetoiBittle.NoResponse`], which is a convention 
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

Deserializes that the content in `bytes` between `startidx` and `endidx` into `Type`. 
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
    LibSerialPort.sp_drain(connection.sp)
    LibSerialPort.sp_flush(connection.sp, LibSerialPort.SP_BUF_BOTH)
    buffer::Vector{UInt8} = connection.buffer
    nextind::Int = 1
    buffer, nextind = serialize_to_bytes!(buffer, command, nextind)
    buffer[nextind] = Constants.char.newline
    @debug "Sending command to Petoi Bittle" command = BufferedString(buffer, 1, nextind)
    GC.@preserve buffer begin
        before_command(connection, command)
        ntransmitted = LibSerialPort.sp_blocking_write(
            connection.sp.ref, pointer(buffer), nextind, connection.sp.write_timeout_ms
        )
        @assert ntransmitted == nextind "The amount of transmitted bytes is not equal to the buffer size"
        LibSerialPort.sp_drain(connection.sp)
        after_command(connection, command)

        R = command_return_type(typeof(command))
        if R === NoResponse
            return nothing
        else
            # Is a simple guard to avoid infinite loops
            # technically we should just timeout on read and never reach this
            maximum_nr_of_retries::Int = 5
            current_attempt::Int = 1
            stop_reading_output::Bool = false
            readind::Int = 0
            while !stop_reading_output || current_attempt > maximum_nr_of_retries
                nread = LibSerialPort.sp_blocking_read(
                    connection.sp.ref, pointer(buffer) + readind, 1, connection.sp.read_timeout_ms
                )
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
end
