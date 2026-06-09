```@meta
CurrentModule = PetoiBittle
```

# Sound

The robot has a buzzer. You can play its built-in melody or compose your own tune from
[`PetoiBittle.Tone`](@ref)s.

## Use case: play a short tune

```julia
using PetoiBittle

connection = PetoiBittle.connect(PetoiBittle.find_bittle_port())

# the built-in melody
PetoiBittle.send_command(connection, PetoiBittle.PlayMelody())

# a custom three-note phrase (a rest is pitch -1)
PetoiBittle.send_command(connection, PetoiBittle.PlayMusic(
    (pitch = 20, duration = 4),
    (pitch = 22, duration = 4),
    (pitch = -1, duration = 2),
    (pitch = 24, duration = 8)
))

PetoiBittle.disconnect(connection)
```

!!! note
    [`PetoiBittle.PlayMusic`](@ref) sends raw signed bytes (binary, `'~'`-terminated), so every
    `pitch` and `duration` must fit in `-128:127`.

## Reference

```@docs
PetoiBittle.PlayMelody
PetoiBittle.PlayMusic
PetoiBittle.Tone
```
