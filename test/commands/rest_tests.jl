@testitem "Rest command should be correctly serialized" begin
    import PetoiBittle: Rest, serialize_to_bytes!

    bytes = zeros(UInt8, 4)
    rbytes, nextind = serialize_to_bytes!(bytes, Rest(), 1)

    @test bytes === rbytes
    @test nextind == 2
    @test bytes == UInt8['d', 0, 0, 0]

    bytes = zeros(UInt8, 4)
    rbytes, nextind = serialize_to_bytes!(bytes, Rest(), 3)

    @test bytes === rbytes
    @test nextind == 4
    @test bytes == UInt8[0, 0, 'd', 0]
end
