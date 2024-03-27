<h1 align="center"> AwesomeWM Luapulse </h1>

<p align="center"><b>Simple C library for interacting with PulseAudio server.</b>
<p align="center">All tracking of devices is done within awesome configuration

<h3>Install:</h3>

```bash
git clone https://github.com/IllicitFrog/luapulse

cd luapulse

cmake -S . -B build

cmake --build build
```

<h3>Usage:</h3>

```lua
local luapulse = require("libluapulse")

local lpulse = luapulse()
```

<h3>Functions:</h3>

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

<h3>Signals:</h3>

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

<h3>Examples:</h3>

```lua
local luapulse = require("libluapulse")

local sinks = {}
local sources = {}
local default_sink
local default_source

--Default Devices Update
awesome.connect_signal("luapulse::default", function(defaults)
	default_sink = defaults.sink
  default_source = defaults.source
end)

--Remove Sink
awesome.connect_signal("luapulse::remove_sink", function(name)
	for _, v in pairs(sources) do
		if v.name == name then
			sources[name] = nil
		end
	end
end)

--Remove Source
awesome.connect_signal("luapulse::remove_source", function(name)
	for _, v in pairs(sinks) do
		if v.name == name then
			sinks[name] = nil
		end
	end
end)

--Sink Update
awesome.connect_signal("luapulse::update_sink", function(data)
	if sinks[data.name] then
		if sinks[data.name].mute ~= data.mute or sinks[data.name].volume ~= data.volume then
			sinks[data.name].volume = data.volume
			sinks[data.name].mute = data.mute
		end
	end
end)

--Source Update
awesome.connect_signal("luapulse::update_source", function(data)
	if sources[data.name] then
		if sources[data.name].mute ~= data.mute or sources[data.name].volume ~= data.volume then
			sources[data.name].volume = data.volume
			sources[data.name].mute = data.mute
		end
	end
end)

--New Sink
awesome.connect_signal("luapulse::new_sink", function(data)
	sinks[data.name] = data
end)

--New Source
awesome.connect_signal("luapulse::new_source", function(data)
	sources[data.name] = data
end)

--Start monitor loop
local lpulse = luapulse()
lpulse:run()

awful.keys.append_global_keybindings({
    awful.key({}, "XF86AudioLowerVolume", function()
        local volume = sinks[default_sink].volume - 2
        if volume <= 0 then
            volume = 0
            if not sinks[default_sink].mute then
                lpulse:setMute(true)
            end
        end
        lpulse:setVolume(default_sink, sinks[default_sink].channels, volume)
    end, { description = "decrease volume", group = "awesome" })

    awful.key({}, "XF86AudioRaiseVolume", function()
        local volume = sinks[default_sink].volume + 2
        if sinks[default_sink].mute then
            lpulse:setMute(false)
        end
        if volume > 100 then
            volume = 100
        end
        lpulse:setVolume(default_sink.name, sinks[default_sink].channels, volume)
    end, { description = "increase volume", group = "awesome" })

    awful.key({}, "XF86AudioMute", function()
        lpulse:muteSink(default_sink, not sinks[default_sink].mute)
    end, { description = "mute volume", group = "awesome" })
})
```
