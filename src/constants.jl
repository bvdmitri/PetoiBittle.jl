"""
A sub-module of PetoiBittle containing some useful constants
Constants are united in their respective namespaces. 

The available namespaces are:

- `char`: a list of character codes in `UInt8`
    - `tab`: `UInt8` code of the tab character '\t'
    - `newline`: `UInt8` code of the newline character '\n'
    - `caret`: `UInt8` code of the caret character '\r'
    - `zero`: `UInt8` code of the zero character '0' (a digit)
    - `nine`: `UInt8` code of the nine character '9' (a digit)
    - `null`: `UInt8` code of the null character '\0' (a terminator)
    - `dot`: `UInt8` code of the dot character '.'
    - `minus`: `UInt8` code of the minus character '-'

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
        nine    = convert(UInt8, '9'),
        null    = convert(UInt8, '\0'),
        dot     = convert(UInt8, '.'),
        minus   = convert(UInt8, '-'),
    )
end
