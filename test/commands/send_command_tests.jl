@testsnippet FakeSerialPortUtils begin
    import PetoiBittle: Connection, _transport_drain!, _transport_flush!, _transport_write!, _transport_read_byte!

    # A fake serial port that scripts the bytes the "device" sends back and records the
    # bytes written to it. It lets us exercise the full `send_command` flow without any
    # hardware. `read_pos` advances one byte per `_transport_read_byte!`; once the scripted
    # bytes are exhausted, reads return 0 to mimic a timeout.
    mutable struct FakeSerialPort
        to_read::Vector{UInt8}
        read_pos::Int
        written::Vector{UInt8}
    end

    FakeSerialPort(to_read::Vector{UInt8}) = FakeSerialPort(to_read, 0, UInt8[])

    str_to_bytes(str) = convert.(UInt8, collect(string(str)))

    function fake_connection(to_read::Vector{UInt8}; buffer_capacity = 256)
        return Connection("fake", FakeSerialPort(to_read), zeros(UInt8, buffer_capacity))
    end

    _transport_drain!(::FakeSerialPort) = nothing
    _transport_flush!(::FakeSerialPort) = nothing

    function _transport_write!(sp::FakeSerialPort, buffer::Vector{UInt8}, n::Int)
        append!(sp.written, view(buffer, 1:n))
        return n
    end

    function _transport_read_byte!(sp::FakeSerialPort, buffer::Vector{UInt8}, idx::Int)
        if sp.read_pos >= length(sp.to_read)
            return 0 # no more scripted bytes: simulate a read timeout
        end
        sp.read_pos += 1
        buffer[idx] = sp.to_read[sp.read_pos]
        return 1
    end

    # A valid GyroStats response line (starts with a tab, ends with a newline).
    const VALID_GYRO_LINE = str_to_bytes("\t1\t-3\t4.1\t2\t4\t7\r\n")
end

@testsnippet TerminatorCommands begin
    import PetoiBittle: Command, serialize_to_bytes!, command_terminator, NO_TERMINATOR, Constants

    # Three throwaway commands, one per terminator mode, used to exercise the write path of
    # `send_command` in isolation. All are `NoResponse` so `send_command` only writes.

    # Default terminator (newline). Serializes a single 'a'.
    struct DefaultTerminatorCommand <: Command end
    Base.@propagate_inbounds function serialize_to_bytes!(bytes, ::DefaultTerminatorCommand, startidx::Int)
        bytes[startidx] = convert(UInt8, 'a')
        return bytes, startidx + 1
    end

    # Binary terminator ('~'). Serializes a single 'L'.
    struct TildeTerminatorCommand <: Command end
    Base.@propagate_inbounds function serialize_to_bytes!(bytes, ::TildeTerminatorCommand, startidx::Int)
        bytes[startidx] = convert(UInt8, 'L')
        return bytes, startidx + 1
    end
    command_terminator(::Type{TildeTerminatorCommand}) = Constants.char.tilde

    # No terminator. Serializes a single 'M'.
    struct NoTerminatorCommand <: Command end
    Base.@propagate_inbounds function serialize_to_bytes!(bytes, ::NoTerminatorCommand, startidx::Int)
        bytes[startidx] = convert(UInt8, 'M')
        return bytes, startidx + 1
    end
    command_terminator(::Type{NoTerminatorCommand}) = NO_TERMINATOR

    # Serializes a payload that exactly fills a 4-byte buffer, leaving no room for the
    # appended terminator. Used to test the buffer-bounds guard.
    struct OverflowCommand <: Command end
    Base.@propagate_inbounds function serialize_to_bytes!(bytes, ::OverflowCommand, startidx::Int)
        nextind = startidx
        for _ in 1:4
            bytes[nextind] = convert(UInt8, 'x')
            nextind += 1
        end
        return bytes, nextind
    end
end

@testitem "send_command appends a newline terminator by default" setup = [FakeSerialPortUtils, TerminatorCommands] begin
    import PetoiBittle: send_command

    connection = fake_connection(UInt8[])
    @test send_command(connection, DefaultTerminatorCommand()) === nothing
    @test connection.sp.written == str_to_bytes("a\n")
end

@testitem "send_command appends a tilde terminator for binary commands" setup = [FakeSerialPortUtils, TerminatorCommands] begin
    import PetoiBittle: send_command

    connection = fake_connection(UInt8[])
    @test send_command(connection, TildeTerminatorCommand()) === nothing
    # Exactly the token and a '~', with no trailing newline.
    @test connection.sp.written == str_to_bytes("L~")
end

@testitem "send_command appends nothing for no-terminator commands" setup = [FakeSerialPortUtils, TerminatorCommands] begin
    import PetoiBittle: send_command

    connection = fake_connection(UInt8[])
    @test send_command(connection, NoTerminatorCommand()) === nothing
    @test connection.sp.written == str_to_bytes("M")
end

@testitem "command_terminator defaults to newline" setup = [FakeSerialPortUtils, TerminatorCommands] begin
    import PetoiBittle: command_terminator, Constants

    @test command_terminator(DefaultTerminatorCommand) == Constants.char.newline
    @test command_terminator(TildeTerminatorCommand) == Constants.char.tilde
end

@testitem "send_command errors cleanly when the command overflows the buffer" setup = [FakeSerialPortUtils, TerminatorCommands] begin
    import PetoiBittle: send_command, Command, serialize_to_bytes!

    # A command whose serialized payload alone fills the entire buffer, leaving no room for
    # the terminator. `send_command` must error rather than write out of bounds.
    connection = fake_connection(UInt8[]; buffer_capacity = 4)
    @test_throws "buffer" send_command(connection, OverflowCommand())
end

@testitem "send_command returns the parsed response on the happy path" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, GyroStats

    connection = fake_connection(copy(VALID_GYRO_LINE))
    output = send_command(connection, GyroStats())

    @test output.yaw ≈ 1.0
    @test output.pitch ≈ -3.0
    @test output.roll ≈ 4.1
    @test output.acceleration_x == 2
    @test output.acceleration_y == 4
    @test output.acceleration_z == 7

    # The command itself should have been written, terminated by a newline.
    @test connection.sp.written == str_to_bytes("v\n")
end

@testitem "send_command retries once when the first line is invalid then succeeds" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, GyroStats

    to_read = vcat(str_to_bytes("garbage\n"), VALID_GYRO_LINE)
    connection = fake_connection(to_read)
    output = send_command(connection, GyroStats())

    @test output.yaw ≈ 1.0
    @test output.acceleration_z == 7
end

@testitem "send_command gives up with a clear error after exhausting retries" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, GyroStats

    # Six invalid lines: more than the retry budget, so the device never times out before
    # the retry guard should fire.
    to_read = reduce(vcat, fill(str_to_bytes("garbage\n"), 6))
    connection = fake_connection(to_read)

    @test_throws "The output of the command could not be read" send_command(connection, GyroStats())
end

@testitem "send_command errors cleanly when the response overflows the buffer" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, GyroStats

    # A response that never contains a newline and is longer than the connection buffer.
    to_read = fill(convert(UInt8, 'x'), 64)
    connection = fake_connection(to_read; buffer_capacity = 8)

    @test_throws "buffer" send_command(connection, GyroStats())
end
