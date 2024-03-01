cmake_minimum_required(VERSION 3.8.2)

project(luapulse)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 17)

find_package(PkgConfig REQUIRED)
find_package(Lua REQUIRED)
pkg_search_module(GLIB REQUIRED glib-2.0)

message(STATUS "GLIB: ${GLIB_INCLUDE_DIRS}")
message(STATUS "LUA: ${LUA_INCLUDE_DIR}")
include_directories(include ${GLIB_INCLUDE_DIRS} ${LUA_INCLUDE_DIR})

add_library(luapulse SHARED src/luapulse.cpp)

message(STATUS "GLIB: ${GLIB_LDFLAGS}")
message(STATUS "LUA: ${LUA_LIBRARIES}")

target_link_libraries(luapulse PUBLIC ${LUA_LIBRARIES} ${GLIB_LDFLAGS} pulse)
