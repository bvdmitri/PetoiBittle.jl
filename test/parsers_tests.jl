@testsnippet ParsersTestsUtils begin 
    function number_to_bytes(number)
        return convert.(UInt8, collect(string(number)))
    end

    function numbers_to_bytes(numbers, separator, ending)
        bytes = UInt8[]
        nnumbers = length(numbers)
        for (i, number) in enumerate(numbers)
            nbytes = number_to_bytes(number)
            append!(bytes, nbytes)
            if i !== nnumbers
                push!(bytes, separator)
            end
        end
        push!(bytes, ending)
    end
end

@testitem "parse_number" setup=[ParsersTestsUtils] begin
    import PetoiBittle: parse_number
    import PetoiBittle: Constants
    
    @test parse_number(number_to_bytes("10")) ≈ 10.0
    @test parse_number(Int, number_to_bytes("10")) === 10
    @test parse_number(number_to_bytes("123")) ≈ 123
    @test parse_number(Int, number_to_bytes("123")) === 123
    @test parse_number(number_to_bytes("-321")) ≈ -321
    @test parse_number(Int, number_to_bytes("-321")) === -321

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

    @test parse_number(number_to_bytes("-3.3")) ≈ -3.3
    @test parse_number(number_to_bytes("-345.378")) ≈ -345.378
    @test parse_number(number_to_bytes("592.9945")) ≈ 592.9945
end

@testitem "parse_number with indices" setup=[ParsersTestsUtils] begin 
    import PetoiBittle: parse_number
    import PetoiBittle: Constants

    @testset let bytes = numbers_to_bytes(
        ["1", "2"], Constants.char.tab, Constants.char.newline
    ) 
        @test parse_number(Int, bytes, 1, 3) === (1, 3)
        @test parse_number(Int, bytes, 3, 3) === (2, 4)
    end

    @testset let bytes = numbers_to_bytes(
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
     
    @testset let bytes = numbers_to_bytes(
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
