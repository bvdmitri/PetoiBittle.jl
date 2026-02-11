@testitem "Test that character constats are correct" begin 
    import PetoiBittle: Constants

    @test convert(Char, Constants.char.tab) == '\t'
    @test convert(Char, Constants.char.newline) == '\n'
    @test convert(Char, Constants.char.caret) == '\r'
    @test convert(Char, Constants.char.zero) == '0'
    @test convert(Char, Constants.char.nine) == '9'
    @test convert(Char, Constants.char.null) == '\0'
    @test convert(Char, Constants.char.dot) == '.'
    @test convert(Char, Constants.char.minus) == '-'
end
