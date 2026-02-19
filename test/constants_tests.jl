@testitem "Test that character constants are correct" begin 
    import PetoiBittle: Constants

    @test convert(Char, Constants.char.tab)     == '\t'
    @test convert(Char, Constants.char.newline) == '\n'
    @test convert(Char, Constants.char.caret)   == '\r'
    @test convert(Char, Constants.char.zero)    == '0'
    @test convert(Char, Constants.char.one)     == '1'
    @test convert(Char, Constants.char.two)     == '2'
    @test convert(Char, Constants.char.three)   == '3'
    @test convert(Char, Constants.char.four)    == '4'
    @test convert(Char, Constants.char.five)    == '5'
    @test convert(Char, Constants.char.six)     == '6'
    @test convert(Char, Constants.char.seven)   == '7'
    @test convert(Char, Constants.char.eight)   == '8'
    @test convert(Char, Constants.char.nine)    == '9'
    @test convert(Char, Constants.char.null)    == '\0'
    @test convert(Char, Constants.char.dot)     == '.'
    @test convert(Char, Constants.char.minus)   == '-'
    @test convert(Char, Constants.char.space)   == ' '
end
