```@meta
CurrentModule = PetoiBittle
```

# Control & state

These commands manage the robot's overall state rather than a specific motion: resting,
pausing, toggling the gyroscope, calibrating, and reading the IMU.

## Use case: rest, then calibrate the gyro

```julia
using PetoiBittle

connection = PetoiBittle.connect(PetoiBittle.find_bittle_port())

PetoiBittle.send_command(connection, PetoiBittle.Rest())          # lie down and relax the servos
PetoiBittle.send_command(connection, PetoiBittle.GyroCalibrate()) # calibrate from the resting state

stats = PetoiBittle.send_command(connection, PetoiBittle.GyroStats())
@show stats.yaw stats.pitch stats.roll

PetoiBittle.disconnect(connection)
```

!!! note
    On the Petoi firmware the bare token `"d"` ([`PetoiBittle.Rest`](@ref)) is the lie-down /
    rest-all-servos command. [`PetoiBittle.Pause`](@ref) instead freezes the current motion and
    can be toggled to resume.

## Resting and pausing

```@docs
PetoiBittle.Rest
PetoiBittle.Pause
PetoiBittle.Recover
```

## Gyroscope / IMU

```@docs
PetoiBittle.SwitchGyro
PetoiBittle.Calibrate
PetoiBittle.GyroCalibrate
PetoiBittle.GyroStats
PetoiBittle.GyroStatsOutput
```
