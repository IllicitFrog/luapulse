#ifndef LUAPULSE_H
#define LUAPULSE_H
#include <glib.h>
#include <lua.hpp>
#include <pulse/pulseaudio.h>
#include <string>

#define LUA_PULSE "l_pulse"

typedef struct {
  lua_State *L;
  std::string signal;
  std::string name;
  std::string desc;
  unsigned int idx;
  unsigned int volume;
  int mute;
  unsigned int channels;
} pa_device;

typedef struct {
  lua_State *L;
  std::string signal;
  unsigned int idx;
  unsigned int volume;
  int mute;
} pa_update;

typedef struct {
  lua_State *L;
  std::string signal;
  unsigned int idx;
} pa_remove;

typedef struct {
  lua_State *L;
  std::string error;
} pa_error;

typedef struct {
  lua_State *L;
  std::string signal;
  unsigned int idx;
} pa_default;

class luapulse {
public:
  luapulse(lua_State *L, bool _defaults);
  ~luapulse();

  void setMicVolume(std::string name, unsigned int channels, int volume);
  void setVolume(std::string name, unsigned int channels, int volume);
  void muteSink(bool mute);
  void muteSource(bool mute);
  void setDefaultSink(std::string name, bool move);
  void setDefaultSource(std::string name, bool move);
  void run();

private:
  lua_State *L;
  pa_context *context;
  pa_threaded_mainloop *mainloop;
  bool defaults;
  unsigned int default_sink;
  unsigned int default_source;

  // State Callback, call initial handling and subscribe
  static void contextStateCallback(pa_context *c, void *userdata) {
    luapulse *pulse = static_cast<luapulse *>(userdata);
    switch (pa_context_get_state(pulse->context)) {
    case PA_CONTEXT_READY:
      pa_context_get_sink_info_list(pulse->context, sinkNew, pulse->L);
      pa_context_get_source_info_list(pulse->context, sourceNew, pulse->L);
      pa_context_get_server_info(pulse->context, serverInfoUpdate, pulse);
      pa_context_subscribe(
          pulse->context,
          (pa_subscription_mask_t)(PA_SUBSCRIPTION_MASK_SOURCE |
                                   PA_SUBSCRIPTION_MASK_SINK |
                                   PA_SUBSCRIPTION_MASK_SERVER),
          NULL, NULL);
      pa_context_set_subscribe_callback(pulse->context, subscribeCallback,
                                        pulse);
      break;
    case PA_CONTEXT_CONNECTING:
    case PA_CONTEXT_AUTHORIZING:
    case PA_CONTEXT_SETTING_NAME:
      break;
    case PA_CONTEXT_FAILED:
    case PA_CONTEXT_TERMINATED:
    case PA_CONTEXT_UNCONNECTED:
      pa_error *error = new pa_error();
      error->L = pulse->L;
      error->error = pa_strerror(pa_context_errno(pulse->context));
      g_idle_add(signalError, error);
      break;
    }
  }

  // Subscription call back based on event type
  static void subscribeCallback(pa_context *c, pa_subscription_event_type_t t,
                                uint32_t idx, void *userdata) {
    luapulse *pulse = static_cast<luapulse *>(userdata);
    // Event Type
    switch (t & PA_SUBSCRIPTION_EVENT_TYPE_MASK) {
      // Event Change
    case PA_SUBSCRIPTION_EVENT_CHANGE:
      switch (t & PA_SUBSCRIPTION_EVENT_FACILITY_MASK) {
      case (PA_SUBSCRIPTION_EVENT_SINK):
        if (pulse->default_sink == idx || !pulse->defaults)
          pa_context_get_sink_info_by_index(pulse->context, idx, sinkChange,
                                            pulse->L);
        break;
      case PA_SUBSCRIPTION_EVENT_SOURCE:
        if (pulse->default_source == idx || !pulse->defaults)
          pa_context_get_source_info_by_index(pulse->context, idx, sourceChange,
                                              pulse->L);

        break;
      case PA_SUBSCRIPTION_EVENT_SERVER:
        pa_context_get_server_info(pulse->context, serverInfoUpdate, pulse);
        break;
      default:
        break;
      }
      break;
      // Event New
    case PA_SUBSCRIPTION_EVENT_NEW:
      switch (t & PA_SUBSCRIPTION_EVENT_FACILITY_MASK) {
      case PA_SUBSCRIPTION_EVENT_SINK:
        pa_context_get_sink_info_by_index(pulse->context, idx, sinkNew,
                                          pulse->L);
        break;
      case PA_SUBSCRIPTION_EVENT_SOURCE:
        pa_context_get_source_info_by_index(pulse->context, idx, sourceNew,
                                            pulse->L);
        break;
      default:
        break;
      }
      break;
    // Event Remove
    case PA_SUBSCRIPTION_EVENT_REMOVE:
      switch (t & PA_SUBSCRIPTION_EVENT_FACILITY_MASK) {
      case PA_SUBSCRIPTION_EVENT_SINK: {
        pa_remove *rm = new pa_remove{pulse->L, "luapulse::remove_sink", idx};
        g_idle_add(signalRemove, rm);
        break;
      }
      case PA_SUBSCRIPTION_EVENT_SOURCE: {
        pa_remove *rm = new pa_remove{pulse->L, "luapulse::remove_source", idx};
        g_idle_add(signalRemove, rm);
        break;
      }
      default:
        break;
      }
    default:
      break;
    }
  }

