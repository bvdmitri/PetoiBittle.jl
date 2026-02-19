import LibSerialPort

"""
    is_bittle_port(port; timeout = 5)

Checks if the `port` responds with `Start` and `Bittle` upon connection. Only waits for `timeout` seconds for the responses. Returns `true/false`.

See also: [`find_bittle_port`](@ref)
"""
function is_bittle_port(port::String; timeout = 5)
    try
        connection = connect(port; timeout = timeout)
        is_bittle = connection isa BittleConnection
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
    find_bittle_port(; individual_port_timeout = 5, verbose = true)

Scan all ports and find the one that returns `true` when calling [`is_bittle_port`](@ref). Passes `individual_port_timeout` as `timeout` to `is_bittle_port`. If `verbose=true` (default) prints info messages to track scanning progress. If no port Bittle is found, throws an error.

See also: [`is_bittle_port`](@ref)
"""
function find_bittle_port(; individual_port_timeout = 5, verbose = true)::String
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

struct BittleConnection
    port::String
    sp::LibSerialPort.SerialPort
    buffer::Vector{UInt8}
end

function connect(port::String; timeout = 5)
    sp = LibSerialPort.open(port, 115200; mode = LibSerialPort.SP_MODE_READ_WRITE)
    LibSerialPort.set_read_timeout(sp, timeout)
    LibSerialPort.set_flow_control(sp)
    LibSerialPort.sp_flush(sp, LibSerialPort.SP_BUF_BOTH)
    output = String(readuntil(sp, "Bittle"))
    is_bittle_port_answer = occursin("Start", output)
    if !is_bittle_port_answer
        close(sp)
        error("The provided port `$port` is not a Bittle port")
    end
    @debug "Opened Petoi Bittle connection" port
    return BittleConnection(port, sp, zeros(UInt8, 256))
end

function send_task(connection::BittleConnection, task)
    LibSerialPort.sp_drain(connection.sp)
    buffer, nextind = serialize_to_bytes!(connection.buffer, task, 1)
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

function disconnect(connection::BittleConnection)
    close(connection.sp)
    @debug "Closed Petoi Bittle connection" connection.port
end
