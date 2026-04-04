const std = @import("std");

/// Filtro de Savitzky-Golay para suavização de traços.
/// Implementação otimizada com coeficientes pré-calculados para janelas fixas.
pub fn SavitzkyGolay(comptime window_size: usize, comptime T: type) type {
    if (window_size % 2 == 0) @compileError("Window size must be odd");

    return struct {
        const Self = @This();
        const half_window = window_size / 2;

        history: [window_size]T,
        count: usize = 0,
        write_idx: usize = 0,

        // Coeficientes para Polinômio de 2º/3º Grau (derivados de mínimos quadrados)
        const coeffs: [window_size]f64 = switch (window_size) {
            5 => .{ -3.0 / 35.0, 12.0 / 35.0, 17.0 / 35.0, 12.0 / 35.0, -3.0 / 35.0 },
            7 => .{ -2.0 / 21.0, 3.0 / 21.0, 6.0 / 21.0, 7.0 / 21.0, 6.0 / 21.0, 3.0 / 21.0, -2.0 / 21.0 },
            9 => .{ -21.0 / 231.0, 14.0 / 231.0, 39.0 / 231.0, 54.0 / 231.0, 59.0 / 231.0, 54.0 / 231.0, 39.0 / 231.0, 14.0 / 231.0, -21.0 / 231.0 },
            else => @compileError("Unsupported window size. Please provide coefficients."),
        };

        pub fn init() Self {
            return .{
                .history = undefined,
            };
        }

        /// Adiciona um novo ponto e retorna o valor suavizado (do "centro" da janela).
        /// Note: Este filtro introduz um atraso de (window_size/2) pontos.
        pub fn process(self: *Self, value: T) ?T {
            self.history[self.write_idx] = value;
            self.write_idx = (self.write_idx + 1) % window_size;

            if (self.count < window_size) {
                self.count += 1;
                return null; // Ainda enchendo a janela
            }

            // Convolução
            var sum: f64 = 0;
            var i: usize = 0;
            while (i < window_size) : (i += 1) {
                // O ponto central da janela (o que estamos suavizando) está 
                // no meio do buffer circular relativo ao write_idx.
                const idx = (self.write_idx + i) % window_size;
                sum += @as(f64, @floatCast(self.history[idx])) * coeffs[i];
            }

            // Retorno genérico baseado no tipo T
            if (@typeInfo(T) == .float) {
                return @as(T, @floatCast(sum));
            } else {
                return @as(T, @floatFromInt(@as(i64, @intFromFloat(@round(sum)))));
            }
        }

        /// Reset do estado do filtro
        pub fn reset(self: *Self) void {
            self.count = 0;
            self.write_idx = 0;
        }
    };
}
