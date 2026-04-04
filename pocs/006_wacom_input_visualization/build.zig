const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "poc_006_wacom_input_visualization",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addImport("sokol", dep_sokol.module("sokol"));

    // Libinput + udev
    exe.linkSystemLibrary("input");
    exe.linkSystemLibrary("udev");
    
    // X11 + GL (Sokol needs these on Linux)
    exe.linkSystemLibrary("X11");
    exe.linkSystemLibrary("Xi");
    exe.linkSystemLibrary("Xcursor");
    exe.linkSystemLibrary("GL");
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Executar POC 006");
    run_step.dependOn(&run_cmd.step);
}
