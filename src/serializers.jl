
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
