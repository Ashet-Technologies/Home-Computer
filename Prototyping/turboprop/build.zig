const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSafe });
    const target = b.standardTargetOptions(.{});

    const serial_dep = b.dependency("serial", .{});
    const args_dep = b.dependency("zig-args", .{});
    const spin2cpp_dep = b.dependency("spin2cpp", .{});

    const serial_mod = serial_dep.module("serial");
    const args_mod = args_dep.module("args");

    // turboprop loader:
    {
        const exe = b.addExecutable(.{
            .name = "turboprop",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        exe.root_module.addImport("serial", serial_mod);
        exe.root_module.addImport("args", args_mod);

        b.installArtifact(exe);
    }

    // flexspin compiler
    const flexspin_exe = blk: {
        const flexspin_compile = b.addSystemCommand(&.{
            "make",
        });

        flexspin_compile.addArg("-C");
        flexspin_compile.addDirectoryArg(spin2cpp_dep.path("."));

        flexspin_compile.addArg(b.fmt("CC={s} cc -target {s} -static -fno-pie", .{
            b.graph.zig_exe,
            // "x86_64-linux-musl",
            target.query.zigTriple(b.allocator) catch @panic("oom"),
        }));

        const flexspin_exe = spin2cpp_dep.path("build/flexspin");

        const install_file = b.addInstallFileWithDir(
            flexspin_exe,
            .bin,
            "flexspin",
        );

        install_file.step.dependOn(&flexspin_compile.step);

        b.getInstallStep().dependOn(&install_file.step);

        break :blk flexspin_exe;
    };

    // Blinky
    {
        const compile_blinky = std.Build.Step.Run.create(b, "Compile Blinky");

        compile_blinky.addFileArg(flexspin_exe);

        compile_blinky.addArg("-2");
        compile_blinky.addArg("-b");
        compile_blinky.addArg("-Wall");

        compile_blinky.addArg("-o");
        const blinky_bin = compile_blinky.addOutputFileArg("blinky.bin");

        compile_blinky.addFileArg(b.path("src/blinky.pasm"));

        const install_blinky_bin = b.addInstallFileWithDir(
            blinky_bin,
            .{ .custom = "firmware" },
            "blinky.bin",
        );

        b.getInstallStep().dependOn(&install_blinky_bin.step);
    }
}
