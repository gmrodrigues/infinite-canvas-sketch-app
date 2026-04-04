//! POC 007: SDL2 Renderer 2D + Wacom Input
//! Hipótese: SDL_Renderer 2D consegue mostrar cursor + riscos do Wacom sem OpenGL
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
const TabletEvent = struct {
    x: f64,
    y: f64,
    pressure: f64,
    in_proximity: bool,
    tip_down: bool,
};

const MAX_POINTS: usize = 32768;

const Point2D = struct {
    x: i32,
    y: i32,
    pressure: f32,
};

// --- Estado Global ---
var g_tablet_w: f64 = 152.0; // mm - detectado via libinput_device_get_size
var g_tablet_h: f64 = 95.0;

const WIN_W: i32 = 1280;
const WIN_H: i32 = 720;

var state: struct {
    current_x: i32 = 0,
    current_y: i32 = 0,
    current_pressure: f32 = 0.0,
    in_proximity: bool = false,
    tip_down: bool = false,
    points: [MAX_POINTS]Point2D = undefined,
    point_count: usize = 0,
    events_received: usize = 0,
    should_quit: bool = false,
    last_tip_down: bool = false, // detectar stroke break
} = .{};

// --- SPSC Queue ---
const QUEUE_SIZE: usize = 2048;
var queue: struct {
    buffer: [QUEUE_SIZE]TabletEvent = undefined,
    write_idx: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
    read_idx: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
} = .{};

fn queuePush(event: TabletEvent) bool {
    const w = queue.write_idx.load(.monotonic);
    const r = queue.read_idx.load(.acquire);
    const next_w = (w + 1) % QUEUE_SIZE;
    if (next_w == r) return false;
    queue.buffer[w] = event;
    queue.write_idx.store(next_w, .release);
    return true;
}

fn queuePop() ?TabletEvent {
    const r = queue.read_idx.load(.monotonic);
    const w = queue.write_idx.load(.acquire);
    if (r == w) return null;
    const event = queue.buffer[r];
    queue.read_idx.store((r + 1) % QUEUE_SIZE, .release);
    return event;
}

