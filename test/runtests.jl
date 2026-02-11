using PetoiBittle
using Test
using Aqua
using JET
using TestItemRunner

@testset "PetoiBittle.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(PetoiBittle)
    end

    @testset "Code linting (JET.jl)" begin
        JET.test_package(PetoiBittle; target_defined_modules = true)
    end

    TestItemRunner.@run_package_tests()
end
