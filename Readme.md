Simple pulseaudio interface for awesomewm, was just a project to learn some lua/c bindings!

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
