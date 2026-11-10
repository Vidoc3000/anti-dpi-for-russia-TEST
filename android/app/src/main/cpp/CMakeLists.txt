cmake_minimum_required(VERSION 3.22.1)
project(antidpi_native C)

file(GLOB BYEDPI_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/byedpi/*.c")
list(REMOVE_ITEM BYEDPI_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/byedpi/win_service.c")

add_library(antidpi_native SHARED ${BYEDPI_SOURCES} byedpi-jni.c)
target_include_directories(antidpi_native PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/byedpi")
target_compile_definitions(antidpi_native PRIVATE ANDROID_APP)
target_compile_options(antidpi_native PRIVATE
    -std=c99 -O2 -Wall -Wextra -Wno-unused -Wno-unused-parameter -pedantic)
target_link_libraries(antidpi_native PRIVATE android log dl)
target_link_options(antidpi_native PRIVATE "-Wl,--wrap=daemon")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,max-page-size=16384")