  // Callback for server changes - update device list and default sink/source
  static void serverInfoUpdate(pa_context *c, const pa_server_info *i,
                               void *userdata) {
    luapulse *pulse = static_cast<luapulse *>(userdata);
    pa_context_get_sink_info_by_name(pulse->context, i->default_sink_name,
                                     defaultSink, pulse);
    pa_context_get_source_info_by_name(pulse->context, i->default_source_name,
                                       defaultSource, pulse);
  }

  static void defaultSink(pa_context *c, const pa_sink_info *i, int eol,
                          void *userdata) {
    if (!eol) {
      luapulse *pulse = static_cast<luapulse *>(userdata);
      if (pulse->default_sink != i->index) {
        pulse->default_sink = i->index;
        pa_default *def = new pa_default{
            pulse->L,
            "luapulse::sink_default",
            pulse->default_sink,
        };
        printf("sink default %d\n", pulse->default_sink);
        g_idle_add(signalDefault, def);
      }
    }
  }

  static void defaultSource(pa_context *c, const pa_source_info *i, int eol,
                            void *userdata) {
    if (!eol) {
      luapulse *pulse = static_cast<luapulse *>(userdata);
      if (pulse->default_source != i->index) {
        pulse->default_source = i->index;
        pa_default *def = new pa_default{
            pulse->L,
            "luapulse::source_default",
            pulse->default_sink,
        };
        g_idle_add(signalDefault, def);
      }
    }
  }

  // Callback for sink output move request when changing default Sink
  static void sinkInputListcb(pa_context *c, const pa_sink_input_info *i,
                              int eol, void *userdata) {
    if (!eol) {
      luapulse *pulse = static_cast<luapulse *>(userdata);
      pa_context_move_sink_input_by_index(pulse->context, i->index,
                                          pulse->default_sink, NULL, NULL);
    }
  }

  // Callback for source output move request when changing default Source
  static void sourceInputListcb(pa_context *c, const pa_source_output_info *i,
                                int eol, void *userdata) {
    if (!eol) {
      luapulse *pulse = static_cast<luapulse *>(userdata);
      pa_context_move_source_output_by_index(pulse->context, i->index,
                                             pulse->default_source, NULL, NULL);
    }
  }

  // Sink event change, Update volume and state
  static void sinkChange(pa_context *c, const pa_sink_info *i, int eol,
                         void *userdata) {
    if (!eol) {
      pa_update *upd = new pa_update{
          (lua_State *)userdata, "luapulse::update_sink", i->index,
          pa_cvolume_avg(&i->volume) * 100 / PA_VOLUME_NORM, i->mute};
      g_idle_add(signalUpdate, upd);
    }
  }

  // Source event change, Update volume and state
  static void sourceChange(pa_context *c, const pa_source_info *i, int eol,
                           void *userdata) {
    if (!eol) {
      pa_update *upd = new pa_update{
          (lua_State *)userdata, "luapulse::update_source", i->index,
          pa_cvolume_avg(&i->volume) * 100 / PA_VOLUME_NORM, i->mute};
      g_idle_add(signalUpdate, upd);
    }
  }

  static void sinkNew(pa_context *c, const pa_sink_info *i, int eol,
                      void *userdata) {
    if (!eol) {
      pa_device *dev =
          new pa_device{(lua_State *)userdata,
                        "luapulse::new_sink",
                        i->name,
                        i->description,
                        i->index,
                        pa_cvolume_avg(&i->volume) * 100 / PA_VOLUME_NORM,
                        i->mute,
                        i->channel_map.channels};
      g_idle_add(signalNew, dev);
    }
  }

