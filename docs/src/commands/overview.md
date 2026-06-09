```@meta
CurrentModule = PetoiBittle
```

# Commands overview

PetoiBittle.jl is built around a small, fast command layer. Every action you can ask the
robot to perform is a [`PetoiBittle.Command`](@ref); you send it over an open
[`PetoiBittle.Connection`](@ref) with [`PetoiBittle.send_command`](@ref).

On top of that low-level layer, the built-in skills (gaits, postures, behaviors) also expose
**convenience verbs** so you can write expressive, high-level code:

```julia
using PetoiBittle

port = PetoiBittle.find_bittle_port()
connection = PetoiBittle.connect(port)

PetoiBittle.sit(connection)            # high-level verb
PetoiBittle.walk_forward(connection)   # ... and another

# the verb above is exactly equivalent to the explicit, low-level form:
PetoiBittle.send_command(connection, PetoiBittle.WalkForward())

PetoiBittle.disconnect(connection)
```

Both styles compile down to the same zero-allocation write path, so the convenience verbs cost
nothing extra at runtime.

The full Petoi protocol is documented on the Petoi website in the
[Serial Protocol](https://docs.petoi.com/apis/serial-protocol) section. This library
implements a curated subset; commands that are not modelled yet can still be sent with the
low-level [`PetoiBittle.RawCommand`](@ref) / [`PetoiBittle.RawQuery`](@ref). PRs adding new
typed commands are welcome!

## The command interface

```@docs
PetoiBittle.Command
PetoiBittle.send_command
PetoiBittle.command_terminator
PetoiBittle.NO_TERMINATOR
PetoiBittle.before_command
PetoiBittle.after_command
PetoiBittle.command_return_type
PetoiBittle.NoResponse
PetoiBittle.validate_return_type
PetoiBittle.deserialize_from_bytes
```

## Built-in skills at a glance

The table below lists every built-in skill (gait, posture, behavior): its command type, its
convenience verb, and the raw firmware token it sends. It is generated directly from
[`PetoiBittle.skills_overview`](@ref), so it always matches the code.

```@eval
using PetoiBittle, Markdown
rows = PetoiBittle.skills_overview()
io = IOBuffer()
println(io, "| Category | Command type | Convenience verb | Token | Description |")
println(io, "|:---------|:-------------|:-----------------|:------|:------------|")
for r in rows
    println(io, "| ", r.category, " | `", r.julia_name, "` | `", r.verb, "` | `", r.token, "` | ", r.description, " |")
end
Markdown.parse(String(take!(io)))
```

Commands that take arguments (joint control, sound) and the low-level primitives are described
on their own pages: [Joint control](joints.md), [Control & state](control.md),
[Sound](sound.md), and [Low-level & advanced](lowlevel.md).

```@docs
PetoiBittle.skills_overview
```

```@index
Pages = ["overview.md", "gaits.md", "postures.md", "behaviors.md", "joints.md", "control.md", "sound.md", "lowlevel.md"]
```
