@testitem "GyroCalibrate command should be correctly serialized" begin
    import PetoiBittle: GyroCalibrate, serialize_to_bytes!

    bytes = zeros(UInt8, 4)
    rbytes, nextind = serialize_to_bytes!(bytes, GyroCalibrate(), 1)

    @test bytes === rbytes
    @test nextind == 2
    @test bytes == UInt8['g', 0, 0, 0]

    bytes = zeros(UInt8, 4)
    rbytes, nextind = serialize_to_bytes!(bytes, GyroCalibrate(), 3)

    @test bytes === rbytes
    @test nextind == 4
    @test bytes == UInt8[0, 0, 'g', 0]
end
