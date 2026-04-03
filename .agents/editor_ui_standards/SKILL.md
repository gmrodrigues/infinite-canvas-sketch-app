---
name: editor_ui_standards
description: Padrões de UI/UX para editores internos: layout 4-quadrantes, componentes reutilizáveis, ZUI.
version: 1.0
exported_from: doom_editor_ui_standards + nuklear_zui_standards
---

# Editor UI Standards

**Propósito:** Definir padrões de interface para todos os editores internos (Map Forge, Voxel Forge, Asset Browser, etc.).

**Princípios:**
1. **Consistência** - Todos editores seguem mesma estrutura
2. **Reutilização** - Componentes do catálogo, não ad-hoc
3. **ZUI Ready** - Suporte a zoom/pan para viewports 3D
4. **90s Aesthetic** - Windows 3.1 / Winamp vibe

---

## 1. Layout 4-Quadrantes

```
┌─────────────────────────────────────────────────────────────────┐
│ UTILITY STRIP (40px)                                            │
│ [☰ Menu] [🛠 Tools ▼] [💾] [⚙️]                 [🔍] [⏻] [◻] [X]│
├──────────────────────┬──────────────────────────────────────────┤
│                      │                                          │
│ PRIMARY VIEWPORT     │  WORKSPACE / EDITOR                      │
│ (3D View, Game)      │  (Properties, Lists, 2D Views)           │
│                      │                                          │
│ • Orbit/pan/zoom     │  • Property panels                       │
│ • RenderTexture2D    │  • Asset lists                           │
│ • ZUI camera         │  • Layer controls                        │
│                      │                                          │
├──────────────────────┴──────────────────────────────────────────┤
│ CONTEXTUAL HUD / STATUS BAR (30px)                              │
│ [X: 123.45 Y: 678.90]  [FPS: 60]  [Layer: 3/6]  [💾] [⚙️]      │
└─────────────────────────────────────────────────────────────────┘
```

### 1.1 Dimensões

| Área | Altura/Largura | Conteúdo |
|------|----------------|----------|
| **Utility Strip** | 40px | Menu, tools, window controls |
| **Primary Viewport** | Flex | 3D view, game preview |
| **Workspace** | Flex | Properties, lists, editors |
| **Status Bar** | 30px | Coordinates, FPS, context |

### 1.2 Responsive Behavior

- Viewport mínimo: 320x240
- Workspace colapsável (botão no Utility Strip)
- Status bar mostra overflow menu se necessário

---

## 2. Component Catalog

### 2.1 Directional/Perspective Tiles

**Uso:** Preview de sprites 8-direções, tiles isométricos

```
┌─────┬─────┬─────┐
│  N  │ NE  │  E  │
├─────┼─────┼─────┤
│ SE  │  S  │ SW  │
├─────┼─────┼─────┤
│  W  │ NW  │ [3D]│
└─────┴─────┴─────┘
```

**Estados:**
- Normal: Borda branca 1px
- Selected: Borda ciano 2px
- Hover: Background mais claro

### 2.2 Contextual Control Rows

**Uso:** Toolbars contextuais

```
[Tool 1] [Tool 2] [Tool 3] | [Separator] | [Option A ▼] [Option B ▼]
```

**Padrões:**
- Ícones 16x16 + tooltip
- Separator vertical (linha cinza 1px)
- Dropdowns estilo Windows 3.1

### 2.3 Parameter Strips

**Uso:** Controles de propriedades

```
Label: ━━━━━━━━━━┫ 123.45 ┣━━━━━━━━━━
Slider: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Toggle: [✓] Enable Feature
Color:  [████] #FF0000
```

### 2.4 Palette Swatch

**Uso:** Seleção de cores/texturas

```
┌───┬───┬───┬───┬───┐
│███│███│███│███│███│
├───┼───┼───┼───┼───┤
│███│███│███│███│███│
└───┴───┴───┴───┴───┘
[+] Import  [🗑] Delete  [⬆️] [⬇️] Reorder
```

---

## 3. ZUI Camera (Zoomable User Interface)

### 3.1 Camera Abstraction

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

### 3.2 Input Handling

```zig
pub fn handleZUIInput(camera: *ZUICamera) void {
    // Zoom com scroll
    const scroll = rl.GetMouseWheelMove();
    if (scroll != 0) {
        const mouse_pos = rl.GetMousePosition();
        camera.zoomAt(.{
            .x = @floatFromInt(mouse_pos.x),
            .y = @floatFromInt(mouse_pos.y),
        }, scroll * 0.2);
    }
    
    // Pan com middle mouse
    if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_MIDDLE)) {
        const delta = rl.GetMouseDelta();
        camera.pan(.{
            .x = @floatFromInt(delta.x),
            .y = @floatFromInt(delta.y),
        });
    }
}
```

### 3.3 3D Viewport Integration

