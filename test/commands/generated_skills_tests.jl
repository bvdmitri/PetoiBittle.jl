@testitem "every generated skill serializes to its exact token" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: skills_overview, serialize_to_bytes!, command_terminator, Constants

    for row in skills_overview()
        command = getproperty(PetoiBittle, row.julia_name)()
        buffer = zeros(UInt8, 32)
        _, nextind = serialize_to_bytes!(buffer, command, 1)
        @test buffer[1:(nextind - 1)] == codeunits(row.token)
        @test nextind == length(row.token) + 1
        # All named skills are ASCII `k...` tokens: newline-terminated.
        @test command_terminator(typeof(command)) == Constants.char.newline
    end
end

@testitem "every generated skill writes token + newline over the wire" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: skills_overview, send_command

    for row in skills_overview()
        command = getproperty(PetoiBittle, row.julia_name)()
        connection = fake_connection(UInt8[])
        @test send_command(connection, command) === nothing
        @test connection.sp.written == str_to_bytes(row.token * "\n")
    end
end

@testitem "every generated convenience verb sends its command" setup = [FakeSerialPortUtils] begin
    import PetoiBittle: skills_overview

    for row in skills_overview()
        verb = getproperty(PetoiBittle, row.verb)
        connection = fake_connection(UInt8[])
        @test verb(connection) === nothing
        @test connection.sp.written == str_to_bytes(row.token * "\n")
    end
end

@testitem "generated skill names, verbs and tokens are unique" begin
    import PetoiBittle: skills_overview

    rows = skills_overview()
    tokens = [row.token for row in rows]
    julia_names = [row.julia_name for row in rows]
    verbs = [row.verb for row in rows]

    @test length(unique(tokens)) == length(tokens)
    @test length(unique(julia_names)) == length(julia_names)
    @test length(unique(verbs)) == length(verbs)

    # No generated token may collide with the existing hand-written single-character or
    # short tokens used elsewhere in the package.
    reserved = ("d", "i", "v", "gc")
    @test all(t -> !(t in reserved), tokens)

    # Every category we promised is represented.
    categories = unique([row.category for row in rows])
    @test "Gaits" in categories
    @test "Postures" in categories
    @test "Behaviors" in categories
end

@testitem "generated names are part of the public API" begin
    import PetoiBittle: skills_overview

    @static if VERSION >= v"1.11"
        for row in skills_overview()
            @test Base.ispublic(PetoiBittle, row.julia_name)
            @test Base.ispublic(PetoiBittle, row.verb)
        end
        @test Base.ispublic(PetoiBittle, :skills_overview)
    end
end

@testitem "a representative generated command is type stable and allocation free" setup = [FakeSerialPortUtils] begin
    import PetoiBittle
    import PetoiBittle: WalkForward, walk_forward, serialize_to_bytes!, send_command
    import JET

    # Scope JET to our own module: the intent is to verify that *our* command code is type
    # stable. `send_command` calls `@debug`, whose Base.CoreLogging frontend has an inference
    # imprecision on Julia 1.10 (a runtime dispatch deep inside `typejoin`); that is Base's,
    # not ours, so we filter it out the same way `test_package` does in runtests.jl.
    buffer = zeros(UInt8, 32)
    JET.@test_opt target_modules = (PetoiBittle,) serialize_to_bytes!(buffer, WalkForward(), 1)

    # Measure allocations behind a function barrier; at test-module top level the untyped
    # globals would otherwise box the arguments and report spurious allocations.
    probe(buf) = @allocated serialize_to_bytes!(buf, WalkForward(), 1)
    probe(buffer) # warm up / compile
    @test probe(buffer) == 0

    connection = fake_connection(UInt8[])
    JET.@test_opt target_modules = (PetoiBittle,) send_command(connection, WalkForward())
end
