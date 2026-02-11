
"""
    parse_number(::Type{T}, bytes)

Parse decimal representation of a number of type `T` from `bytes`

```jldoctest
julia> PetoiBittle.parse_number(Int, [ 0x34, 0x32 ])
42

julia> PetoiBittle.parse_number(Floa64, [ 0x2d, 0x30, 0x2e, 0x35 ])
-0.5
```
"""
function parse_number(::Type{T}, bytes) where {T}
    return 10
end

"Short-hand for `parse_number(Float64, ...)`"
parse_number(bytes) = parse_number(Float64, bytes)
