---
name: tech_stack_zig_raylib
description: Stack técnica para desenvolvimento de jogos: Zig, Raylib, Nuklear, SDL2, com foco em performance e estética retro.
version: 1.0
exported_from: rigorous_zig_dod + nuklear_zui_standards
---

# Tech Stack: Zig + Raylib + Nuklear + SDL2

**Propósito:** Definir padrões técnicos para desenvolvimento de jogos com foco em performance, controle de memória explícito e estética retro.

**Stack Alvo:**
- **Linguagem**: Zig 0.11+
- **Renderização**: Raylib 5.5.0 + SDL2
- **UI**: Nuklear (Immediate Mode GUI)
- **Audio**: Raylib audio + síntese procedural
- **Assets**: QOI (textures), YAML (metadata)

---

## 1. Zig Language Standards

### 1.1 Versão e Configuração

```zig
// build.zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // Usar Zig 0.11+ para comptime aprimorado
    const exe = b.addExecutable(.{
        .name = "game",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    
    // Link libraries
    exe.linkSystemLibrary("raylib");
    exe.linkSystemLibrary("SDL2");
}
```

### 1.2 Memory Management Patterns

#### Arena Allocator (Frame-based)
```zig
const std = @import("std");

pub const FrameAllocator = struct {
    arena: std.heap.ArenaAllocator,
    
    pub fn init() FrameAllocator {
        return .{
            .arena = std.heap.ArenaAllocator.init(std.heap.page_allocator),
        };
    }
    
    pub fn beginFrame(self: *FrameAllocator) *std.mem.Allocator {
        return &self.arena.allocator;
    }
    
    pub fn endFrame(self: *FrameAllocator) void {
        self.arena.reset();
    }
    
    pub fn deinit(self: *FrameAllocator) void {
        self.arena.deinit();
    }
};

// Uso:
var frame_alloc = FrameAllocator.init();
defer frame_alloc.deinit();

while (!should_quit) {
    const alloc = frame_alloc.beginFrame();
    defer frame_alloc.endFrame();
    
    // Usar alloc para memória temporária do frame
    const temp_data = try alloc.alloc(u8, 1024);
}
```

#### General Purpose Allocator (Persistent)
```zig
pub const Game = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}),
    entities: std.ArrayList(Entity),
    
    pub fn init() Game {
        return .{
            .gpa = std.heap.GeneralPurposeAllocator(.{}),
            .entities = std.ArrayList(Entity).init(std.heap.page_allocator),
        };
    }
    
    pub fn deinit(self: *Game) void {
        self.entities.deinit();
        _ = self.gpa.deinit();
    }
};
```

#### Pool Allocator (Entidades Efêmeras)
```zig
pub const EntityPool = struct {
    const PoolSize = 1024;
    
    positions: [PoolSize]Vec3,
    velocities: [PoolSize]Vec3,
    health: [PoolSize]f32,
    active: [PoolSize]bool,
    free_list: std.ArrayList(u32),
    
    pub fn init(allocator: std.mem.Allocator) EntityPool {
        var pool = EntityPool{
            .positions = undefined,
            .velocities = undefined,
            .health = undefined,
            .active = undefined,
            .free_list = std.ArrayList(u32).init(allocator),
        };
        
        // Initialize all as inactive
        for (0..PoolSize) |i| {
            pool.active[i] = false;
            pool.free_list.append(@intCast(i)) catch unreachable;
        }
        
        return pool;
    }
    
    pub fn spawn(self: *EntityPool) ?u32 {
        if (self.free_list.pop()) |idx| {
            self.active[idx] = true;
            self.positions[idx] = .{ .x = 0, .y = 0, .z = 0 };
            self.velocities[idx] = .{ .x = 0, .y = 0, .z = 0 };
            self.health[idx] = 100.0;
            return idx;
        }
        return null; // Pool full
    }
    
    pub fn despawn(self: *EntityPool, idx: u32) void {
        self.active[idx] = false;
        self.free_list.append(idx) catch unreachable;
    }
};
```

### 1.3 Data-Oriented Design (SoA)

