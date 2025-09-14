# Ashet Expansion Bus

The Ashet *Expansion Bus* is the core component of the composability of the Ashet Home Computer.

## Overview

- Hot Swappable
- Power Supply
  - 12V, (up to) 2A
  - 5V, (up to) 1A
  - 3.3V, (up to) 1A
  - Overcurrent Protection
- Standard Mode I²C Bus
- 8 Programmable I/O Pins
- 8 High Speed Lanes (up to 300 MHz)
- Dual-Stream I²S Bus

## Optional Features

The Expansion Bus has several *optional* features that must not be present on each slot.

Each feature might require a certain set of signals to be present:

| Feature  | Standard Signals | Video Signals | Audio Signals |
| -------- | ---------------- | ------------- | ------------- |
| Standard | ✅                | ❌             | ❌             |
| Audio    | ✅                | ❌             | ✅             |
| Video    | ✅                | ✅             | ❌             |

## Signals

| Signal Name           | Driver    | Type                  | Function                                                                      | Frequency Limit |
| --------------------- | --------- | --------------------- | ----------------------------------------------------------------------------- | --------------- |
| *All Variants*        |           |                       |                                                                               |                 |
| `GND`                 | Backplane | Power                 | Signal Ground                                                                 |                 |
| `+3V3`                | Backplane | Power                 | 3.3 V power supply                                                            |                 |
| `+5V`                 | Backplane | Power                 | 5 V power supply                                                              |                 |
| `+12V`                | Backplane | Power                 | 12 V power supply                                                             |                 |
| `/PDET`               | Card      | Static                | Presence detection. Must be tied to ground on the expansion card              |                 |
| `SLOT_A0`...`SLOT_A3` | Backplane | Static                | Module slot index, bits 0 to 3                                                |                 |
| `/SLOT_AUDIO`         | Backplane | Static                | This signal is connected to GND if the slot has the *Audio* feature available |                 |
| `/SLOT_VIDEO`         | Backplane | Static                | This signal is connected to GND if the slot has the *Video* feature available |                 |
| `/IRQ`                | Card      | Open Collector        | Interrupt request. Card drives this to low for system notification            |                 |
| `/RESET`              | Backplane | Logic                 | Reset signal. Is driven low when the card should reset itself                 |                 |
| `CLK`                 | Backplane | Logic                 | Global 8 MHz clock for synchronization                                        | 8 MHz           |
| `I2C_SCL`             | Bi-di     | Open Collector        | Clock Lane of the System I²C Bus                                              | 100 kHz         |
| `I2C_SDA`             | Bi-di     | Open Collector        | Data Lane of the System I²C Bus                                               | 100 kHz         |
| `GP0`...`GP7`         | Bi-di     | Logic or Analog       | General-purpose I/O signals from the Southbridge                              | 150 MHz         |
| *Video Signals*       |           |                       |                                                                               |                 |
| `HSTX0`...`HSTX7`     | Backplane | Logic or Differential | Unidirectional high-speed lanes. Even/odd pairs for a differential pair       | 300 MHz         |
| *Audio Signals*       |           |                       |                                                                               |                 |
| `I2S_MCLK`            | Backplane | Logic                 | Master clock of both I²S streams                                              | 25 MHz          |
| `I2S_BCLK`            | Backplane | Logic                 | Bit clock of both I²S streams                                                 | 6.5 MHz         |
| `I2S_WCLK`            | Backplane | Logic                 | Word clock of both I²S streams                                                | 192 kHz         |
| `I2S_SDIN`            | Card      | Logic                 | Data lane of the I²S input stream                                             | 6.5 MHz         |
| `I2S_SDOUT`           | Backplane | Logic                 | Data lane of the I²S output stream                                            | 6.5 MHz         |

All signals that are not power signals will use nominal voltage levels between 0.0V and 3.3V.

### Power

> TO BE DONE

### I²C

The I²C bus uses standard speed I²C and must have at least a standard EEPROM connected.

This EEPROM must have at an 8-bit memory organization with at least 8K of memory. It contains the *Module Descriptor Data* described further below.

The following addresses are reserved on the bus in addition to the specification:

| Address | Use                  |
| ------: | -------------------- |
|    0x57 | Metadata EEPROM      |
|    0x70 | Backplane I²C Switch |

All other addresses on the I²C bus are available to the expansion card and will not be occupied by the host system.

