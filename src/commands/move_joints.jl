
"""
    MoveJointSpec(id::Int, angle::Int)

A command specification for a joint with id `id` to change its angle to `angle`.
Note, that this structure is not a _command_ by itself. To move a single joint 
you should still use the [`PetoiBittle.MoveJoints`](@ref) command.

```jldoctest 
julia> convert(PetoiBittle.MoveJointSpec, (id = 1, angle = 10))
PetoiBittle.MoveJointSpec(1, 10)

julia> convert(PetoiBittle.MoveJointSpec, (id = 1, ))
ERROR: Cannot convert NamedTuple (id = 1,) to `MoveJointSpec(id = ..., angle = ...)`. Missing key `angle`.
[...]
```

See also: [`PetoiBittle.MoveJoints`](@ref)
"""
struct MoveJointSpec
    id::Int
    angle::Int
end

function Base.convert(::Type{MoveJointSpec}, nt::NamedTuple{(:id, :angle)})::MoveJointSpec
    return MoveJointSpec(nt.id, nt.angle)
end
function Base.convert(::Type{MoveJointSpec}, nt::NamedTuple{(:angle, :id)})::MoveJointSpec
    return MoveJointSpec(nt.id, nt.angle)
end
function Base.convert(::Type{MoveJointSpec}, nt::NamedTuple)::MoveJointSpec
    err_msg = "Cannot convert NamedTuple $(nt) to `MoveJointSpec(id = ..., angle = ...)`."

    nt_keys = keys(nt)
    missing_keys = setdiff((:id, :angle), intersect(nt_keys, (:id, :angle)))
    if !isempty(missing_keys)
        err_msg *= " Missing key `$(first(missing_keys))`."
    end
    extra_keys = setdiff(nt_keys, (:id, :angle))
    if !isempty(extra_keys)
        err_msg *= " Extra key `$(first(extra_keys))`."
    end

    error(err_msg)
end

"""
    serialize_to_bytes!(bytes, spec::MoveJointSpec, startidx)

Write the `spec` to `bytes` starting at `startidx`. Returns the modified `bytes` 
and the next to last modified index.

```jldoctest 
julia> PetoiBittle.serialize_to_bytes!(zeros(UInt8, 4), PetoiBittle.MoveJointSpec(7, 0), 1)
(UInt8[0x37, 0x20, 0x30, 0x00], 4)
```
"""
Base.@propagate_inbounds function serialize_to_bytes!(bytes, spec::MoveJointSpec, startidx::Int)
    bytes, nextind = serialize_to_bytes!(bytes, spec.id, startidx)
    bytes[nextind] = Constants.char.space
    return serialize_to_bytes!(bytes, spec.angle, nextind + 1)
end

"""
    MoveJoints(joint_movements_as_named_tuple...)
    MoveJoints(single_tuple_of_move_joint_specs)

A [`PetoiBittle.Command`](@ref) that specifies which joint to move at which angle.
Can be constructed from a vararg argument list of named tuples with `id` and `angle` 
keys present or a single tuple containing multiple [`PetoiBittle.MoveJointSpec`](@ref).

```jldoctest
julia> PetoiBittle.MoveJoints(
           (id = 8, angle = 10),
           (id = 9, angle = 20)
       )
PetoiBittle.MoveJoints{2}((PetoiBittle.MoveJointSpec(8, 10), PetoiBittle.MoveJointSpec(9, 20)))

julia> PetoiBittle.MoveJoints(
           (id = 9, angle = 10),
           (id = 9, angle = 20)
       )
ERROR: Cannot create MoveJoints. Duplicate `id` found `9`. Set `check_unique = false` to skip the check.
[...]
```

See also: [`PetoiBittle.MoveJointSpec`](@ref)
"""
struct MoveJoints{N} <: Command
    joint_movements::NTuple{N, MoveJointSpec}

    function MoveJoints(movements::NTuple{N, MoveJointSpec}; check_unique = true) where {N}
        if check_unique
            for i in 1:length(movements)
                for j in (i + 1):length(movements)
                    if movements[i].id === movements[j].id
                        error(
                            lazy"Cannot create MoveJoints. Duplicate `id` found `$(movements[i].id)`. Set `check_unique = false` to skip the check."
                        )
                    end
                end
            end
        end
        return new{N}(movements)
    end

    function MoveJoints(movements...; check_unique = true)
        return MoveJoints(map(m -> convert(MoveJointSpec, m), movements); check_unique = check_unique)
    end
end

"""
    serialize_to_bytes!(bytes, task::MoveJoints, startidx)

Write the `task` to `bytes` starting at `startidx`. 
The `MoveJoints` task always starts with the `I` character.
Returns the modified `bytes` and the next to last modified index.

```jldoctest 
julia> PetoiBittle.serialize_to_bytes!(zeros(UInt8, 16), PetoiBittle.MoveJoints((id = 1, angle = 10), (id = 3, angle = -10)), 1)
(UInt8[0x69, 0x31, 0x20, 0x31, 0x30, 0x20, 0x33, 0x20, 0x2d, 0x31, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00], 12)
```
"""
Base.@propagate_inbounds function serialize_to_bytes!(bytes, command::MoveJoints, startidx::Int)
    nextind::Int = startidx
    bytes[nextind] = convert(UInt8, 'i')
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
