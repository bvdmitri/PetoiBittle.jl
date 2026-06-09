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
