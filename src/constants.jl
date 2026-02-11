"""
A sub-module of PetoiBittle containing some useful constants
Constants are united in their respective namespaces. 

The available namespaces are:

- `char`: a list of character codes in `UInt8`
    - `tab`:     `UInt8` code of the tab character     '\t'
    - `newline`: `UInt8` code of the newline character '\n'
    - `caret`:   `UInt8` code of the caret character   '\r'
    - `zero`:    `UInt8` code of the zero character    '0' (a digit)
    - `one`:     `UInt8` code of the one character     '1' (a digit)
    - `two`:     `UInt8` code of the two character     '2' (a digit)
    - `three`:   `UInt8` code of the three character   '3' (a digit)
    - `four`:    `UInt8` code of the four character    '4' (a digit)
    - `five`:    `UInt8` code of the five character    '5' (a digit)
    - `six`:     `UInt8` code of the six character     '6' (a digit)
    - `seven`:   `UInt8` code of the seven character   '7' (a digit)
    - `eight`:   `UInt8` code of the eight character   '8' (a digit)
    - `nine`:    `UInt8` code of the nine character    '9' (a digit)
    - `null`:    `UInt8` code of the null character    '\0' (a terminator)
    - `dot`:     `UInt8` code of the dot character     '.'
    - `minus`:   `UInt8` code of the minus character   '-'

```jldoctest
julia> PetoiBittle.Constants.char.tab
0x09
```
"""
module Constants 
    const char = (
        tab     = convert(UInt8, '\t'),
        newline = convert(UInt8, '\n'),
        caret   = convert(UInt8, '\r'),
        zero    = convert(UInt8, '0'),
        one     = convert(UInt8, '1'),
        two     = convert(UInt8, '2'),
        three   = convert(UInt8, '3'),
        four    = convert(UInt8, '4'),
        five    = convert(UInt8, '5'),
        six     = convert(UInt8, '6'),
        seven   = convert(UInt8, '7'),
        eight   = convert(UInt8, '8'),
        nine    = convert(UInt8, '9'),
        null    = convert(UInt8, '\0'),
        dot     = convert(UInt8, '.'),
        minus   = convert(UInt8, '-'),
    )
end
