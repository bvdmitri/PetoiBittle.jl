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

See also: [`PetoiBittle.send_command`](@ref)
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
function PetoiBittle.deserialize_from_bytes(bytes, ::Type{MySpecificCommandResponse}, startidx)
    # ...
    return MySpecificCommandResponse(...)
end
```
to deserialize the response from raw bytes. The `bytes` will contain everything 
that has been captured after the command has been sent until the `\n` symbol.

Default return type is assumed to be [`PetoiBittle.NoResponse`], which is a convention 
that the command does not have any response. In this case the return value of the 
[`PetoiBittle.send_command`](@ref) is `nothing` and the deserialization procedure 
is not being called. That also means everything the Petoi Bittle sends after the command 
has been executed is being ignored.

See also: [`PetoiBittle.deserialize_from_bytes`](@ref)
"""
command_return_type(::Type{T}) where {T <: Command} = NoResponse

"""
    send_command(connection::Connection, command::Command)

A function to send a command to a Bittle robot through opened [`PetoiBittle.Connection`](@ref).

Use
```julia
julia> subtypes(PetoiBittle.Command)
```
to get the list of all available commands.

See also: [`PetoiBittle.Command`](@ref)
"""
function send_command(connection::Connection, command::Command)
    LibSerialPort.sp_drain(connection.sp)
    LibSerialPort.sp_flush(connection.sp, LibSerialPort.SP_BUF_BOTH)
    buffer, nextind = serialize_to_bytes!(connection.buffer, command, 1)
    buffer[nextind] = Constants.char.newline
    @debug "Sending command to Petoi Bittle" command = BufferedString(buffer, 1, nextind)
    GC.@preserve buffer begin
        ntransmitted = LibSerialPort.sp_blocking_write(
            connection.sp.ref, pointer(buffer), nextind, connection.sp.write_timeout_ms
        )
        @assert ntransmitted == nextind "The amount of transmitted bytes is not equal to the buffer size"
        LibSerialPort.sp_drain(connection.sp)

        R = command_return_type(typeof(command))
        if R === NoResponse
            return nothing
        else
            stop_reading_output = false
            readind = 0
            while !stop_reading_output
                nread = LibSerialPort.sp_blocking_read(
                    connection.sp.ref, pointer(buffer) + readind, 1, connection.sp.read_timeout_ms
                )
                @assert nread >= 1 "The amount of read bytes is less than 1 after timeout"
                readind += nread
                @inbounds last_character = buffer[readind]
                if last_character === Constants.char.newline
                    stop_reading_output = true
                end
            end
            @debug "Read output" output = BufferedString(buffer, 1, readind)
            return deserialize_from_bytes(buffer, R, 1)
        end
    end
end
