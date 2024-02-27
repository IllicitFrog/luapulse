local luapulse = require("libluapulse")

local sinks = {}
local sources = {}
local default_sink
local default_source

awesome.connect_signal("luapulse::sink_default", function(index)
	default_sink = index
	--emit update single for widgets
end)

awesome.connect_signal("luapulse::source_default", function(index)
	default_source = index
	--emit update single for widgets
end)

awesome.connect_signal("luapulse::remove_sink", function(index)
	sinks[index] = nil
end)

awesome.connect_signal("luapulse::remove_source", function(index)
	sources[index] = nil
end)

--Sink Update
awesome.connect_signal("luapulse::update_sink", function(data)
	if sinks[data.index] then
		if sinks[data.index].mute ~= data.mute or sinks[data.index].volume ~= data.volume then
			sinks[data.index].volume = data.volume
			sinks[data.index].mute = data.mute
			--emit update single for widgets
		end
	end
end)

--Source Update
awesome.connect_signal("luapulse::update_source", function(data)
	if sources[data.index] then
		if sources[data.index].mute ~= data.mute or sources[data.index].volume ~= data.volume then
			sources[data.index].volume = data.volume
			sources[data.index].mute = data.mute
			--emit update single for widgets
		end
	end
end)

--New Sink
awesome.connect_signal("luapulse::new_sink", function(data)
	sinks[data.index] = data
end)

--New Source
awesome.connect_signal("luapulse::new_source", function(data)
	sources[data.index] = data
end)

--Receive Only Default Device Updates (true)
local lpulse = luapulse(true)
lpulse:run()

--awful.keys.append_global_keybindings({
awful.key({}, "XF86AudioLowerVolume", function()
	local volume = sinks[default_sink].volume - 2
	if volume <= 0 then
		volume = 0
		if not sinks[default_sink].mute then
			lpulse:setMute(true)
		end
	end
	lpulse:setVolume(sinks[default_sink].name, sinks[default_sink].channels, volume)
end, { description = "decrease volume", group = "awesome" })

awful.key({}, "XF86AudioRaiseVolume", function()
	local volume = sinks[default_sink].volume + 2
	if sinks[default_sink].mute then
		lpulse:setMute(false)
	end
	if volume > 100 then
		volume = 100
	end
	lpulse:setVolume(sinks[default_sink].name, sinks[default_sink].channels, volume)
end, { description = "increase volume", group = "awesome" })

awful.key({}, "XF86AudioMute", function()
	lpulse:muteSink(not sinks[default_sink].mute)
end, { description = "mute volume", group = "awesome" })
