---
name: asset_pipeline_qoi
description: Pipeline de assets: QOI textures, YAML metadata, 8-direction sprites, conversão PNG→QOI.
version: 1.0
exported_from: qoi_asset_factory + doom_graphics_factory
---

# Asset Pipeline: QOI + YAML

**Propósito:** Definir fluxo de produção, conversão e carregamento de assets (texturas, sprites, metadados).

**Formatos:**
- **QOI** - Texturas (encode lossless, decode rápido)
- **YAML** - Metadados de objetos, configurações
- **PNG** - Source files (convertidos para QOI)

---

## 1. QOI Format

### 1.1 Por que QOI?

| Formato | Decode Speed | Size | Alpha |
|---------|--------------|------|-------|
| **QOI** | ~90 MB/s | Small | ✅ |
| PNG | ~30 MB/s | Smaller | ✅ |
| BMP | ~200 MB/s | Large | ❌ |
| TGA | ~150 MB/s | Large | ✅ |

**Vantagens:**
- Decode extremamente rápido (importante para runtime)
- Lossless compression
- Suporte alpha channel
- Simple implementation (~400 lines)

### 1.2 QOI Header

```zig
pub const QOIHeader = packed struct {
    magic: [4]u8,      // "qoif"
    width: u32,
    height: u32,
    channels: u8,      // 3 ou 4
    colorspace: u8,    // 0 = sRGB, 1 = linear
};
```

---

## 2. Directory Structure

```
assets/
├── game/
│   ├── env/
│   │   ├── wall.qoi          # 64x64 textura de parede
│   │   ├── floor.qoi         # 64x64 textura de chão
│   │   ├── ceiling.qoi       # 64x64 textura de teto
│   │   ├── grass.png         # → convertido para grass.qoi
│   │   └── tree.png          # → convertido para tree.qoi
│   │
│   ├── objects/
│   │   └── server/
│   │       ├── N.qoi         # Vista norte
│   │       ├── NE.qoi        # Vista nordeste
│   │       ├── E.qoi         # Vista leste
│   │       ├── SE.qoi        # Vista sudeste
│   │       ├── S.qoi         # Vista sul
│   │       ├── SW.qoi        # Vista sudoeste
│   │       ├── W.qoi         # Vista oeste
│   │       ├── NW.qoi        # Vista noroeste
│   │       ├── icon.qoi      # 16x16 para inventário
│   │       └── object.yaml   # Metadados
│   │
│   └── entities/
│       ├── player/
│       │   └── [...]
│       └── gremlin/
│           └── [...]
│
├── tools/
│   ├── icons/
│   │   ├── editor_icon.qoi
│   │   └── voxel_icon.qoi
│   └── mascots/
│       └── banana_01.qoi
│
└── ui/
    ├── buttons/
    │   ├── button_normal.qoi
    │   ├── button_hover.qoi
    │   └── button_pressed.qoi
    └── windows/
        └── window_frame.qoi
```

---

## 3. YAML Metadata Schema

### 3.1 Object Metadata

```yaml
# assets/game/objects/server/object.yaml
asset_name: server_rack
type: interactive_object
size:
  width: 64
  height: 64
pivot:
  x: 32
  y: 64  # Bottom center
collision_box:
  width: 48
  height: 48
  offset_x: 8
  offset_y: 16
directions:
  - N.qoi
  - NE.qoi
  - E.qoi
  - SE.qoi
  - S.qoi
  - SW.qoi
  - W.qoi
  - NW.qoi
icon: icon.qoi
flags:
  - pushable
  - destructible
  - interacts_with_electricity
interactions:
  - name: "Examine"
    icon: "magnifying_glass"
    action: "show_description"
  - name: "Push"
    icon: "hand"
    action: "apply_force"
```

### 3.2 Animation Metadata

```yaml
# assets/game/entities/player/walk/walk.yaml
asset_name: player_walk
type: animation
frame_count: 8
frame_duration_ms: 100
loop: true
directions:
  N:
    - N_00.qoi
    - N_01.qoi
    - N_02.qoi
    - N_03.qoi
    - N_04.qoi
    - N_05.qoi
    - N_06.qoi
    - N_07.qoi
  E:
    - E_00.qoi
    - E_01.qoi
    # ...
pivot:
  x: 32
  y: 64
```

---

## 4. PNG → QOI Conversion

### 4.1 AssetProxy Tool

