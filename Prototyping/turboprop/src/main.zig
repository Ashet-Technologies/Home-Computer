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

    // Validate CLI args:

    if (cli.options.help) {
        try args_parser.printHelp(CliArgs, cli.executable_name orelse "turboprop", std.io.getStdOut().writer());
        return 0;
    }

    if (cli.options.exec == .default and cli.positionals.len == 0) {
        std.log.err("A path to a binary file is required!", .{});
        return 1;
    }

    const maybe_load_file_path: ?[]const u8, const chainloader_argv: []const []const u8 = if (cli.options.exec == .default)
        .{ cli.positionals[0], cli.positionals[1..] }
    else
        .{ null, cli.positionals };

    if (cli.options.monitor and chainloader_argv.len > 0) {
        std.log.err("monitor and sub-command execution contradict each other!", .{});
        return 1;
    }

    // Load an application file if possible

    var load_file_buffer: [p2_ram + 4]u8 = undefined;
    const checksummed_file: []const u8 = if (maybe_load_file_path) |load_file_path| cs_file: {
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

        break :cs_file checksummed_file;
    } else "";

    // Open and configure serial port:

    var port = try std.fs.cwd().openFile(cli.options.port, .{ .mode = .read_write });
    defer port.close();

    try serial_utils.configureSerialPort(port, .{
        .baud_rate = cli.options.baudrate,
        .parity = .none,
        .stop_bits = .one,
        .word_size = .eight,
    });

    // Reset device if necessary:

    if (cli.options.reset != .none) {
        std.debug.print("resetting...\n", .{});
        try serial_utils.changeControlPins(port, .{
            .dtr = optional_value(cli.options.reset == .dtr, true),
            .rts = optional_value(cli.options.reset == .rts, true),
        });
        std.time.sleep(5 * std.time.ns_per_ms);
        try serial_utils.changeControlPins(port, .{
            .dtr = optional_value(cli.options.reset == .dtr, false),
            .rts = optional_value(cli.options.reset == .rts, false),
        });
        std.time.sleep(20 * std.time.ns_per_ms);
    }

    // perform auto-baud configuration:
    try port.writeAll("> ");

    // version check:
    if (!cli.options.@"no-version-check") {
        std.log.info("check version...", .{});
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

    switch (cli.options.exec) {
        .default => {
            std.log.info("load code...", .{});

            var b64_buffer: [std.base64.standard.Encoder.calcSize(load_file_buffer.len)]u8 = undefined;
            const b64_data = std.base64.standard.Encoder.encode(&b64_buffer, checksummed_file);

            const chunk_size: usize = cli.options.@"chunk-size";

            try port.writeAll("Prop_Txt 0 0 0 0 ");
            {
                var rest: []const u8 = b64_data;
                while (rest.len > 0) {
                    const chunk = rest[0..@min(rest.len, chunk_size)];

                    try port.writeAll(chunk);

                    rest = rest[chunk.len..];

                    if (rest.len > 0) {
                        // Resynchronize after each transferred chunk:
                        try port.writeAll("\r> ");
                    }
                }
            }

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

            std.log.info("code fully loaded.", .{});
        },

        .monitor => {
            std.log.info("starting monitor...", .{});
            try port.writeAll(&.{std.ascii.control_code.eot}); // "Ctrl-D" starts the monitor
        },

        .taqoz => {
            std.log.info("starting taqoz...", .{});
            try port.writeAll(&.{std.ascii.control_code.esc}); // "ESC" starts the monitor
        },
    }

    if (chainloader_argv.len > 0) {
        @panic("subcommand execution is not supported yet!");
    }

    if (cli.options.monitor) {
        while (true) {
            var buffer: [64]u8 = undefined;
            const len = try port.read(&buffer);
            std.debug.print("{}\n", .{
                std.zig.fmtEscapes(buffer[0..len]),
            });
        }
    }

    return 0;
}

const CliArgs = struct {
    help: bool = false,

    monitor: bool = false,

    port: []const u8 = "/dev/ttyUSB0",
    baudrate: u32 = 115200,

    reset: ResetKind = .dtr,
    exec: ExecMode = .default,
    @"chunk-size": usize = 32,

    @"no-version-check": bool = false,

    pub const shorthands = .{
        .h = "help",
        .P = "port",
        .m = "monitor",
        .b = "baudrate",
    };

    pub const meta = .{
        .usage_summary = "summary",

        .full_text = "full",

        .option_docs = .{
            .help = "Prints this help",
            .port = "Selects which serial port is used.",
            .monitor = "If enabled, will start a simple monitor which prints what is sent over the serial port.",
            .@"chunk-size" = "Defines the size of ",
            .reset = "Selects how to reset the device before starting",
            .baudrate = "Selects the baud rate used for loading",
            .@"no-version-check" = "Disables checking if the device is actually the expected Propeller 2",
            .exec = "Sets what should be started by turboprop.",
        },
    };
};

const ResetKind = enum {
    none,
    dtr,
    rts,
};

const ExecMode = enum {
    default,
    monitor,
    taqoz,
};

fn optional_value(enabled: bool, value: anytype) ?@TypeOf(value) {
    return if (enabled)
        value
    else
        null;
}
