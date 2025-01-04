const std = @import("std");

const args_parser = @import("args");
const serial_utils = @import("serial");

const p2_ram = 512 * 1024;
const p2_version = "Prop_Ver G";

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var cli = args_parser.parseForCurrentProcess(CliArgs, allocator, .print) catch return 1;
    defer cli.deinit();

    if (cli.positionals.len != 1) {
        std.log.err("requires exactly one positional file!", .{});
        return 1;
    }

    const load_file_path = cli.positionals[0];
    var load_file_buffer: [p2_ram + 4]u8 = undefined;

    const load_file = try std.fs.cwd().readFile(load_file_path, &load_file_buffer);
    std.debug.assert(load_file.len <= p2_ram);

    if ((load_file.len % 4) != 0) {
        std.log.err("{} is not loadable: length not divisible by 4!", .{
            std.zig.fmtEscapes(load_file_path),
        });
        return 1;
    }

    if (load_file.len == 0) {
        std.log.warn("{} is empty!", .{
            std.zig.fmtEscapes(load_file_path),
        });
    }

    const checksum: u32 = blk: {
        var cs: u32 = 0x706F7250; // "Prop"
        for (std.mem.bytesAsSlice(u32, load_file)) |item| {
            const word = std.mem.littleToNative(u32, item);
            cs -%= word;
        }
        break :blk cs;
    };
    std.log.debug("file checksum is 0x{X:0>8}", .{checksum});

    // append checksum to buffer:
    const checksummed_file: []const u8 = blk: {
        var data = load_file;
        const end = data.len;
        data.len += 4;
        std.mem.writeInt(u32, data[end..][0..4], checksum, .little);
        break :blk data;
    };

    var port = try std.fs.cwd().openFile(cli.options.port, .{ .mode = .read_write });
    defer port.close();

    try serial_utils.configureSerialPort(port, .{
        .baud_rate = 115200,
        .parity = .none,
        .stop_bits = .one,
        .word_size = .eight,
    });

    std.debug.print("resetting...\n", .{});
    try serial_utils.changeControlPins(port, .{
        .dtr = true,
    });
    std.time.sleep(5 * std.time.ns_per_ms);
    try serial_utils.changeControlPins(port, .{
        .dtr = false,
    });
    std.time.sleep(20 * std.time.ns_per_ms);

    // baud rate detection:
    std.log.info("check version...", .{});
    try port.writeAll("> ");

    // version check:
    {
        var magic_buf: [256]u8 = undefined;

        try port.writeAll("Prop_Chk 0 0 0 0\r");

        // response will be [ CR, LF, "Prop_Ver G", CR, LF]
        const reader = port.reader();

        try reader.skipUntilDelimiterOrEof('\n');

        var fbs = std.io.fixedBufferStream(&magic_buf);

        try reader.streamUntilDelimiter(fbs.writer(), '\n', null);

        const magic = std.mem.trim(u8, fbs.getWritten(), " \r\n");

        if (!std.mem.eql(u8, magic, p2_version)) {
            std.log.warn("Device identifies as '{}', but epxected '{}'", .{
                std.zig.fmtEscapes(magic),
                std.zig.fmtEscapes(p2_version),
            });
        }
    }

    std.log.info("load code...", .{});

    {
        var b64_buffer: [std.base64.standard.Encoder.calcSize(load_file_buffer.len)]u8 = undefined;

        const b64_data = std.base64.standard.Encoder.encode(&b64_buffer, checksummed_file);

        try port.writeAll("Prop_Txt 0 0 0 0 ");
        try port.writeAll(b64_data);
        try port.writeAll(" ?\r");

        const response = try port.reader().readByte();
        switch (response) {
            '.' => {},
            '!' => {
                std.log.err("invalid checksum!", .{});
                return 1;
            },
            else => {
                std.log.err("unexpected response from Prop_Txt: 0x{X:0>8}!", .{response});
                return 1;
            },
        }
    }

    std.log.info("code fully loaded.", .{});

    while (true) {
        var buffer: [64]u8 = undefined;
        const len = try port.read(&buffer);
        std.debug.print("{}\n", .{
            std.zig.fmtEscapes(buffer[0..len]),
        });
    }

    return 0;
}

const CliArgs = struct {
    help: bool = false,
    port: []const u8 = "/dev/ttyUSB0",

    pub const shorthands = .{
        .h = "help",
        .P = "port",
    };
};
