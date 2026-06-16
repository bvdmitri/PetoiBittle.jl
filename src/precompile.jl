using PrecompileTools

# A minimal, internal fake serial port used only by the precompile workload below. It mirrors
# the `FakeSerialPort` from the test suite: it scripts the bytes the "device" sends back and
# records what was written, so the full `send_command` flow can be exercised at precompile
# time without any hardware. It is intentionally NOT part of the public API.
#
# Because `Connection{S}` is parametric in the serial-port type and the serialize/parse/dispatch
# machinery operates on the shared `buffer::Vector{UInt8}` (independent of `S`), running the
# workload through this fake port compiles and caches the per-command-type code that is actually
# expensive on first use. The LibSerialPort-specific specialization of `send_command` itself is a
# small shell that is recompiled at runtime once real hardware is connected.
mutable struct _PrecompileSerialPort
    to_read::Vector{UInt8}
    read_pos::Int
    written::Vector{UInt8}
end

_PrecompileSerialPort(to_read::Vector{UInt8}) = _PrecompileSerialPort(to_read, 0, UInt8[])

_transport_drain!(::_PrecompileSerialPort) = nothing
_transport_flush!(::_PrecompileSerialPort) = nothing

function _transport_write!(sp::_PrecompileSerialPort, buffer::Vector{UInt8}, n::Int)
    append!(sp.written, view(buffer, 1:n))
    return n
end

function _transport_read_byte!(sp::_PrecompileSerialPort, buffer::Vector{UInt8}, idx::Int)
    if sp.read_pos >= length(sp.to_read)
        return 0 # no more scripted bytes: simulate a read timeout
    end
    sp.read_pos += 1
    buffer[idx] = sp.to_read[sp.read_pos]
    return 1
end

_precompile_connection(to_read::Vector{UInt8} = UInt8[]) =
    Connection("precompile", _PrecompileSerialPort(to_read), zeros(UInt8, BUFFER_CAPACITY))

@setup_workload begin
    # Guarded by a compile-time preference so the workload can be turned off without editing
    # source (see `PetoiBittle.PRECOMPILE_WORKLOAD`).
    if PRECOMPILE_WORKLOAD
        # A valid GyroStats response line (tab-prefixed, CR/LF-terminated), matching the wire
        # format the firmware sends back.
        valid_gyro = Vector{UInt8}("\t1\t-3\t4.1\t2\t4\t7\r\n")

        @compile_workload begin
            nores = _precompile_connection()

            # No-response commands, covering each terminator mode (newline, '~', and the
            # before/after callbacks) and every serialization path.
            send_command(nores, RawCommand("p"))                                   # raw token, newline
            send_command(nores, WalkForward())                                     # generated singleton skill
            send_command(nores, Skill("balance"))                                  # parametric, name-iterating skill
            send_command(nores, Rest())
            send_command(nores, MoveJoints((id = 8, angle = 10), (id = 9, angle = 20)))
            send_command(nores, MoveJointSequence((id = 0, angle = 30), (id = 0, angle = -30)))
            send_command(nores, SetAllJoints(ntuple(_ -> 0, 16)))                  # binary, '~' terminator
            send_command(nores, Pause())
            send_command(nores, SwitchGyro())
            send_command(nores, Calibrate())
            send_command(nores, Recover())
            send_command(nores, PlayMelody())
            send_command(nores, PlayMusic((pitch = 20, duration = 4), (pitch = -1, duration = 2)))
            # Zero waits keep precompilation fast; this still exercises the before/after callbacks
            # and the follow-up save command.
            send_command(nores, GyroCalibrate(wait_before = 0.0, wait_after = 0.0, verbose = false))

            # Response-parsing commands (the read/validate/retry loop plus int and float parsing).
            send_command(_precompile_connection(copy(valid_gyro)), GyroStats())
            send_command(_precompile_connection(Vector{UInt8}("8.40\r\n")), RawQuery("b"))
        end
    end
end
