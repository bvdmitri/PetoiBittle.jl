```@meta
CurrentModule = PetoiBittle
```

# Joint control

Beyond the built-in skills you can drive individual joints directly. There are three flavours:

- [`PetoiBittle.MoveJoints`](@ref) moves a subset of joints **simultaneously** (ASCII form,
  token `"i"`).
- [`PetoiBittle.MoveJointSequence`](@ref) moves them **one after another, in order** (ASCII
  form, token `"m"`).
- [`PetoiBittle.SetAllJoints`](@ref) sets **all 16 joints at once** from a single frame (binary
  form, token `"L"`, `'~'`-terminated).

Joints are addressed by index; consult the
[Petoi serial protocol](https://docs.petoi.com/apis/serial-protocol) for the joint map of your
model. Angles are in degrees.

## Use case: nod the head, then strike a pose

```julia
using PetoiBittle

connection = PetoiBittle.connect(PetoiBittle.find_bittle_port())

# move joint 0 to +30 and joint 1 to -30 at the same time
PetoiBittle.send_command(connection, PetoiBittle.MoveJoints((id = 0, angle = 30), (id = 1, angle = -30)))

# step the same joint through a little nod, in sequence
PetoiBittle.send_command(connection, PetoiBittle.MoveJointSequence((id = 0, angle = 20), (id = 0, angle = -20), (id = 0, angle = 0)))

# set an entire 16-joint frame at once (here: all neutral)
PetoiBittle.send_command(connection, PetoiBittle.SetAllJoints(ntuple(_ -> 0, 16)))

PetoiBittle.disconnect(connection)
```

!!! note
    `SetAllJoints` sends raw signed bytes, so every angle must fit in `-128:127`. Out-of-range
    values raise an error when the command is serialized.

## Reference

```@docs
PetoiBittle.MoveJoints
PetoiBittle.MoveJointSpec
PetoiBittle.MoveJointSequence
PetoiBittle.SetAllJoints
```