```zig
// ❌ WRONG: Array of Structures (AoS)
pub const Gremlin = struct {
    position: Vec3,
    velocity: Vec3,
    health: f32,
    state: EntityState,
};

pub const GremlinBatch = struct {
    gremlins: []Gremlin, // Cache-unfriendly!
};

// ✅ CORRECT: Structure of Arrays (SoA)
pub const GremlinBatch = struct {
    positions: []Vec3,    // Cache-friendly sequential access
    velocities: []Vec3,
    health: []f32,
    states: []EntityState,
    
    pub fn updatePhysics(self: *GremlinBatch, dt: f32) void {
        // Sequential memory access = cache friendly
        for (0..self.positions.len) |i| {
            if (self.health[i] > 0) {
                self.positions[i] = self.positions[i].add(
                    self.velocities[i].scale(dt)
                );
            }
        }
    }
    
    pub fn init(allocator: std.mem.Allocator, count: usize) !GremlinBatch {
        return .{
            .positions = try allocator.alloc(Vec3, count),
            .velocities = try allocator.alloc(Vec3, count),
            .health = try allocator.alloc(f32, count),
            .states = try allocator.alloc(EntityState, count),
        };
    }
    
    pub fn deinit(self: *GremlinBatch, allocator: std.mem.Allocator) void {
        allocator.free(self.positions);
        allocator.free(self.velocities);
        allocator.free(self.health);
        allocator.free(self.states);
    }
};
```

### 1.4 Comptime Magic

```zig
// Compile-time lookup table
pub const DamageTable = struct {
    values: [256]f32,
    
    pub fn init() DamageTable {
        var table = DamageTable{ .values = undefined };
        var i: usize = 0;
        while (i < 256) : (i += 1) {
            table.values[i] = @as(f32, @floatFromInt(i)) / 255.0 * 100.0;
        }
        return table;
    }
};

// Comptime type-safe enum to int
pub fn enumToInt(comptime E: type, value: E) comptime_int {
    return @intFromEnum(value);
}

// Comptime string mixing for asset paths
pub fn assetPath(comptime name: []const u8) []const u8 {
    return "assets/" ++ name ++ ".qoi";
}
```

### 1.5 Anti-Patterns (NUNCA FAÇA)

```zig
// ❌ NUNCA: page_allocator em loops
fn badFunction() void {
    for (items) |item| {
        const data = std.heap.page_allocator.alloc(u8, 1024); // LEAK!
    }
}

// ❌ NUNCA: Global allocator implícito
var global_data: []u8 = undefined; // Sem owner claro!

// ❌ NUNCA: Deep call stacks com alocações
fn level1() void {
    const a = allocator.alloc(u8, 100);
    level2(); // Quem dealoca?
}

// ✅ SEMPRE: Explicit allocation ownership
fn goodFunction(allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    
    const alloc = arena.allocator();
    const data = try alloc.alloc(u8, 1024);
    // Auto-freed when arena.deinit() called
}
```

---

## 2. Raylib Integration

### 2.1 Setup Básico

```zig
const rl = @import("raylib");

pub const GameWindow = struct {
    width: c_int,
    height: c_int,
    title: []const u8,
    
    pub fn init(self: *GameWindow) void {
        rl.SetConfigFlags(rl.FLAG_VSYNC_HINT);
        rl.InitWindow(self.width, self.height, self.title.ptr);
        rl.SetTargetFPS(60);
    }
    
    pub fn shouldClose(self: GameWindow) bool {
        return rl.WindowShouldClose();
    }
    
    pub fn deinit(self: GameWindow) void {
        rl.CloseWindow();
    }
};
```

### 2.2 RenderTexture2D (Off-screen Rendering)

```zig
pub const ViewportRenderer = struct {
    render_texture: rl.RenderTexture2D,
    width: c_int,
    height: c_int,
    
    pub fn init(width: c_int, height: c_int) !ViewportRenderer {
        const texture = rl.LoadRenderTexture(width, height);
        if (texture.id == 0) return error.FailedToCreateRenderTexture;
        
        return .{
            .render_texture = texture,
            .width = width,
            .height = height,
        };
    }
    
    pub fn beginDraw(self: *ViewportRenderer) void {
        rl.BeginTextureMode(self.render_texture);
        rl.ClearBackground(rl.BLACK);
    }
    
    pub fn endDraw(self: *ViewportRenderer) void {
        rl.EndTextureMode();
    }
    
    pub fn drawToScreen(self: ViewportRenderer, x: f32, y: f32, scale: f32) void {
        const source = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(self.width)),
            .height = @as(f32, @floatFromInt(-self.height)), // Flip Y
        };
        
        const dest = rl.Rectangle{
            .x = x,
            .y = y,
            .width = @as(f32, @floatFromInt(self.width)) * scale,
            .height = @as(f32, @floatFromInt(self.height)) * scale,
        };
        
        rl.DrawTexturePro(
            self.render_texture.texture,
            source,
            dest,
            .{ .x = 0, .y = 0 },
            0.0,
            rl.WHITE,
        );
    }
    
    pub fn deinit(self: *ViewportRenderer) void {
        rl.UnloadRenderTexture(self.render_texture);
    }
};
```

