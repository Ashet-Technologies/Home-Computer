# Ashet Express Gen1

## Pinout

| Name  | Function                   | Direction  | Freq Limit |
| ----- | -------------------------- | ---------- | ---------- |
| DSD0  | Downstream Data, Channel 0 | Downstream | 75 MHz     |
| DSD1  | Downstream Data, Channel 1 | Downstream | 75 MHz     |
| DSFE  | Downstream Frame Enable    | Downstream | 7.5 MHZ    |
| USD0  | Upstream Data, Channel 0   | Upstream   | 75 MHz     |
| USD1  | Upstream Data, Channel 1   | Upstream   | 75 MHz     |
| USFE  | Upstream Frame Enable      | Upstream   | 7.5 MHZ    |
|       |                            |            |            |
|       |                            |            |            |
| DSRES | Downsteam Reset            |            |            |

## Core Utilization

| Cog ID | Usage                             | Code Memory Range | Config Memory Range | Data Memory Range |
| ------ | --------------------------------- | ----------------- | ------------------- | ----------------- |
| 0      | Expansion Slot 0 Conntroller      | `0x`…`0x`         | `0x`…`0x`           | `0x`…`0x`         |
| 1      | Expansion Slot 1 Controller       | `0x`…`0x`         | `0x`…`0x`           | `0x`…`0x`         |
| 2      | Expansion Slot 2 Controller       | `0x`…`0x`         | `0x`…`0x`           | `0x`…`0x`         |
| 3      | Expansion Slot 3 Controller       | `0x`…`0x`         | `0x`…`0x`           | `0x`…`0x`         |
| 4      | Expansion Slot 4 Controller       | `0x`…`0x`         | `0x`…`0x`           | `0x`…`0x`         |
| 5      | Expansion Slot 5 Controller       | `0x`…`0x`         | `0x`…`0x`           | `0x`…`0x`         |
| 6      | Expansion Slot 6 Controller       | `0x`…`0x`         | `0x`…`0x`           | `0x`…`0x`         |
| 7      | Upstream Communication Controller | `0x`…`0x`         | `0x`…`0x`           | `0x`…`0x`         |

## Memory Layout

> TODO: Implement the nextgen packet fifo layout

### Packet Stream Configuration

```zig
/// Configuration of a single packet stream.
///
/// NOTE: All fields except `wptr` and `rptr` are static.
const StreamConfig = extern struct {
    // these four fields can be fetched in one memory access
    wptr: u8, // Index of next element in PacketRing to write. Only written by producer.
    rptr: u8, // Index of next element in PacketRing to read, read possible when wptr != rptr. Only written by consumer.
    _padding: u8 = 0,
    flags: packed struct(u8) {
        _padding: u7 = 0,
        enabled: bool, // if `true`, will set the "carry" bit of the first config u32, and is trivial to check in code then
    },

    // these can be fetched with one memory access:
    ring_base: u16, // pointer to the first byte of the *data ring buffer* in memory
    ring_limit: u16, // length of *data ring buffer* minus one. allows efficient use of INCMOD wraparound for address counting.
};

/// A packet descriptor.
///
/// NOTE: The data may wrap around in memory according to `StreamConfig.ring_base` and `StreamConfig.ring_limit`.
const Packet = packed struct(u32) {
    offset: u16, // where in memory is the packet start
    length: u16, // how long is the packet in bytes?
};

/// A ring buffer of packet slices.
const PacketRing = [32]Packet;

/// Stores the configurations of the packet streams.
const StreamConfigs = extern struct {
    downstream: [4]StreamConfig,
    upstream: [4]StreamConfig,
};

/// Stores the packet ring buffers for each of the 8 streams.
const RingStorage = extern struct {
    downstream: [4]PacketRing,
    upstream: [4]PacketRing,
};

/// NOTE: Located at `CONFIG BASE + 0x000`
const ConfigBlock = extern struct {
    configs: StreamConfigs align(1024), // NOTE: Located at `CONFIG BASE + 0x000`
    storage: RingStorage align(1024), // NOTE: Located at `CONFIG BASE + 0x400`
};
```
