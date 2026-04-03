const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "poc_micro",
        .root_source_file = .{ .path = "main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Adicione dependências externas conforme necessário.
    // NUNCA aponte para src/ do projeto principal.

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Executar a Micro POC");
    run_step.dependOn(&run_cmd.step);

    // Adicione um step de test se a POC tiver assertions de validação.
    const test_exe = b.addTest(.{
        .root_source_file = .{ .path = "main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const test_step = b.step("test", "Rodar testes da POC");
    test_step.dependOn(&b.addRunArtifact(test_exe).step);
}
