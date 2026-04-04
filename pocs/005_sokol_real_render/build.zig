const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "poc_005_sokol_real_render",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Sokol-gfx via sokol-zig (floooh)
    const sokol_dep = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("sokol", sokol_dep.module("sokol"));

    // Sokol já linka as bibliotecas necessárias
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Executar POC 005: Sokol Real Render");
    run_step.dependOn(&run_cmd.step);
}
