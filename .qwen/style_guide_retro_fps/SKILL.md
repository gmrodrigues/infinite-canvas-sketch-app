---
name: style_guide_retro_fps
description: Guia de estilo para estética retro FPS 90s: paletas, resolução, scaling, UI, e constraints visuais.
version: 1.0
exported_from: doom_vibe_curator + doom_graphics_factory + nuklear_zui_standards
---

# Style Guide: Retro FPS 90s Aesthetic

**Propósito:** Definir padrões visuais para jogos com estética de FPS dos anos 90 (DOOM, Duke Nukem 3D, Wolfenstein 3D).

**Princípios Fundamentais:**
1. **Resolução Baixa é Feature** - 320x200 ou 640x400 interno
2. **Paleta Restrita** - 256 cores ou menos
3. **Integer Scaling** - Sem blur, sem anti-aliasing
4. **2.5D Puro** - Raycasting, sprites 8-direções, sem modelos 3D reais

---

## 1. Resolução e Scaling

### 1.1 Resoluções Internas

| Nome | Resolução | Aspect Ratio | Uso |
|------|-----------|--------------|-----|
| **Potato** | 320x200 | 16:10 | Engine principal (raycasting) |
| **Classic** | 640x400 | 16:10 | Editores, UI |
| **Enhanced** | 640x480 | 4:3 | Cutscenes, menus |

### 1.2 Scaling Rules

```zig
// ✅ CORRETO: Integer scaling
const scale: u32 = 3; // 320x200 → 960x600
const scaled_width = internal_width * scale;
const scaled_height = internal_height * scale;

// ❌ ERRADO: Scaling não-integer (causa blur)
const scale: f32 = 2.5; // NÃO FAZER ISSO
```

### 1.3 Window Configuration (Raylib)

```zig
pub const WindowConfig = struct {
    // Resolução interna (render target)
    internal_width: c_int = 320,
    internal_height: c_int = 200,
    
    // Resolução da janela (integer scaled)
    scale: c_int = 3,
    
    pub fn windowWidth(self: WindowConfig) c_int {
        return self.internal_width * self.scale;
    }
    
    pub fn windowHeight(self: WindowConfig) c_int {
        return self.internal_height * self.scale;
    }
    
    pub fn initWindow(self: WindowConfig, title: []const u8) void {
        rl.SetConfigFlags(rl.FLAG_VSYNC_HINT);
        rl.InitWindow(
            self.windowWidth(),
            self.windowHeight(),
            title.ptr,
        );
        rl.SetTargetFPS(60);
    }
};
```

---

## 2. Paletas de Cores

### 2.1 Corporate Cyan & Blood Red (Padrão do Projeto)

```yaml
# resources/color_palette.yaml
name: Corporate Grimdark
description: Paleta inspirada em ambientes corporativos dos anos 90 com toque distópico

colors:
  # Corporate Greyscale (4 tons)
  corporate_white: "#E8E8E8"
  corporate_grey_light: "#B0B0B0"
  corporate_grey_dark: "#606060"
  corporate_black: "#181818"
  
  # Primary Accent
  corporate_cyan: "#00FFFF"      # UI ativa, seleção
  doom_red: "#FF0000"            # Perigo, sangue, alerts
  error_yellow: "#FFFF00"        # Warnings, glitches
  innocence_green: "#00FF00"     // HUD, saúde, segurança
  
  # Environment
  wall_concrete: "#808080"
  wall_brick: "#8B4513"
  floor_tile: "#404040"
  ceiling_dark: "#303030"
  
  # Special Effects
  glitch_purple: "#8B00FF"
  possession_orange: "#FF8C00"
  ghost_blue: "#0080FF"

# Usage constraints
max_simultaneous_colors: 64     # Limite prático para estética 8-bit
ui_colors_max: 7                # Regra das 7 cores na UI
```

### 2.2 Loading Palette em Zig

```zig
pub const ColorPalette = struct {
    corporate_white: rl.Color = .{ .r = 232, .g = 232, .b = 232, .a = 255 },
    corporate_cyan: rl.Color = .{ .r = 0, .g = 255, .b = 255, .a = 255 },
    doom_red: rl.Color = .{ .r = 255, .g = 0, .b = 0, .a = 255 },
    // ... etc
    
    pub fn loadFromYAML(path: []const u8) !ColorPalette {
        // Implementar parser YAML ou usar hard-coded
        return .{}; // Placeholder
    }
};
```

