const std = @import("std");

pub const PinMode = packed struct(u32) {
    zero: u1 = 0,
    smart_mode: SmartMode,
    tt: DirOutControl,
    MMMMMMMMMMMMM: u13,
    filter: InputFilter = .default,
    adj_input: InputSelector = .{ .inverted = false, .source = .pad },
    pin_input: InputSelector = .{ .inverted = false, .source = .pad },
};

pub const DirOutControl = packed union {
    dumb_logic: enum(u2) {
        out = 0b00, // OUT drives output
        other = 0b10, // OTHER drives output
    },
    dumb_dac: enum(u2) {
        use_mode_level = 0b00, // DIR enables DAC, M[7:0] sets DAC level
        use_cog_dac = 0b01, // OUT enables ADC, M[3:0] selects cog DAC channel
        out_to_bit_dac = 0b10, // OUT drives BIT_DAC
        other_to_bit_dac = 0b11, // OTHER drives BIT_DAC
    },
    smart_logic: packed struct(u2) {
        output: enum(u1) { disabled = 0, enabled = 1 },
        driver: enum(u1) { smart_out = 0, smart_other = 1 },
    },
    smart_dac: packed struct(u2) {
        output: enum(u1) { disabled = 0, enabled = 1 },
        enable: enum(u1) { out = 0, other = 1 },
    },
};

pub const SmartMode = enum(u5) {
    off = 0b00000,
};

pub const InputFilter = enum(u3) {
    default = 0b000, // A, B (default)
    @"A&B,B" = 0b001, // A AND B, B
    @"A|B,B" = 0b010, // A OR B, B
    @"A^B,B" = 0b011, // A XOR B, B
    filt0 = 0b100, // A, B, both filtered using global filt0 settings
    filt1 = 0b101, // A, B, both filtered using global filt1 settings
    filt2 = 0b110, // A, B, both filtered using global filt2 settings
    filt3 = 0b111, // A, B, both filtered using global filt3 settings
};

pub const InputSelector = packed struct(u4) {
    source: InputSource = .pad,
    inverted: bool = false,
};

pub const InputSource = enum(u3) {
    pad = 0b000, // this pin's read state (default)
    @"+1" = 0b001, // relative +1 pin's read state
    @"+2" = 0b010, // relative +2 pin's read state
    @"+3" = 0b011, // relative +3 pin's read state
    out = 0b100, // this pin's OUT bit from cogs
    @"-3" = 0b101, // relative -3 pin's read state
    @"-2" = 0b110, // relative -2 pin's read state
    @"-1" = 0b111, // relative -1 pin's read state
};
