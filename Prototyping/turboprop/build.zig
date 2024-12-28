const std = @import("std");

pub fn build(b:* std.Build) void 
{
    const serial_dep = b.dependency("serial", .{});
    const args_dep = b.dependency("zig-args", .{});

    const serial_mod = serial_dep.module("serial");
    const args_mod = args_dep.module("args");

    const exe = b.addExecutable(.{
        .name = "turboprop",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
    });

    exe.root_module.addImport("serial", serial_mod);
    exe.root_module.addImport("args", args_mod);

    b.installArtifact(exe);
}