---

## 3. UI Standards (90s Winamp/Windows 3.1)

### 3.1 Layout 4-Quadrantes

```
┌─────────────────────────────────────────────────────────────┐
│ UTILITY STRIP (40px)                                        │
│ [Menu] [Tools] [▼]                          [⏻] [◻] [X]    │
├──────────────────────┬──────────────────────────────────────┤
│                      │                                      │
│ PRIMARY VIEWPORT     │  WORKSPACE / EDITOR                  │
│ (3D View, Game)      │  (Properties, Lists, 2D Views)       │
│                      │                                      │
│                      │                                      │
├──────────────────────┴──────────────────────────────────────┤
│ CONTEXTUAL HUD / STATUS BAR (30px)                          │
│ [X: 123 Y: 456]  [FPS: 60]  [Entities: 42]  [💾] [⚙️]      │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Component Styles

#### Botões (90s Beveled)
```
┌──────────────┐  ← Light top/left (white 1px)
│   BUTTON     │  ← Dark bottom/right (black 1px)
└──────────────┘  ← Background: grey #B0B0B0
```

**Estados:**
- **Normal**: Cinza claro, texto preto
- **Hover**: Cinza mais claro, borda ciano 1px
- **Pressed**: Invertido (dark top/left, light bottom/right)
- **Disabled**: Cinza escuro, texto cinza médio

#### Janelas (Windows 3.1 Style)
```
┌─────────────────────────────────────────┐
│ ═ Title Bar (Blue #000080, White Text) ═│
├─────────────────────────────────────────┤
│                                         │
│  Content Area (White background)        │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

### 3.3 Fontes

| Uso | Fonte | Tamanho | Estilo |
|-----|-------|---------|--------|
| **UI Geral** | Bitmap 8x8 | 8px | Monospace |
| **Títulos** | Bitmap 8x8 | 16px (2x scale) | Bold |
| **HUD** | Bitmap 8x8 | 8px | Verde corporativo |
| **Menus** | Bitmap 8x8 | 8px | Branco/Cinza |

### 3.4 Translucidez

| Elemento | Opacidade | Uso |
|----------|-----------|-----|
| **Ghost/Preview** | 25-50% | Drag preview, placement ghost |
| **Selection Overlay** | 50% | Área selecionada |
| **Glitch Effects** | 75% | Distorções temporárias |
| **Shadow Pass** | 0% | UI é shadowless (sem sombras) |

---

## 4. Sprite Standards (8-Direction)

### 4.1 Naming Convention

```
assets/game/objects/[entity_name]/
├── N.qoi    ← Norte (frente)
├── NE.qoi   ← Nordeste
├── E.qoi    ← Leste (perfil)
├── SE.qoi   ← Sudeste
├── S.qoi    ← Sul (trás)
├── SW.qoi   ← Sudoeste
├── W.qoi    ← Oeste (perfil)
├── NW.qoi   ← Noroeste
├── icon.qoi ← 16x16 para inventário/mapa
└── object.yaml ← Metadados
```

### 4.2 Angle Calculation

```zig
pub fn getSpriteAngle(camera_pos: Vec2, entity_pos: Vec2) u32 {
    const dx = camera_pos.x - entity_pos.x;
    const dy = camera_pos.y - entity_pos.y;
    
    // Ângulo em radianos
    var angle = @atan2(dy, dx);
    
    // Normalizar para 0-2π
    if (angle < 0) angle += 2.0 * std.math.pi;
    
    // Converter para 8 direções (0-7)
    const direction = @as(u32, @intFromFloat(
        (angle / (2.0 * std.math.pi)) * 8.0 + 0.5
    )) % 8;
    
    // Mapear para convenção N, NE, E, SE, S, SW, W, NW
    const mapping = [_]u32{ 4, 5, 6, 7, 0, 1, 2, 3 };
    return mapping[direction];
}
```

### 4.3 Sprite Dimensions

| Tipo | Tamanho | Pivot |
|------|---------|-------|
| **Player** | 64x64 | Centro inferior |
| **Enemy (Gremlin)** | 48x48 | Centro inferior |
| **Object (Server)** | 64x64 | Centro inferior |
| **Pickup (Coffee)** | 32x32 | Centro |
| **Icon (Inventory)** | 16x16 | Centro |

---

## 5. Iluminação e Shading

### 5.1 Sector Lighting (Raycasting)

```zig
// 16 níveis de iluminação (0-15)
pub const LightLevel = enum(u4) {
    full = 15,
    bright = 12,
    normal = 8,
    dim = 4,
    dark = 2,
    pitch = 0,
};

pub fn applyLighting(base_color: rl.Color, level: LightLevel) rl.Color {
    const intensity = @as(f32, @floatFromInt(@intFromEnum(level))) / 15.0;
    
    return rl.Color{
        .r = @intFromFloat(@as(f32, @floatFromInt(base_color.r)) * intensity),
        .g = @intFromFloat(@as(f32, @floatFromInt(base_color.g)) * intensity),
        .b = @intFromFloat(@as(f32, @floatFromInt(base_color.b)) * intensity),
        .a = base_color.a,
    };
}
```

### 5.2 Palette Shading (Indexed Lighting)

Para engines que usam paleta indexada:
- Cada cor base tem 16 variantes (uma por nível de luz)
- Lookup table pré-computada
- Zero cálculo em runtime

---

## 6. Efeitos Visuais (Glitch & Retro)

### 6.1 Glitch Injection

```zig
pub fn applyGlitch(pixels: []u8, glitch_factor: f32) void {
    const rng = std.crypto.random;
    
    var i: usize = 0;
    while (i < pixels.len) : (i += 4) {
        // Random pixel glitch
        if (rng.float(f32) < glitch_factor) {
            // XOR com valor aleatório para efeito "corrupted"
            const xor_val = rng.intRangeAtMost(u8, 0, 50);
            pixels[i] ^= xor_val;     // R
            pixels[i + 1] ^= xor_val; // G
            pixels[i + 2] ^= xor_val; // B
        }
        
        // Scanline glitch (horizontal line)
        if (i % (pixels.len / 100) == 0) {
            const offset = rng.intRangeAtMost(usize, 0, 3);
            if (i + offset * 4 < pixels.len) {
                pixels[i + offset * 4] = 255; // R max
            }
        }
    }
}
```

### 6.2 Dithering (Floyd-Steinberg)

```zig
pub fn applyDithering(image: []u8, width: usize, height: usize) void {
    for (0..height) |y| {
        for (0..width) |x| {
            const idx = (y * width + x) * 4;
            const old_pixel = image[idx];
            
            // Quantizar para 4 níveis (2-bit)
            const new_pixel = @as(u8, @intFromFloat(
                @floor(@as(f32, @floatFromInt(old_pixel)) / 64.0) * 64.0
            ));
            
            const error = old_pixel - new_pixel;
            image[idx] = new_pixel;
            
            // Distribuir erro (Floyd-Steinberg)
            if (x + 1 < width) {
                image[(y * width + x + 1) * 4] +|= @intCast(error * 7 / 16);
            }
            if (y + 1 < height) {
                if (x > 0) {
                    image[((y + 1) * width + x - 1) * 4] +|= @intCast(error * 3 / 16);
                }
                image[((y + 1) * width + x) * 4] +|= @intCast(error * 5 / 16);
                if (x + 1 < width) {
                    image[((y + 1) * width + x + 1) * 4] +|= @intCast(error * 1 / 16);
                }
            }
        }
    }
}
```

### 6.3 CRT Scanlines (Post-processing)

```zig
// Fragment shader para CRT effect
const crt_scanline_fs = 
\\#version 330
\\in vec2 fragTexCoord;
\\in vec4 fragColor;
\\uniform sampler2D texture0;
\\out vec4 finalColor;
\\
\\void main() {
\\    vec4 color = texture(texture0, fragTexCoord);
\\    
\\    // Scanline
\\    float scanline = sin(fragTexCoord.y * 800.0) * 0.04;
\\    color.rgb -= scanline;
\\    
\\    // Vignette
\\    vec2 uv = fragTexCoord * 2.0 - 1.0;
\\    float vignette = 1.0 - dot(uv, uv) * 0.3;
\\    color.rgb *= vignette;
\\    
\\    finalColor = vec4(color.rgb, fragColor.a);
\\}
;
```

---

## 7. Modernisms Proibidos 🚫

| Modernism | Por que é Proibido | Alternativa Retro |
|-----------|-------------------|-------------------|
| **Anti-aliasing** | Suaviza pixels, perde estética | Pixel perfeito, integer scaling |
| **High-poly models** | Quebra estética 2.5D | Sprites 8-direções QOI |
| **PBR Materials** | Muito moderno, realista | Palette shading, texturas dithered |
| **16:9 Nativo** | Anacrônico para 320x200 | 4:3 ou 16:10 com letterbox |
| **Smooth Scrolling** | Muito "moderno" | Scroll em passos de pixel |
| **Fontes Vectoriais** | Muito limpas | Bitmap 8x8 |
| **Sombras Dinâmicas** | Complexo demais | Shadowless UI, baked lighting |
| **UI Translúcida Blur** | Efeito moderno | Translucidez sólida (sem blur) |
| **Particle Systems Complexos** | Muito moderno | Sprites animados simples |
| **HDR** | Anacrônico | LDR, paleta restrita |

---

## 8. Vibe Check Checklist

Antes de commitar, verifique:

### Visual
- [ ] Resolução interna é 320x200, 640x400 ou 640x480?
- [ ] Scaling é integer (2x, 3x, 4x)?
- [ ] Zero anti-aliasing?
- [ ] Paleta usa máximo 64-256 cores?
- [ ] UI parece Windows 3.1 / Winamp?
- [ ] Fontes são bitmap 8x8?

### Sprites
- [ ] Sprites são 8-direções?
- [ ] Naming convention seguida (N.qoi, NE.qoi, etc.)?
- [ ] Icon.qoi 16x16 existe para inventário?
- [ ] Pivot point é centro inferior?

### Efeitos
- [ ] Glitches são sutis (XOR, scanlines)?
- [ ] Dithering é Floyd-Steinberg ou similar?
- [ ] CRT effects são opcionais (toggle)?

### Performance
- [ ] Frame time < 16.67ms (60 FPS)?
- [ ] Sprites são QOI (não PNG em runtime)?
- [ ] Texturas são carregadas uma vez?

---

## 9. Exemplos de Assets

### 9.1 Estrutura de Diretórios

```
assets/
├── game/
│   ├── env/
│   │   ├── wall.qoi          # Textura de parede (64x64)
│   │   ├── floor.qoi         # Textura de chão (64x64)
│   │   ├── ceiling.qoi       # Textura de teto (64x64)
│   │   ├── grass.png         # Grama (convertida para QOI)
│   │   └── tree.png          # Árvore (convertida para QOI)
│   ├── objects/
│   │   ├── server/
│   │   │   ├── N.qoi
│   │   │   ├── NE.qoi
│   │   │   ├── E.qoi
│   │   │   ├── SE.qoi
│   │   │   ├── S.qoi
│   │   │   ├── SW.qoi
│   │   │   ├── W.qoi
│   │   │   ├── NW.qoi
│   │   │   ├── icon.qoi
│   │   │   └── object.yaml
│   │   └── coffee_machine/
│   │       └── [...]
│   └── entities/
│       ├── player/
│       │   └── [...]
│       └── gremlin/
│           └── [...]
├── tools/
│   ├── icons/
│   │   ├── editor_icon.qoi
│   │   └── voxel_icon.qoi
│   └── mascots/
│       └── banana_01.qoi
└── ui/
    ├── buttons/
    │   ├── button_normal.qoi
    │   ├── button_hover.qoi
    │   └── button_pressed.qoi
    └── windows/
        └── window_frame.qoi
```

### 9.2 YAML Metadata Template

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
```

---

## 10. Referências Cruzadas

Esta skill referencia:
- `workflow_orchestrator` - Workflow de desenvolvimento
- `tech_stack_zig_raylib` - Implementação técnica
- `asset_pipeline_qoi` - Pipeline de assets
- `game_mechanics_dod` - Mecânicas de jogo

É referenciada por:
- `editor_ui_standards` - UI de editores
- `doom_graphics_factory` - Produção de gráficos

---

**Version**: 1.0  
**Aesthetic Inspiration**: DOOM (1993), Duke Nukem 3D (1996), Wolfenstein 3D (1992)  
**License**: MIT
