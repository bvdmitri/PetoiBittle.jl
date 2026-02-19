
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
