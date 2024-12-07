# Ashet Expansion Bus

## Core Features

- USB 1.1
- SPI with 2 Chip Select
- I²C
- Global Clock Signal
- Well-known Slot Address
- 4-bit Shared Bus
- Interrupt Signal

## Video Features

- 8 High-speed Pseudo-differential Lanes

## Audio Features

- 2 Synchronous I²S Streams

## Pin Definitions

### Core Bus

| Pin | Name  | Type   | Group      | Function                          | Frequency Limit |
|-----|-------|--------|------------|-----------------------------------|-----------------|
|     | GND   | Supply | Power      | Signal Ground                     |                 |
|     | 5V    | Supply | Power      | 5 V Supply Voltage                |                 |
|     | 3V3   | Supply | Power      | 3.3 V Supply Voltage              |                 |
|     | A0    | Static | General    | Module Address Bit 0              |                 |
|     | A1    | Static | General    | Module Address Bit 1              |                 |
|     | A2    | Static | General    | Module Address Bit 2              |                 |
|     | A3    | Static | General    | Module Address Bit 3              |                 |
|     | IRQ   | Signal | General    | Interrupt Request                 |                 |
|     | MCLK  | Signal | General    | 16 MHz Global Clock               | 16 MHz          |
|     | D+    | Signal | USB        | USB D+                            | 12 MHz          |
|     | D-    | Signal | USB        | USB D-                            | 12 MHz          |
|     | SCL   | Signal | I²C        | I²C Clock                         | 400 kHz         |
|     | SDA   | Signal | I²C        | I²C Data                          | 400 kHz         |
|     | SCK   | Signal | SPI        | SPI Clock                         | 75 MHz          |
|     | CIPO  | Signal | SPI        | SPI Controller In/Peripherial Out | 75 MHz          |
|     | COPI  | Signal | SPI        | SPI Controller Out/Peripherial In | 75 MHz          |
|     | CS0   | Signal | SPI        | SPI Chip Select 0                 | 10 MHz          |
|     | CS1   | Signal | SPI        | SPI Chip Select 1                 | 10 MHz          |
|     | GPIO0 | Signal | Shared Bus | General Purpose IO 0              |                 |
|     | GPIO1 | Signal | Shared Bus | General Purpose IO 1              |                 |
|     | SB0   | Signal | Shared Bus | Shared Bus Bit 0                  |                 |
|     | SB1   | Signal | Shared Bus | Shared Bus Bit 1                  |                 |
|     | SB2   | Signal | Shared Bus | Shared Bus Bit 2                  |                 |
|     | SB3   | Signal | Shared Bus | Shared Bus Bit 3                  |                 |

### Video Bus

| Pin | Name  | Type   | Group | Function            | Frequency Limit |
|-----|-------|--------|-------|---------------------|-----------------|
|     | HSTX0 | Signal | Video | High Speed Signal 0 | 300 MHz         |
|     | HSTX1 | Signal | Video | High Speed Signal 1 | 300 MHz         |
|     | HSTX2 | Signal | Video | High Speed Signal 2 | 300 MHz         |
|     | HSTX3 | Signal | Video | High Speed Signal 3 | 300 MHz         |
|     | HSTX4 | Signal | Video | High Speed Signal 4 | 300 MHz         |
|     | HSTX5 | Signal | Video | High Speed Signal 5 | 300 MHz         |
|     | HSTX6 | Signal | Video | High Speed Signal 6 | 300 MHz         |
|     | HSTX7 | Signal | Video | High Speed Signal 7 | 300 MHz         |

### Audio Bus

| Pin | Name  | Type   | Group | Function          | Frequency Limit |
|-----|-------|--------|-------|-------------------|-----------------|
|     | LRCLK | Signal | Audio | Word Select       | 192 kHz         |
|     | BCLK  | Signal | Audio | Serial Bit Clock  | 6.5 MHz         |
|     | SDIN  | Signal | Audio | Audio Input Data  | 6.5 MHz         |
|     | SDOUT | Signal | Audio | Audio Output Data | 6.5 MHz         |
|     | MCLK  | Signal | Audio | I²S Master Clock  | 25 MHz          |
