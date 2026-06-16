using Preferences

# Configurable package constants, backed by Preferences.jl. Each value can be overridden
# without editing source, for example:
#
#     using PetoiBittle, Preferences
#     set_preferences!(PetoiBittle, "baud_rate" => 9600)
#
# Because these are read here at load time they are compile-time preferences: changing one
# invalidates the precompilation cache, so a Julia restart is required for the new value to
# take effect.

"""
    PetoiBittle.BUFFER_CAPACITY

Size, in bytes, of the pre-allocated I/O buffer held by a [`PetoiBittle.Connection`](@ref).
Commands are serialized into this buffer and responses are read back into it, so it bounds
the largest single response line that can be received. Defaults to `256`. Override with the
`"buffer_capacity"` preference.
"""
const BUFFER_CAPACITY = @load_preference("buffer_capacity", 256)

"""
    PetoiBittle.BAUD_RATE

Baud rate used when opening the serial connection in [`PetoiBittle.connect`](@ref).
Defaults to `115200`. Override with the `"baud_rate"` preference.
"""
const BAUD_RATE = @load_preference("baud_rate", 115200)

"""
    PetoiBittle.MAX_RETRIES

Maximum number of times [`PetoiBittle.send_command`](@ref) re-reads the response when the
output fails [`PetoiBittle.validate_return_type`](@ref) before giving up with an error.
Defaults to `5`. Override with the `"max_retries"` preference.
"""
const MAX_RETRIES = @load_preference("max_retries", 5)

"""
    PetoiBittle.DEFAULT_TIMEOUT

Default timeout, in seconds, used for opening a connection and for serial read/write
operations. Defaults to `5`. Override with the `"default_timeout"` preference.
"""
const DEFAULT_TIMEOUT = @load_preference("default_timeout", 5)

"""
    PetoiBittle.PRECOMPILE_WORKLOAD

Whether to run the [PrecompileTools.jl](https://github.com/JuliaLang/PrecompileTools.jl)
workload at precompilation time. The workload drives [`PetoiBittle.send_command`](@ref)
through a fake in-memory serial port for a representative set of commands, so the
serialization, parsing, and command-dispatch machinery is compiled once and cached in the
package image instead of on first use. This makes the first real `send_command` fast, which
matters on low-power targets such as a Raspberry Pi.

Defaults to `true`. Set it to `false` to skip the workload (useful in headless CI or when
iterating on the package, where the extra precompilation cost is not worth it):

```julia
using PetoiBittle, Preferences
set_preferences!(PetoiBittle, "precompile_workload" => false)
```

Override with the `"precompile_workload"` preference.
"""
const PRECOMPILE_WORKLOAD = @load_preference("precompile_workload", true)
