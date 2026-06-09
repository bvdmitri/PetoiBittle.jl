```@meta
CurrentModule = PetoiBittle
```

# Behaviors

Behaviors are **multi-frame, one-shot actions**: the robot performs the action once and then
returns to a neutral state. They are great for demos and interaction.

## Use case: say hello and show off

```julia
using PetoiBittle

connection = PetoiBittle.connect(PetoiBittle.find_bittle_port())

PetoiBittle.greet(connection)        # wave hello
sleep(3)
PetoiBittle.check_around(connection) # look around
sleep(3)
PetoiBittle.back_flip(connection)    # the grand finale

PetoiBittle.disconnect(connection)
```

!!! warning
    Dynamic behaviors such as [`PetoiBittle.back_flip`](@ref) and [`PetoiBittle.push_up`](@ref)
    are physically demanding. Run them on a clear, flat surface with the robot well charged.

## Reference

```@docs
PetoiBittle.Greeting
PetoiBittle.greet
PetoiBittle.CheckAround
PetoiBittle.check_around
PetoiBittle.PushUp
PetoiBittle.push_up
PetoiBittle.Pee
PetoiBittle.pee
PetoiBittle.MimicDeath
PetoiBittle.play_dead
PetoiBittle.BackFlip
PetoiBittle.back_flip
```
