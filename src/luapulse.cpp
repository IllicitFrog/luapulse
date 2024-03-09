#include "luapulse.h"

luapulse::luapulse(lua_State *Lua) {
  L = Lua;
  mainloop = pa_threaded_mainloop_new();
  context = pa_context_new(pa_threaded_mainloop_get_api(mainloop), "luasub");

  pa_context_set_state_callback(context, contextStateCallback, this);
  if (pa_context_connect(context, NULL, PA_CONTEXT_NOFLAGS, NULL) < 0) {
    pa_error *error = new pa_error();
    error->L = L;
    error->error = pa_strerror(pa_context_errno(context));
    g_idle_add(signalError, error);
  }
}

void luapulse::run() { pa_threaded_mainloop_start(mainloop); }

// Cleanup When quit or leaving
luapulse::~luapulse() {
  pa_context_disconnect(context);
  pa_context_unref(context);
  pa_threaded_mainloop_stop(mainloop);
  pa_threaded_mainloop_free(mainloop);
}

void luapulse::setDefaultSink(std::string name, bool move) {

  pa_context_set_default_sink(context, name.c_str(), NULL, NULL);
  if (move) {
    std::string *sm = new std::string(name);
    pa_context_get_sink_input_info_list(context, sinkInputListcb, sm);
  }
}

void luapulse::setDefaultSource(std::string name, bool move) {
  pa_context_set_default_source(context, name.c_str(), NULL, NULL);
  if (move) {
    std::string *sm = new std::string(name);
    pa_context_get_source_output_info_list(context, sourceInputListcb, sm);
  }
}

void luapulse::setVolume(std::string name, unsigned int channels, int volume) {
  if (volume <= 0) {
    volume = 0;
  } else if (volume > 100) {
    volume = 100;
  }
  pa_cvolume cvolume;
  pa_cvolume_init(&cvolume);
  pa_cvolume_set(&cvolume, channels, PA_VOLUME_NORM * volume / 100);
  pa_context_set_sink_volume_by_name(context, name.c_str(), &cvolume, NULL,
                                     NULL);
}

void luapulse::setMicVolume(std::string name, unsigned int channels,
                            int volume) {
  if (volume <= 0) {
    volume = 0;
  } else if (volume > 100) {
    volume = 100;
  }
  pa_cvolume cvolume;
  pa_cvolume_init(&cvolume);
  pa_cvolume_set(&cvolume, channels, PA_VOLUME_NORM * volume / 100);
  pa_context_set_source_volume_by_name(context, name.c_str(), &cvolume, NULL,
                                       NULL);
}

void luapulse::muteSink(std::string name, bool mute) {
  pa_context_set_sink_mute_by_name(context, name.c_str(), mute, NULL,
                                    NULL); // idx, mute, NULL, NULL);
}

void luapulse::muteSource(std::string name, bool mute) {
  pa_context_set_source_mute_by_name(context, name.c_str(), mute, NULL,
                                      NULL);
}

//----- Lua Functions -------
static int luapulse_new(lua_State *L) {
  *reinterpret_cast<luapulse **>(lua_newuserdata(L, sizeof(luapulse *))) =
      new luapulse(L);
  luaL_setmetatable(L, LUA_PULSE);
  return 1;
}

static int luapulse_delete(lua_State *L) {
  (*reinterpret_cast<luapulse **>(luaL_checkudata(L, 1, LUA_PULSE)))
      ->~luapulse();
  return 0;
}

static int luapulse_setDefaultSink(lua_State *L) {
  (*reinterpret_cast<luapulse **>(luaL_checkudata(L, 1, LUA_PULSE)))
      ->setDefaultSink(luaL_checkstring(L, 2), lua_isboolean(L, 3));
  return 0;
}

static int luapulse_setDefaultSource(lua_State *L) {
  (*reinterpret_cast<luapulse **>(luaL_checkudata(L, 1, LUA_PULSE)))
      ->setDefaultSource(luaL_checkstring(L, 2), lua_isboolean(L, 3));
  return 0;
}

static int luapulse_setVolume(lua_State *L) {
  (*reinterpret_cast<luapulse **>(luaL_checkudata(L, 1, LUA_PULSE)))
      ->setVolume(luaL_checkstring(L, 2), luaL_checknumber(L, 3),
                  luaL_checknumber(L, 4));
  return 0;
}

static int luapulse_setMicVolume(lua_State *L) {
  (*reinterpret_cast<luapulse **>(luaL_checkudata(L, 1, LUA_PULSE)))
      ->setMicVolume(luaL_checkstring(L, 2), luaL_checknumber(L, 3),
                     luaL_checknumber(L, 4));
  return 0;
}

static int luapulse_muteSink(lua_State *L) {
  (*reinterpret_cast<luapulse **>(luaL_checkudata(L, 1, LUA_PULSE)))
      ->muteSink(luaL_checkstring(L, 2), lua_toboolean(L, 3));
  return 0;
}

static int luapulse_muteSource(lua_State *L) {
  (*reinterpret_cast<luapulse **>(luaL_checkudata(L, 1, LUA_PULSE)))
      ->muteSource(luaL_checkstring(L, 2),lua_toboolean(L, 3));
  return 0;
}

static int luapulse_run(lua_State *L) {
  (*reinterpret_cast<luapulse **>(luaL_checkudata(L, 1, LUA_PULSE)))->run();
  return 0;
}

// Register luapulse in lua
static void register_myobject(lua_State *L) {
  static const luaL_Reg meta[] = {
      {"__gc", luapulse_delete},
      {NULL, NULL},
  };
  static const luaL_Reg funcs[] = {
      {"setVolume", luapulse_setVolume},
      {"setMicVolume", luapulse_setMicVolume},
      {"muteSink", luapulse_muteSink},
      {"muteSource", luapulse_muteSource},
      {"setDefaultSink", luapulse_setDefaultSink},
      {"setDefaultSource", luapulse_setDefaultSource},
      {"run", luapulse_run},
      {NULL, NULL},
  };
  luaL_newmetatable(L, LUA_PULSE);
  luaL_setfuncs(L, meta, 0);
  luaL_newlib(L, funcs);
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1);

  lua_pushcfunction(L, luapulse_new);
}

// Register Lua Functions
extern "C" int luaopen_libluapulse(lua_State *L) {
  luaL_openlibs(L);
  register_myobject(L);
  return 1;
}
