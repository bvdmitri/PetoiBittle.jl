@testitem "parse_number" begin
    import PetoiBittle: parse_number

    function number_to_bytes(number)
        return convert.(UInt8, collect(string(number)))
    end

    @test parse_number(number_to_bytes("10")) ≈ 10
    @test parse_number(number_to_bytes("123")) ≈ 123
end
