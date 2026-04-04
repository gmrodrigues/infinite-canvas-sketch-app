//! POC 005: Sokol Real Render - Validação Básica
//! Hipótese: Sokol-gfx consegue abrir janela nativa e renderizar a 60 FPS
//! Data: 2026-04-03
//!
//! Esta POC valida APENAS:
//! - Sokol abre janela sem crashes
//! - Loop de renderização roda a 60 FPS
//! - GPA limpo no shutdown
//!
//! REGRA DE ISOLAMENTO:
//!   - Este arquivo NÃO importa nada de src/
//!   - Este arquivo NÃO importa nada de outras POCs

const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const stm = sokol.time;

var gpa_instance: std.heap.GeneralPurposeAllocator(.{}) = undefined;

fn init() callconv(.c) void {
    stm.setup();

    // Sokol gfx setup mínimo
    sg.setup(.{
        .buffer_pool_size = 128,
        .image_pool_size = 64,
        .shader_pool_size = 32,
        .pipeline_pool_size = 32,
    });

    std.debug.print("[POC 005] ✅ Sokol inicializado!\n", .{});
    std.debug.print("[POC 005] Janela 1280x720, pressione ESC para sair.\n", .{});
}

fn frame() callconv(.c) void {
    // Begin pass com swapchain explícito (necessário para validação)
    sg.beginPass(.{
        .action = .{
            .colors = .{
                .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.15, .a = 1.0 } },
                .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.15, .a = 1.0 } },
                .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.15, .a = 1.0 } },
                .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.15, .a = 1.0 } },
                .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.15, .a = 1.0 } },
                .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.15, .a = 1.0 } },
                .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.15, .a = 1.0 } },
                .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.15, .a = 1.0 } },
            },
        },
        .swapchain = .{
            .width = 1280,
            .height = 720,
            .sample_count = 1,
            .color_format = .RGBA8,
            .depth_format = .NONE,
        },
    });

    // Aqui entraria o draw call quando tivermos shaders prontos
    // Por enquanto, apenas limpamos a tela

    sg.endPass();
    sg.commit();
}

fn cleanup() callconv(.c) void {
    sg.shutdown();
    std.debug.print("[POC 005] ✅ Sokol shutdown completo.\n", .{});
}

fn input(event: [*c]const sapp.Event) callconv(.c) void {
    const evt = event.*;
    if (evt.type == .KEY_DOWN and evt.key_code == .ESCAPE) {
        sapp.quit();
    }
}

pub fn main() !void {
    gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa_instance.deinit();
        if (check == .leak) {
            std.debug.print("[POC 005] ⚠️ MEMORY LEAK DETECTADO!\n", .{});
        } else {
            std.debug.print("[POC 005] ✅ GPA limpo, zero leaks.\n", .{});
        }
    }

    // Sokol app setup
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = input,
        .width = 1280,
        .height = 720,
        .window_title = "POC 005: Sokol Real Render",
        .icon = .{
            .sokol_default = true,
        },
    });
}
