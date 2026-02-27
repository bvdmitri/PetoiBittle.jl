@testsnippet ParsersTestsUtils begin 
    function str_to_bytes(str)
        return convert.(UInt8, collect(string(str)))
    end

    function strs_to_bytes(strs, separator, ending)
        bytes = UInt8[]
        nstrs = length(strs)
        for (i, number) in enumerate(strs)
            nbytes = str_to_bytes(number)
            append!(bytes, nbytes)
            if i !== nstrs
                push!(bytes, separator)
            end
        end
        push!(bytes, ending)
    end
end

@testitem "parse_number" setup=[ParsersTestsUtils] begin
    import PetoiBittle: parse_number
    import PetoiBittle: Constants
    import JET
    
    @test parse_number(str_to_bytes("10")) ≈ 10.0
    @test parse_number(Int, str_to_bytes("10")) === 10
    @test parse_number(str_to_bytes("123")) ≈ 123
    @test parse_number(Int, str_to_bytes("123")) === 123
    @test parse_number(str_to_bytes("-321")) ≈ -321
    @test parse_number(Int, str_to_bytes("-321")) === -321

    @test parse_number(Float64, [
        Constants.char.nine,
        Constants.char.dot,
        Constants.char.nine
    ]) ≈ 9.9

    @test parse_number(Float64, [
        Constants.char.minus,
        Constants.char.zero,
        Constants.char.dot,
        Constants.char.seven
    ]) ≈ -0.7

    @test parse_number(str_to_bytes("-3.3")) ≈ -3.3
    @test parse_number(str_to_bytes("-345.378")) ≈ -345.378
    @test parse_number(str_to_bytes("592.9945")) ≈ 592.9945

    @testset let bytes = str_to_bytes("-42.42")
        JET.@test_opt parse_number(bytes)
    end
end

@testitem "parse_number with tabs" setup=[ParsersTestsUtils] begin
    import PetoiBittle: parse_number

    @test parse_number(Float64, str_to_bytes("10\t-3")) ≈ 10.0
    @test parse_number(Float64, str_to_bytes("-42\t-3")) ≈ -42.0
    @test parse_number(Float64, str_to_bytes("-42 -3")) ≈ -42.0
    @test parse_number(Float64, str_to_bytes("-42\n-3")) ≈ -42.0
    @test parse_number(Float64, str_to_bytes("-42\r\n-3")) ≈ -42.0
end

