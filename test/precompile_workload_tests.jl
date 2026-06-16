# Regression guard for the PrecompileTools workload in src/precompile.jl. The workload drives
# `send_command` through a fake serial port for a representative command of every category; if
# any of those calls would error or mis-parse, precompilation itself would fail. This test
# exercises the same surface against the test suite's `FakeSerialPort` so the covered set stays
# in sync and is checked on every CI run.

@testitem "precompile workload commands all run end-to-end" setup = [FakeSerialPortUtils] begin
    import PetoiBittle:
        send_command, RawCommand, WalkForward, Skill, Rest, MoveJoints, MoveJointSequence,
        SetAllJoints, Pause, SwitchGyro, Calibrate, Recover, PlayMelody, PlayMusic, GyroCalibrate

    # Every no-response command in the workload should write its bytes and return `nothing`.
    no_response_commands = (
        RawCommand("p"),
        WalkForward(),
        Skill("balance"),
        Rest(),
        MoveJoints((id = 8, angle = 10), (id = 9, angle = 20)),
        MoveJointSequence((id = 0, angle = 30), (id = 0, angle = -30)),
        SetAllJoints(ntuple(_ -> 0, 16)),
        Pause(),
        SwitchGyro(),
        Calibrate(),
        Recover(),
        PlayMelody(),
        PlayMusic((pitch = 20, duration = 4), (pitch = -1, duration = 2)),
        GyroCalibrate(wait_before = 0.0, wait_after = 0.0, verbose = false),
    )

    for command in no_response_commands
        connection = fake_connection(UInt8[])
        @test send_command(connection, command) === nothing
        @test !isempty(connection.sp.written)
    end
end

@testitem "precompile workload response commands parse their scripted replies" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: send_command, GyroStats, RawQuery, RawResponse

    gyro = send_command(fake_connection(copy(VALID_GYRO_LINE)), GyroStats())
    @test gyro.yaw ≈ 1.0
    @test gyro.pitch ≈ -3.0
    @test gyro.roll ≈ 4.1
    @test gyro.acceleration_x == 2
    @test gyro.acceleration_y == 4
    @test gyro.acceleration_z == 7

    raw = send_command(fake_connection(str_to_bytes("8.40\r\n")), RawQuery("b"))
    @test raw isa RawResponse
    @test raw.line == "8.40"
end
