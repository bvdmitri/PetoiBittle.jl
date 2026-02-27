# Petoi Bittle commands

To interact with the robot, the library exposes a [`PetoiBittle.Command`](@ref) interface and the [`PetoiBittle.send_command`](@ref) function.

```@docs
PetoiBittle.Command
PetoiBittle.send_command
```

# The list of available commands

The full list of available commands for Petoi Robots and their specification can also be found on the Petoi Bittle website in the [Serial Protocol](https://docs.petoi.com/apis/serial-protocol) section. This library implements a **subset** of commands. PRs are welcome to add new commands!

To get the list of all available commands implemented in the package use in REPL:
```@repl list-of-available-commands
using PetoiBittle #hide
using InteractiveUtils #hide
subtypes(PetoiBittle.Command)
```

!!! note
    This command only works in Julia REPL.

## Move joints

```@docs
PetoiBittle.MoveJoints
PetoiBittle.MoveJointSpec
```