```zig
// tools/asset_proxy.zig
const std = @import("std");
const qoi = @import("qoi");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    
    if (args.len < 3) {
        std.debug.print("Usage: asset_proxy <input.png> <output.qoi>\n", .{});
        return;
    }
    
    const input_path = args[1];
    const output_path = args[2];
    
    // Load PNG (usar stb_image ou similar)
    const image = try loadImage(allocator, input_path);
    defer image.deinit();
    
    // Encode QOI
    const qoi_data = try qoi.encode(allocator, image.pixels, image.width, image.height);
    defer allocator.free(qoi_data);
    
    // Write output
    var file = try std.fs.cwd().createFile(output_path, .{});
    defer file.close();
    
    try file.writeAll(qoi_data);
    
    std.debug.print("Converted: {s} → {s}\n", .{ input_path, output_path });
}

const Image = struct {
    pixels: []u8,
    width: u32,
    height: u32,
    
    pub fn deinit(self: *Image, allocator: std.mem.Allocator) void {
        allocator.free(self.pixels);
    }
};

fn loadImage(allocator: std.mem.Allocator, path: []const u8) !Image {
    // Implementar com stb_image ou chamar ImageMagick
    unreachable;
}
```

### 4.2 Batch Conversion Script

```bash
#!/bin/bash
# tools/batch_convert.sh

INPUT_DIR="assets/source_png"
OUTPUT_DIR="assets/game"

for png in "$INPUT_DIR"/**/*.png; do
    qoi="${png/$INPUT_DIR/$OUTPUT_DIR}"
    qoi="${qoi/.png/.qoi}"
    
    mkdir -p "$(dirname "$qoi")"
    ./zig-out/bin/asset_proxy "$png" "$qoi"
done
```

### 4.3 Cache System

```zig
pub const AssetCache = struct {
    cache_dir: []const u8,
    
    pub fn getCachePath(self: AssetCache, source_path: []const u8) []const u8 {
        // Hash do path source + timestamp
        // Se cache existe e é válido, usar cache
        // Senão, converter
        return ""; // Placeholder
    }
    
    pub fn isCacheValid(self: AssetCache, source_path: []const u8, cache_path: []const u8) bool {
        // Comparar timestamps
        return false; // Placeholder
    }
};
```

---

## 5. 8-Direction Sprite Convention

### 5.1 Naming

| Direção | Arquivo | Ângulo |
|---------|---------|--------|
| Norte | N.qoi | 0° |
| Nordeste | NE.qoi | 45° |
| Leste | E.qoi | 90° |
| Sudeste | SE.qoi | 135° |
| Sul | S.qoi | 180° |
| Sudoeste | SW.qoi | 225° |
| Oeste | W.qoi | 270° |
| Noroeste | NW.qoi | 315° |

### 5.2 Angle Calculation

```zig
pub fn getSpriteDirection(camera_pos: Vec2, entity_pos: Vec2) u8 {
    const dx = camera_pos.x - entity_pos.x;
    const dy = camera_pos.y - entity_pos.y;
    
    var angle = @atan2(dy, dx);
    if (angle < 0) angle += 2.0 * std.math.pi;
    
    const direction = @as(u8, @intFromFloat(
        (angle / (2.0 * std.math.pi)) * 8.0 + 0.5
    )) % 8;
    
    // Mapping: 0=N, 1=NE, 2=E, 3=SE, 4=S, 5=SW, 6=W, 7=NW
    const mapping = [_]u8{ 4, 5, 6, 7, 0, 1, 2, 3 };
    return mapping[direction];
}

pub fn directionToString(dir: u8) []const u8 {
    const names = [_][]const u8{ "N", "NE", "E", "SE", "S", "SW", "W", "NW" };
    return names[dir];
}
```

### 5.3 Generation Script (Python)

```python
# scripts/gen_metadata.py
import yaml
import os

def generate_metadata(asset_name, output_path):
    metadata = {
        'asset_name': asset_name,
        'type': 'interactive_object',
        'size': {'width': 64, 'height': 64},
        'pivot': {'x': 32, 'y': 64},
        'collision_box': {'width': 48, 'height': 48, 'offset_x': 8, 'offset_y': 16},
        'directions': ['N.qoi', 'NE.qoi', 'E.qoi', 'SE.qoi', 'S.qoi', 'SW.qoi', 'W.qoi', 'NW.qoi'],
        'icon': 'icon.qoi',
        'flags': ['pushable', 'destructible'],
    }
    
    with open(output_path, 'w') as f:
        yaml.dump(metadata, f, default_flow_style=False)

if __name__ == '__main__':
    import sys
    generate_metadata(sys.argv[1], sys.argv[2])
```

