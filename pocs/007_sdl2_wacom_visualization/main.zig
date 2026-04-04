//! POC 007: SDL2 Renderer 2D + Wacom Input
//! Estratégia: SDL_GetMouseState() para posição do cursor (o driver já mapeia o tablet)
//!             libinput apenas para pressure + tip_down
//! Data: 2026-04-03

const std = @import("std");

// SDL2
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

// Libinput
const c = @cImport({
    @cInclude("libinput.h");
    @cInclude("libudev.h");
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
});

// --- Libinput callbacks ---
fn openRestricted(path: [*c]const u8, flags: c_int, user_data: ?*anyopaque) callconv(.c) c_int {
    _ = user_data;
    return c.open(path, flags);
}

fn closeRestricted(fd: c_int, user_data: ?*anyopaque) callconv(.c) void {
    _ = user_data;
    _ = c.close(fd);
}

const libinput_interface = c.libinput_interface{
    .open_restricted = openRestricted,
    .close_restricted = closeRestricted,
};

// --- Tipos --- 
// Apenas pressão + tip state vêm do libinput
const TabletState = struct {
    pressure: f64,
    tip_down: bool,
};

const MAX_POINTS: usize = 65536;

const Point2D = struct {
    x: i32,
    y: i32,
    pressure: f32,
    sentinel: bool = false, // true = quebra de stroke
};

// --- Estado Global ---
var g_tablet_name: [64]u8 = undefined;

var state: struct {
    // Posição vem do SDL (mouse events)
    cursor_x: i32 = 0,
    cursor_y: i32 = 0,
    // Pressure + tip vêm do libinput
    pressure: f32 = 0.0,
    tip_down: bool = false,
    last_tip_down: bool = false,
    in_proximity: bool = false,
    // Stroke buffer
    points: [MAX_POINTS]Point2D = undefined,
    point_count: usize = 0,
    events_received: usize = 0,
    should_quit: bool = false,
} = .{};

// --- SPSC Queue (libinput → main thread) ---
const QUEUE_SIZE: usize = 4096;
var queue: struct {
    buffer: [QUEUE_SIZE]TabletState = undefined,
    write_idx: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
    read_idx: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
} = .{};

fn queuePush(ev: TabletState) bool {
    const w = queue.write_idx.load(.monotonic);
    const r = queue.read_idx.load(.acquire);
    const next_w = (w + 1) % QUEUE_SIZE;
    if (next_w == r) return false;
    queue.buffer[w] = ev;
    queue.write_idx.store(next_w, .release);
    return true;
}

fn queuePop() ?TabletState {
    const r = queue.read_idx.load(.monotonic);
    const w = queue.write_idx.load(.acquire);
    if (r == w) return null;
    const ev = queue.buffer[r];
    queue.read_idx.store((r + 1) % QUEUE_SIZE, .release);
    return ev;
}

// --- Input Thread (apenas libinput para pressão/tip) ---
fn inputThread() void {
    const udev = c.udev_new() orelse {
        std.debug.print("[POC 007] ❌ udev failed\n", .{});
        return;
    };
    defer _ = c.udev_unref(udev);

    const li = c.libinput_udev_create_context(&libinput_interface, null, udev) orelse {
        std.debug.print("[POC 007] ❌ libinput failed\n", .{});
        return;
    };
    defer _ = c.libinput_unref(li);

    if (c.libinput_udev_assign_seat(li, "seat0") != 0) {
        std.debug.print("[POC 007] ❌ seat assign failed\n", .{});
        return;
    }

    std.debug.print("[POC 007] ✅ Libinput OK\n", .{});

    while (!state.should_quit) {
        _ = c.libinput_dispatch(li);
        var event = c.libinput_get_event(li);
        while (event != null) : (event = c.libinput_get_event(li)) {
            defer c.libinput_event_destroy(event);
            const event_type = c.libinput_event_get_type(event);

            if (event_type == c.LIBINPUT_EVENT_DEVICE_ADDED) {
                const dev = c.libinput_event_get_device(event);
                var w: f64 = 0;
                var h: f64 = 0;
                if (c.libinput_device_get_size(dev, &w, &h) == 0 and w > 0) {
                    const name = c.libinput_device_get_name(dev);
                    std.debug.print("[POC 007] 📐 Tablet: {s} ({d:.1}x{d:.1}mm)\n", .{ name, w, h });
                }
            }

            if (event_type == c.LIBINPUT_EVENT_TABLET_TOOL_AXIS or
                event_type == c.LIBINPUT_EVENT_TABLET_TOOL_TIP)
            {
                const tev = c.libinput_event_get_tablet_tool_event(event);
                if (tev != null) {
                    const tip = c.libinput_event_tablet_tool_get_tip_state(tev) == c.LIBINPUT_TABLET_TOOL_TIP_DOWN;
                    const pressure = c.libinput_event_tablet_tool_get_pressure(tev);
                    _ = queuePush(.{
                        .pressure = pressure,
                        .tip_down = tip,
                    });
                }
            }

            if (event_type == c.LIBINPUT_EVENT_TABLET_TOOL_PROXIMITY) {
                const tev = c.libinput_event_get_tablet_tool_event(event);
                if (tev != null) {
                    const prox_state = c.libinput_event_tablet_tool_get_proximity_state(tev);
                    state.in_proximity = prox_state == c.LIBINPUT_TABLET_TOOL_PROXIMITY_STATE_IN;
                }
            }
        }
        std.Thread.sleep(500_000); // 0.5ms
    }
}

