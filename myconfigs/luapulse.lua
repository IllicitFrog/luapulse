local luapulse = require("libluapulse")
--global variables are all stored in configs should have been named Vars
--configs = {}
--configs.sinks = {}
--configs.sources = {}

------ Luapulse Signals --------------
--Default Sink Changed
awesome.connect_signal("luapulse::sink_default", function(name)
	config.default_sink = name
	awesome.emit_signal("pulseaudio::update")
end)

--Default Source Changed
awesome.connect_signal("luapulse::source_default", function(name)
	config.default_source = name
	awesome.emit_signal("pulseaudio::update")
end)

--Remove Sink
awesome.connect_signal("luapulse::remove_sink", function(index)
	for _, sink in pairs(config.sinks) do
		if sink.index == index then
			config.sinks[sink.name] = nil
      break
		end
	end
end)

--Remove Source
awesome.connect_signal("luapulse::remove_source", function(index)
	for _, source in pairs(config.sources) do
		if source.index == index then
			config.sources[source.name] = nil
      break
		end
	end
end)

--Sink Update
awesome.connect_signal("luapulse::update_sink", function(data)
	if config.sinks[data.name] then
		if config.sinks[data.name].volume ~= data.volume or config.sinks[data.name].mute ~= data.mute then
			config.sinks[data.name].volume = data.volume
			config.sinks[data.name].mute = data.mute
			awesome.emit_signal("volume::widget", data)
			awesome.emit_signal("pulseaudio::update")
		end
	end
end)

--Source Update
awesome.connect_signal("luapulse::update_source", function(data)
	if config.sources[data.name] then
		if config.sources[data.name].volume ~= data.volume or config.sources[data.name].mute ~= data.mute then
			config.sources[data.name].volume = data.volume
			config.sources[data.name].mute = data.mute
			awesome.emit_signal("volume::widget", data)
			awesome.emit_signal("pulseaudio::update")
		end
	end
end)

--New Sink
awesome.connect_signal("luapulse::new_sink", function(data)
	config.sinks[data.name] = data
end)

--New Source
awesome.connect_signal("luapulse::new_source", function(data)
	config.sources[data.name] = data
end)

--Receive Only Default Device Updates (true)
local lpulse = luapulse(true)
lpulse:run()

--Set Default Sink Volume
awesome.connect_signal("luapulse::setVolume", function(volume)
	lpulse:setVolume(config.sinks[config.default_sink].name, config.sinks[config.default_sink].channels, volume)
end)

--Mute Default Sink
awesome.connect_signal("luapulse::set_mute", function(mute)
	lpulse:muteSink(mute)
end)

--Set Default Sink
awesome.connect_signal("luapulse::set_defaultSink", function(index, move)
	lpulse:setDefaultSink(index, move)
end)

--Set Default Source Volume
awesome.connect_signal("luapulse::set_sourceVolume", function(volume)
	lpulse:setMicVolume(
		config.sources[config.default_source].name,
		config.sources[config.default_source].channels,
		volume
	)
end)

--Mute Default Source
awesome.connect_signal("luapulse::set_sourceMute", function(mute)
	lpulse:muteSource(mute)
end)

--Set Default Source
awesome.connect_signal("luapulse::set_defaultSource", function(index, move)
	lpulse:setDefaultSource(index, move)
end)
