const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "poc_nano",
        .root_source_file = .{ .path = "main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Adicione aqui dependências externas se a POC precisar (ex: sokol, libinput).
    // NUNCA aponte para src/ do projeto principal.
    // Exemplo para sokol via pacote local:
    // const sokol_dep = b.dependency("sokol", .{ .target = target, .optimize = optimize });
    // exe.root_module.addImport("sokol", sokol_dep.module("sokol"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Executar a Nano POC");
    run_step.dependOn(&run_cmd.step);
}