### 2.3 Camera 3D (Para Editores)

```zig
pub const EditorCamera = struct {
    camera: rl.Camera3D,
    speed: f32 = 5.0,
    sensitivity: f32 = 0.1,
    
    pub fn init() EditorCamera {
        return .{
            .camera = rl.Camera3D{
                .position = .{ .x = 10, .y = 10, .z = 10 },
                .target = .{ .x = 0, .y = 0, .z = 0 },
                .up = .{ .x = 0, .y = 1, .z = 0 },
                .fovy = 45.0,
                .projection = rl.CAMERA_PERSPECTIVE,
            },
        };
    }
    
    pub fn update(self: *EditorCamera) void {
        // Orbit controls
        if (rl.IsKeyDown(rl.KEY_W)) {
            self.camera.position.y += self.speed * rl.GetFrameTime();
        }
        if (rl.IsKeyDown(rl.KEY_S)) {
            self.camera.position.y -= self.speed * rl.GetFrameTime();
        }
        
        // Mouse look (simple version)
        const mouse_delta = rl.GetMouseDelta();
        self.camera.target.x += mouse_delta.x * self.sensitivity;
        self.camera.target.y -= mouse_delta.y * self.sensitivity;
    }
};
```

---

## 3. Nuklear GUI (Immediate Mode)

### 3.1 Setup Básico

```zig
const nk = @import("nuklear");

pub const GuiContext = struct {
    ctx: *nk.Context,
    
    pub fn init() !GuiContext {
        const ctx = nk.nk_create_context(null);
        if (ctx == null) return error.FailedToCreateNuklearContext;
        
        return .{ .ctx = ctx.? };
    }
    
    pub fn beginFrame(self: *GuiContext, width: c_int, height: c_int) void {
        _ = nk.nk_begin(
            self.ctx,
            "Window",
            nk.nk_rect(0, 0, @floatFromInt(width), @floatFromInt(height)),
            nk.NK_WINDOW_BACKGROUND,
        );
    }
    
    pub fn endFrame(self: *GuiContext) void {
        nk.nk_end(self.ctx);
    }
    
    pub fn deinit(self: *GuiContext) void {
        nk.nk_free(self.ctx);
    }
};
```

### 3.2 ZUI Camera Abstraction

```zig
pub const ZUICamera = struct {
    position: Vec2,
    zoom: f32 = 1.0,
    min_zoom: f32 = 0.1,
    max_zoom: f32 = 10.0,
    
    pub fn worldToScreen(self: ZUICamera, world: Vec2) Vec2 {
        return .{
            .x = (world.x - self.position.x) * self.zoom,
            .y = (world.y - self.position.y) * self.zoom,
        };
    }
    
    pub fn screenToWorld(self: ZUICamera, screen: Vec2) Vec2 {
        return .{
            .x = (screen.x / self.zoom) + self.position.x,
            .y = (screen.y / self.zoom) + self.position.y,
        };
    }
    
    pub fn zoomAt(self: *ZUICamera, screen_pos: Vec2, delta: f32) void {
        const world_pos = self.screenToWorld(screen_pos);
        const new_zoom = @clamp(self.zoom + delta, self.min_zoom, self.max_zoom);
        
        self.position.x = world_pos.x - (screen_pos.x / new_zoom);
        self.position.y = world_pos.y - (screen_pos.y / new_zoom);
        self.zoom = new_zoom;
    }
    
    pub fn pan(self: *ZUICamera, delta: Vec2) void {
        self.position.x -= delta.x / self.zoom;
        self.position.y -= delta.y / self.zoom;
    }
};
```

---

## 4. SDL2 Integration (Engine Core)

### 4.1 Window & Input

