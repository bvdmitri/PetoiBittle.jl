"""
    PlayMelody()

A [`PetoiBittle.Command`](@ref) that plays the robot's built-in melody on its buzzer.
Serializes to the token `"o"`.

To play your own notes instead, use [`PetoiBittle.PlayMusic`](@ref).
"""
struct PlayMelody <: Command end

Base.@propagate_inbounds function serialize_to_bytes!(bytes, ::PlayMelody, startidx::Int)
    return _serialize_token!(bytes, "o", startidx)
end

"""
    Tone(pitch::Int, duration::Int)

A single note used by [`PetoiBittle.PlayMusic`](@ref): `pitch` is the tone (a rest is encoded
as `-1`) and `duration` its length. Both are sent as raw signed bytes, so each must fit in
`-128:127`. Construct directly or via a named tuple `(pitch = ..., duration = ...)`.
"""
struct Tone
    pitch::Int
    duration::Int
end

Base.convert(::Type{Tone}, nt::NamedTuple{(:pitch, :duration)}) = Tone(nt.pitch, nt.duration)
Base.convert(::Type{Tone}, nt::NamedTuple{(:duration, :pitch)}) = Tone(nt.pitch, nt.duration)

Base.@propagate_inbounds function serialize_to_bytes!(bytes, tone::Tone, startidx::Int)
    bytes, nextind = _serialize_raw_i8!(bytes, tone.pitch, startidx)
    return _serialize_raw_i8!(bytes, tone.duration, nextind)
end

"""
    PlayMusic(tones_as_named_tuples...)
    PlayMusic(single_tuple_of_tones)

A [`PetoiBittle.Command`](@ref) that plays a custom sequence of [`PetoiBittle.Tone`](@ref)s on
the buzzer. This is the binary form of the protocol: it serializes to the token `"B"` followed
by raw `pitch`/`duration` byte pairs and is terminated by `'~'` (see
[`PetoiBittle.command_terminator`](@ref)).

```jldoctest
julia> PetoiBittle.PlayMusic((pitch = 20, duration = 4), (pitch = -1, duration = 2))
PetoiBittle.PlayMusic{2}((PetoiBittle.Tone(20, 4), PetoiBittle.Tone(-1, 2)))
```

See also: [`PetoiBittle.PlayMelody`](@ref) (the built-in melody).
"""
struct PlayMusic{N} <: Command
    tones::NTuple{N, Tone}

    PlayMusic(tones::NTuple{N, Tone}) where {N} = new{N}(tones)
    PlayMusic(tones...) = PlayMusic(map(t -> convert(Tone, t), tones))
end

command_terminator(::Type{<:PlayMusic}) = Constants.char.tilde

Base.@propagate_inbounds function serialize_to_bytes!(bytes, command::PlayMusic, startidx::Int)
    nextind::Int = startidx
    bytes[nextind] = convert(UInt8, 'B')
    nextind = nextind + 1
    for tone in command.tones
        _, nextind = serialize_to_bytes!(bytes, tone, nextind)
    end
    return bytes, nextind
end
