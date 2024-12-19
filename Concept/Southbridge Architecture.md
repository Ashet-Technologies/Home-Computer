# Southbridge Architecture

## tl;dr

- Propeller2 based
- Support for 7 expansion slots
  - 1 cog per slot
  - 64k RAM per slot
- 1 cog upstream
- 64k management ram + code

## Interface

| Interface Pin | Propeller Pin | Name   | Direction  | Function                                  | Alt. Function |
|--------------:|---------------|--------|------------|-------------------------------------------|---------------|
|             1 | 53            | D0     | Bi-di      |                                           | -             |
|             2 | 57            | D1     | Bi-di      |                                           | -             |
|             3 | 58            | D2     | Bi-di      |                                           | -             |
|             4 | 59            | D3     | Bi-di      |                                           | Forced HIGH   |
|             5 | 60            | CLK    |            |                                           | *don't care*  |
|             6 | 61            | CS     |            |                                           | *don't care*  |
|             7 | 62            |        |            |                                           | Boot RX       |
|             8 | 63            | /IRQ   | Upstream   |                                           | Boot TX       |
|             9 | RESn          | /RESET | Downstream | Resets the southbridge into initial state |               |

Upstream: Southbridge to Host CPU

Downstream: Host CPU to Southbridge

## Protocol

Required Operations:

- Setup EXP Code
- Start EXP
- Shutdown EXP
- Write to EXP Register
- Read from EXP Register
- Write to EXP FIFO
- Read from EXP FIFO
- Acknowledge EXP IRQ

## Memory Map

| Address Range    | Function             |
|------------------|----------------------|
| `00000`..`0FFFF` | Expansion Slot 1 RAM |
| `10000`..`1FFFF` | Expansion Slot 2 RAM |
| `20000`..`2FFFF` | Expansion Slot 3 RAM |
| `30000`..`3FFFF` | Expansion Slot 4 RAM |
| `40000`..`4FFFF` | Expansion Slot 5 RAM |
| `50000`..`5FFFF` | Expansion Slot 6 RAM |
| `60000`..`6FFFF` | Expansion Slot 7 RAM |
| `70000`..`7FFFF` |                      |
