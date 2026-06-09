@testitem "RawCommand serializes the given token verbatim" begin
    import PetoiBittle: serialize_to_bytes!, RawCommand

    buffer = zeros(UInt8, 16)
    _, nextind = serialize_to_bytes!(buffer, RawCommand("gb"), 1)
    @test buffer[1:(nextind - 1)] == codeunits("gb")
end

@testitem "RawCommand writes token + newline over the wire" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, RawCommand

    connection = fake_connection(UInt8[])
    @test send_command(connection, RawCommand("p")) === nothing
    @test connection.sp.written == str_to_bytes("p\n")
end

@testitem "RawQuery returns the raw response line, trimmed of CR/LF" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, RawQuery, RawResponse

    connection = fake_connection(str_to_bytes("8.40\r\n"))
    response = send_command(connection, RawQuery("b"))

    @test response isa RawResponse
    @test response.line == "8.40"
    # The query token itself was written, newline-terminated.
    @test connection.sp.written == str_to_bytes("b\n")
end

@testitem "RawQuery handles a bare newline-terminated line" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, RawQuery

    connection = fake_connection(str_to_bytes("hello\n"))
    response = send_command(connection, RawQuery("x"))
    @test response.line == "hello"
end
