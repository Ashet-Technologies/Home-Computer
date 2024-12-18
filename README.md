# Ashet Home Computer Mk4

### _The 21st century home computer_

| Project Status             |
|----------------------------|
| ⚠️ **WORK IN PROGRESS** ⚠️ |

## Introduction

The Ashet Home Computer is the attempt to recreate the home computer experience from the 80ies in the current days.

Modern computers are so complex nobody can understand them anymore. They are incredibly powerful and useful, but the user can't get as close to their machine as it was possible in the past. Even single-board computers like the RaspberryPi are so complex from their hardware and software architecture that they are hard to grasp for beginners, and even advanced users.

This home computer attempts to give you the best of both worlds:

- Interfaces with the modern world
- Simple enough to be understood by a single person

## Features

The computer follows a modular design similar to a PC where you have expansion cards that you can plug into the system.

### Core Features

These features are available no matter what expansion cards you have installed.

- RP2350 Core
  - Dual-Core System
  - Each Core Might Be
    - Arm CPU (Cortex-M33, 150 MHz)
    - RISC-V CPU (Cortex-M33, 150 MHz)
- 8 MB RAM
- 16 MB Flash
- USB 1.1 Host
- 10/100 Mbps Ethernet
- Battery-Backed Real-Time Clock
- Status Display (128x64, monochrome)
- Integrated Debug Probe
- 7 Expansion Slots
  - 1 Video Expansion Slot
  - 1 Audio Expansion Slot
  - 5 Generic Expansion Slots

### Standard Expansions

The following expansion cards are the stock expansion cards which come with a default-assembled Ashet Home Computer:

1. Framebuffer Video Card
    - DVI Video Out (800x480, 60 Hz)
2. Stereo Sound Card
    - PCM Audio Out (48 kHz, 16 bit)
    - PCM Audio In (48 kHz, 16 bit)
3. USB Card
    - 4 USB 1.1 Host Ports
4. RS232 Card
    - TTL UART (3.3V, 5V, ±12V)
5. Basic I/O Card
    - Pin Header Connector
    - 8 GPIOs
    - Dedicated I²C
    - 5V and 3.3V power supply available
6. Commodore Connectivity Card
    - 2× C64 Serial
7. User Expansion Card
    - Minimal Expansion Card
    - Perfboard For Custom Expansions
    - Pin Header Connector
    - SUB DE9 Connector

### Other Expansions

There are many more ideas that can be realized with expansion cards.

Take a peek at our [List of Expansion Board Ideas](Concept/Expansion%20Boards.md) or check out the [Expansion Card Interface Specification](Specs/Expansion%20Bus.md) how to create your own.

## Architecture

### Block Diagram

![Block Diagram](Concept/Block%20Diagram%20Gen2.svg)

## Glossary

<dl>
  <dt>Mainboard</dt>
  <dd>The Mainboard houses the cpu core and everything necessary to run the system, even without <em>Expansion Boards</em> or the <em>Backplane</em>.</dd>

  <dt>Backplane</dt>
  <dd>The Backplane is the interconnect between the <em>Mainboard</em> and <em>Expansion Boards</em>. This board also contains the <em>I/O Southbridge</em></dd>

  <dt>Expansion Board</dt>
  <dd>Expansion Boards provide more capabilities to the computer. They usually add more I/O features, but could also house any other kind of electronics that want to interface with the <em>Mainboard</em>.</dd>

  <dt>Video Expansion Board</dt>
  <dd>A Video Expansion Board is a special expansion that is only installable in a single socket of the <em>Backplane</em>. In addition to the generic <em>Expansion Board</em> interface, it has an additional 8 lanes of high-speed interconnect to the <em>Mainboard</em>.</dd>
  
  <dt>Audio Expansion</dt>
  <dd>An Audio Expansion Board is a special expansion that is only installable in a single socket of the <em>Backplane</em>. In addition to the generic <em>Expansion Board</em> interface, it has an additional 2-lane I²S interconnect to the <em>Mainboard</em>.</dd>

  <dt>I/O Southbridge</dt>
  <dd>The I/O Southbridge provides the main interconnect between the <em>Main Board</em> and the <em>Expansion Boards</em>. It is realized by a <a href="https://www.parallax.com/propeller-2/">Propeller 2</a>.</dd>
</dl>