@testitem "parse_number with indices" setup=[ParsersTestsUtils] begin 
    import PetoiBittle: parse_number
    import PetoiBittle: Constants
    import JET

    @testset let bytes = strs_to_bytes(
        ["1", "2"], Constants.char.tab, Constants.char.newline
    ) 
        @test parse_number(Int, bytes, 1, 3) === (1, 3)
        @test parse_number(Int, bytes, 3, 3) === (2, 4)
        @test parse_number(Float64, bytes, 1, 3) === (1.0, 3)
        @test parse_number(Float64, bytes, 3, 3) === (2.0, 4)
        JET.@test_opt parse_number(Int, bytes, 1, 3)
        JET.@test_opt parse_number(Float64, bytes, 1, 3)
    end

    @testset let bytes = strs_to_bytes(
        ["123", "456"], Constants.char.tab, Constants.char.newline
    )
        @test parse_number(Int, bytes, 1, 1) === (1, 2)
        @test parse_number(Int, bytes, 1, 2) === (12, 3)
        @test parse_number(Int, bytes, 1, 3) === (123, 4)
        @test parse_number(Int, bytes, 1, 4) === (123, 5)
        @test parse_number(Int, bytes, 1, 5) === (123, 5)

        @test parse_number(Int, bytes, 2, 2) === (2, 3)
        @test parse_number(Int, bytes, 2, 3) === (23, 4)
        @test parse_number(Int, bytes, 2, 4) === (23, 5)
        @test parse_number(Int, bytes, 2, 5) === (23, 5)

        @test parse_number(Int, bytes, 3, 3) === (3, 4)
        @test parse_number(Int, bytes, 3, 4) === (3, 5)
        @test parse_number(Int, bytes, 3, 5) === (3, 5)

        @test parse_number(Int, bytes, 4, 4) === (0, 5)
        @test parse_number(Int, bytes, 4, 5) === (0, 5)

        @test parse_number(Float64, bytes, 1, 1) === (1.0, 2)
        @test parse_number(Float64, bytes, 1, 2) === (12.0, 3)
        @test parse_number(Float64, bytes, 1, 3) === (123.0, 4)
        @test parse_number(Float64, bytes, 1, 4) === (123.0, 5)
        @test parse_number(Float64, bytes, 1, 5) === (123.0, 5)

        @test parse_number(Float64, bytes, 2, 2) === (2.0, 3)
        @test parse_number(Float64, bytes, 2, 3) === (23.0, 4)
        @test parse_number(Float64, bytes, 2, 4) === (23.0, 5)
        @test parse_number(Float64, bytes, 2, 5) === (23.0, 5)

        @test parse_number(Float64, bytes, 3, 3) === (3.0, 4)
        @test parse_number(Float64, bytes, 3, 4) === (3.0, 5)
        @test parse_number(Float64, bytes, 3, 5) === (3.0, 5)

        @test parse_number(Float64, bytes, 4, 4) === (0.0, 5)
        @test parse_number(Float64, bytes, 4, 5) === (0.0, 5)
    end
     
    @testset let bytes = strs_to_bytes(
        ["123", "456"], Constants.char.tab, Constants.char.newline
    )
        @test parse_number(Int, bytes, 5, 4 + 1) === (4,   6)
        @test parse_number(Int, bytes, 5, 4 + 2) === (45,  7)
        @test parse_number(Int, bytes, 5, 4 + 3) === (456, 8)
        @test parse_number(Int, bytes, 5, 4 + 4) === (456, 9)
        @test parse_number(Int, bytes, 5, 4 + 5) === (456, 9)

        @test parse_number(Int, bytes, 6, 4 + 2) === (5,  7)
        @test parse_number(Int, bytes, 6, 4 + 3) === (56, 8)
        @test parse_number(Int, bytes, 6, 4 + 4) === (56, 9)
        @test parse_number(Int, bytes, 6, 4 + 5) === (56, 9)

        @test parse_number(Int, bytes, 7, 4 + 3) === (6, 8)
        @test parse_number(Int, bytes, 7, 4 + 4) === (6, 9)
        @test parse_number(Int, bytes, 7, 4 + 5) === (6, 9)

        @test parse_number(Int, bytes, 8, 4 + 4) === (0, 9)
        @test parse_number(Int, bytes, 8, 4 + 5) === (0, 9)

        @test parse_number(Float64, bytes, 5, 4 + 1) === (4.0,   6)
        @test parse_number(Float64, bytes, 5, 4 + 2) === (45.0,  7)
        @test parse_number(Float64, bytes, 5, 4 + 3) === (456.0, 8)
        @test parse_number(Float64, bytes, 5, 4 + 4) === (456.0, 9)
        @test parse_number(Float64, bytes, 5, 4 + 5) === (456.0, 9)

        @test parse_number(Float64, bytes, 6, 4 + 2) === (5.0,  7)
        @test parse_number(Float64, bytes, 6, 4 + 3) === (56.0, 8)
        @test parse_number(Float64, bytes, 6, 4 + 4) === (56.0, 9)
        @test parse_number(Float64, bytes, 6, 4 + 5) === (56.0, 9)

        @test parse_number(Float64, bytes, 7, 4 + 3) === (6.0, 8)
        @test parse_number(Float64, bytes, 7, 4 + 4) === (6.0, 9)
        @test parse_number(Float64, bytes, 7, 4 + 5) === (6.0, 9)

        @test parse_number(Float64, bytes, 8, 4 + 4) === (0.0, 9)
        @test parse_number(Float64, bytes, 8, 4 + 5) === (0.0, 9)

    end

end

@testitem "Parse number should parse a series of numbers in a single buffer" begin 
    import PetoiBittle: parse_number

    buffer_str = "1.90118\t-6.48583\t2.21230\t-1092\t355\t8089\r\n"
    bytes = Iterators.map(c -> convert(UInt8, c), buffer_str) |> collect
    firstindex = 1
    lastindex = length(bytes)

    v1, nextind = parse_number(Float64, bytes, firstindex, lastindex)
    v2, nextind = parse_number(Float64, bytes, nextind, lastindex)
    v3, nextind = parse_number(Float64, bytes, nextind, lastindex)
    v4, nextind = parse_number(Int, bytes, nextind, lastindex)
    v5, nextind = parse_number(Int, bytes, nextind, lastindex)
    v6, nextind = parse_number(Int, bytes, nextind, lastindex)

    @test v1 ≈ 1.90118
    @test v2 ≈ -6.48583
    @test v3 ≈ 2.21230
    @test v4 == -1092
    @test v5 == 355
    @test v6 == 8089
end
