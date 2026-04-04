const std = @import("std");
const SavitzkyGolay = @import("SavitzkyGolay.zig").SavitzkyGolay;
const BitMap = @import("BitMap.zig").BitMap;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n--- POC 003: Visual Validation ---\n", .{});

    const width = 800;
    const height = 1200;
    var bmp = try BitMap.init(width, height, allocator);
    defer bmp.deinit(allocator);

    // Filtros para X e Y
    var filter_x = SavitzkyGolay(7, f64).init(); // Janela 7 para suavização mais visível
    var filter_y = SavitzkyGolay(7, f64).init();

    var prng = std.Random.DefaultPrng.init(1234);
    const random = prng.random();

    const center_x = 400.0;
    const radius = 250.0;
    const num_points = 200;

    var last_raw_x: f64 = 0;
    var last_raw_y: f64 = 0;
    var last_smooth_x: f64 = 0;
    var last_smooth_y: f64 = 0;

    var i: usize = 0;
    while (i < num_points) : (i += 1) {
        const angle = (@as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(num_points))) * 2.0 * std.math.pi;
        
        // Círculo Ideal
        const ideal_x = center_x + @cos(angle) * radius;
        const ideal_y = 300.0 + @sin(angle) * radius; // Top Half (Raw)

        // Adicionando Ruído (Jitter de +- 10px para ser bem visível)
        const noise_x = (random.float(f64) - 0.5) * 15.0;
        const noise_y = (random.float(f64) - 0.5) * 15.0;

        const raw_x = ideal_x + noise_x;
        const raw_y = ideal_y + noise_y;

        // Desenhar no Plot superior (Raw)
        if (i > 0) {
            bmp.drawLine(last_raw_x, last_raw_y, raw_x, raw_y);
        }
        last_raw_x = raw_x;
        last_raw_y = raw_y;

        // Processar Filtro
        const smoothed_x = filter_x.process(raw_x);
        const smoothed_y = filter_y.process(raw_y);

        // Desenhar no Plot inferior (Smooth)
        if (smoothed_x != null and smoothed_y != null) {
            const sx = smoothed_x.?;
            const sy = smoothed_y.? + 600.0; // Deslocar para metade inferior

            if (last_smooth_x != 0) {
                bmp.drawLine(last_smooth_x, last_smooth_y, sx, sy);
            }
            last_smooth_x = sx;
            last_smooth_y = sy;
        }
    }

    // Adicionar Texto/Separador Visual (Linha horizontal no meio)
    var x: u32 = 0;
    while (x < width) : (x += 1) {
        bmp.setPixel(x, 600, true);
    }

    try bmp.save("output_comparison.bmp");
    std.debug.print("Imagem 'output_comparison.bmp' gerada com sucesso! ✅\n", .{});
    std.debug.print("- Topo: Raw (com ruído)\n", .{});
    std.debug.print("- Base: Savitzky-Golay (Smoothed)\n\n", .{});
}
