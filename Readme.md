<h1 align="center"> AwesomeWM Luapulse </h1>

<p align="center"><b>Simple C library for interacting with PulseAdudio server.</b>
<p align="center">All handling of devices is done within awesome configuration

<p align="center">Made breaking changes no longer are default updates only an option,
default signal is now combined and cleaned up, race condition happening where default wasn'> [!TIP]
> set in awesome </p>
### Install:
```bash
git clone https://github.com/IllicitFrog/luapulse

cd luapulse

cmake -S . -B build

cmake --build build
```

### Usage:

```lua
local luapulse = require("libluapulse")

local lpulse = luapulse()
```

<s>local lpulse = luapulse(bool)</s>

### Functions:
 ```lua
 --Start monitor loop on seperate thread, will add signals to awesome wm loop
 lpulse:run()

 --Set Volume on output
 lpulse:setVolume(name, channels, volume)

 --Set Microphone Volume
 lpulse:setMicVolume(name, channels, volume)

 --Mute default sink
 lpulse:muteSink(name, bool)

 --Mute default source
 lpulse:muteSource(name, bool)

 --Set default sink by name and optionally move inputs
 lpulse:setDefaultSink(name, bool)

 --Set default source by name and optionally move outputs
 lpulse:setDefaultSource(name, move)
 ```

### Signals:

```lua
--defaults defaults={sink, source}
connect_signal("luapulse::default", function(defaults)

--sink removed
connect_signal("luapulse::remove_sink", function(index)

--source removed
connect_signal("luapulse::remove_source", function(index)

--sink updated data={index, volume, mute}
connect_signal("luapulse::sink_update", function(data)

--source updated data={index, volume, mute}
connect_signal("luapulse::source_update", function(data)

--new sink data={name, desc, index, channels, volume, mute}
connect_signal("luapulse::new_sink", function(data)

--new source data={name, desc, index, channels, volume, mute}
connect_signal("luapulse::new_source", function(data)
```
