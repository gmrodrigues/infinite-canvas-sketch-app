const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "poc_macro",
        .root_source_file = .{ .path = "main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Adicione dependências externas conforme necessário.
    // NUNCA aponte para src/ do projeto principal.
    //
    // Exemplo: Sokol
    // const sokol_dep = b.dependency("sokol", .{ .target = target, .optimize = optimize });
    // exe.root_module.addImport("sokol", sokol_dep.module("sokol"));
    //
    // Exemplo: libinput (sistema)
    // exe.linkSystemLibrary("input");
    // exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Executar a Macro POC");
    run_step.dependOn(&run_cmd.step);

    // Tests de integração internos à POC
    const test_exe = b.addTest(.{
        .root_source_file = .{ .path = "main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const test_step = b.step("test", "Rodar testes da Macro POC");
    test_step.dependOn(&b.addRunArtifact(test_exe).step);
}
