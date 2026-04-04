//! POC 006: Wacom Input Visualization com Sokol-Zig
//! Arquitetura Definitiva (baseada no sucesso da POC 007):
//!   - sapp.Event (MOUSE_MOVE) → Posição do cursor (driver Wacom já mapeou)
//!   - libinput → APENAS pressão + tip_state
//!   - Sem mapeamento mm→pixel manual (Absolute Map by Driver)
//! Data: 2026-04-04

const std = @import("std");
const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;

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
const TabletState = struct {
    pressure: f32,
    tip_down: bool,
};

const Point = struct {
    x: f32,
    y: f32,
    pressure: f32,
    sentinel: bool = false,
};

const MAX_POINTS: usize = 65536;

// --- Estado Global ---
var state: struct {
    pass_action: sg.PassAction = .{},
    pip: sg.Pipeline = .{},
    bind: sg.Bindings = .{},
    
    // Posição (sapp events)
    cursor_x: f32 = 0.0,
    cursor_y: f32 = 0.0,
    
    // Pressure/Tip (libinput)
    pressure: f32 = 0.0,
    tip_down: bool = false,
    last_tip_down: bool = false,
    in_proximity: bool = false,

    // Stroke Buffer
    points: [MAX_POINTS]Point = undefined,
    point_count: usize = 0,
    
    should_quit: bool = false,
} = .{};

var frame_count: std.atomic.Value(u64) = std.atomic.Value(u64).init(0);

// --- SPSC Queue ---
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

// --- Input Thread ---
fn inputThread() void {
    const udev = c.udev_new() orelse return;
    defer _ = c.udev_unref(udev);

    const li = c.libinput_udev_create_context(&libinput_interface, null, udev) orelse return;
    defer _ = c.libinput_unref(li);

    if (c.libinput_udev_assign_seat(li, "seat0") != 0) return;

    while (!state.should_quit) {
        _ = c.libinput_dispatch(li);
        var event_li = c.libinput_get_event(li);
        while (event_li != null) : (event_li = c.libinput_get_event(li)) {
            defer c.libinput_event_destroy(event_li);
            const event_type = c.libinput_event_get_type(event_li);

            if (event_type == c.LIBINPUT_EVENT_TABLET_TOOL_PROXIMITY) {
                const tev = c.libinput_event_get_tablet_tool_event(event_li);
                if (tev != null) {
                    const prox = c.libinput_event_tablet_tool_get_proximity_state(tev);
                    state.in_proximity = (prox == c.LIBINPUT_TABLET_TOOL_PROXIMITY_STATE_IN);
                }
            }

            if (event_type == c.LIBINPUT_EVENT_TABLET_TOOL_AXIS or
                event_type == c.LIBINPUT_EVENT_TABLET_TOOL_TIP)
            {
                const tev = c.libinput_event_get_tablet_tool_event(event_li);
                if (tev != null) {
                    const tip = c.libinput_event_tablet_tool_get_tip_state(tev) == c.LIBINPUT_TABLET_TOOL_TIP_DOWN;
                    _ = queuePush(.{
                        .pressure = @floatCast(c.libinput_event_tablet_tool_get_pressure(tev)),
                        .tip_down = tip,
                    });
                }
            }
        }
        std.Thread.sleep(500_000); // 0.5ms
    }
}

