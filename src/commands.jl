"""
    Command

An abstract type incapsulated all available commands. 

Use
```julia
julia> subtypes(PetoiBittle.Command)
```
to get the list of all available commands.

See also: [`PetoiBittle.send_command`](@ref)
"""
abstract type Command end

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
function send_command(connection::Connection, command)
    LibSerialPort.sp_drain(connection.sp)
    buffer, nextind = serialize_to_bytes!(connection.buffer, command, 1)
    buffer[nextind] = Constants.char.newline
    @debug "Sending command to Petoi Bittle" command = String(view(copy(buffer), 1:nextind))
    buffer = copy(buffer)
    GC.@preserve buffer begin
        ntransmitted = LibSerialPort.sp_blocking_write(
            connection.sp.ref, pointer(buffer), nextind, connection.sp.write_timeout_ms
        )
        @assert ntransmitted == nextind "The amount of transmitted bytes is not equal to the buffer size"
        LibSerialPort.sp_drain(connection.sp)
    end
end

