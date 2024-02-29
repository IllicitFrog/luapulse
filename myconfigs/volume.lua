local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local utils = require("main.utils")
local gears = require("gears")

local pulsenotify = awful.popup({
	ontop = true,
	visible = false,
	widget = wibox.container.background,
	placement = function(c)
		awful.placement.centered(c, { margins = { top = beautiful.dpi(240) } })
	end,
	screen = config.centerM,
	bg = beautiful.bg1,
	shape = utils.rrect(beautiful.dpi(25)),
	border_width = beautiful.dpi(1),
	border_color = beautiful.blue,
	opacity = 0.9,
})

local device = wibox.widget({
	markup = "device",
	align = "center",
	margins = beautiful.dpi(5),
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
	forced_height = beautiful.dpi(15),
	margins = { top = beautiful.dpi(10) },
	widget = wibox.widget.progressbar,
	border_width = beautiful.dpi(1),
	border_color = beautiful.fg,
	shape = utils.rrect(beautiful.dpi(20)),
	color = beautiful.blue,
	background_color = beautiful.fg0,
})

local icon = wibox.widget({
	image = beautiful.config_path .. "assets/audio_low.png",
	halign = "center",
	valign = "center",
	forced_width = beautiful.dpi(30),
	forced_height = beautiful.dpi(30),
	widget = wibox.widget.imagebox,
})

pulsenotify:setup({
	{
		icon,
		device,
		slider,
		spacing = beautiful.dpi(10),
		layout = wibox.layout.fixed.vertical,
	},
	widget = wibox.container.margin,
	margins = beautiful.dpi(10),
	forced_height = beautiful.dpi(130),
	forced_width = beautiful.dpi(300),
})

awesome.connect_signal("volume::widget", function(data)
	device.markup = "<b>" .. config.sinks[data.name].desc .. "</b>"
	slider.value = data.volume
	if config.sinks[data.name].mute then
		icon.image = beautiful.config_path .. "assets/audio_mute.png"
		slider.color = beautiful.red
	elseif config.sinks[data.name].volume >= 50 then
		icon.image = beautiful.config_path .. "assets/audio_high.png"
		slider.color = beautiful.blue
	else
		icon.image = beautiful.config_path .. "assets/audio_low.png"
		slider.color = beautiful.blue
	end
	if not pulsenotify.visible then
		pulsenotify.visible = true
		timer:start()
	else
		timer:again()
	end
end)
