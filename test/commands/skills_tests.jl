@testitem "Skill command should be correctly serialized" begin 
    import PetoiBittle: Skill, serialize_to_bytes!

    bytes = zeros(UInt8, 8)
    rbytes, nextind = serialize_to_bytes!(bytes, Skill("rest"), 2)
    @test rbytes === bytes
    @test nextind == 7
    @test bytes == UInt8[
        0, 'k', 'r', 'e', 's', 't', 0, 0
    ]

    bytes = zeros(UInt8, 8)
    rbytes, nextind = serialize_to_bytes!(bytes, Skill("calib"), 1)
    @test rbytes === bytes
    @test nextind == 7
    @test bytes == UInt8[
        'k', 'c', 'a', 'l', 'i', 'b', 0, 0
    ]

    bytes = zeros(UInt8, 6)
    rbytes, nextind = serialize_to_bytes!(bytes, Skill("sit"), 1)
    @test rbytes === bytes
    @test nextind == 5
    @test bytes == UInt8[
        'k', 's', 'i', 't', 0, 0
    ]

end
