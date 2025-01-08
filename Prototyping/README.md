# Prototyping

## Setup

- [RP2350 Stamp XL](https://www.solder.party/docs/rp2350-stamp-xl/)
- [RP2xxx Stamp Carrier XL](https://www.solder.party/docs/rp2xxx-stamp-carrier-xl/)
- [Propeller 2 Evaluation Board](https://www.parallax.com/product/propeller-2-evaluation-board-rev-c/)

## Goals

- Get setup ready for RP2350 + PSRAM
  - Evaluate RAM performance
  - => <https://github.com/earlephilhower/arduino-pico/blob/master/cores/rp2040/psram.cpp>
- Provide porting target for Ashet OS
- Evaluate design concepts
  - Backplane
    - Host Communication
    - Module Hotplug / Init
    - Driver System
- Video Output Architecture
  - Figure out timing configuration
  - Is it necessary to use internal SRAM as framebuffer?
  - HDMI Bitbang Viability
  - How to do palettized video instead of RGB232
- Evaluate Ethernet Chip
  - Figure out basic driver
  - Figure out throughput
    - Parallel Port
    - SPI Port
  - Select ENC424J600 or ENC624J600
- Evaluate USB Space
  - Decide if we should use TinyUSB or not
  - Prototype for USB Host Support
    - Keyboard Input
    - Mouse Input
    - Mass Storage Read/Write
- Prototype Drivers
  - I²C RTC
  - SSD1306 Display
- Audio Interface
  - Set up basic drivers for I²S input and output
  - Figure out OS API
  - Figure out realtime requirements
- Create I/O Card Schematics + Prototypes
  - Stereo Sound Card
  - RS232 Card
  - Commodore Connectivity Card
- Test rendering and input latency for a simple UI system
