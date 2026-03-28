# Ashet Home Computer Mainboard

## Overview

- RP2350B as main CPU
- RP2350B as a debug probe
- Two 16 MiB flash chips
- 12 MHz Crystal for debug probe
- 4-port USB 1.1 HUB
- 10/100 Base-T/TX ethernet through ENC424J600
- 8 MB PSRAM (APS6404L-SQH-SN)
- 1.8V LDO for QSPI_IOVDD / PSRAM / Flash Chips

## Design Notes

- Attach debug probe to global I²S bus for both sniffing and controlling the system
- Debug probe must be able to reset the main CPU
- Debug probe can additionally drive global CLOCK_48MHZ so we can run the mainboard standalone without backplane
- Drive main CPU from CLOCK_48MHZ
- Drive debug probe through dedicated crystal
- Evaluate if debug probe can trigger the main cpu "boot over serial"
- Attach debug probe to main cpu flash directly
- Main CPU cannot be programmed through USB/UF2, but only through the debug probe
  - This must be as convenient as possible
