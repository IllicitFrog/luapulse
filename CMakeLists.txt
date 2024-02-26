cmake_minimum_required(VERSION 3.8.2)

project(luapulse)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 17)

find_package(PkgConfig REQUIRED)
find_package(Lua 5.4 REQUIRED)
pkg_search_module(GLIB REQUIRED glib-2.0)

include_directories(include ${GLIB_INCLUDE_DIRS} ${LUA_INCLUDE_DIR})

add_library(luapulse SHARED src/luapulse.cpp)

target_link_libraries(luapulse PUBLIC ${LUA_LIBRARIES} ${GLIB_LDFLAGS} pulse)
