const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "sokol_spsc_pipeline",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Dependências de hardware
    exe.linkSystemLibrary("input");
    exe.linkSystemLibrary("udev");
    exe.linkLibC();

    // TODO: Adicionar Sokol se disponível. Para esta POC, focamos no SPSC + multi-threading.
    // Se Sokol não estiver no path, o main.zig rodará em modo headless/terminal.

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Executar POC: SPSC + Input Threading");
    run_step.dependOn(&run_cmd.step);
}
