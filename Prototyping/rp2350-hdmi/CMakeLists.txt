cmake_minimum_required(VERSION 3.13...3.27)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# note: this must happen before project()
include(../vendor/pico-sdk/pico_sdk_init.cmake)

project(rp2350_hdmi_setup CXX C ASM)

# initialize the Raspberry Pi Pico SDK
pico_sdk_init()

add_executable(rp2350_hdmi
    src/main.c
)

target_link_libraries(rp2350_hdmi
    pico_stdlib
    pico_multicore
    hardware_dma
    pico_sync
)

pico_enable_stdio_usb(rp2350_hdmi ENABLED)
pico_enable_stdio_uart(rp2350_hdmi ENABLED)

pico_add_extra_outputs(rp2350_hdmi)
