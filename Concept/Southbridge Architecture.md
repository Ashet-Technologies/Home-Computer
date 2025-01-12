# Southbridge Architecture

## tl;dr

- Propeller2 based
- Support for 7 expansion slots
  - 1 cog per slot
  - 64k RAM per slot
- 1 cog upstream
- 64k management ram + code

## Interface

### Physical

> TBD

### Electrical

| Interface Pin | Propeller Pin | Name   | Direction  | Idle State | Function                                                                                    | Alt. Function |
| ------------: | ------------- | ------ | ---------- | ---------- | ------------------------------------------------------------------------------------------- | ------------- |
|             1 | 53            | D0     | Bi-di      | Don't care | Data bit, L=0, H=1                                                                          | -             |
|             2 | 57            | D1     | Bi-di      | Don't care | Data bit, L=0, H=1                                                                          | -             |
|             3 | 58            | D2     | Bi-di      | Don't care | Data bit, L=0, H=1                                                                          | -             |
|             4 | 59            | D3     | Bi-di      | Don't care | Data bit, L=0, H=1                                                                          | Forced HIGH   |
|             5 | 60            | CLK    | Bi-di      | High       | The bit clock for D0, D1, D2, D3. Shift in on rising edge                                   | *don't care*  |
|             6 | 61            | EN     | Downstream | Low        | Determines if a transfer is active. On a rising edge, a new transfer is started             | *don't care*  |
|             7 | 62            | DIR    | Downstream | Low        | The direction of a transfer. H means towards Downstream, L is towards Upstream              | Boot RX       |
|             8 | 63            | /REQ   | Upstream   | High       | A falling edge will signal the upstream that an event happened and data is ready to be read | Boot TX       |
|             9 | RESn          | /RESET | Downstream | High       | Resets the southbridge into initial state                                                   |               |

Upstream: Southbridge to Host CPU

Downstream: Host CPU to Southbridge

### Logical

The protocol is transfer-oriented with each transfer being made of a sequence of octets.

A transfer is initiated by the upstream setting `DIR` to the desired state, then pulling the `EN` pin to high. The rising edge is detected on the downstream which then samples the `DIR` pin.

Depending on `DIR`, either a *write* or a *read* operation is performed. For *write* operations, the upstream is the driver for `CLK` and the data pins, on a *read* operation, the downstream drives these signals.

After the transfer setup has been done, pairs of nibbles are transferred. For each nibble, the sender will set up the data pins and pull `CLK` low, afterwards pulling `CLK` high.
The data must sampled by the receiver on the rising edge of the `CLK` signal. The first transferred nibble contains the upper 4 bit of the octet, the second one contanis the lower 4 bit.

A transfer is completed on a falling edge of `EN`. `DIR` should remain constant throughout the transfer, but only the state after the rising edge of `EN` defines the transfer direction.

The `/REQ` signal shall be pulled low by the downstream as long as it has pending outgoing requests. It must be cleared after a rising edge of `EN` when `DIR=H`, but can be enabled again as soon as `EN=L` when another transfer is ready or the previous transfer was not completed.

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

| Address Range    | Size  | Function          |
| ---------------- | ----- | ----------------- |
| `00000`..`007FF` | 2048  | Control Core Code |
| `00800`..`00FFF` | 2048  | Control Core Data                  |
| `01000`..`017FF` | 2048  | Slot 1 Code       |
| `01800`..`01FFF` | 2048  | Slot 1 Config     |
| `02000`..`027FF` | 2048  | Slot 2 Code       |
| `02800`..`02FFF` | 2048  | Slot 2 Config     |
| `03000`..`037FF` | 2048  | Slot 3 Code       |
| `03800`..`03FFF` | 2048  | Slot 3 Config     |
| `04000`..`047FF` | 2048  | Slot 4 Code       |
| `04800`..`04FFF` | 2048  | Slot 4 Config     |
| `05000`..`057FF` | 2048  | Slot 5 Code       |
| `05800`..`05FFF` | 2048  | Slot 5 Config     |
| `06000`..`067FF` | 2048  | Slot 6 Code       |
| `06800`..`06FFF` | 2048  | Slot 6 Config     |
| `07000`..`077FF` | 2048  | Slot 7 Code       |
| `07800`..`07FFF` | 2048  | Slot 7 Config     |
| `10000`..`1FFFF` | 65536 | Slot 1 RAM        |
| `20000`..`2FFFF` | 65536 | Slot 2 RAM        |
| `30000`..`3FFFF` | 65536 | Slot 3 RAM        |
| `40000`..`4FFFF` | 65536 | Slot 4 RAM        |
| `50000`..`5FFFF` | 65536 | Slot 5 RAM        |
| `60000`..`6FFFF` | 65536 | Slot 6 RAM        |
| `70000`..`7FFFF` | 65536 | Slot 7 RAM        |
