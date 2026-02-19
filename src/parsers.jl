
"""
    parse_number(::Type{T}, bytes)

Parse decimal representation of a number of type `T` from `bytes`.
Stops at non-digits characters, with the exception of `-` and `.`.

```jldoctest
julia> PetoiBittle.parse_number(Int, [ 0x34, 0x32 ])
42

julia> PetoiBittle.parse_number(Float64, [ 0x2d, 0x30, 0x2e, 0x35 ])
-0.5
```
"""
function parse_number(::Type{T}, bytes) where {T}
    result, _ = @inbounds parse_number(T, bytes, firstindex(bytes), lastindex(bytes))
    return result
end

"""
    parse_number(bytes)

Short-hand for `parse_number(Float64, bytes)`.
"""
parse_number(bytes) = parse_number(Float64, bytes)

"""
    parse_number(::Type{T}, bytes, firstindex, lastindex)

Parse decimal representation of a number of type `T` from `bytes` at 
indices between `firstindex` and `lastindex`. Stops at non-digits characters, with the exception of `-` and `.`.

Returns `(result, nextindex)`, where `result` is the actual parsed number
and `nextindex` is either:
- an index next to a non-digit character or; 
- `lastindex + 1`

```jldoctest 
julia> PetoiBittle.parse_number(Float64, [ 0x34, 0x32 ], 1, 1)
(4.0, 2)

julia> PetoiBittle.parse_number(Float64, [ 0x34, 0x32 ], 1, 2)
(42.0, 3)
```
"""
Base.@propagate_inbounds function parse_number(::Type{T}, bytes, firstindex, lastindex) where {T}
    consumed_indices::Int = 0
    is_negative::Bool = false
    before_point_decimal::Bool = true
    exponent::T = one(T)
    result::T = zero(T)

    for index in firstindex:lastindex
        character::UInt8 = bytes[index]::UInt8
        consumed_indices += 1

        isdigit = Constants.char.zero <= character <= Constants.char.nine
        isdot = character === Constants.char.dot
        isminus = character === Constants.char.minus

        if !isdigit && !isdot && !isminus
            break
        end
        if isdot
            before_point_decimal = false
            continue
        end
        if isminus
            is_negative = true
            continue
        end
        number::UInt8 = character - Constants.char.zero
        if before_point_decimal
            result = 10 * result + convert(T, T(number))
        else
            exponent = convert(T, T(exponent / 10))
            result   = result + convert(T, T(number)) * exponent
        end
    end
    result = is_negative ? -result : result
    nextindex = firstindex + consumed_indices
    return (result, nextindex)
end
