# Commodore Connectivity Expansion

The Commodore Connectivity Expansion provides two [C64 Serial](https://www.c64-wiki.com/wiki/Serial_Port) compatible DIN connectors.

Each connector is it's own dedicated bus and they are not connected internally. This way two devices can be operated independently from each other.

## Pinout

The pinout of the two DIN connectors is the same as on the C64 or other compatible devices:

| Pin | Name         | Signal direction | Remark                                                                      |
|-----|--------------|------------------|-----------------------------------------------------------------------------|
| 1   | SERIAL SRQ   | in               | Serial Service Request In, at the C128 "Fast Serial Clock"                  |
| 2   | GND          | -                | Ground, signal ground (0V)                                                  |
| 3   | SERIAL ATN   | out              | Attention, for the selection of a device at beginning/end of a transmission |
| 4   | SERIAL CLK   | in/out           | Clock (for data transmission)                                               |
| 5   | SERIAL DATA  | in/out           | Data                                                                        |
| 6   | SERIAL RESET | out(/in)         | Reset, in older VIC-20 unused                                               |

## Parts

| Function            | Manufacturer                    | Part Number    | Distributors                                                                                         |
|---------------------|---------------------------------|----------------|------------------------------------------------------------------------------------------------------|
| DIN 45322 Connector | CLIFF Electronic Components Ltd | FM6726         | [DigiKey](https://www.digikey.de/de/products/detail/cliff-electronic-components-ltd/FM6726/21676225) |
| 16 bit I/O Expander | Microchip Technology            | MCP23S17T-E/SO | [DigiKey](https://www.digikey.de/de/products/detail/microchip-technology/MCP23S17T-E-SO/964187)      |
