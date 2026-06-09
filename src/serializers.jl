
"""
    DigitsIterator

A special iterator that iterates over digits of a number `Int` without allocating 
an intermediate array. Use the [`PetoiBittle.iterate_digits`](@ref) function to create the iterator.

```jldoctest 
julia> PetoiBittle.iterate_digits(123) |> collect
3-element Vector{Int64}:
 1
 2
 3

julia> reduce(+, PetoiBittle.iterate_digits(123))
6
```
"""
struct DigitsIterator
    number::Int
    biggest_exponent10::Int
    len::Int
end

Base.IteratorSize(::Type{DigitsIterator}) = Base.HasLength()
Base.IteratorEltype(::Type{DigitsIterator}) = Base.HasEltype()

Base.eltype(::Type{DigitsIterator}) = Int
Base.length(iter::DigitsIterator) = iter.len

"""
    iterate_digits(number::Int)

Creates [`PetoiBittle.DigitsIterator`](@ref) from `number`.
Use this to iterate through digits of the `number` without allocating 
intermediate array.

```jldoctest 
julia> PetoiBittle.iterate_digits(123) |> collect
3-element Vector{Int64}:
 1
 2
 3

julia> reduce(+, PetoiBittle.iterate_digits(123))
6
```
"""
function iterate_digits(number::Int)
    number = abs(number)
    biggest_exponent10::Int = 1
    len::Int = 1
    while div(number, 10biggest_exponent10) != 0
        biggest_exponent10 = 10biggest_exponent10
        len = len + 1
    end
    return DigitsIterator(number, biggest_exponent10, len)
end

function Base.iterate(iter::DigitsIterator)
    next_digit = div(iter.number, iter.biggest_exponent10)
    next_remainder = rem(iter.number, iter.biggest_exponent10)
    next_exponent10 = div(iter.biggest_exponent10, 10)
    return next_digit, (next_remainder, next_exponent10)
end

function Base.iterate(::DigitsIterator, state::Tuple{Int, Int})
    number, exponent10 = state
    if iszero(exponent10)
        return nothing
    end
    next_digit = div(number, exponent10)
    next_remainder = rem(number, exponent10)
    next_exponent10 = div(exponent10, 10)
    return next_digit, (next_remainder, next_exponent10)
end

"""
    _serialize_token!(bytes, token::AbstractString, startidx)

Write the ASCII `token` byte for byte to `bytes` starting at `startidx`, without allocating.
Used by fixed-token commands (skills, postures, gaits, ...). Accepts any `AbstractString`
(`String`, `SubString`, ...); it specializes per concrete type at the call site, so it
stays type-stable and allocation-free. Returns the modified `bytes` and the next to last
modified index.

```jldoctest
julia> PetoiBittle._serialize_token!(zeros(UInt8, 5), "ksit", 1)
(UInt8[0x6b, 0x73, 0x69, 0x74, 0x00], 5)
```
"""
Base.@propagate_inbounds function _serialize_token!(bytes, token::AbstractString, startidx::Int)
    nextind = startidx
    for byte in codeunits(token)
        bytes[nextind] = byte
        nextind = nextind + 1
    end
    return bytes, nextind
end

"""
    _serialize_raw_i8!(bytes, value::Int, startidx)

Write `value` as a single raw signed-byte (two's complement) to `bytes` at `startidx`.
Used by binary commands whose arguments are packed as raw bytes (for example joint angles
in a transform-to-frame command). Errors if `value` is outside the signed 8-bit range
`-128:127`. Returns the modified `bytes` and the next to last modified index.

```jldoctest
julia> PetoiBittle._serialize_raw_i8!(zeros(UInt8, 2), -1, 1)
(UInt8[0xff, 0x00], 2)
```
"""
Base.@propagate_inbounds function _serialize_raw_i8!(bytes, value::Int, startidx::Int)
    if value < -128 || value > 127
        error(lazy"Cannot serialize `$(value)` as a raw signed byte: out of the -128:127 range")
    end
    bytes[startidx] = reinterpret(UInt8, convert(Int8, value))
    return bytes, startidx + 1
end

"""
    serialize_to_bytes!(bytes, number::Int, startidx)

Write the `number` digit by digit to `bytes` starting at `startidx`.
Negative number start with the `-` character (`0x2d`, see [`PetoiBittle.Constants`](@ref))
Returns the modified `bytes` and the next to last modified index.
"""
Base.@propagate_inbounds function serialize_to_bytes!(bytes, number::Int, startidx::Int)
    nextind = startidx
    if isless(number, zero(number))
        bytes[nextind] = Constants.char.minus
        nextind = nextind + 1
    end
    for digit in iterate_digits(number)
        bytes[nextind] = Constants.char.zero + digit
        nextind = nextind + 1
    end
    return bytes, nextind
end
