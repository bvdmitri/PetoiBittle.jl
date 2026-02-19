@testitem "Move joints command should be translated to a correct string" begin
    import PetoiBittle: MoveJoints

    task = MoveJoints((id = 1, angle = 10), (id = 2, angle = -10))

    @test string(task) == "I 1 10 2 -10"
end

@testitem "MoveJoints can be created from a list of NamedTuples" begin
    import PetoiBittle: MoveJoints

    @testset let task = MoveJoints((id = 1, angle = 10), (id = 2, angle = -10))
        @test length(task.joint_movements) == 2
        @test task.joint_movements[1].id === 1
        @test task.joint_movements[1].angle === 10
        @test task.joint_movements[2].id === 2
        @test task.joint_movements[2].angle === -10
    end

    @test_throws "Duplicate `id` found `1`" MoveJoints(
        (id = 1, angle = 10),
        (id = 1, angle = -10)
    )
    @test_throws "Duplicate `id` found `3`" MoveJoints(
        (id = 1, angle = 10),
        (id = 2, angle = -10),
        (id = 3, angle = -10),
        (id = 4, angle = -10),
        (id = 3, angle = -20),
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