  static void sourceNew(pa_context *c, const pa_source_info *i, int eol,
                        void *userdata) {
    if (!eol) {
      pa_device *dev =
          new pa_device{(lua_State *)userdata,
                        "luapulse::new_source",
                        i->name,
                        i->description,
                        i->index,
                        pa_cvolume_avg(&i->volume) * 100 / PA_VOLUME_NORM,
                        i->mute,
                        i->channel_map.channels};
      g_idle_add(signalNew, dev);
    }
  }

  // Remove Device from List
  static gboolean signalRemove(gpointer data) {
    pa_remove *rm = static_cast<pa_remove *>(data);
    lua_getglobal(rm->L, "awesome");
    lua_getfield(rm->L, -1, "emit_signal");
    lua_remove(rm->L, -2);
    lua_pushstring(rm->L, rm->signal.c_str());
    lua_pushnumber(rm->L, rm->idx);
    lua_call(rm->L, 2, 0);
    delete rm;
    return G_SOURCE_REMOVE;
  }

  // Remove Device from List
  static gboolean signalDefault(gpointer data) {
    pa_default *def = static_cast<pa_default *>(data);
    lua_getglobal(def->L, "awesome");
    lua_getfield(def->L, -1, "emit_signal");
    lua_remove(def->L, -2);
    lua_pushstring(def->L, def->signal.c_str());
    lua_pushnumber(def->L, def->idx);
    lua_call(def->L, 2, 0);
    delete def;
    return G_SOURCE_REMOVE;
  }

  static gboolean signalUpdate(gpointer data) {
    pa_update *upd = static_cast<pa_update *>(data);
    lua_getglobal(upd->L, "awesome");
    lua_getfield(upd->L, -1, "emit_signal");
    lua_remove(upd->L, -2);
    lua_pushstring(upd->L, upd->signal.c_str());
    lua_newtable(upd->L);
    lua_pushliteral(upd->L, "index");
    lua_pushnumber(upd->L, upd->idx);
    lua_rawset(upd->L, -3);
    lua_pushliteral(upd->L, "volume");
    lua_pushnumber(upd->L, upd->volume);
    lua_rawset(upd->L, -3);
    lua_pushliteral(upd->L, "mute");
    lua_pushboolean(upd->L, upd->mute);
    lua_rawset(upd->L, -3);
    lua_call(upd->L, 2, 0);
    delete upd;
    return G_SOURCE_REMOVE;
  }

  static gboolean signalNew(gpointer data) {
    pa_device *dev = static_cast<pa_device *>(data);
    lua_getglobal(dev->L, "awesome");
    lua_getfield(dev->L, -1, "emit_signal");
    lua_remove(dev->L, -2);
    lua_pushstring(dev->L, dev->signal.c_str());
    lua_newtable(dev->L);
    lua_pushliteral(dev->L, "name");
    lua_pushstring(dev->L, dev->name.c_str());
    lua_rawset(dev->L, -3);
    lua_pushliteral(dev->L, "desc");
    lua_pushstring(dev->L, dev->desc.c_str());
    lua_rawset(dev->L, -3);
    lua_pushliteral(dev->L, "index");
    lua_pushnumber(dev->L, dev->idx);
    lua_rawset(dev->L, -3);
    lua_pushliteral(dev->L, "channels");
    lua_pushnumber(dev->L, dev->channels);
    lua_rawset(dev->L, -3);
    lua_pushliteral(dev->L, "volume");
    lua_pushnumber(dev->L, dev->volume);
    lua_rawset(dev->L, -3);
    lua_pushliteral(dev->L, "mute");
    lua_pushboolean(dev->L, dev->mute);
    lua_rawset(dev->L, -3);
    lua_call(dev->L, 2, 0);
    delete dev;
    return G_SOURCE_REMOVE;
  }

  static gboolean signalError(gpointer data) {
    pa_error *err = static_cast<pa_error *>(data);
    lua_getglobal(err->L, "awesome");
    lua_getfield(err->L, -1, "emit_signal");
    lua_remove(err->L, -2);
    lua_pushstring(err->L, "request::display_error");
    lua_pushstring(err->L, err->error.c_str());
    lua_call(err->L, 2, 0);
    delete err;
    return G_SOURCE_REMOVE;
  }
};
#endif
