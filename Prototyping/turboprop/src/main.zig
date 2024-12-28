const std = @import("std");

const args_parser = @import("args");
const serial_utils = @import("serial");

pub fn main() !u8 
{   
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var cli =  args_parser.parseForCurrentProcess(CliArgs, allocator, .print) catch return 1;
    defer cli.deinit();

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

    // baud rate detection
    std.debug.print("init...\n", .{});
    try port.writeAll("> ");

    try port.writeAll("Prop_Chk 0 0 0 0\r");

    std.time.sleep(100 * std.time.ns_per_ms);

    try port.writeAll("Prop_Txt 0 0 0 0 BICA/wD2Z/0f9if0H/on9AAG3Pzw+oL/HwBm/R/65/Q= ~\r");

    while(true)
    {
        var buffer: [64]u8 = undefined;
        const len = try port.read(&buffer);
        std.debug.print("{}\n", .{
            std.zig.fmtEscapes(buffer[0..len]),
        });
    }

    return 0;
}

const CliArgs  =struct {
    help: bool = false,
    port: []const u8 = "/dev/ttyUSB0",

    pub const shorthands = .{
        .h = "help",
        .P = "port",
    };
};