// --- Main ---
pub fn main() !void {
    // Iniciar thread de input
    const thread = std.Thread.spawn(.{}, inputThread, .{}) catch {
        std.debug.print("[POC 007] ❌ Thread failed\n", .{});
        return error.ThreadFailed;
    };
    thread.detach();

    // SDL init
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) < 0) return error.SdlInitFailed;
    defer sdl.SDL_Quit();

    // Window
    const window = sdl.SDL_CreateWindow(
        "POC 007: SDL2 Wacom Visualization",
        sdl.SDL_WINDOWPOS_CENTERED,
        sdl.SDL_WINDOWPOS_CENTERED,
        1280,
        720,
        sdl.SDL_WINDOW_SHOWN | sdl.SDL_WINDOW_RESIZABLE,
    ) orelse return error.WindowFailed;
    defer sdl.SDL_DestroyWindow(window);

    // Renderer 2D
    const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse return error.RendererFailed;
    defer sdl.SDL_DestroyRenderer(renderer);

    // Habilitar relative mouse para capturar movimento do tablet
    _ = sdl.SDL_SetRelativeMouseMode(sdl.SDL_FALSE);

    std.debug.print("[POC 007] ✅ SDL2 Renderer OK\n", .{});
    std.debug.print("[POC 007] 🎯 Cursor: posição do mouse SDL (driver Wacom)\n", .{});
    std.debug.print("[POC 007] ✏️  Pressão + tip: libinput\n", .{});
    std.debug.print("[POC 007] ESC: Sair | C: Limpar\n", .{});

    var frame_count: u64 = 0;
    const start_time = std.time.milliTimestamp();

    while (!state.should_quit) {
        frame_count += 1;

        // 1. SDL events — captura posição do cursor (mouse = tablet mapped by driver)
        var sdl_event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&sdl_event) != 0) {
            switch (sdl_event.type) {
                sdl.SDL_QUIT => state.should_quit = true,
                sdl.SDL_KEYDOWN => {
                    if (sdl_event.key.keysym.sym == sdl.SDLK_ESCAPE) state.should_quit = true;
                    if (sdl_event.key.keysym.sym == sdl.SDLK_c) state.point_count = 0;
                },
                sdl.SDL_MOUSEMOTION => {
                    state.cursor_x = sdl_event.motion.x;
                    state.cursor_y = sdl_event.motion.y;
                },
                else => {},
            }
        }

        // 2. Processar estados do libinput (só pressure + tip)
        while (queuePop()) |tev| {
            state.events_received += 1;
            state.pressure = @as(f32, @floatCast(tev.pressure));

            // Detectar levantada da caneta → inserir sentinel
            if (state.last_tip_down and !tev.tip_down) {
                if (state.point_count < MAX_POINTS) {
                    state.points[state.point_count] = .{ .x = 0, .y = 0, .pressure = 0, .sentinel = true };
                    state.point_count += 1;
                }
            }
            state.last_tip_down = tev.tip_down;
            state.tip_down = tev.tip_down;

            // Se tip está pressionado, registrar ponto na posição ATUAL do cursor SDL
            if (tev.tip_down) {
                if (state.point_count < MAX_POINTS) {
                    state.points[state.point_count] = .{
                        .x = state.cursor_x,
                        .y = state.cursor_y,
                        .pressure = state.pressure,
                        .sentinel = false,
                    };
                    state.point_count += 1;
                }
            }
        }

        // 3. Render
        _ = sdl.SDL_SetRenderDrawColor(renderer, 12, 12, 20, 255);
        _ = sdl.SDL_RenderClear(renderer);

        // Desenhar stroke
        if (state.point_count > 1) {
            var i: usize = 1;
            while (i < state.point_count) : (i += 1) {
                const p1 = state.points[i - 1];
                const p2 = state.points[i];
                if (p1.sentinel or p2.sentinel) continue;
                // Cor baseada na pressão
                const intensity: u8 = @intFromFloat(@min(255.0, p2.pressure * 255.0 + 80.0));
                _ = sdl.SDL_SetRenderDrawColor(renderer, intensity, intensity, 255, 255);
                _ = sdl.SDL_RenderDrawLine(renderer, p1.x, p1.y, p2.x, p2.y);
            }
        }

        // Cursor: ponto verde quando hovering, vermelho quando pressionar
        {
            const size: i32 = if (state.tip_down) 4 else 7;
            const r: u8 = if (state.tip_down) 255 else 0;
            const g: u8 = if (state.tip_down) 80 else 255;
            _ = sdl.SDL_SetRenderDrawColor(renderer, r, g, 0, 255);
            _ = sdl.SDL_RenderFillRect(renderer, &sdl.SDL_Rect{
                .x = state.cursor_x - size,
                .y = state.cursor_y - size,
                .w = size * 2,
                .h = size * 2,
            });
        }

        sdl.SDL_RenderPresent(renderer);

        if (frame_count % 120 == 0) {
            const elapsed = @as(f64, @floatFromInt(std.time.milliTimestamp() - start_time)) / 1000.0;
            const fps = @as(f64, @floatFromInt(frame_count)) / elapsed;
            std.debug.print("[POC 007] Frame {d} | FPS: {d:.1} | Eventos: {d} | Pontos: {d} | Tip: {} | P: {d:.2}\n", .{
                frame_count, fps, state.events_received, state.point_count, state.tip_down, state.pressure,
            });
        }

        sdl.SDL_Delay(16);
    }

    std.debug.print("[POC 007] ✅ Shutdown OK\n", .{});
}
