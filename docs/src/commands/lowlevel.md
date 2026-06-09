```@meta
CurrentModule = PetoiBittle
```

# Low-level & advanced

This page covers the primitives for talking to the robot when no dedicated typed command
exists yet, and for defining your own commands.

## Free-form skills

[`PetoiBittle.Skill`](@ref) sends any named skill (`"k"` + name) without needing a dedicated
type. This is handy for custom skills you have uploaded to the robot.

```julia
PetoiBittle.send_command(connection, PetoiBittle.Skill("balance"))
```

## Raw commands and queries

For anything the firmware understands but this package does not model yet (including sensor,
pin, and other hardware-dependent commands whose wire format is device-specific), use the raw
primitives. [`PetoiBittle.RawCommand`](@ref) sends a token and returns nothing;
[`PetoiBittle.RawQuery`](@ref) sends a token and hands you back the raw response line for you to
parse with [`PetoiBittle.parse_number`](@ref).

```julia
# send an arbitrary command
PetoiBittle.send_command(connection, PetoiBittle.RawCommand("p"))

# send a command and read back the raw response line
response = PetoiBittle.send_command(connection, PetoiBittle.RawQuery("b"))
value = PetoiBittle.parse_number(Float64, codeunits(response.line))
```

!!! warning
    The response format of raw queries is whatever the firmware emits; this package does not
    interpret it. Check the [Petoi serial protocol](https://docs.petoi.com/apis/serial-protocol)
    for the exact reply of the command you are sending.

```@docs
PetoiBittle.Skill
PetoiBittle.RawCommand
PetoiBittle.RawQuery
PetoiBittle.RawResponse
```

## Defining your own command

A command is any subtype of [`PetoiBittle.Command`](@ref) that implements
[`PetoiBittle.serialize_to_bytes!`](@ref). Optionally override
[`PetoiBittle.command_terminator`](@ref) (for binary `'~'`-terminated or unterminated
commands), [`PetoiBittle.command_return_type`](@ref) together with
[`PetoiBittle.validate_return_type`](@ref) / [`PetoiBittle.deserialize_from_bytes`](@ref) (for
commands that read a response), and the [`PetoiBittle.before_command`](@ref) /
[`PetoiBittle.after_command`](@ref) hooks. The zero-allocation serialization helpers below are
useful building blocks.

```@docs
PetoiBittle._serialize_token!
PetoiBittle._serialize_raw_i8!
```
