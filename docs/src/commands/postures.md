```@meta
CurrentModule = PetoiBittle
```

# Postures

Postures are **single, static poses**. The robot moves into the pose and holds it. They are
useful as start/stop states around gaits and behaviors.

## Use case: a little routine

```julia
using PetoiBittle

connection = PetoiBittle.connect(PetoiBittle.find_bittle_port())

PetoiBittle.stretch(connection)   # wake up with a stretch
sleep(2)
PetoiBittle.sit(connection)       # sit down
sleep(2)
PetoiBittle.nap(connection)       # fold down into the sleep posture

PetoiBittle.disconnect(connection)
```

!!! note
    The firmware's bare lie-down / rest command is exposed separately as
    [`PetoiBittle.Rest`](@ref) (token `"d"`) on the [Control & state](control.md) page.
    [`PetoiBittle.balance`](@ref) makes the robot stand and actively self-balance using its
    gyroscope.

## Reference

```@docs
PetoiBittle.Balance
PetoiBittle.balance
PetoiBittle.Sit
PetoiBittle.sit
PetoiBittle.Stretch
PetoiBittle.stretch
PetoiBittle.Sleep
PetoiBittle.nap
PetoiBittle.Zero
PetoiBittle.straighten
PetoiBittle.ButtUp
PetoiBittle.butt_up
PetoiBittle.CalibrationPose
PetoiBittle.calibration_pose
```