// --- App Callbacks ---
export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    std.debug.print("[POC 006] 🚀 Sokol init OK\n", .{});

    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .usage = .{ .vertex_buffer = true, .stream_update = true },
        .size = MAX_POINTS * @sizeOf(Point),
    });

    const shd = sg.makeShader(.{
        .vertex_func = .{ .source = 
            \\#version 330
            \\layout(location=0) in vec2 pos;
            \\layout(location=1) in float pressure;
            \\layout(location=2) in float sentinel;
            \\out float v_pressure;
            \\void main() {
            \\  gl_Position = vec4(pos.x, pos.y, 0.0, 1.0);
            \\  v_pressure = pressure;
            \\}
        },
        .fragment_func = .{ .source = 
            \\#version 330
            \\in float v_pressure;
            \\out vec4 frag_color;
            \\void main() {
            \\  frag_color = vec4(v_pressure + 0.3, 0.6, 1.0, 1.0);
            \\}
        },
    });

    state.pip = sg.makePipeline(.{
        .shader = shd,
        .layout = .{
            .attrs = init: {
                var a = [_]sg.VertexAttrState{.{}} ** 16;
                a[0].format = .FLOAT2; // pos
                a[1].format = .FLOAT;  // pressure
                a[2].format = .FLOAT;  // sentinel
                break :init a;
            },
        },
        .primitive_type = .LINES,
        .label = "stroke-pipeline",
    });

    state.pass_action.colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.05, .g = 0.05, .b = 0.1, .a = 1.0 } };
    
    // Iniciar thread
    const thread = std.Thread.spawn(.{}, inputThread, .{}) catch |err| {
        std.debug.print("[POC 006] ❌ Thread spawn failed: {}\n", .{err});
        return;
    };
    thread.detach();
    std.debug.print("[POC 006] 🧵 Input thread detached\n", .{});
}

export fn frame() void {
    while (queuePop()) |tev| {
        state.pressure = tev.pressure;
        
        if (state.last_tip_down and !tev.tip_down) {
            if (state.point_count < MAX_POINTS) {
                state.points[state.point_count] = .{ .x = 0, .y = 0, .pressure = 0, .sentinel = true };
                state.point_count += 1;
            }
        }
        state.last_tip_down = tev.tip_down;
        state.tip_down = tev.tip_down;

        if (tev.tip_down) {
            const nx = (state.cursor_x / sapp.widthf()) * 2.0 - 1.0;
            const ny = 1.0 - (state.cursor_y / sapp.heightf()) * 2.0; 
            if (state.point_count < MAX_POINTS) {
                state.points[state.point_count] = .{
                    .x = nx,
                    .y = ny,
                    .pressure = state.pressure,
                };
                state.point_count += 1;
            }
        }
    }

    var line_points: [MAX_POINTS]Point = undefined;
    var line_count: usize = 0;
    if (state.point_count > 1) {
        var i: usize = 1;
        while (i < state.point_count) : (i += 1) {
            const p1 = state.points[i - 1];
            const p2 = state.points[i];
            if (p1.sentinel or p2.sentinel) continue;
            if (line_count + 2 >= MAX_POINTS) break;
            line_points[line_count] = p1;
            line_points[line_count + 1] = p2;
            line_count += 2;
        }
    }

    if (line_count > 0) {
        sg.updateBuffer(state.bind.vertex_buffers[0], .{ .ptr = &line_points, .size = line_count * @sizeOf(Point) });
    }

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    if (line_count > 0) {
        sg.applyPipeline(state.pip);
        sg.applyBindings(state.bind);
        sg.draw(0, @intCast(line_count), 1);
    }
    sg.endPass();
    sg.commit();

    const fc = frame_count.load(.monotonic);
    frame_count.store(fc + 1, .release);
    if (fc % 300 == 0) {
        std.debug.print("[POC 006] Frame {d} | Pts: {d} | Tip: {} | Pres: {d:.2}\n", .{
            fc, state.point_count, state.tip_down, state.pressure,
        });
    }
}

export fn event(ev: [*c]const sapp.Event) void {
    if (ev.*.type == .MOUSE_MOVE) {
        state.cursor_x = ev.*.mouse_x;
        state.cursor_y = ev.*.mouse_y;
    }
    if (ev.*.type == .KEY_DOWN) {
        if (ev.*.key_code == .ESCAPE) sapp.requestQuit();
        if (ev.*.key_code == .C) state.point_count = 0;
    }
}

export fn cleanup() void {
    state.should_quit = true;
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 1280,
        .height = 720,
        .window_title = "POC 006: Sokol Clean Wacom Architecture",
        .logger = .{ .func = slog.func },
        .icon = .{ .sokol_default = true },
    });
}
