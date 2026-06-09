"""
    SetAllJoints(angles::NTuple{16, Int})
    SetAllJoints(angle1, angle2, ..., angle16)

A [`PetoiBittle.Command`](@ref) that sets **all 16 joints at once** to the given target
angles (a "transform to frame"). This is the binary form of the protocol: it serializes to
the token `"L"` followed by 16 raw signed bytes (one per joint) and is terminated by `'~'`
rather than a newline (see [`PetoiBittle.command_terminator`](@ref)).

Each angle must fit in a signed byte (`-128:127`); out-of-range values error when the command
is serialized. Exactly 16 angles are required.

```jldoctest
julia> PetoiBittle.SetAllJoints(ntuple(_ -> 0, 16))
PetoiBittle.SetAllJoints{16}((0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
```

See also: [`PetoiBittle.MoveJoints`](@ref) (move a subset simultaneously, ASCII form).
"""
struct SetAllJoints{N} <: Command
    angles::NTuple{N, Int}

    function SetAllJoints(angles::NTuple{N, Int}) where {N}
        if N != 16
            error(lazy"SetAllJoints requires exactly 16 angles, got $(N)")
        end
        return new{N}(angles)
    end

    function SetAllJoints(angles...)
        return SetAllJoints(map(a -> convert(Int, a), angles))
    end
end

command_terminator(::Type{<:SetAllJoints}) = Constants.char.tilde

Base.@propagate_inbounds function serialize_to_bytes!(bytes, command::SetAllJoints, startidx::Int)
    nextind::Int = startidx
    bytes[nextind] = convert(UInt8, 'L')
    nextind = nextind + 1
    for angle in command.angles
        _, nextind = _serialize_raw_i8!(bytes, angle, nextind)
    end
    return bytes, nextind
end