```zig
pub const Viewport3D = struct {
    render_texture: rl.RenderTexture2D,
    camera: ZUICamera,
    width: c_int,
    height: c_int,
    
    pub fn init(width: c_int, height: c_int) !Viewport3D {
        const texture = rl.LoadRenderTexture(width, height);
        if (texture.id == 0) return error.FailedToCreateRenderTexture;
        
        return .{
            .render_texture = texture,
            .camera = ZUICamera{},
            .width = width,
            .height = height,
        };
    }
    
    pub fn beginDraw(self: *Viewport3D) void {
        rl.BeginTextureMode(self.render_texture);
        rl.ClearBackground(rl.BLACK);
        // Setup 3D camera based on ZUI zoom
    }
    
    pub fn endDraw(self: *Viewport3D) void {
        rl.EndTextureMode();
    }
    
    pub fn drawToScreen(self: *Viewport3D, x: f32, y: f32, scale: f32) void {
        const source = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(self.width)),
            .height = @as(f32, @floatFromInt(-self.height)),
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
};
```

---

## 4. Style Guide

### 4.1 Cores

| Elemento | Cor | Hex |
|----------|-----|-----|
| **Background** | Dark Grey | #303030 |
| **Panel** | Medium Grey | #404040 |
| **Button Normal** | Light Grey | #B0B0B0 |
| **Button Hover** | Lighter Grey + Cyan border | #C0C0C0 + #00FFFF |
| **Button Pressed** | Inverted bevel | #808080 |
| **Text** | White/Black | #FFFFFF / #000000 |
| **Accent** | Corporate Cyan | #00FFFF |
| **Warning** | Error Yellow | #FFFF00 |
| **Danger** | Doom Red | #FF0000 |

### 4.2 Bevels (90s Style)

```
Button Normal:          Button Pressed:
┌──────────┐            └──────────┘
│  BUTTON  │            │  BUTTON  │
└──────────┘            ┌──────────┘
Light: top/left white   Dark: top/left black
Dark: bottom/right black Light: bottom/right white
```

### 4.3 Fonts

| Uso | Fonte | Tamanho |
|-----|-------|---------|
| **UI Geral** | Bitmap 8x8 | 8px |
| **Títulos** | Bitmap 8x8 | 16px (2x) |
| **Tooltips** | Bitmap 8x8 | 8px |
| **Coordinates** | Bitmap 8x8 | 8px, monospace |

---

## 5. Window Management (DOOM_OS_311 Style)

### 5.1 Window States

- **Normal**: Windowed, draggable
- **Minimized**: Snap-to-icon na utility strip
- **Maximized**: Full viewport
- **Closed**: Removed from manager

### 5.2 Dragging

```zig
pub const WindowManager = struct {
    windows: std.ArrayList(Window),
    active: ?usize,
    drag_offset: Vec2,
    
    pub fn beginDrag(self: *WindowManager, idx: usize, mouse_pos: Vec2) void {
        self.active = idx;
        self.drag_offset = .{
            .x = mouse_pos.x - self.windows.items[idx].x,
            .y = mouse_pos.y - self.windows.items[idx].y,
        };
    }
    
    pub fn updateDrag(self: *WindowManager, mouse_pos: Vec2) void {
        if (self.active) |idx| {
            self.windows.items[idx].x = mouse_pos.x - self.drag_offset.x;
            self.windows.items[idx].y = mouse_pos.y - self.drag_offset.y;
        }
    }
    
    pub fn endDrag(self: *WindowManager) void {
        self.active = null;
    }
};
```

### 5.3 Minimize Animation (Snap-to-Icon)

```zig
pub fn minimizeAnimation(window: *Window, icon_pos: Vec2) void {
    // Windows 3.1 style: instant snap, no animation
    window.x = icon_pos.x;
    window.y = icon_pos.y;
    window.width = 32;
    window.height = 32;
    window.state = .minimized;
}
```

---

## 6. Compliance Checklist

Antes de commitar UI nova:

- [ ] Usa layout 4-quadrantes
- [ ] Componentes do catálogo (não ad-hoc)
- [ ] Cores da paleta corporativa
- [ ] Fontes bitmap 8x8
- [ ] Bevels 90s style
- [ ] ZUI camera para viewports 3D
- [ ] Window dragging funcional
- [ ] Minimize snap-to-icon
- [ ] Zero modernisms (blur, shadows, etc.)

---

## 7. Referências Cruzadas

Esta skill referencia:
- `style_guide_retro_fps` - Estética geral
- `tech_stack_zig_raylib` - Nuklear, Raylib
- `workflow_orchestrator` - Workflow de features

É referenciada por:
- `editor_feature_workflow` - Features de editores
- Todos os editores (Map Forge, Voxel Forge, etc.)

---

**Version**: 1.0  
**Inspired By**: Windows 3.1, Winamp, early 3D editors  
**License**: MIT
