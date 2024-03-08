local luapulse = require("libluapulse")

local sinks = {}
local sources = {}
local default_sink
local default_source

--Defaults changed, simplified, race condition was happening
--sometimes default signal didn't happen before awesome loaded causing issues
awesome.connect_signal("luapulse::default", function(defaults)
	default_sink = defaults.sink
  default_source = defaults.source
	--emit update single for widgets
end)

awesome.connect_signal("luapulse::remove_sink", function(name)
	for _, v in pairs(sources) do
		if v.name == name then
			sources[name] = nil
		end
	end
end)

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
			--emit update single for widgets
		end
	end
end)

--Source Update
awesome.connect_signal("luapulse::update_source", function(data)
	if sources[data.name] then
		if sources[data.name].mute ~= data.mute or sources[data.name].volume ~= data.volume then
			sources[data.name].volume = data.volume
			sources[data.name].mute = data.mute
			--emit update single for widgets
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

--No longer supports only default updates results in extra call logic or outdated info on switching
--handle in lua if wanted
local lpulse = luapulse()
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
