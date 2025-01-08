# RS232 Expansion

The RS232 expansion provides two fully equipped [RS232](https://en.wikipedia.org/wiki/RS-232) ports.

Each port has the serial lanes as well as all control signals available.

## Pinout

The pinout of the two SUB DE 9 connectors follow the RS232 standard:

| Pin | Name | Signal direction | Remark                |
|-----|------|------------------|-----------------------|
| 1   | DCD  | in               | (Data) Carrier Detect |
| 2   | RXD  | in               | Receive Data          |
| 3   | TXD  | out              | Transmit Data         |
| 4   | DTR  | out              | Data Terminal Ready   |
| 5   | GND  | -                | Signal Ground         |
| 6   | DSR  | in               | Data Set Ready        |
| 7   | RTS  | out              | Request To Send       |
| 8   | CTS  | in               | Clear To Send         |
| 9   | RI   | in               | Ring Indicator        |

## Parts

| Function                | Manufacturer           | Part Number      | Distributors                                                                                         |
|-------------------------|------------------------|------------------|------------------------------------------------------------------------------------------------------|
| RS232 Transceiver       | Texas Instruments      | MAX3243EIPWR     | [DigiKey](https://www.digikey.de/de/products/detail/texas-instruments/MAX3243EIPWR/1120503)          |
| 16 bit I/O Expander     | Microchip Technology   | MCP23S17T-E/SO   | [DigiKey](https://www.digikey.de/de/products/detail/microchip-technology/MCP23S17T-E-SO/964187)      |
| SUB DE 9 Male Connector | Assmann WSW Components | A-DS 09 A/KG-T4S | [DigiKey](https://www.digikey.de/de/products/detail/assmann-wsw-components/A-DS-09-A-KG-T4S/1241806) |
