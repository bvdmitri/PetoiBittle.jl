import LibSerialPort

"""
    is_bittle_port(port; timeout = DEFAULT_TIMEOUT)

Checks if the `port` responds with `Start` and `Bittle` upon connection. Only waits for `timeout` seconds for the responses (defaults to [`PetoiBittle.DEFAULT_TIMEOUT`](@ref)). Returns `true/false`.

See also: [`find_bittle_port`](@ref)
"""
function is_bittle_port(port::String; timeout = DEFAULT_TIMEOUT)
    try
        connection = connect(port; timeout = timeout)
        is_bittle = connection isa Connection
        if is_bittle
            disconnect(connection)
        end
        return is_bittle
    catch e
        @debug "Is not a bittle port" port error = (e, catch_backtrace())
        return false
    end
end

"""
    find_bittle_port(; individual_port_timeout = DEFAULT_TIMEOUT, verbose = true)

Scan all ports and find the one that returns `true` when calling [`is_bittle_port`](@ref). Passes `individual_port_timeout` as `timeout` to `is_bittle_port` (defaults to [`PetoiBittle.DEFAULT_TIMEOUT`](@ref)). If `verbose=true` (default) prints info messages to track scanning progress. If no port Bittle is found, throws an error.

See also: [`is_bittle_port`](@ref)
"""
function find_bittle_port(; individual_port_timeout = DEFAULT_TIMEOUT, verbose = true)::String
    ports = LibSerialPort.get_port_list()
    sort_hint =
        (port) -> begin
            return occursin("ttyUSB", port) || occursin("ttyACM", port) || (occursin("cu", port) && occursin("modem", port))
        end
    ports = sort(ports, by = sort_hint, rev = true)
    verbose && @info("Start scanning for potential Bittle ports", ports)
    for port in ports
        verbose && @info("Scanning port", port)
        if is_bittle_port(port; timeout = individual_port_timeout)
            verbose && @info("Found Bittle port", port)
            return port
        end
    end
    error("Could not find Bittle port")
end

"""
    Connection

A connection to Petoi Bittle robot. Use [`PetoiBittle.connect`](@ref) to open
a connection.

The connection is parametric in the serial-port type `S`. In normal usage `S` is a
`LibSerialPort.SerialPort`, but the parameter allows substituting an alternative
transport (for example a fake serial port in tests) as long as it implements the
internal transport methods (`_transport_drain!`, `_transport_flush!`, `_transport_write!`
and `_transport_read_byte!`).
"""
struct Connection{S}
    port::String
    sp::S
    buffer::Vector{UInt8}
end

# Transport seam. `send_command` talks to the serial port only through these four
# internal methods, dispatched on the serial-port type. The real implementation wraps
# `LibSerialPort`; tests can provide their own methods for a fake port and thus exercise
# the full `send_command` flow without any hardware.

# Block until all buffered output has been transmitted. Wraps `LibSerialPort.sp_drain`.
_transport_drain!(sp::LibSerialPort.SerialPort) = LibSerialPort.sp_drain(sp)

# Discard the contents of the input and output buffers. Wraps `LibSerialPort.sp_flush`.
_transport_flush!(sp::LibSerialPort.SerialPort) = LibSerialPort.sp_flush(sp, LibSerialPort.SP_BUF_BOTH)

# Write the first `n` bytes of `buffer` to the port and return the number of bytes
# transmitted. Wraps `LibSerialPort.sp_blocking_write`.
function _transport_write!(sp::LibSerialPort.SerialPort, buffer::Vector{UInt8}, n::Int)
    GC.@preserve buffer begin
        return LibSerialPort.sp_blocking_write(sp.ref, pointer(buffer), n, sp.write_timeout_ms)
    end
end

# Read a single byte from the port into `buffer[idx]` and return the number of bytes read
# (`0` on timeout). Wraps `LibSerialPort.sp_blocking_read`.
function _transport_read_byte!(sp::LibSerialPort.SerialPort, buffer::Vector{UInt8}, idx::Int)
    GC.@preserve buffer begin
        return LibSerialPort.sp_blocking_read(sp.ref, pointer(buffer) + (idx - 1), 1, sp.read_timeout_ms)
    end
end

"""
    connect(port::String; [timeout = DEFAULT_TIMEOUT])

Open a [`PetoiBittle.Connection`](@ref) at a specified `port`. Try for no longer
than `timeout` (defaults to [`PetoiBittle.DEFAULT_TIMEOUT`](@ref)). The port must be
manually [`PetoiBittle.disconnect`](@ref)-ed when unneeded. The timeout is also being
used to set read and write timeouts. The connection is opened at the
[`PetoiBittle.BAUD_RATE`](@ref) baud rate with a [`PetoiBittle.BUFFER_CAPACITY`](@ref)-byte buffer.

See [`PetoiBittle.is_bittle_port`](@ref) and [`PetoiBittle.find_bittle_port`](@ref).
"""
function connect(port::String; timeout = DEFAULT_TIMEOUT)
    sp = LibSerialPort.open(port, BAUD_RATE; mode = LibSerialPort.SP_MODE_READ_WRITE)
    LibSerialPort.set_read_timeout(sp, timeout)
    LibSerialPort.set_write_timeout(sp, timeout)
    LibSerialPort.set_flow_control(sp)
    LibSerialPort.sp_flush(sp, LibSerialPort.SP_BUF_BOTH)
    output = String(readuntil(sp, "Bittle"))
    is_bittle_port_answer = occursin("Start", output)
    if !is_bittle_port_answer
        close(sp)
        error("The provided port `$port` is not a Bittle port")
    end
    @debug "Opened Petoi Bittle connection" port
    return Connection(port, sp, zeros(UInt8, BUFFER_CAPACITY))
end

"""
    disconnect(connection::Connection)

Disconnects the `connection`. 

See also: [`PetoiBittle.Connection`](@ref), [`PetoiBittle.connect`](@ref)
"""
function disconnect(connection::Connection)
    close(connection.sp)
    @debug "Closed Petoi Bittle connection" connection.port
end

struct BufferedString
    buffer::Vector{UInt8}
    startidx::Int
    stopidx::Int
end

function Base.show(io::IO, buffered::BufferedString)
    for i in (buffered.startidx):(buffered.stopidx)
        character = buffered.buffer[i]
        if character === Constants.char.newline
            print(io, '\\')
            print(io, 'n')
        elseif character === Constants.char.tab
            print(io, '\\')
            print(io, 't')
        elseif character === Constants.char.caret
            print(io, '\\')
            print(io, 'r')
        else
            print(io, convert(Char, buffered.buffer[i]))
        end
    end
end