```zig
const sdl = @import("sdl");

pub const SDLWindow = struct {
    window: *sdl.SDL_Window,
    renderer: *sdl.SDL_Renderer,
    
    pub fn init(title: []const u8, width: c_int, height: c_int) !SDLWindow {
        try sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
        
        const window = sdl.SDL_CreateWindow(
            title.ptr,
            sdl.SDL_WINDOWPOS_CENTERED,
            sdl.SDL_WINDOWPOS_CENTERED,
            width,
            height,
            sdl.SDL_WINDOW_SHOWN,
        ) orelse return error.FailedToCreateWindow;
        
        const renderer = sdl.SDL_CreateRenderer(
            window,
            -1,
            sdl.SDL_RENDERER_ACCELERATED | sdl.SDL_RENDERER_PRESENTVSYNC,
        ) orelse return error.FailedToCreateRenderer;
        
        return .{
            .window = window,
            .renderer = renderer,
        };
    }
    
    pub fn pollEvents(self: SDLWindow) sdl.SDL_Event {
        var event: sdl.SDL_Event = undefined;
        _ = sdl.SDL_PollEvent(&event);
        return event;
    }
    
    pub fn deinit(self: SDLWindow) void {
        sdl.SDL_DestroyRenderer(self.renderer);
        sdl.SDL_DestroyWindow(self.window);
        sdl.SDL_Quit();
    }
};
```

---

## 5. QOI Asset Pipeline

### 5.1 Carregamento de Texturas

```zig
const qoi = @import("qoi");

pub const TextureManager = struct {
    textures: std.AutoHashMap([]const u8, rl.Texture2D),
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) TextureManager {
        return .{
            .textures = std.AutoHashMap([]const u8, rl.Texture2D).init(allocator),
            .allocator = allocator,
        };
    }
    
    pub fn loadQOI(self: *TextureManager, path: []const u8) !rl.Texture2D {
        // Check cache
        if (self.textures.get(path)) |cached| {
            return cached;
        }
        
        // Load QOI file
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        
        const qoi_data = try file.readToEndAlloc(self.allocator, 10 * 1024 * 1024);
        defer self.allocator.free(qoi_data);
        
        const desc = qoi.decode(qoi_data) catch return error.InvalidQOI;
        
        // Create Raylib texture
        const image = rl.Image{
            .data = qoi_data.ptr,
            .width = @intCast(desc.width),
            .height = @intCast(desc.height),
            .mipmaps = 1,
            .format = rl.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8,
        };
        
        const texture = rl.LoadTextureFromImage(image);
        try self.textures.put(try self.allocator.dupe(u8, path), texture);
        
        return texture;
    }
    
    pub fn deinit(self: *TextureManager) void {
        var it = self.textures.iterator();
        while (it.next()) |entry| {
            rl.UnloadTexture(entry.value_ptr.*);
            self.allocator.free(entry.key_ptr.*);
        }
        self.textures.deinit();
    }
};
```

---

## 6. Audio System (Síntese Procedural)

### 6.1 Waveform Generation

```zig
pub const AudioSynth = struct {
    sample_rate: u32 = 44100,
    bits: u32 = 16,
    
    pub fn generateSine(
        allocator: std.mem.Allocator,
        frequency: f32,
        duration: f32,
        amplitude: f32,
    ) ![]i16 {
        const samples = @as(usize, @intFromFloat(duration * 44100.0));
        const buffer = try allocator.alloc(i16, samples);
        
        for (0..samples) |i| {
            const t = @as(f32, @floatFromInt(i)) / 44100.0;
            const value = @sin(2.0 * std.math.pi * frequency * t) * amplitude;
            buffer[i] = @intFromFloat(value * 32767.0);
        }
        
        return buffer;
    }
    
    pub fn generateSquare(
        allocator: std.mem.Allocator,
        frequency: f32,
        duration: f32,
        amplitude: f32,
    ) ![]i16 {
        const samples = @as(usize, @intFromFloat(duration * 44100.0));
        const buffer = try allocator.alloc(i16, samples);
        
        const period = @as(f32, 44100.0) / frequency;
        
        for (0..samples) |i| {
            const t = @mod(@as(f32, @floatFromInt(i)), period);
            const value = if (t < period / 2.0) amplitude else -amplitude;
            buffer[i] = @intFromFloat(value * 32767.0);
        }
        
        return buffer;
    }
};
```

---

