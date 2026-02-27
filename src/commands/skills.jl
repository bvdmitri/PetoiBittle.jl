"""
    Skill(skill_name)

A command that executes a predefined `skill_name`. Please consult the Petoi 
documentation to get the list of predefined skills (e.g. [here](https://docs.petoi.com/apis/serial-protocol)).
You can also add your own skills and attach names to them. 

`skill_name` should be an iterable of `Char`, e.g. `String` or a `Vector{Char}`.
"""
struct Skill{S} <: Command 
    skill_name::S
end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, command::Skill, startidx::Int)
    nextind::Int = startidx
    bytes[nextind] = convert(UInt8, 'k')
    nextind += 1
    for c in command.skill_name
        @assert c isa Char "Skill name should be an iterable of `Char`s"
        bytes[nextind] = convert(UInt8, c)
        nextind += 1
    end
    return bytes, nextind
end
