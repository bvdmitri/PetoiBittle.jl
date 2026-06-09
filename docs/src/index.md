```@meta
CurrentModule = PetoiBittle
```

```@raw html
<div align="center">
  <img src="assets/logo.svg" alt="PetoiBittle.jl logo" width="200">
</div>
```

# PetoiBittle

Documentation for [PetoiBittle](https://github.com/bvdmitri/PetoiBittle.jl).

## PetoiBittle connection

PetoiBittle.jl implements convenience functions to find and/or check if a port is connected to Petoi Bittle Dog robot as well as 
establish a connection with a given port.

```@docs 
PetoiBittle.is_bittle_port
PetoiBittle.find_bittle_port
PetoiBittle.Connection
PetoiBittle.connect
PetoiBittle.disconnect
```

Users can also use `PetoiBittle.LibSerialPort.get_port_list` to get a list of all ports compatible with `LibSerialPort`.

## PetoiBittle parsers

PetoiBittle.jl implements simple parsers to parse responses from 
serial ports of PetoiBittle directly from bytes

```@docs 
PetoiBittle.parse_number
```

## PetoiBittle serializers

PetoiBittle.jl implements simple serializers to write responses to 
serial ports of PetoiBittle directly as bytes

```@docs 
PetoiBittle.serialize_to_bytes!
PetoiBittle.DigitsIterator
PetoiBittle.iterate_digits
```

## PetoiBittle Constants

```@docs
PetoiBittle.Constants
```

## PetoiBittle Configuration

A few package constants are configurable through
[Preferences.jl](https://github.com/JuliaPackaging/Preferences.jl). The defaults suit a
standard Petoi Bittle, but you can override them without editing the source. For example,
to change the baud rate:

```julia
using PetoiBittle, Preferences
set_preferences!(PetoiBittle, "baud_rate" => 9600)
```

This records the value in a `LocalPreferences.toml` file next to your active project:

```toml
[PetoiBittle]
baud_rate = 9600
```

!!! note
    These preferences are read when the package is loaded, which makes them compile-time
    preferences. Changing one invalidates the precompilation cache, so you need to restart
    Julia for the new value to take effect.

```@docs
PetoiBittle.BUFFER_CAPACITY
PetoiBittle.BAUD_RATE
PetoiBittle.MAX_RETRIES
PetoiBittle.DEFAULT_TIMEOUT
```


```@index
```
