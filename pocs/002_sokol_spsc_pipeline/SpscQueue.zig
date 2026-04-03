const std = @import("std");
const atomic = std.atomic;

/// Single-Producer Single-Consumer Lock-Free Queue
/// Adequado para passar eventos de input da thread de polling para a thread de render.
pub fn SpscQueue(comptime T: type, comptime capacity: usize) type {
    // A capacidade deve ser potência de 2 para eficiência do mapeamento circular
    if (!std.math.isPowerOfTwo(capacity)) {
        @compileError("Capacidade da SpscQueue deve ser potência de 2");
    }

    return struct {
        const Self = @This();

        buffer: [capacity]T = undefined,
        write_index: atomic.Value(usize) = atomic.Value(usize).init(0),
        read_index: atomic.Value(usize) = atomic.Value(usize).init(0),

        pub fn init() Self {
            return .{};
        }

        /// Tenta inserir um item. Retorna false se a fila estiver cheia.
        pub fn tryPush(self: *Self, item: T) bool {
            const w = self.write_index.load(.monotonic);
            const r = self.read_index.load(.acquire);

            if (w -% r == capacity) {
                return false; // Cheia
            }

            self.buffer[w % capacity] = item;
            self.write_index.store(w +% 1, .release);
            return true;
        }

        /// Tenta remover um item. Retorna null se a fila estiver vazia.
        pub fn tryPop(self: *Self) ?T {
            const r = self.read_index.load(.monotonic);
            const w = self.write_index.load(.acquire);

            if (r == w) {
                return null; // Vazia
            }

            const item = self.buffer[r % capacity];
            self.read_index.store(r +% 1, .release);
            return item;
        }

        pub fn isEmpty(self: *Self) bool {
            return self.read_index.load(.monotonic) == self.write_index.load(.monotonic);
        }
    };
}