> **LORE:**
> The *Metadata EEPROM* uses the address `0x57` instead of `0x50`, as `0x50` is the default for EEPROMs and these might already be taken by other
> EEPROM systems like the [DDC](https://en.wikipedia.org/wiki/Display_Data_Channel) [EDID](https://en.wikipedia.org/wiki/Extended_Display_Identification_Data) EEPROM.

### General Purpose I/O

These signals will have a card-specific function and are driven by either the card or the southbridge on the backplane.

They can be either logic signals or analog signals, as long as they stay in the nominal voltage range.

Each expansion card will have to ship a low level driver which provides the southbridge configuration for these I/Os. See *Module Descriptor Data* for more information.

### I²S

The I²S bus has two audio streams on the signals `I2S_SDIN` and `I2S_SDOUT`.

`I2S_SDOUT` contains the left and right channel data of a stereo audio output, while `I2S_SDIN` contains the left and right channel data of a stereo capturing device.

The clock signals are shared for both audio streams and are always driven by the host system. This means that the sample rate is defined by the host and cannot be set by the card itself.

Cards that need to be in control of their sample rate might need to do audio resampling or use the *General Purpose I/O* signals.

It is only available on slots with the *Audio* signal set.

### High Speed Lanes

> TO BE DONE

The high speed lanes are only available on slots with the *Video* signal set.

## Connector

### Mechanical

The *Expansion Bus* uses a standard *PCI Express x4* connector with 64 positions.

### Pinout

|  Pin | A Side     | B Side      |
| ---: | ---------- | ----------- |
|    1 | GND        | GND         |
|    2 | +3V3       | +12V        |
|    3 | +3V3       | +12V        |
|    4 | GND        | +12V        |
|    5 | SLOT_A0    | +12V        |
|    6 | SLOT_A1    | +5V         |
|    7 | SLOT_A2    | +5V         |
|    8 | SLOT_A3    | GND         |
|    9 | I2C_SCL    | /PDET       |
|   10 | I2C_SDA    | /SLOT_AUDIO |
|   11 | /IRQ       | /SLOT_VIDEO |
|  Key | -          | -           |
|   12 | GND        | GND         |
|   13 | CLK        | HSTX0       |
|   14 | GND        | HSTX1       |
|   15 | GP0        | GND         |
|   16 | GP1        | HSTX2       |
|   17 | GP2        | HSTX3       |
|   18 | GP3        | GND         |
|   19 | GP4        | HSTX4       |
|   20 | GP5        | HSTX5       |
|   21 | GP6        | GND         |
|   22 | GP7        | HSTX6       |
|   23 | *reserved* | HSTX7       |
|   24 | *reserved* | GND         |
|   25 | *reserved* | I2S_MCLK    |
|   26 | *reserved* | GND         |
|   27 | *reserved* | I2S_BCLK    |
|   28 | *reserved* | I2S_WCLK    |
|   29 | *reserved* | GND         |
|   30 | *reserved* | I2S_SDIN    |
|   31 | /RESET     | I2S_SDOUT   |
|   32 | GND        | GND         |

## Module Descriptor Data

The Module Descriptor Data describes the expansion card and provides a low-level driver for the southbridge.

### Memory Map

The data is located at the start of the EEPROM and follows the following memory layout:

| Address Range  | Function                |
| -------------- | ----------------------- |
| `0000`..`01FF` | Metadata Block          |
| `0200`..`07FF` | *reserved*              |
| `0800`..`0FFF` | Module Card Icon        |
| `1000`..`1FFF` | Low Level Driver Binary |

### Metadata Block

The metadata block encodes generic information about the expansion card that can be processed by the host system.

| Offset | Field             | Type     | Function                                                |
| ------ | ----------------- | -------- | ------------------------------------------------------- |
| `0000` | Vendor ID         | `u32`    | Unique ID for the vendor of the expansion card          |
| `0004` | Product ID        | `u32`    | Vendor-unique ID for the expansion card                 |
| `0008` | Serial Number     | `[8]u8`  | Serial number of the expansion card. Can be zero-padded |
| `0018` |                   |          | *padding*                                               |
| `0020` | Required Features | `u8`     | Bitmask of which expansion slot features are required   |
| `0021` |                   |          | *padding*                                               |
| `0024` | Driver Interface  | `u32`    | Type of driver interface this expansion card uses       |
| `0028` |                   |          | *padding*                                               |
| `0030` | Driver Specific   | `[16]u8` |                                                         |
| `0040` |                   |          | *padding*                                               |
| `0100` | Vendor Name       | `[64]u8` | UTF-8 encoded vendor name                               |
| `0140` | Product Name      | `[64]u8` | UTF-8 encoded product name                              |
| `0180` |                   |          | *padding*                                               |

### Module Card Icon

Each module card may embed an icon so a host os can show the user a nice visual representation.

As the resolution of the host system is not known, up to three icon sizes can be embedded:

- 16x16
- 24x24
- 32x32

All icons share the same color palette, which can have up to 63 colors and a transparency key.

The icon memory block is organized as such:

| Address Range  | Function                                    |
| -------------- | ------------------------------------------- |
| `0000`..`00FF` | 8-bit pixel data for 16x16 icon             |
| `0100`..`04FF` | 8-bit pixel data for 32x32 icon             |
| `0500`..`0BFF` | 8-bit pixel data for 24x24 icon             |
| `0740`         | 16x16 icon Configuration Field              |
| `0741`         | 32x32 icon Configuration Field              |
| `0742`         | 24x24 icon Configuration Field              |
| `0743`..`07FF` | 63-entry palette with \[R,G,B] color values |

Each *Configuration Field* is a bit field with the following items:

|  Bit | Function                                               |
| ---: | ------------------------------------------------------ |
| 0..5 | Number of palette entries. Zero means icon is disabled |
| 6..7 | *reserved, must be zero*                               |

An icon is present if it has more than zero colors in its palette.

The pixel data contains row-major organized indices into the palette using 0...62 as defined by the palette table, and 63 as the transparency key. On load, the uppermost two bits may be discarded, truncating the 8-bit index to 6 bits.

### Low Level Driver

The low level driver is a Propeller 2 binary which is loaded into one of the cogs of the southbridge.

> TO BE DONE
