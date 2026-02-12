```@meta
CurrentModule = PetoiBittle
```

# PetoiBittle

Documentation for [PetoiBittle](https://github.com/bvdmitri/PetoiBittle.jl).

## PetoiBittle ports

PetoiBittle.jl implements convenience functions to find and/or check if a port is connected to Petoi Bittle Dog robot. 

```@docs 
PetoiBittle.is_bittle_port
PetoiBittle.find_bittle_port
```

Users can also use `PetoiBittle.LibSerialPort.get_port_list` to get a list of all ports compatible with `LibSerialPort`.

## PetoiBittle parsers

PetoiBittle.jl implements simple parsers to parse responses from 
serial ports of PetoiBittle directly from bytes

```@docs 
PetoiBittle.parse_number
```

## PetoiBittle Constants

```@docs
PetoiBittle.Constants
```


```@index
```
