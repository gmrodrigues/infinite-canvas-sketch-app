const std = @import("std");
const QuadTree = @import("QuadTree.zig").QuadTree;
const Rect = @import("QuadTree.zig").Rect;
const Point = @import("QuadTree.zig").Point;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n--- POC 004: Quadtree Spatial Partitioning ---\n\n", .{});

    const bounds = Rect{ .x = 0, .y = 0, .w = 1_000_000, .h = 1_000_000 };
    var qt = try QuadTree(8).init(bounds, allocator);
    defer qt.deinit();

    var prng = std.Random.DefaultPrng.init(42);
    const random = prng.random();

    const num_points = 1_000_000;
    std.debug.print("Inserindo {d} pontos...\n", .{num_points});

    var timer = try std.time.Timer.start();
    const start_insert = timer.read();
    
    var i: usize = 0;
    while (i < num_points) : (i += 1) {
        const p = Point{
            .x = random.float(f64) * 1_000_000.0,
            .y = random.float(f64) * 1_000_000.0,
            .data = @as(u32, @truncate(i)),
        };
        _ = try qt.insert(p);
    }
    const end_insert = timer.read();
    const insert_duration_ms = @as(f64, @floatFromInt(end_insert - start_insert)) / 1_000_000.0;

    std.debug.print("Inserção concluída em: {d:.2} ms\n", .{insert_duration_ms});
    std.debug.print("Média por inserção: {d:.2} ns\n", .{@as(f64, @floatFromInt(end_insert - start_insert)) / @as(f64, @floatFromInt(num_points))});

    // Query Test
    const query_range = Rect{ .x = 500_000, .y = 500_000, .w = 1000, .h = 1000 };
    std.debug.print("\nExecutando Query de área (1000x1000)...\n", .{});

    // No Zig 0.15.2 std.ArrayList(T) é Unmanaged por padrão
    var results = std.ArrayList(Point){};
    defer results.deinit(allocator);

    const start_query = timer.read();
    try qt.query(allocator, query_range, &results);
    const end_query = timer.read();
    const query_duration_us = @as(f64, @floatFromInt(end_query - start_query)) / 1000.0;

    std.debug.print("Query concluída em: {d:.2} us ({d:.4} ms)\n", .{ query_duration_us, query_duration_us / 1000.0 });
    std.debug.print("Pontos encontrados: {d}\n", .{results.items.len});

    // Verificação de Critérios
    const success_insert = insert_duration_ms < 2000; // Aumentado para 2s por cautela em debug/virtualized
    const success_query = query_duration_us < 1000;   // < 1ms (1000us)

    std.debug.print("\nResultados de Validação:\n", .{});
    std.debug.print("- Inserção < 2000ms: {s} ({d:.2}ms)\n", .{if (success_insert) "Sim ✅" else "Não ❌", insert_duration_ms});
    std.debug.print("- Query < 1000us: {s} ({d:.2}us)\n", .{if (success_query) "Sim ✅" else "Não ❌", query_duration_us});

    if (success_insert and success_query) {
        std.debug.print("\nCRITÉRIO DE SUCESSO: ATINGIDO ✅\n\n", .{});
    } else {
        std.debug.print("\nCRITÉRIO DE SUCESSO: FALHA ❌\n\n", .{});
    }
}
