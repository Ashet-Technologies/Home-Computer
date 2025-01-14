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

### Protocol

The protocol has two participants:

- Host (the RP2350)
- Device (the Southbridge)

Each participant can send messages at any time and the sequence isn't necessarily in-order and "ping pong" style.

Both parts send messages using this format:

```bfdl
struct Message
{
  type:            u8,
  length:          u8,
  payload: [length]u8,
  crc:             u16,
};
```

The `payload` contains the data for `type`, which is a direction-dependent command.

#### Host Messages

These messages are sent by the host to the device.

The following messages are allowed:

| `type` | Message Name         | Short Description                                          |
| ------ | -------------------- | ---------------------------------------------------------- |
| 0      | Write Memory         | Writes bytes into hub memory.                              |
| 1      | Read Memory          | Reads bytes from hub memory.                               |
| 2      | Start Slot           | Starts the cog for a slot.                                 |
| 3      | Stop Slot            | Stops the cog for a slot.                                  |
| 4      | Write To FIFO        | Writes to the output FIFO for a slot.                      |
| 5      | Request From FIFO    | Requests that the device sends remaining data from a FIFO. |
| 6      | Configure Input FIFO | Configures FIFO behaviour.                                 |
| 7      | Acknowledge IRQ      | Clears the IRQ flag for configured slots.                  |

##### Write Memory

```bfdl
struct Payload
{
  address: u32,
  payload: [*]u8,
};
```

##### Read Memory

```bfdl
struct Payload
{
  address: u32,
  length: u32,
};
```

##### Start Slot

```bfdl
struct Payload
{
  slot_id: u8, // 0..6
};
```

##### Stop Slot

```bfdl
struct Payload
{
  slot_id: u8, // 0..6
};
```

##### Write To FIFO

```bfdl
struct Payload
{
  fifo: u4,
  slot: u4,
  data: [*]u8,
};
```

##### Request From FIFO

```bfdl
struct Payload
{
  fifo: u4,
  slot: u4,
  max_length: u16, // Max number of bytes from FIFO
};
```

##### Configure Input FIFO

```bfdl
struct Payload
{
  fifo: u4,
  slot: u4,
  threshold: u16, // Minimum number of data bytes in FIFO before auto-flushing. 0 is disabled.
};
```

##### Acknowledge IRQ

```bfdl
struct Payload
{
  ack_mask: u8,
};
```

#### Device Messages

These messages are sent by the device to the host.

The following messages are allowed:

| `type` | Message Name   | Short Description                                            |
| ------ | -------------- | ------------------------------------------------------------ |
| 0      | Status         | Contains system status, is sent periodically and on changes. |
| 1      | Memory Content | Data from hub memory, is response to "Read Memory".          |
| 2      | Data From FIFO | Data from an in input FIFO has data.                         |
| 3      | Cog Started    | A cog has successfully started.                              |

##### Status

```bfdl
struct Payload
{
  slot_mask:          u8, // which slots are active
  irq_mask:           u8,  // which slots have IRQs pending
  fifo_cnt:           u8,  // number of non-empty FIFOs
  fifos:    [fifo_cnt]FIFO_Status,
};

struct FIFO_Status
{
  fifo: u4,
  slot: u4,
  level: u16,
};
```

##### Memory Content

```bfdl
struct Payload
{
  address:    u32,
  data:    [*]u8,
};
```

##### Data From FIFO

```bfdl
struct Payload
{
  fifo:    u4,
  slot:    u4,
  data: [*]u8,
};
```

##### Cog Started

```bfdl
struct Payload
{
  cog_id: u8,
  input_fifo_mask: u16,
  output_fifo_mask: u16,
};
```

## Memory Map

| Address Range    | Size  | Function          |
| ---------------- | ----- | ----------------- |
| `00000`..`007FF` | 2048  | Control Core Code |
| `00800`..`00FFF` | 2048  | Control Core Data |
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

### Slot RAM

Each slot RAM can be configured as 16 parts, which can be:

- RAM / Registers
- Input FIFO, which can send data to the host
- Output FIFO, which can receive data from the host

The memory map for the slot ram looks like this:

| Address Range    | Size |
| ---------------- | ---- |
| `x0000`..`x0FFF` | 4096 |
| `x1000`..`x1FFF` | 4096 |
| `x2000`..`x2FFF` | 4096 |
| `x3000`..`x3FFF` | 4096 |
| `x4000`..`x4FFF` | 4096 |
| `x5000`..`x5FFF` | 4096 |
| `x6000`..`x6FFF` | 4096 |
| `x7000`..`x7FFF` | 4096 |
| `x8000`..`x8FFF` | 4096 |
| `x9000`..`x9FFF` | 4096 |
| `xA000`..`xAFFF` | 4096 |
| `xB000`..`xBFFF` | 4096 |
| `xC000`..`xCFFF` | 4096 |
| `xD000`..`xDFFF` | 4096 |
| `xE000`..`xEFFF` | 4096 |
| `xF000`..`xFFFF` | 4096 |

There are up to 8 input and 8 output FIFOs. Each slot can be assigned one of these functions.
