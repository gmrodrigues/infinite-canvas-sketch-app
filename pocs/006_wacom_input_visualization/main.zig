//! POC 006: Wacom Input Visualization com OpenGL puro
//! Hipótese: Input Wacom real + OpenGL = cursor + riscos visíveis
//! Data: 2026-04-03

const std = @import("std");

// OpenGL
const gl = @cImport({
    @cInclude("GL/gl.h");
    @cInclude("GL/glu.h");
});

// GLFW para janela
const glfw = @cImport({
    @cDefine("GLFW_INCLUDE_NONE", "");
    @cInclude("GLFW/glfw3.h");
});

// Libinput
const c = @cImport({
    @cInclude("libinput.h");
    @cInclude("libudev.h");
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
});

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

const TabletEvent = struct {
    x: f64,
    y: f64,
    pressure: f64,
    in_proximity: bool,
    tip_down: bool,
};

const MAX_POINTS: usize = 16384;

const Point2D = struct {
    x: f32,
    y: f32,
    pressure: f32,
};

var state: struct {
    current_x: f32 = 0.0,
    current_y: f32 = 0.0,
    current_pressure: f32 = 0.0,
    in_proximity: bool = false,
    tip_down: bool = false,
    points: [MAX_POINTS]Point2D = undefined,
    point_count: usize = 0,
    events_received: usize = 0,
    should_close: bool = false,
} = .{};

// SPSC Queue
const QUEUE_SIZE: usize = 1024;
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

fn inputThread() void {
    const udev = c.udev_new() orelse return;
    defer _ = c.udev_unref(udev);

    const li = c.libinput_udev_create_context(&libinput_interface, null, udev) orelse return;
    defer _ = c.libinput_unref(li);

    if (c.libinput_udev_assign_seat(li, "seat0") != 0) return;

    std.debug.print("[POC 006] ✅ Libinput inicializado\n", .{});

    while (!state.should_close) {
        _ = c.libinput_dispatch(li);
        var event = c.libinput_get_event(li);
        while (event != null) : (event = c.libinput_get_event(li)) {
            defer c.libinput_event_destroy(event);
            const event_type = c.libinput_event_get_type(event);
            if (event_type == c.LIBINPUT_EVENT_TABLET_TOOL_AXIS) {
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
        std.Thread.sleep(1_000_000);
    }
}

fn keyCallback(window: ?*glfw.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.c) void {
    _ = scancode;
    _ = mods;
    if (key == glfw.GLFW_KEY_ESCAPE and action == glfw.GLFW_PRESS) {
        state.should_close = true;
        if (window) |w| glfw.glfwSetWindowShouldClose(w, glfw.GLFW_TRUE);
    }
}

pub fn main() !void {
    // Iniciar thread de input
    const thread = std.Thread.spawn(.{}, inputThread, .{}) catch {
        std.debug.print("[POC 006] ❌ Falha ao criar thread de input\n", .{});
        return error.ThreadFailed;
    };
    thread.detach();

    // GLFW
    if (glfw.glfwInit() == glfw.GLFW_FALSE) return error.GlfwInitFailed;
    defer glfw.glfwTerminate();

    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);

    const window = glfw.glfwCreateWindow(1280, 720, "POC 006: Wacom Input Visualization", null, null) orelse return error.WindowFailed;
    defer glfw.glfwDestroyWindow(window);

    glfw.glfwMakeContextCurrent(window);
    _ = glfw.glfwSetKeyCallback(window, keyCallback);

    std.debug.print("[POC 006] ✅ OpenGL + Libinput inicializados!\n", .{});
    std.debug.print("[POC 006] 🎯 Caneta no ar: cursor verde\n", .{});
    std.debug.print("[POC 006] ✏️  Caneta tocando: risco branco\n", .{});
    std.debug.print("[POC 006] ESC: Sair\n", .{});

    var frame_count: u64 = 0;
    const start_time = std.time.milliTimestamp();

    while (glfw.glfwWindowShouldClose(window) == glfw.GLFW_FALSE) {
        frame_count += 1;

        // Processar input
        while (queuePop()) |event| {
            state.events_received += 1;
            const ndc_x = @as(f32, @floatCast((event.x / 32000.0) * 2.0 - 1.0));
            const ndc_y = @as(f32, @floatCast((event.y / 20000.0) * 2.0 - 1.0));
            state.current_x = ndc_x;
            state.current_y = ndc_y;
            state.current_pressure = @as(f32, @floatCast(event.pressure));
            state.in_proximity = event.in_proximity;
            state.tip_down = event.tip_down;

            if (event.tip_down) {
                if (state.point_count < MAX_POINTS) {
                    state.points[state.point_count] = .{
                        .x = ndc_x,
                        .y = ndc_y,
                        .pressure = state.current_pressure,
                    };
                    state.point_count += 1;
                }
            }
        }

        // Clear
        gl.glClearColor(0.05, 0.05, 0.08, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        // Desenhar stroke
        if (state.point_count > 1) {
            gl.glLineWidth(3.0);
            gl.glBegin(gl.GL_LINE_STRIP);
            var i: usize = 0;
            while (i < state.point_count) : (i += 1) {
                gl.glVertex2f(state.points[i].x, state.points[i].y);
            }
            gl.glEnd();
        }

        // Desenhar cursor
        if (state.in_proximity and !state.tip_down and state.point_count == 0) {
            gl.glPointSize(15.0);
            gl.glBegin(gl.GL_POINTS);
            gl.glVertex2f(state.current_x, state.current_y);
            gl.glEnd();
        }

        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();

        if (frame_count % 120 == 0) {
            const elapsed = @as(f64, @floatFromInt(std.time.milliTimestamp() - start_time)) / 1000.0;
            const fps = @as(f64, @floatFromInt(frame_count)) / elapsed;
            std.debug.print("[POC 006] Frame {d} | FPS: {d:.1} | Eventos: {d} | Pontos: {d}\n", .{
                frame_count, fps, state.events_received, state.point_count,
            });
        }
    }
}
