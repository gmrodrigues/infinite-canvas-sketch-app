//! POC: libinput_tablet_input — Nano
//! Hipótese: @cImport + libinput via udev consegue ler pressão, posição e
//!           inclinação de um tablet Wacom em Zig 0.13, com valores f64 corretos.
//! Data: 2026-04-03
//!
//! ISOLAMENTO: Não importa nada de src/. Executa standalone.
//! Execute:  sudo zig build run   (sudo necessário para acesso ao /dev/input)
//! Ou configure udev rules para acesso sem sudo (ver planning.md)

const std = @import("std");
const c = @cImport({
    @cInclude("libinput.h");
    @cInclude("libudev.h");
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
});

// Callbacks obrigatórios pelo libinput para gerenciar abertura/fechamento de fd
fn openRestricted(path: [*c]const u8, flags: c_int, user_data: ?*anyopaque) callconv(.c) c_int {
    _ = user_data;
    const fd = c.open(path, flags);
    if (fd < 0) {
        std.debug.print("openRestricted: falhou ao abrir {s}\n", .{path});
        return -1;
    }
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

pub fn main() !void {
    // ---- SETUP UDEV + LIBINPUT ----
    const udev = c.udev_new() orelse {
        std.debug.print("ERRO: falhou ao criar contexto udev\n", .{});
        return error.UdevFailed;
    };
    defer _ = c.udev_unref(udev);

    const li = c.libinput_udev_create_context(&interface, null, udev) orelse {
        std.debug.print("ERRO: falhou ao criar contexto libinput\n", .{});
        return error.LibinputFailed;
    };
    defer _ = c.libinput_unref(li);

    const seat = "seat0";
    if (c.libinput_udev_assign_seat(li, seat) != 0) {
        std.debug.print("ERRO: falhou ao atribuir seat '{s}'\n", .{seat});
        return error.SeatFailed;
    }

    std.debug.print("libinput inicializado. Aguardando eventos de tablet...\n", .{});
    std.debug.print("Mova/pressione a caneta. Ctrl+C para sair.\n\n", .{});

    // ---- LOOP DE EVENTOS ----
    while (true) {
        _ = c.libinput_dispatch(li);

        var event = c.libinput_get_event(li);
        while (event != null) : (event = c.libinput_get_event(li)) {
            defer c.libinput_event_destroy(event);

            const event_type = c.libinput_event_get_type(event);

            switch (event_type) {
                c.LIBINPUT_EVENT_TABLET_TOOL_AXIS,
                c.LIBINPUT_EVENT_TABLET_TOOL_TIP,
                c.LIBINPUT_EVENT_TABLET_TOOL_PROXIMITY,
                => {
                    const tablet_event = c.libinput_event_get_tablet_tool_event(event);

                    const x        = c.libinput_event_tablet_tool_get_x(tablet_event);
                    const y        = c.libinput_event_tablet_tool_get_y(tablet_event);
                    const pressure = c.libinput_event_tablet_tool_get_pressure(tablet_event);
                    const tilt_x   = c.libinput_event_tablet_tool_get_tilt_x(tablet_event);
                    const tilt_y   = c.libinput_event_tablet_tool_get_tilt_y(tablet_event);

                    const tip_state = c.libinput_event_tablet_tool_get_tip_state(tablet_event);
                    const touching  = tip_state == c.LIBINPUT_TABLET_TOOL_TIP_DOWN;

                    std.debug.print(
                        "x={d:.4}  y={d:.4}  pressure={d:.4}  tilt=({d:.2},{d:.2})  tip={}\n",
                        .{ x, y, pressure, tilt_x, tilt_y, touching },
                    );
                },

                c.LIBINPUT_EVENT_DEVICE_ADDED => {
                    const device = c.libinput_event_get_device(event);
                    const name   = c.libinput_device_get_name(device);
                    std.debug.print(">> Dispositivo detectado: {s}\n", .{name});
                },

                c.LIBINPUT_EVENT_DEVICE_REMOVED => {
                    std.debug.print(">> Dispositivo removido\n", .{});
                },

                else => {},
            }
        }

        // Aguarda ~1ms para não queimar CPU em polling puro
        std.Thread.sleep(1 * std.time.ns_per_ms);
    }
}
