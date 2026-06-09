
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

@testitem "_serialize_token! writes the token bytes verbatim" begin
    import PetoiBittle: _serialize_token!

    # "ksit" -> 'k','s','i','t' starting at index 1; nextind is one-past the token.
    bytes = zeros(UInt8, 8)
    @test _serialize_token!(bytes, "ksit", 1) == (bytes, 5)
    @test bytes[1:4] == [0x6b, 0x73, 0x69, 0x74]
    @test bytes[5:end] == zeros(UInt8, 4)

    # Honours a non-1 start index and returns the correct next index.
    fill!(bytes, 0)
    @test _serialize_token!(bytes, "kwkF", 3) == (bytes, 7)
    @test bytes[3:6] == [0x6b, 0x77, 0x6b, 0x46]

    # A single-character token.
    fill!(bytes, 0)
    @test _serialize_token!(bytes, "d", 1) == (bytes, 2)
    @test bytes[1] == convert(UInt8, 'd')
end

@testitem "_serialize_token! does not allocate" begin
    import PetoiBittle: _serialize_token!
    import JET

    bytes = zeros(UInt8, 8)
    JET.@test_opt _serialize_token!(bytes, "ksit", 1)
    @test @allocated(_serialize_token!(bytes, "ksit", 1)) === 0
end

@testitem "_serialize_raw_i8! writes one signed byte" begin
    import PetoiBittle: _serialize_raw_i8!

    bytes = zeros(UInt8, 4)
    # Positive values pass through unchanged.
    @test _serialize_raw_i8!(bytes, 30, 1) == (bytes, 2)
    @test bytes[1] == 0x1e

    # Negative values are written as their two's-complement byte (-1 -> 0xff, -90 -> 0xa6).
    fill!(bytes, 0)
    @test _serialize_raw_i8!(bytes, -1, 1) == (bytes, 2)
    @test bytes[1] == 0xff
    fill!(bytes, 0)
    @test _serialize_raw_i8!(bytes, -90, 1) == (bytes, 2)
    @test bytes[1] == reinterpret(UInt8, Int8(-90))

    # The boundary values of a signed byte are accepted.
    fill!(bytes, 0)
    @test _serialize_raw_i8!(bytes, 127, 1)[2] == 2
    @test bytes[1] == 0x7f
    fill!(bytes, 0)
    @test _serialize_raw_i8!(bytes, -128, 1)[2] == 2
    @test bytes[1] == 0x80

    # Out-of-range values must error rather than silently wrap.
    @test_throws "range" _serialize_raw_i8!(bytes, 128, 1)
    @test_throws "range" _serialize_raw_i8!(bytes, -129, 1)
end
