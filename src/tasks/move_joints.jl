
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

struct MoveJoints{N}
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
(UInt8[0x49, 0x20, 0x31, 0x20, 0x31, 0x30, 0x20, 0x33, 0x20, 0x2d, 0x31, 0x30, 0x00, 0x00, 0x00, 0x00], 13)
```
"""
Base.@propagate_inbounds function serialize_to_bytes!(bytes, task::MoveJoints, startidx::Int)
    nextind::Int = startidx
    bytes[nextind] = convert(UInt8, 'I')
    nextind = nextind + 1
    bytes[nextind] = Constants.char.space
    nextind = nextind + 1

    isfirst::Bool = true
    for movement in task.joint_movements
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
