import LibSerialPort

"""
    is_bittle_port(port; timeout = 5)

Checks if the `port` responds with `Start` and `Bittle` upon connection. Only waits for `timeout` seconds for the responses. Returns `true/false`.

See also: [`find_bittle_port`](@ref)
"""
function is_bittle_port(port; timeout = 5)
    is_bittle_port_answer::Bool = false
    try
        sp = LibSerialPort.open(port, 115200; mode = LibSerialPort.SP_MODE_READ)
        LibSerialPort.set_read_timeout(sp, timeout)
        LibSerialPort.set_flow_control(sp)
        LibSerialPort.sp_flush(sp, LibSerialPort.SP_BUF_OUTPUT)
        output = String(readuntil(sp, "Bittle"))
        close(sp)
        is_bittle_port_answer = occursin("Start", output)
    catch _
        is_bittle_port_answer = false
    end
    return is_bittle_port_answer
end

"""
    find_bittle_port(; individual_port_timeout = 5, verbose = true)

Scan all ports and find the one that returns `true` when calling [`is_bittle_port`](@ref). Passes `individual_port_timeout` as `timeout` to `is_bittle_port`. If `verbose=true` (default) prints info messages to track scanning progress. If no port Bittle is found, throws an error.

See also: [`is_bittle_port`](@ref)
"""
function find_bittle_port(; individual_port_timeout = 5, verbose = true)
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
