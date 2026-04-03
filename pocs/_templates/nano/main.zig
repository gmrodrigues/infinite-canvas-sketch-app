//! POC: [Nome da POC]
//! Hipótese: [O que você espera que aconteça]
//! Data: YYYY-MM-DD
//!
//! REGRA DE ISOLAMENTO:
//!   - Este arquivo NÃO importa nada de src/
//!   - Este arquivo NÃO importa nada de outras POCs
//!   - Execute com: zig build run  (dentro deste diretório)

const std = @import("std");

pub fn main() !void {
    // ---- SETUP ----
    // Configure o mínimo necessário para testar a hipótese.
    // Use std.heap.page_allocator ou std.testing.allocator conforme necessário.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    _ = allocator; // remova se não usar

    // ---- HIPÓTESE ----
    // Execute o comportamento que quer validar.

    // ---- RESULTADO ----
    // Documente o que foi observado.
    std.debug.print("POC: [Nome] — Resultado: ...\n", .{});
}
