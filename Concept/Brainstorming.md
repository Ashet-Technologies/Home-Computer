# Brainstorming

## Global Clock Source

Original Idea: Spread 16 MHz

Required Frequencies:

- 48 MHz for USB 1.1
- 26.136 .. 29.5 MHz RGB Signal (800x480 @ 60 Hz)
- 4.43 MHz PAL Signal
- 150 MHz RP2350
- 300 MHz Propeller 2
- 48 kHz Audio Sample Rate
- 1.536 MHz Audio Bit Rate

No oscillator with 16 MHz on DigiKey

Multiplier Table:

| Frequency | 8 MHz   |
|-----------|---------|
| 48 kHz    | 0.006   |
| 1.536 MHz | 0.192   |
| 4.43 MHz  | 0.55375 |
| 29.5 MHz  | 3.6875  |
| 48 MHz    | 6       |
| 150 MHz   | 18.75   |
| 300 MHz   | 37.5    |

## Expansion Required Parts

