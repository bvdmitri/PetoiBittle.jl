@testitem "all fixed command tokens are distinct" begin
    import PetoiBittle: skills_overview, serialize_to_bytes!
    import PetoiBittle: Rest, Pause, SwitchGyro, Calibrate, Recover, PlayMelody, GyroStats

    # Serialize a no-argument command and read back the token it produced.
    token_of(command) = let buffer = zeros(UInt8, 16)
        _, nextind = serialize_to_bytes!(buffer, command, 1)
        String(buffer[1:(nextind - 1)])
    end

    # The fixed-token singleton commands, serialized for real.
    singleton_tokens = Dict(
        "Rest"       => token_of(Rest()),
        "Pause"      => token_of(Pause()),
        "SwitchGyro" => token_of(SwitchGyro()),
        "Calibrate"  => token_of(Calibrate()),
        "Recover"    => token_of(Recover()),
        "PlayMelody" => token_of(PlayMelody()),
        "GyroStats"  => token_of(GyroStats())
    )

    # Spot-check a couple of the tokens against the protocol.
    @test singleton_tokens["Rest"] == "d"
    @test singleton_tokens["Pause"] == "p"
    @test singleton_tokens["GyroStats"] == "v"

    # The leading tokens of the argument-carrying / multi-byte commands. Their full
    # serialization is checked in their own test files; here we only guard collisions.
    other_tokens = ["i", "m", "L", "B", "gc"] # MoveJoints, MoveJointSequence, SetAllJoints, PlayMusic, GyroCalibrate

    generated_tokens = [row.token for row in skills_overview()]

    all_tokens = vcat(collect(values(singleton_tokens)), other_tokens, generated_tokens)
    @test length(unique(all_tokens)) == length(all_tokens)
end
