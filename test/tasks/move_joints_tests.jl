@testitem "MoveJoints can be created from a list of NamedTuples" begin
    import PetoiBittle: MoveJoints

    @testset let task = MoveJoints((id = 1, angle = 10), (id = 2, angle = -10))
        @test length(task.joint_movements) == 2
        @test task.joint_movements[1].id === 1
        @test task.joint_movements[1].angle === 10
        @test task.joint_movements[2].id === 2
        @test task.joint_movements[2].angle === -10
    end

    @test_throws "Duplicate `id` found `1`" MoveJoints((id = 1, angle = 10), (id = 1, angle = -10))
    @test_throws "Duplicate `id` found `3`" MoveJoints(
        (id = 1, angle = 10), (id = 2, angle = -10), (id = 3, angle = -10), (id = 4, angle = -10), (id = 3, angle = -20)
    )
end

@testitem "Converstion from NamedTuple to MoveJointSpec" begin
    import PetoiBittle: MoveJointSpec

    @test convert(MoveJointSpec, (id = 1, angle = 10)) == MoveJointSpec(1, 10)
    @test convert(MoveJointSpec, (id = 3, angle = -10)) == MoveJointSpec(3, -10)
    @test convert(MoveJointSpec, (angle = 1, id = 8)) == MoveJointSpec(8, 1)
    @test convert(MoveJointSpec, (angle = 3, id = 6)) == MoveJointSpec(6, 3)

    @test_throws "Extra key `extra`" convert(MoveJointSpec, (id = 1, angle = 2, extra = 3))
    @test_throws "Extra key `extra`" convert(MoveJointSpec, (angle = 2, id = 1, extra = 3))
    @test_throws "Extra key `extra`" convert(MoveJointSpec, (extra = 3, id = 1, angle = 2))

    @test_throws "Missing key `id`" convert(MoveJointSpec, (angle = 2,))
    @test_throws "Missing key `id`" convert(MoveJointSpec, (angle = 2, extra = 3))
    @test_throws "Missing key `id`" convert(MoveJointSpec, (extra = 3, angle = 2))

    @test_throws "Missing key `angle`" convert(MoveJointSpec, (id = 1,))
    @test_throws "Missing key `angle`" convert(MoveJointSpec, (id = 1, extra = 3))
    @test_throws "Missing key `angle`" convert(MoveJointSpec, (extra = 3, id = 1))
end

@testitem "Single MoveJointSpec should be serialized correctly" begin
    import PetoiBittle: MoveJointSpec, serialize_to_bytes!

    @testset let spec = MoveJointSpec(1, 0)
        bytes = zeros(UInt8, 4)
        bytes, nextind = serialize_to_bytes!(bytes, spec, 1)
        @test bytes == [0x31, 0x20, 0x30, 0x00]
        @test nextind == 4
        @test String(bytes) == "1 0\0"
    end

    @testset let spec = MoveJointSpec(8, 300)
        bytes = zeros(UInt8, 8)
        bytes, nextind = serialize_to_bytes!(bytes, spec, 1)
        @test bytes == [0x38, 0x20, 0x33, 0x30, 0x30, 0x00, 0x00, 0x00]
        @test nextind == 6
        @test String(bytes) == "8 300\0\0\0"
    end

    @testset let spec = MoveJointSpec(17, -12)
        bytes = zeros(UInt8, 8)
        bytes, nextind = serialize_to_bytes!(bytes, spec, 2)
        @test bytes == [0x00, 0x31, 0x37, 0x20, 0x2d, 0x31, 0x32, 0x00]
        @test nextind == 8
    end
end

@testitem "Move joints command should be serialized correctly" begin
    import PetoiBittle: MoveJoints, serialize_to_bytes!

    @testset let task = MoveJoints((id = 1, angle = 10), (id = 2, angle = -10))
        bytes = zeros(UInt8, 1024)
        bytes, nextind = serialize_to_bytes!(bytes, task, 1)

        @test String(filter(!iszero, bytes)) == "I 1 10 2 -10"
        @test nextind == 13
    end

    @testset let task = MoveJoints((id = 8, angle = -102), (id = 2, angle = 40), (id = 7, angle = 86))
        bytes = zeros(UInt8, 1024)
        bytes, nextind = serialize_to_bytes!(bytes, task, 1)

        @test String(filter(!iszero, bytes)) == "I 8 -102 2 40 7 86"
        @test nextind == 19
    end
end
