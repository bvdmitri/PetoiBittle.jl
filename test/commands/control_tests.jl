@testitem "control commands serialize to their tokens" begin
    import PetoiBittle: serialize_to_bytes!, Pause, SwitchGyro, Calibrate, Recover

    serialize(command) = let buffer = zeros(UInt8, 8)
        _, nextind = serialize_to_bytes!(buffer, command, 1)
        buffer[1:(nextind - 1)]
    end

    @test serialize(Pause()) == codeunits("p")
    @test serialize(SwitchGyro()) == codeunits("g")
    @test serialize(Calibrate()) == codeunits("c")
    @test serialize(Recover()) == codeunits("krc")
end

@testitem "control commands write token + newline over the wire" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, Pause, SwitchGyro, Calibrate, Recover

    for (command, token) in ((Pause(), "p"), (SwitchGyro(), "g"), (Calibrate(), "c"), (Recover(), "krc"))
        connection = fake_connection(UInt8[])
        @test send_command(connection, command) === nothing
        @test connection.sp.written == str_to_bytes(token * "\n")
    end
end
