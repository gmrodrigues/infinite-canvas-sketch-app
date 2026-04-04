const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "poc_006_wacom_input_visualization",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // GLFW
    exe.linkSystemLibrary("glfw3");
    
    // Libinput + udev
    exe.linkSystemLibrary("input");
    exe.linkSystemLibrary("udev");
    
    // OpenGL + X11
    exe.linkSystemLibrary("GL");
    exe.linkSystemLibrary("X11");
    exe.linkSystemLibrary("Xi");
    exe.linkSystemLibrary("Xcursor");
    exe.linkSystemLibrary("Xrandr");
    exe.linkSystemLibrary("Xxf86vm");
    exe.linkSystemLibrary("Xinerama");
    exe.linkSystemLibrary("dl");
    exe.linkSystemLibrary("pthread");
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Executar POC 006: Wacom Input Visualization");
    run_step.dependOn(&run_cmd.step);
}
