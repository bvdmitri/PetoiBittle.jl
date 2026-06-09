@testitem "SetAllJoints serializes 'L' + 16 raw signed bytes" begin
    import PetoiBittle: serialize_to_bytes!, SetAllJoints, command_terminator, Constants

    buffer = zeros(UInt8, 32)
    angles = ntuple(_ -> 0, 16)
    _, nextind = serialize_to_bytes!(buffer, SetAllJoints(angles), 1)
    @test buffer[1] == convert(UInt8, 'L')
    @test buffer[2:17] == zeros(UInt8, 16) # 16 angles, all zero
    @test nextind == 18

    # A binary command: terminated by '~', not newline.
    @test command_terminator(SetAllJoints{16}) == Constants.char.tilde
end

@testitem "SetAllJoints encodes negative angles as signed bytes" begin
    import PetoiBittle: serialize_to_bytes!, SetAllJoints

    angles = ntuple(i -> i == 1 ? -1 : (i == 2 ? -90 : 0), 16)
    buffer = zeros(UInt8, 32)
    serialize_to_bytes!(buffer, SetAllJoints(angles), 1)
    @test buffer[2] == 0xff                              # -1
    @test buffer[3] == reinterpret(UInt8, Int8(-90))     # -90
end

@testitem "SetAllJoints requires exactly 16 angles" begin
    import PetoiBittle: SetAllJoints

    @test_throws "16" SetAllJoints((1, 2, 3))
end

@testitem "SetAllJoints rejects out-of-range angles" begin
    import PetoiBittle: serialize_to_bytes!, SetAllJoints

    angles = ntuple(i -> i == 1 ? 200 : 0, 16)
    buffer = zeros(UInt8, 32)
    @test_throws "range" serialize_to_bytes!(buffer, SetAllJoints(angles), 1)
end

@testitem "SetAllJoints writes 'L' + bytes + '~' over the wire" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, SetAllJoints

    connection = fake_connection(UInt8[])
    angles = ntuple(_ -> 0, 16)
    @test send_command(connection, SetAllJoints(angles)) === nothing
    @test connection.sp.written == vcat(str_to_bytes("L"), zeros(UInt8, 16), str_to_bytes("~"))
    @test connection.sp.written[end] == convert(UInt8, '~')
    @test !(convert(UInt8, '\n') in connection.sp.written) # no newline for a binary command
end