## 7. Build System (build.zig)

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // Main game executable
    const exe = b.addExecutable(.{
        .name = "tlc_at_doom",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    
    // Link system libraries
    exe.linkSystemLibrary("raylib");
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("m"); // Math library
    
    // Link Nuklear (compile C file)
    const nuklear = b.addStaticLibrary(.{
        .name = "nuklear",
        .target = target,
        .optimize = optimize,
    });
    nuklear.addCSourceFile(.{
        .file = .{ .path = "vendor/nuklear/nuklear.c" },
        .flags = &.{},
    });
    exe.linkLibrary(nuklear);
    
    // Install
    b.installArtifact(exe);
    
    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    
    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
    
    // POC executables
    const poc_steps = .{
        .{ .name = "grass", .path = "src/grass_poc.zig" },
        .{ .name = "area", .path = "src/area_poc.zig" },
        .{ .name = "vector", .path = "src/vector_poc.zig" },
    };
    
    inline for (poc_steps) |poc| {
        const poc_exe = b.addExecutable(.{
            .name = "tlc_" ++ poc.name ++ "_poc",
            .root_source_file = .{ .path = poc.path },
            .target = target,
            .optimize = optimize,
        });
        poc_exe.linkSystemLibrary("raylib");
        b.installArtifact(poc_exe);
        
        const poc_run = b.addRunArtifact(poc_exe);
        const poc_step = b.step("run-" ++ poc.name ++ "-poc", "Run " ++ poc.name ++ " POC");
        poc_step.dependOn(&poc_run.step);
    }
}
```

---

## 8. Performance Guidelines

### 8.1 Budgets por Frame (60 FPS)

| System | Budget | Notes |
|--------|--------|-------|
| **Logic Update** | < 4ms | DOD, cache-friendly |
| **Render** | < 8ms | Batch draws, minimal state changes |
| **Audio** | < 2ms | Procedural, pre-computed buffers |
| **Input** | < 1ms | Poll once per frame |
| **Total** | < 16.67ms | 60 FPS target |

### 8.2 Memory Budgets

| Allocator | Budget | Reset |
|-----------|--------|-------|
| **Frame Arena** | 10 MB | Every frame |
| **Persistent GPA** | 100 MB | Game lifetime |
| **Entity Pool** | 5 MB | Level lifetime |

### 8.3 Asset Budgets

| Asset Type | Max Size | Count | Total |
|------------|----------|-------|-------|
| **Textures (QOI)** | 256 KB | 100 | 25 MB |
| **Audio (WAV)** | 100 KB | 50 | 5 MB |
| **Maps** | 1 MB | 10 | 10 MB |

---

## 9. Debug Tools

### 9.1 Memory Profiler

```zig
pub const MemoryProfiler = struct {
    allocations: usize = 0,
    deallocations: usize = 0,
    bytes_allocated: usize = 0,
    
    pub fn recordAlloc(self: *MemoryProfiler, bytes: usize) void {
        self.allocations += 1;
        self.bytes_allocated += bytes;
    }
    
    pub fn recordDealloc(self: *MemoryProfiler, bytes: usize) void {
        self.deallocations += 1;
        self.bytes_allocated -|= bytes;
    }
    
    pub fn printReport(self: MemoryProfiler) void {
        std.debug.print("=== Memory Profile ===\n", .{});
        std.debug.print("Allocations: {}\n", .{self.allocations});
        std.debug.print("Deallocations: {}\n", .{self.deallocations});
        std.debug.print("Leaked bytes: {}\n", .{self.bytes_allocated});
        std.debug.print("===================\n", .{});
    }
};
```

### 9.2 Frame Time Tracker

```zig
pub const FrameTimer = struct {
    times: [60]f64 = [_]f64{0} ** 60,
    index: usize = 0,
    
    pub fn record(&mut self, time: f64) void {
        self.times[self.index] = time;
        self.index = (self.index + 1) % 60;
    }
    
    pub fn average(self: FrameTimer) f64 {
        var sum: f64 = 0;
        for (self.times) |t| {
            sum += t;
        }
        return sum / 60.0;
    }
    
    pub fn printFPS(self: FrameTimer) void {
        const avg_ms = self.average() * 1000.0;
        const fps = 1.0 / self.average();
        std.debug.print("FPS: {d:.1} (Frame: {d:.2}ms)\n", .{ fps, avg_ms });
    }
};
```

---

## 10. Referências Cruzadas

Esta skill referencia:
- `workflow_orchestrator` - Workflow de desenvolvimento
- `style_guide_retro_fps` - Estética visual
- `game_mechanics_dod` - Implementação de mecânicas
- `asset_pipeline_qoi` - Pipeline de assets

É referenciada por:
- Todas as skills técnicas

---

**Version**: 1.0  
**Compatible With**: Zig 0.11+, Raylib 5.5.0, Nuklear ~4.10  
**License**: MIT
