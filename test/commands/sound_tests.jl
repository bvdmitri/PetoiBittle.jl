@testitem "PlayMelody serializes to 'o'" begin
    import PetoiBittle: serialize_to_bytes!, PlayMelody

    buffer = zeros(UInt8, 8)
    _, nextind = serialize_to_bytes!(buffer, PlayMelody(), 1)
    @test buffer[1:(nextind - 1)] == codeunits("o")
end

@testitem "PlayMelody writes token + newline over the wire" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, PlayMelody

    connection = fake_connection(UInt8[])
    @test send_command(connection, PlayMelody()) === nothing
    @test connection.sp.written == str_to_bytes("o\n")
end

@testitem "PlayMusic serializes 'B' + raw tone/duration bytes" begin
    import PetoiBittle: serialize_to_bytes!, PlayMusic, Tone, command_terminator, Constants

    buffer = zeros(UInt8, 16)
    _, nextind = serialize_to_bytes!(buffer, PlayMusic((pitch = 20, duration = 4), (pitch = 22, duration = 8)), 1)
    @test buffer[1] == convert(UInt8, 'B')
    @test buffer[2:5] == UInt8[20, 4, 22, 8]
    @test nextind == 6

    # A rest is encoded as pitch -1 (0xff).
    fill!(buffer, 0)
    serialize_to_bytes!(buffer, PlayMusic((pitch = -1, duration = 2)), 1)
    @test buffer[2] == 0xff
    @test buffer[3] == 0x02

    @test command_terminator(typeof(PlayMusic((pitch = 20, duration = 4)))) == Constants.char.tilde
end

@testitem "PlayMusic writes 'B' + bytes + '~' over the wire" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, PlayMusic

    connection = fake_connection(UInt8[])
    @test send_command(connection, PlayMusic((pitch = 20, duration = 4))) === nothing
    @test connection.sp.written == vcat(str_to_bytes("B"), UInt8[20, 4], str_to_bytes("~"))
end
