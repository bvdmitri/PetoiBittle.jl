@testitem "the curated public API is marked public" begin
    import PetoiBittle

    # Nothing should be exported (the API is accessed as `PetoiBittle.<name>`). Note that
    # on Julia 1.11+ `names` also returns names marked `public`, so we check exported-ness
    # explicitly rather than relying on `names` being empty.
    exported = filter(n -> n !== :PetoiBittle && Base.isexported(PetoiBittle, n), names(PetoiBittle; all = true))
    @test isempty(exported)

    # `Base.ispublic` is only available on Julia 1.11+. The package supports 1.10, where the
    # `@compat public` declarations are a no-op, so we only assert the marking where it exists.
    @static if VERSION >= v"1.11"
        public_names = (
            :connect,
            :disconnect,
            :find_bittle_port,
            :is_bittle_port,
            :send_command,
            :before_command,
            :after_command,
            :command_terminator,
            :Connection,
            :Command,
            :NoResponse,
            :NO_TERMINATOR,
            :MoveJoints,
            :MoveJointSpec,
            :MoveJointSequence,
            :Pause,
            :SwitchGyro,
            :Calibrate,
            :Recover,
            :SetAllJoints,
            :PlayMelody,
            :PlayMusic,
            :Tone,
            :RawCommand,
            :RawQuery,
            :RawResponse,
            :GyroStats,
            :GyroStatsOutput,
            :GyroCalibrate,
            :Rest,
            :Skill,
            :BUFFER_CAPACITY,
            :BAUD_RATE,
            :MAX_RETRIES,
            :DEFAULT_TIMEOUT
        )
        for name in public_names
            @test Base.ispublic(PetoiBittle, name)
        end
    end
end
