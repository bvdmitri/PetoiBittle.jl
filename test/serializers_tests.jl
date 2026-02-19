
@testitem "iterate_digits works correctly" begin
    import PetoiBittle: iterate_digits

    @test eltype(iterate_digits(1)) == Int

    @test length(iterate_digits(0)) == 1
    @test length(iterate_digits(12)) == 2
    @test length(iterate_digits(123)) == 3
    @test length(iterate_digits(-123)) == 3
    @test length(iterate_digits(1236)) == 4
    @test length(iterate_digits(123699)) == 6

    @test collect(iterate_digits(0)) == [0]
    @test collect(iterate_digits(1)) == [1]
    @test collect(iterate_digits(123)) == [1, 2, 3]
    @test collect(iterate_digits(323)) == [3, 2, 3]
    @test collect(iterate_digits(-10)) == [1, 0]
    @test collect(iterate_digits(-100012)) == [1, 0, 0, 0, 1, 2]

    @test reduce(+, iterate_digits(44)) == 8
    @test reduce(+, iterate_digits(49)) == 13
end

@testitem "iterate_digits doesnot allocate" begin
    import PetoiBittle: iterate_digits
    import JET

    JET.@test_opt reduce(+, iterate_digits(321))
    @test @allocated(reduce(+, iterate_digits(123))) === 0
end

@testitem "serialize a number into bytes" begin
    import PetoiBittle: serialize_to_bytes!

    bytes = Vector{UInt8}(undef, 4)
    fill!(bytes, 0)
    @test serialize_to_bytes!(bytes, 10, 1) == ([0x31, 0x30, 0x00, 0x00], 3)
    fill!(bytes, 0)
    @test serialize_to_bytes!(bytes, 22, 1) == ([0x32, 0x32, 0x00, 0x00], 3)
    fill!(bytes, 0)
    @test serialize_to_bytes!(bytes, 0, 1) == ([0x30, 0x00, 0x00, 0x00], 2)
    fill!(bytes, 0)
    @test serialize_to_bytes!(bytes, 0, 2) == ([0x00, 0x30, 0x00, 0x00], 3)
    fill!(bytes, 0)
    @test serialize_to_bytes!(bytes, 23, 3) == ([0x00, 0x00, 0x32, 0x33], 5)
    fill!(bytes, 0)
    serialize_to_bytes!(bytes, 12, 1)
    serialize_to_bytes!(bytes, 34, 3)
    @test bytes == [0x31, 0x32, 0x33, 0x34]
    fill!(bytes, 0)
    @test serialize_to_bytes!(bytes, -12, 1) == ([0x2d, 0x31, 0x32, 0x00], 4)
    fill!(bytes, 0)
    serialize_to_bytes!(bytes, -1, 1)
    serialize_to_bytes!(bytes, -9, 3)
    @test bytes == [0x2d, 0x31, 0x2d, 0x39]

end
