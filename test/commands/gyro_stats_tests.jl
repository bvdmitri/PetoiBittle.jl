@testitem "GyroStats command should be correctly serialized" begin
    import PetoiBittle: GyroStats, serialize_to_bytes!

    bytes = zeros(UInt8, 4)
    rbytes, nextind = serialize_to_bytes!(bytes, GyroStats(), 1)

    @test bytes === rbytes
    @test nextind == 2
    @test bytes == UInt8['v', 0, 0, 0]

    bytes = zeros(UInt8, 4)
    rbytes, nextind = serialize_to_bytes!(bytes, GyroStats(), 3)

    @test bytes === rbytes
    @test nextind == 4
    @test bytes == UInt8[0, 0, 'v', 0]
end

@testitem "GyroStatsOutput can be read from a binary format" begin
    import PetoiBittle: GyroStatsOutput, validate_return_type, deserialize_from_bytes
    buffer = UInt8['\t', '1', '\t', '-', '3', '\t', '4', '.', '1', '\t', '2', '\t', '4', '\t', '7', '\r', '\n']

    @test validate_return_type(buffer, GyroStatsOutput, 1, length(buffer))
    @test !validate_return_type(buffer, GyroStatsOutput, 2, length(buffer))

    output = deserialize_from_bytes(buffer, GyroStatsOutput, 1, length(buffer))
    @test output.yaw ≈ 1.0
    @test output.pitch ≈ -3.0
    @test output.roll ≈ 4.1
    @test output.acceleration_x == 2
    @test output.acceleration_y == 4
    @test output.acceleration_z == 7

    @test !validate_return_type(UInt8['G'], GyroStatsOutput, 1, 2)
end