---

## 6. Loading em Runtime

### 6.1 Texture Manager

```zig
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
        
        // Load file
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        
        const qoi_data = try file.readToEndAlloc(self.allocator, 10 * 1024 * 1024);
        defer self.allocator.free(qoi_data);
        
        // Decode QOI
        const desc = qoi.decode(qoi_data) catch return error.InvalidQOI;
        
        // Create Image
        const image = rl.Image{
            .data = qoi_data.ptr,
            .width = @intCast(desc.width),
            .height = @intCast(desc.height),
            .mipmaps = 1,
            .format = rl.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8,
        };
        
        // Create Texture
        const texture = rl.LoadTextureFromImage(image);
        
        // Cache
        const path_copy = try self.allocator.dupe(u8, path);
        try self.textures.put(path_copy, texture);
        
        return texture;
    }
    
    pub fn loadSpriteSet(
        self: *TextureManager,
        base_path: []const u8,
    ) !SpriteSet {
        const directions = [_][]const u8{ "N", "NE", "E", "SE", "S", "SW", "W", "NW" };
        var textures: [8]rl.Texture2D = undefined;
        
        for (directions, 0..) |dir, i| {
            var path_buf: [256]u8 = undefined;
            const path = std.fmt.bufPrint(&path_buf, "{s}/{s}.qoi", .{ base_path, dir }) catch unreachable;
            textures[i] = try self.loadQOI(path);
        }
        
        // Load icon
        var icon_path_buf: [256]u8 = undefined;
        const icon_path = std.fmt.bufPrint(&icon_path_buf, "{s}/icon.qoi", .{base_path}) catch unreachable;
        const icon = try self.loadQOI(icon_path);
        
        return .{
            .directions = textures,
            .icon = icon,
        };
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

pub const SpriteSet = struct {
    directions: [8]rl.Texture2D,
    icon: rl.Texture2D,
};
```

### 6.2 YAML Parser (Simplificado)

```zig
pub const ObjectMetadata = struct {
    asset_name: []const u8,
    object_type: []const u8,
    width: u32,
    height: u32,
    pivot_x: u32,
    pivot_y: u32,
    collision_width: u32,
    collision_height: u32,
    flags: []const []const u8,
    
    pub fn load(allocator: std.mem.Allocator, path: []const u8) !ObjectMetadata {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        
        const yaml_data = try file.readToEndAlloc(allocator, 1024 * 1024);
        defer allocator.free(yaml_data);
        
        // Parser YAML simplificado (ou usar library)
        return parseYAML(allocator, yaml_data);
    }
    
    fn parseYAML(allocator: std.mem.Allocator, data: []const u8) !ObjectMetadata {
        // Implementar parser básico ou usar yaml library
        _ = allocator;
        _ = data;
        unreachable;
    }
};
```

---

## 7. Asset Budgets

| Tipo | Max Size | Count | Total |
|------|----------|-------|-------|
| **Textures (QOI)** | 256 KB | 100 | 25 MB |
| **Sprites 8-dir** | 64 KB each | 20 objects | 10 MB |
| **Icons** | 4 KB | 100 | 400 KB |
| **YAML Metadata** | 2 KB | 100 | 200 KB |
| **Total** | - | - | ~36 MB |

---

## 8. Checklist de Produção

### 8.1 Para Novos Assets

- [ ] Source PNG em resolução correta (64x64, 128x128, etc.)
- [ ] 8 direções renderizadas (se objeto)
- [ ] Icon 16x16 criado
- [ ] YAML metadata gerado (usar gen_metadata.py)
- [ ] Convertido para QOI (asset_proxy)
- [ ] Estrutura de diretórios correta
- [ ] Naming convention seguida

### 8.2 Para Animações

- [ ] Todos frames renderizados
- [ ] Naming: `[direction]_[frame].qoi`
- [ ] YAML com frame_count e frame_duration_ms
- [ ] Loop flag definida

---

## 9. Referências Cruzadas

Esta skill referencia:
- `style_guide_retro_fps` - Estética dos assets
- `tech_stack_zig_raylib` - Carregamento em Zig
- `game_mechanics_dod` - Uso de sprites em sistemas

É referenciada por:
- Todas as mecânicas que usam sprites
- Editores (Voxel Forge, Map Forge)

---

**Version**: 1.0  
**QOI Spec**: https://qoiformat.org/  
**License**: MIT
