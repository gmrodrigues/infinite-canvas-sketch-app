const std = @import("std");

pub const BitMap = struct {
    width: u32,
    height: u32,
    data: []u8, // 1 bit por pixel, compactado. Rows are padded to 4-byte boundaries.
    
    pub fn init(width: u32, height: u32, allocator: std.mem.Allocator) !BitMap {
        const row_size = (width + 31) / 32 * 4; // Bytes por linha (alinhado a 32 bits / 4 bytes)
        const size = row_size * height;
        const data = try allocator.alloc(u8, size);
        @memset(data, 0xFF); // Começa branco (1 = branco em BMP monocromático, dependendo da paleta)
        return BitMap{
            .width = width,
            .height = height,
            .data = data,
        };
    }

    pub fn deinit(self: *BitMap, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn setPixel(self: *BitMap, x: u32, y: u32, black: bool) void {
        if (x >= self.width or y >= self.height) return;
        
        const row_size = (self.width + 31) / 32 * 4;
        // BMP armazena de baixo para cima (bottom-up) por padrão
        const reversed_y = self.height - 1 - y;
        const byte_idx = (reversed_y * row_size) + (x / 8);
        const bit_idx = 7 - (x % 8); // Bits são MSB first em 1-bit BMP

        if (black) {
            self.data[byte_idx] &= ~(@as(u8, 1) << @as(u3, @truncate(bit_idx)));
        } else {
            self.data[byte_idx] |= (@as(u8, 1) << @as(u3, @truncate(bit_idx)));
        }
    }

    pub fn drawLine(self: *BitMap, x0: f64, y0: f64, x1: f64, y1: f64) void {
        // Algoritmo de Bresenham simples
        var xi = @as(i32, @intFromFloat(@round(x0)));
        var yi = @as(i32, @intFromFloat(@round(y0)));
        const xf = @as(i32, @intFromFloat(@round(x1)));
        const yf = @as(i32, @intFromFloat(@round(y1)));

        const dx = @as(i32, @intCast(@abs(xf - xi)));
        const dy = @as(i32, @intCast(@abs(yf - yi)));
        const sx: i32 = if (xi < xf) 1 else -1;
        const sy: i32 = if (yi < yf) 1 else -1;
        var err = dx - dy;

        while (true) {
            if (xi >= 0 and xi < @as(i32, @intCast(self.width)) and yi >= 0 and yi < @as(i32, @intCast(self.height))) {
                self.setPixel(@as(u32, @intCast(xi)), @as(u32, @intCast(yi)), true);
            }
            if (xi == xf and yi == yf) break;
            const e2 = 2 * err;
            if (e2 > -dy) {
                err -= dy;
                xi += sx;
            }
            if (e2 < dx) {
                err += dx;
                yi += sy;
            }
        }
    }

    pub fn save(self: BitMap, filename: []const u8) !void {
        const file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();

        const row_size = (self.width + 31) / 32 * 4;
        const pixel_data_size = row_size * self.height;
        const file_size = 14 + 40 + 8 + pixel_data_size;

        // --- Bitmap File Header (14 bytes) ---
        try file.writeAll("BM");
        try file.writeAll(&std.mem.toBytes(@as(u32, file_size)));
        try file.writeAll(&std.mem.toBytes(@as(u16, 0))); // Reserved
        try file.writeAll(&std.mem.toBytes(@as(u16, 0))); // Reserved
        try file.writeAll(&std.mem.toBytes(@as(u32, 14 + 40 + 8))); // Offset

        // --- DIB Header (40 bytes) ---
        try file.writeAll(&std.mem.toBytes(@as(u32, 40)));
        try file.writeAll(&std.mem.toBytes(@as(i32, @intCast(self.width))));
        try file.writeAll(&std.mem.toBytes(@as(i32, @intCast(self.height))));
        try file.writeAll(&std.mem.toBytes(@as(u16, 1)));
        try file.writeAll(&std.mem.toBytes(@as(u16, 1)));
        try file.writeAll(&std.mem.toBytes(@as(u32, 0))); // Compression
        try file.writeAll(&std.mem.toBytes(@as(u32, pixel_data_size)));
        try file.writeAll(&std.mem.toBytes(@as(i32, 0)));
        try file.writeAll(&std.mem.toBytes(@as(i32, 0)));
        try file.writeAll(&std.mem.toBytes(@as(u32, 2)));
        try file.writeAll(&std.mem.toBytes(@as(u32, 0)));

        // --- Color Table ---
        try file.writeAll(&[_]u8{ 0, 0, 0, 0 }); // Black
        try file.writeAll(&[_]u8{ 255, 255, 255, 0 }); // White

        // --- Pixel Data ---
        try file.writeAll(self.data);
    }
};
