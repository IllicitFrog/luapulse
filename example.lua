--[[
------- Luapulse functions -------
 require("libluapulse")
 local lpulse = l_pulse(bool)
    True of false receive only default device sink/source updates
    true by default.
 lpulse:run()
    Start monitor loop
 void setVolume(std::string name, unsigned int channels, int volume);
    Set Volume on output by name
 void setMicVolume(std::string name, unsigned int channels, int volume);
    Set Microphone Volume by name
 void muteSink(bool mute);
    Mute default sink
 void muteSource(bool mute); Mute default source
 void setDefaultSink(std::string name, bool move);
    Set default sink by name and optionally move inputs(index, true or false)
 void setDefaultSource(std::string name, bool move);
    Set default source by name and optionally move outputs(index, true or false)

------ Luapulse Signals --------------
luapulse::sink_default :
  connect_signal("luapulse::sink_default", function(index)
luapulse::source_default :
  connect_signal("luapulse::source_default", function(index)
luapulse::remove_sink
  connect_signal("luapulse::remove_sink", function(index)
luapulse::remove_source
  connect_signal("luapulse::remove_source", function(index)
luapulse::sink_update
  connect_signal("luapulse::sink_update", function(data)
  data = { index, volume, mute }
luapulse::source_update
  connect_signal("luapulse::source_update", function(data)
  data = { index, volume, mute }
luapulse::new_sink
  connect_signal("luapulse::new_sink", function(data)
  data = { name, desc, index, channels, volume, mute }
luapulse::new_source
  connect_signal("luapulse::new_source", function(data)
  data = { name, desc, index, channels, volume, mute }
]]
--

local awful = require("awful")
local wibox = require("wibox")
local utils = require("main.utils")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
require("libluapulse")

local pulsenotify = awful.popup({
	ontop = true,
	visible = false,
	widget = wibox.container.background,
	placement = function(c)
		awful.placement.centered(c, { margins = { top = dpi(240) } })
	end,
	screen = config.centerM,
	bg = beautiful.bg1,
	shape = utils.rrect(dpi(25)),
	border_width = dpi(1),
	border_color = beautiful.blue,
	opacity = 0.9,
})

local device = wibox.widget({
	markup = "device",
	align = "center",
	widget = wibox.widget.textbox,
})

local timer = gears.timer({
	timeout = 2,
	callback = function()
		pulsenotify.visible = false
	end,
})

local slider = wibox.widget({
	max_value = 100,
	value = 50,
	forced_height = dpi(10),
	forced_width = dpi(200),
	widget = wibox.widget.progressbar,
	border_width = dpi(1),
	border_color = beautiful.fg,
	shape = utils.rrect(dpi(20)),
	color = beautiful.blue,
	background_color = beautiful.fg0,
})

local icon = wibox.widget({
	image = beautiful.config_path .. "assets/audio.png",
	halign = "center",
	valign = "center",
	forced_width = dpi(50),
	forced_height = dpi(50),
	widget = wibox.widget.imagebox,
})

pulsenotify:setup({
	{
		{
			icon,
			widget = wibox.container.margin,
			margins = dpi(5),
		},
		{
			device,
			widget = wibox.container.margin,
			margins = dpi(10),
		},
		{
			slider,
			widget = wibox.container.margin,
			margins = { top = dpi(15), left = dpi(20), right = dpi(20), bottom = dpi(0) },
		},
		layout = wibox.layout.fixed.vertical,
	},
	widget = wibox.container.margin,
	forced_width = dpi(300),
	forced_height = dpi(140),
})

------ Luapulse Signals --------------
--Default Sink Changed
awesome.connect_signal("luapulse::sink_default", function(index)
	config.default_sink = index
	awesome.emit_signal("pulseaudio::update")
end)

--Default Source Changed
awesome.connect_signal("luapulse::source_default", function(index)
	config.default_source = index
	awesome.emit_signal("pulseaudio::update")
end)

--Remove Sink
awesome.connect_signal("luapulse::remove_sink", function(index)
	config.sinks[index] = nil
end)

--Remove Source
awesome.connect_signal("luapulse::remove_source", function(index)
	config.sources[index] = nil
end)

--Sink Update
awesome.connect_signal("luapulse::update_sink", function(data)
	if config.sinks[data.index] then
		if config.sinks[data.index].mute ~= data.mute or config.sinks[data.index].volume ~= data.volume then
			config.sinks[data.index].volume = data.volume
			config.sinks[data.index].mute = data.mute
			device.markup = "<b>" .. config.sinks[data.index].desc .. "</b>"
			if config.sinks[data.index].mute then
				icon.image = beautiful.config_path .. "assets/audio_mute.png"
				slider.color = beautiful.red
			else
				if config.sinks[data.index].volume >= 50 then
					icon.image = beautiful.config_path .. "assets/audio_high.png"
				else
					icon.image = beautiful.config_path .. "assets/audio_low.png"
				end
				slider.color = beautiful.blue
				slider.value = data.volume
			end
			if not pulsenotify.visible then
				pulsenotify.visible = true
				timer:start()
			else
				timer:again()
			end
			awesome.emit_signal("pulseaudio::update")
		end
	end
end)

--Source Update
awesome.connect_signal("luapulse::update_source", function(data)
	if config.sources[data.index] then
		if config.sources[data.index].mute ~= data.mute or config.sources[data.index].volume ~= data.volume then
			config.sources[data.index].volume = data.volume
			config.sources[data.index].mute = data.mute
			device.markup = "<b>" .. config.sources[data.index].desc .. "</b>"
			if config.sources[data.index].mute then
				icon.image = beautiful.config_path .. "assets/audio_mute.png"
				slider.color = beautiful.red
			else
				if config.sources[data.index].volume >= 50 then
					icon.image = beautiful.config_path .. "assets/audio_high.png"
				else
					icon.image = beautiful.config_path .. "assets/audio_low.png"
				end
				slider.color = beautiful.blue
				slider.value = data.volume
			end
			if not pulsenotify.visible then
				pulsenotify.visible = true
				timer:start()
			else
				timer:again()
			end
		end
		awesome.emit_signal("pulseaudio::update")
	end
end)

--New Sink
awesome.connect_signal("luapulse::new_sink", function(data)
	config.sinks[data.index] = data
end)

--New Source
awesome.connect_signal("luapulse::new_source", function(data)
	config.sources[data.index] = data
end)

--Receive Only Default Device Updates (true)
local lpulse = l_pulse()
lpulse:run()

--Set Default Sink Volume
awesome.connect_signal("luapulse::setVolume", function(volume)
	if type(volume) == "string" then
		if string.sub(volume, 1, 1) == "+" then
			volume = config.sinks[config.default_sink].volume + tonumber(string.sub(volume, 2, 2))
		elseif string.sub(volume, 1, 1) == "-" then
			volume = config.sinks[config.default_sink].volume - tonumber(string.sub(volume, 2, 2))
		end
	end
	if volume > 100 then
		volume = 100
	elseif volume <= 0 then
		volume = 0
		if not config.sinks[config.default_sink].mute then
			awesome.emit_signal("luapulse::set_mute", true)
		end
	elseif config.sinks[config.default_sink].mute then
		awesome.emit_signal("luapulse::set_mute", false)
	end
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
	if type(volume) == "string" then
		if string.sub(volume, 1, 1) == "+" then
			volume = config.sources[config.default_source].volume + tonumber(string.sub(volume, 2, 2))
		elseif string.sub(volume, 1, 1) == "-" then
			volume = config.sources[config.default_source].volume - tonumber(string.sub(volume, 2, 2))
		end
	end
	if volume > 100 then
		volume = 100
	elseif volume <= 0 then
		volume = 0
		if not config.sinks[config.default_source].mute then
			awesome.emit_signal("luapulse::set_sourceMute", true)
		end
	elseif config.sinks[config.default_sink].mute then
		awesome.emit_signal("luapulse::set_sourceMute", false)
	end
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
