cmake_minimum_required(VERSION 3.22)

include(pico_sdk_import.cmake)

project(clockgen C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

add_compile_options(-Wall -Wextra)
add_executable(clockgen clockgen.c)

target_link_libraries(clockgen pico_stdlib pico_stdio pico_printf hardware_clocks)

pico_enable_stdio_usb(clockgen 1)

pico_add_extra_outputs(clockgen)