// --- Input Thread ---
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

            // Detectar tamanho físico real do tablet
            if (event_type == c.LIBINPUT_EVENT_DEVICE_ADDED) {
                const dev = c.libinput_event_get_device(event);
                var w: f64 = 0;
                var h: f64 = 0;
                if (c.libinput_device_get_size(dev, &w, &h) == 0 and w > 0) {
                    g_tablet_w = w;
                    g_tablet_h = h;
                    std.debug.print("[POC 007] 📐 Tablet: {s} ({d:.1}x{d:.1}mm)\n", .{
                        c.libinput_device_get_name(dev), w, h,
                    });
                    std.debug.print("[POC 007] 📏 Escala: {d:.2} px/mm x, {d:.2} px/mm y\n", .{
                        @as(f64, WIN_W) / w,
                        @as(f64, WIN_H) / h,
                    });
                }
            }

            if (event_type == c.LIBINPUT_EVENT_TABLET_TOOL_AXIS or
                event_type == c.LIBINPUT_EVENT_TABLET_TOOL_TIP)
            {
                const tev = c.libinput_event_get_tablet_tool_event(event);
                if (tev != null) {
                    const tip = c.libinput_event_tablet_tool_get_tip_state(tev) == c.LIBINPUT_TABLET_TOOL_TIP_DOWN;
                    _ = queuePush(.{
                        .x = c.libinput_event_tablet_tool_get_x(tev),
                        .y = c.libinput_event_tablet_tool_get_y(tev),
                        .pressure = c.libinput_event_tablet_tool_get_pressure(tev),
                        .in_proximity = true,
                        .tip_down = tip,
                    });
                }
            }
        }
        std.Thread.sleep(1_000_000); // 1ms
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
        sdl.SDL_WINDOW_SHOWN,
    ) orelse return error.WindowFailed;
    defer sdl.SDL_DestroyWindow(window);

    // Renderer 2D (software, sem OpenGL)
    const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse return error.RendererFailed;
    defer sdl.SDL_DestroyRenderer(renderer);

    std.debug.print("[POC 007] ✅ SDL2 Renderer OK\n", .{});
    std.debug.print("[POC 007] 🎯 Caneta no ar: cursor VERDE\n", .{});
    std.debug.print("[POC 007] ✏️  Caneta tocando: risco BRANCO\n", .{});
    std.debug.print("[POC 007] ESC: Sair | C: Limpar\n", .{});

    var frame_count: u64 = 0;
    const start_time = std.time.milliTimestamp();

    while (!state.should_quit) {
        frame_count += 1;

        // SDL events
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            if (event.type == sdl.SDL_QUIT) {
                state.should_quit = true;
            } else if (event.type == sdl.SDL_KEYDOWN) {
                if (event.key.keysym.sym == sdl.SDLK_ESCAPE) {
                    state.should_quit = true;
                } else if (event.key.keysym.sym == sdl.SDLK_c) {
                    state.point_count = 0; // Limpar
                }
            }
        }

        // Processar input Wacom
        while (queuePop()) |tev| {
            state.events_received += 1;

            // Mapear mm reais para pixels da janela
            state.current_x = @as(i32, @intFromFloat(@round((tev.x / g_tablet_w) * @as(f64, WIN_W))));
            state.current_y = @as(i32, @intFromFloat(@round((tev.y / g_tablet_h) * @as(f64, WIN_H))));
            state.current_pressure = @as(f32, @floatCast(tev.pressure));
            state.in_proximity = tev.in_proximity;

            // Detectar quebra de stroke (levantou a caneta)
            if (state.last_tip_down and !tev.tip_down) {
                // Inserir ponto sentinel para quebrar a linha
                if (state.point_count < MAX_POINTS) {
                    state.points[state.point_count] = .{ .x = -1, .y = -1, .pressure = 0 };
                    state.point_count += 1;
                }
            }
            state.last_tip_down = tev.tip_down;
            state.tip_down = tev.tip_down;

            if (tev.tip_down) {
                if (state.point_count < MAX_POINTS) {
                    state.points[state.point_count] = .{
                        .x = state.current_x,
                        .y = state.current_y,
                        .pressure = state.current_pressure,
                    };
                    state.point_count += 1;
                }
            }
        }

        // Clear tela
        _ = sdl.SDL_SetRenderDrawColor(renderer, 12, 12, 20, 255);
        _ = sdl.SDL_RenderClear(renderer);

        // Desenhar stroke (linhas brancas), com suporte a sentinels de quebra
        if (state.point_count > 1) {
            _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
            var i: usize = 1;
            while (i < state.point_count) : (i += 1) {
                const p1 = state.points[i - 1];
                const p2 = state.points[i];
                // Se qualquer ponto é sentinel (-1,-1), pular esta linha
                if (p1.x < 0 or p2.x < 0) continue;
                _ = sdl.SDL_RenderDrawLine(renderer, p1.x, p1.y, p2.x, p2.y);
            }
        }

        // Desenhar cursor (ponto verde quando hover)
        if (state.in_proximity and !state.tip_down) {
            _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255);
            // Desenhar círculo simples (quadrado 15x15)
            const size: i32 = 7;
            _ = sdl.SDL_RenderFillRect(renderer, &sdl.SDL_Rect{
                .x = state.current_x - size,
                .y = state.current_y - size,
                .w = size * 2,
                .h = size * 2,
            });
        }

        // Present
        sdl.SDL_RenderPresent(renderer);

        // Stats
        if (frame_count % 120 == 0) {
            const elapsed = @as(f64, @floatFromInt(std.time.milliTimestamp() - start_time)) / 1000.0;
            const fps = @as(f64, @floatFromInt(frame_count)) / elapsed;
            std.debug.print("[POC 007] Frame {d} | FPS: {d:.1} | Eventos: {d} | Pontos: {d}\n", .{
                frame_count, fps, state.events_received, state.point_count,
            });
        }

        // Limitar a ~60 FPS
        sdl.SDL_Delay(16);
    }

    std.debug.print("[POC 007] ✅ Shutdown OK\n", .{});
}
