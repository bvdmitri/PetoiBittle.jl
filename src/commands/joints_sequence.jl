"""
    MoveJointSequence(joint_movements_as_named_tuple...)
    MoveJointSequence(single_tuple_of_move_joint_specs)

A [`PetoiBittle.Command`](@ref) that moves the listed joints to their target angles **one
after another, in order** (as opposed to [`PetoiBittle.MoveJoints`](@ref), which moves them
all at once). Serializes to the token `"m"` followed by space-separated `id angle` pairs.

Reuses [`PetoiBittle.MoveJointSpec`](@ref) for each movement. Unlike `MoveJoints`, repeated
joint ids are allowed (the same joint can be stepped through several angles in sequence).

```jldoctest
julia> PetoiBittle.MoveJointSequence((id = 0, angle = 30), (id = 0, angle = -30))
PetoiBittle.MoveJointSequence{2}((PetoiBittle.MoveJointSpec(0, 30), PetoiBittle.MoveJointSpec(0, -30)))
```

See also: [`PetoiBittle.MoveJoints`](@ref), [`PetoiBittle.MoveJointSpec`](@ref)
"""
struct MoveJointSequence{N} <: Command
    joint_movements::NTuple{N, MoveJointSpec}

    function MoveJointSequence(movements::NTuple{N, MoveJointSpec}) where {N}
        return new{N}(movements)
    end

    function MoveJointSequence(movements...)
        return MoveJointSequence(map(m -> convert(MoveJointSpec, m), movements))
    end
end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, command::MoveJointSequence, startidx::Int)
    nextind::Int = startidx
    bytes[nextind] = convert(UInt8, 'm')
    nextind = nextind + 1

    isfirst::Bool = true
    for movement in command.joint_movements
        if !isfirst
            bytes[nextind] = Constants.char.space
            nextind = nextind + 1
        else
            isfirst = false
        end
        _, nextind = serialize_to_bytes!(bytes, movement, nextind)
    end
    return bytes, nextind
end
