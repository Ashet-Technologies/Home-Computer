# RP2350 Pin Assignments

| Pin | Function | Target               |
|-–---|----------|----------------------|
|  0  | UART 0   | Debug UART           |
|  1  | UART 0   | Debug UART           |
|  2  | I²C 1    | OnBoard I²C          |
|  3  | I²C 1    | OnBoard I²C          |
|  4  | UART 1   | UART COM 1           |
|  5  | UART 1   | UART COM 1           |
|  6  | PIO 1    | UART COM 2           |
|  7  | PIO 1    | UART COM 2           |
|  8  | GPIO     | PSRAM                |
|  9  | GPIO     | OnBoard SPI CS       |
| 10  | GPIO     | OnBoard SPI CS       |
| 11  | GPIO     | OnBoard SPI CS       |
| 12  | HSTX     | Video Output         |
| 13  | HSTX     | Video Output         |
| 14  | HSTX     | Video Output         |
| 15  | HSTX     | Video Output         |
| 16  | HSTX     | Video Output         |
| 17  | HSTX     | Video Output         |
| 18  | HSTX     | Video Output         |
| 19  | HSTX     | Video Output         |
| 20  | PIO 2    | I²S Audio Interface  |
| 21  | PIO 2    | I²S Audio Interface  |
| 22  | PIO 2    | I²S Audio Interface  |
| 23  | PIO 2    | I²S Audio Interface  |
| 24  | PIO 2    | I²S Audio Interface  |
| 25  | CLKOUT 3 | I²S Audio Interface  |
| 26  | SPI 1    | OnBoard SPI          |
| 27  | SPI 1    | OnBoard SPI          |
| 28  | SPI 1    | OnBoard SPI          |
| 29  | PIO 0    | Ethernet             |
| 30  | PIO 0    | Ethernet             |
| 31  | PIO 0    | Ethernet             |
| 32  | PIO 0    | Ethernet             |
| 33  | PIO 0    | Ethernet             |
| 34  | PIO 0    | Ethernet             |
| 35  | PIO 0    | Ethernet             |
| 36  | PIO 0    | Ethernet             |
| 37  | PIO 0    | Ethernet             |
| 38  | PIO 0    | Ethernet             |
| 39  | PIO 0    | Ethernet             |
| 40  | PIO 0    | Ethernet             |
| 41  | PIO 0    | Ethernet             |
| 42  | PIO 0    | Ethernet             |
| 43  | PIO 0    | Ethernet             |
| 44  | PIO 0    | Ethernet             |
| 45  | PIO 0    | Ethernet             |
| 46  | PIO 0    | Ethernet             |
| 47  | PIO 0    | Ethernet             |
| D+  | USB      | USB Host             |
| D-  | USB      | USB Host             |

## Pin Consumers

### PSRAM

Total Pins: 1

- CS2

### UART {Debug,COM1,COM2}

Total Pins: 2

- RXD
- TXD

### OnBoard I²S

Total Pins: 2

- SCL
- SDA

### OnBoard SPI

Total Pins: 3 + n

- SCK
- TX
- RX
- CS0 … CSn

### Video Interface

Total Pins: 8

Chosen Mode: DVI

- 8 HSTX Pins

### I²S Audio DAC + ADC

Total Pins: 6

- MCLK
- LRCK
- BCLK
- DATA OUT
- DATA IN

### ENJ624L600

Selected Interface: PSP Mode 5

Total Pins: 19

- AL
- CS
- RD
- WR
- AD0…AD14
