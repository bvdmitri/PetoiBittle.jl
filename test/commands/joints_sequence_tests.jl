@testitem "MoveJointSequence serializes ASCII pairs after 'm'" begin
    import PetoiBittle: serialize_to_bytes!, MoveJointSequence

    buffer = zeros(UInt8, 32)
    _, nextind = serialize_to_bytes!(buffer, MoveJointSequence((id = 8, angle = 40), (id = 0, angle = -35)), 1)
    @test String(buffer[1:(nextind - 1)]) == "m8 40 0 -35"
end

@testitem "MoveJointSequence accepts a single joint" begin
    import PetoiBittle: serialize_to_bytes!, MoveJointSequence

    buffer = zeros(UInt8, 16)
    _, nextind = serialize_to_bytes!(buffer, MoveJointSequence((id = 0, angle = 30)), 1)
    @test String(buffer[1:(nextind - 1)]) == "m0 30"
end

@testitem "MoveJointSequence writes token + newline over the wire" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, MoveJointSequence

    connection = fake_connection(UInt8[])
    @test send_command(connection, MoveJointSequence((id = 1, angle = 10), (id = 2, angle = -10))) === nothing
    @test connection.sp.written == str_to_bytes("m1 10 2 -10\n")
end
