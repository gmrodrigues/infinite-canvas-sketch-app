const std = @import("std");
const SpscQueue = @import("SpscQueue.zig").SpscQueue;

const c = @cImport({
    @cInclude("libinput.h");
    @cInclude("libudev.h");
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
});

const Point = struct {
    x: f64,
    y: f64,
    pressure: f64,
    tilt_x: f64,
    tilt_y: f64,
    tip: bool,
};

// Configuração da fila: 2048 eventos de buffer (potência de 2)
const EventQueue = SpscQueue(Point, 2048);

// Callbacks para o libinput
fn openRestricted(path: [*c]const u8, flags: c_int, user_data: ?*anyopaque) callconv(.c) c_int {
    _ = user_data;
    const fd = c.open(path, flags);
    return fd;
}

fn closeRestricted(fd: c_int, user_data: ?*anyopaque) callconv(.c) void {
    _ = user_data;
    _ = c.close(fd);
}

const interface = c.libinput_interface{
    .open_restricted = openRestricted,
    .close_restricted = closeRestricted,
};

/// Thread de Input: Polling constante do libinput
fn inputThread(queue: *EventQueue) void {
    const udev = c.udev_new() orelse return;
    defer _ = c.udev_unref(udev);

    const li = c.libinput_udev_create_context(&interface, null, udev) orelse return;
    defer _ = c.libinput_unref(li);

    const seat = "seat0";
    if (c.libinput_udev_assign_seat(li, seat) != 0) return;

    std.debug.print("[Input] Thread iniciada. Polling libinput...\n", .{});

    while (true) {
        _ = c.libinput_dispatch(li);
        var event = c.libinput_get_event(li);
        while (event != null) : (event = c.libinput_get_event(li)) {
            defer c.libinput_event_destroy(event);

            const event_type = c.libinput_event_get_type(event);
            if (event_type == c.LIBINPUT_EVENT_TABLET_TOOL_AXIS or
                event_type == c.LIBINPUT_EVENT_TABLET_TOOL_TIP) 
            {
                const tablet_event = c.libinput_event_get_tablet_tool_event(event);
                const p = Point{
                    .x = c.libinput_event_tablet_tool_get_x(tablet_event),
                    .y = c.libinput_event_tablet_tool_get_y(tablet_event),
                    .pressure = c.libinput_event_tablet_tool_get_pressure(tablet_event),
                    .tilt_x = c.libinput_event_tablet_tool_get_tilt_x(tablet_event),
                    .tilt_y = c.libinput_event_tablet_tool_get_tilt_y(tablet_event),
                    .tip = c.libinput_event_tablet_tool_get_tip_state(tablet_event) == c.LIBINPUT_TABLET_TOOL_TIP_DOWN,
                };

                if (!queue.tryPush(p)) {
                    // Fila cheia: descartamos ou registramos overflow
                    // Em uma app real, isso indica que o render está muito lento
                }
            }
        }
        // Dorme um pouco para não fritar a CPU se não houver eventos
        std.Thread.sleep(100 * std.time.ns_per_us); // 0.1ms
    }
}

pub fn main() !void {
    var queue = EventQueue.init();

    // Inicia a thread de input
    const thread = try std.Thread.spawn(.{}, inputThread, .{&queue});
    thread.detach();

    std.debug.print("[Main] Render Loop iniciado (Simulado)...\n", .{});

    // Loop de "Renderização"
    var frame_count: u64 = 0;
    while (true) {
        // Consome todos os eventos acumulados na fila nesta iteração
        var points_processed: usize = 0;
        while (queue.tryPop()) |p| {
            // Aqui seria onde enviaríamos os dados para o buffer da GPU (Sokol)
            if (p.tip) {
                // Desenha apenas se a ponta estiver encostada
                points_processed += 1;
            }
        }

        if (points_processed > 0) {
            std.debug.print("[Main] Frame {d}: Processados {d} pontos de input.\n", .{frame_count, points_processed});
        }

        frame_count += 1;
        // Simula frame lag (ex: 60 FPS = 16.6ms)
        std.Thread.sleep(16 * std.time.ns_per_ms);
    }
}
