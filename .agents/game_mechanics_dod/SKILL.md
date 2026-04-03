---
name: game_mechanics_dod
description: Implementação de mecânicas de jogo usando Data-Oriented Design (DOD), SoA, e sistemas separados.
version: 1.0
exported_from: game_mechanics_logic + rigorous_zig_dod
---

# Game Mechanics: Data-Oriented Design

**Propósito:** Definir padrões para implementação de mecânicas de jogo usando DOD, SoA, e arquitetura baseada em sistemas.

**Princípios:**
1. **Data Layout First** - Como dados são organizados determina performance
2. **Systems Over Objects** - Lógica em sistemas, não em objetos
3. **Stateless Logic** - Funções puras sempre que possível
4. **Explicit Memory** - Sem alocações implícitas

---

## 1. Entity Component System (ECS) Simplificado

### 1.1 Estrutura SoA

```zig
pub const EntityBatch = struct {
    // Components (SoA)
    positions: []Vec3,
    velocities: []Vec3,
    health: []f32,
    max_health: []f32,
    states: []EntityState,
    directions: []u8,
    
    // Metadata
    active: []bool,
    tags: []EntityTag,
    
    count: usize,
    capacity: usize,
    
    pub fn init(allocator: std.mem.Allocator, capacity: usize) !EntityBatch {
        return .{
            .positions = try allocator.alloc(Vec3, capacity),
            .velocities = try allocator.alloc(Vec3, capacity),
            .health = try allocator.alloc(f32, capacity),
            .max_health = try allocator.alloc(f32, capacity),
            .states = try allocator.alloc(EntityState, capacity),
            .directions = try allocator.alloc(u8, capacity),
            .active = try allocator.alloc(bool, capacity),
            .tags = try allocator.alloc(EntityTag, capacity),
            .count = 0,
            .capacity = capacity,
        };
    }
    
    pub fn deinit(self: *EntityBatch, allocator: std.mem.Allocator) void {
        allocator.free(self.positions);
        allocator.free(self.velocities);
        allocator.free(self.health);
        allocator.free(self.max_health);
        allocator.free(self.states);
        allocator.free(self.directions);
        allocator.free(self.active);
        allocator.free(self.tags);
    }
    
    pub fn spawn(self: *EntityBatch) ?usize {
        if (self.count >= self.capacity) return null;
        
        const idx = self.count;
        self.active[idx] = true;
        self.positions[idx] = .{ .x = 0, .y = 0, .z = 0 };
        self.velocities[idx] = .{ .x = 0, .y = 0, .z = 0 };
        self.health[idx] = 100.0;
        self.max_health[idx] = 100.0;
        self.states[idx] = .normal;
        self.directions[idx] = 0;
        self.tags[idx] = .none;
        
        self.count += 1;
        return idx;
    }
    
    pub fn despawn(self: *EntityBatch, idx: usize) void {
        self.active[idx] = false;
        // Swap-with-remove para manter array compact
        if (idx < self.count - 1) {
            self.swap(idx, self.count - 1);
        }
        self.count -= 1;
    }
    
    fn swap(self: *EntityBatch, a: usize, b: usize) void {
        std.mem.swap(Vec3, &self.positions[a], &self.positions[b]);
        std.mem.swap(Vec3, &self.velocities[a], &self.velocities[b]);
        std.mem.swap(f32, &self.health[a], &self.health[b]);
        std.mem.swap(f32, &self.max_health[a], &self.max_health[b]);
        std.mem.swap(EntityState, &self.states[a], &self.states[b]);
        std.mem.swap(u8, &self.directions[a], &self.directions[b]);
        std.mem.swap(bool, &self.active[a], &self.active[b]);
        std.mem.swap(EntityTag, &self.tags[a], &self.tags[b]);
    }
};
```

### 1.2 Entity Types

```zig
pub const EntityType = enum {
    player,
    enemy_gremlin,
    npc_intern,
    object_server,
    object_coffee_machine,
    pickup_health,
    pickup_ammo,
    projectile,
    particle,
};

pub const EntityState = enum {
    normal,
    possessed,
    glitched,
    unconscious,
    dead,
};

pub const EntityTag = enum {
    none,
    pushable,
    destructible,
    interactive,
    quest_item,
};
```

---

## 2. Systems

### 2.1 Movement System

```zig
pub const MovementSystem = struct {
    pub fn update(
        batch: *EntityBatch,
        dt: f32,
        bounds: MapBounds,
    ) void {
        for (0..batch.count) |i| {
            if (!batch.active[i]) continue;
            if (batch.states[i] == .dead) continue;
            
            // Apply velocity
            batch.positions[i].x += batch.velocities[i].x * dt;
            batch.positions[i].y += batch.velocities[i].y * dt;
            
            // Apply friction
            batch.velocities[i].x *= 0.95;
            batch.velocities[i].y *= 0.95;
            
            // Map bounds collision
            if (!bounds.contains(batch.positions[i])) {
                batch.velocities[i].x *= -1;
                batch.velocities[i].y *= -1;
                batch.positions[i] = bounds.clamp(batch.positions[i]);
            }
        }
    }
};
```

### 2.2 Combat System

```zig
pub const CombatSystem = struct {
    pub fn applyDamage(
        batch: *EntityBatch,
        target_idx: usize,
        damage: f32,
        damage_type: DamageType,
    ) DamageResult {
        if (!batch.active[target_idx]) return .miss;
        if (batch.states[target_idx] == .dead) return .miss;
        
        const old_health = batch.health[target_idx];
        batch.health[target_idx] -= damage;
        
        // Check death
        if (batch.health[target_idx] <= 0) {
            batch.health[target_idx] = 0;
            batch.states[target_idx] = .dead;
            return .killed;
        }
        
        // State transitions based on damage type
        switch (damage_type) {
            .exorcism => {
                if (batch.states[target_idx] == .possessed) {
                    batch.states[target_idx] = .unconscious;
                    return .exorcised;
                }
            },
            .glitch => {
                batch.states[target_idx] = .glitched;
            },
            else => {},
        }
        
        return .hit;
    }
    
    pub fn heal(
        batch: *EntityBatch,
        target_idx: usize,
        amount: f32,
    ) void {
        if (!batch.active[target_idx]) return;
        
        batch.health[target_idx] = @min(
            batch.health[target_idx] + amount,
            batch.max_health[target_idx],
        );
        
        if (batch.states[target_idx] == .unconscious) {
            batch.states[target_idx] = .normal;
        }
    }
};

pub const DamageType = enum {
    physical,
    exorcism,
    glitch,
    environmental,
};

pub const DamageResult = enum {
    miss,
    hit,
    killed,
    exorcised,
};
```

### 2.3 Direction System (8-way sprites)

```zig
pub const DirectionSystem = struct {
    pub fn updateDirection(
        entity_pos: Vec2,
        camera_pos: Vec2,
    ) u8 {
        const dx = camera_pos.x - entity_pos.x;
        const dy = camera_pos.y - entity_pos.y;
        
        // 8-direction calculation
        const angle = @atan2(dy, dx);
        const normalized = if (angle < 0) angle + 2.0 * std.math.pi else angle;
        
        // 8 directions: 0=N, 1=NE, 2=E, 3=SE, 4=S, 5=SW, 6=W, 7=NW
        const direction = @as(u8, @intFromFloat(
            (normalized / (2.0 * std.math.pi)) * 8.0 + 0.5
        )) % 8;
        
        // Remap to art convention
        const mapping = [_]u8{ 4, 5, 6, 7, 0, 1, 2, 3 };
        return mapping[direction];
    }
    
    pub fn getSpritePath(
        base_path: []const u8,
        direction: u8,
        allocator: std.mem.Allocator,
    ) ![]u8 {
        const names = [_][]const u8{
            "N", "NE", "E", "SE", "S", "SW", "W", "NW",
        };
        
        return std.fmt.allocPrint(
            allocator,
            "{s}/{s}.qoi",
            .{ base_path, names[direction] },
        );
    }
};
```

---

## 3. Player Controller

### 3.1 FPS Movement (WASD + Mouse)

```zig
pub const PlayerController = struct {
    position: Vec2,
    direction: f32, // Radians
    plane: Vec2,    // Camera plane para raycasting
    
    move_speed: f32 = 5.0,
    rot_speed: f32 = 3.0,
    
    pub fn init(start_pos: Vec2) PlayerController {
        return .{
            .position = start_pos,
            .direction = 0.0,
            .plane = .{ .x = 0, .y = 0.66 }, // 66 degree FOV
        };
    }
    
    pub fn update(
        self: *PlayerController,
        dt: f32,
        map: *const GameMap,
    ) void {
        // Rotation (mouse)
        const mouse_delta = rl.GetMouseDelta().x;
        self.direction += mouse_delta * self.rot_speed * dt;
        
        // Recalculate camera plane (perpendicular to direction)
        const dir_x = @cos(self.direction);
        const dir_y = @sin(self.direction);
        self.plane.x = -dir_y * 0.66;
        self.plane.y = dir_x * 0.66;
        
        // Movement (WASD)
        const move_x: f32 = if (rl.IsKeyDown(rl.KEY_D)) 1.0 else if (rl.IsKeyDown(rl.KEY_A)) -1.0 else 0.0;
        const move_y: f32 = if (rl.IsKeyDown(rl.KEY_S)) 1.0 else if (rl.IsKeyDown(rl.KEY_W)) -1.0 else 0.0;
        
        // Calculate new position with collision
        const new_pos = self.calculateMovement(dir_x, dir_y, move_x, move_y, dt);
        
        // Collision check (sliding)
        const buffer: f32 = 0.2;
        if (map.get(new_pos.x, self.position.y) == 0) {
            self.position.x = new_pos.x;
        }
        if (map.get(self.position.x, new_pos.y) == 0) {
            self.position.y = new_pos.y;
        }
    }
    
    fn calculateMovement(
        self: PlayerController,
        dir_x: f32,
        dir_y: f32,
        move_x: f32,
        move_y: f32,
        dt: f32,
    ) Vec2 {
        // Strafe (perpendicular to direction)
        const strafe_x = -dir_y;
        const strafe_y = dir_x;
        
        return .{
            .x = self.position.x + (dir_x * move_y + strafe_x * move_x) * self.move_speed * dt,
            .y = self.position.y + (dir_y * move_y + strafe_y * move_x) * self.move_speed * dt,
        };
    }
};
```

---

## 4. Interaction System

### 4.1 Proximity Detection

```zig
pub const InteractionSystem = struct {
    pub fn findInteractables(
        batch: *const EntityBatch,
        player_pos: Vec2,
        max_distance: f32,
    ) []usize {
        // Retorna índices de entidades interagíveis próximas
        // Implementar com spatial partition para O(1)
        _ = batch;
        _ = player_pos;
        _ = max_distance;
        unreachable;
    }
    
    pub fn canInteract(
        batch: *const EntityBatch,
        entity_idx: usize,
        player_pos: Vec2,
        max_distance: f32,
    ) bool {
        if (!batch.active[entity_idx]) return false;
        if (batch.tags[entity_idx] != .interactive) return false;
        
        const dx = batch.positions[entity_idx].x - player_pos.x;
        const dy = batch.positions[entity_idx].y - player_pos.y;
        const distance = @sqrt(dx * dx + dy * dy);
        
        return distance <= max_distance;
    }
};
```

### 4.2 Context Actions

```zig
pub const ContextAction = struct {
    name: []const u8,
    icon: []const u8,
    handler: *const fn (entity_idx: usize) void,
};

pub const InteractionMenu = struct {
    actions: [4]ContextAction,
    count: usize,
    selected: usize,
    
    pub fn addAction(
        self: *InteractionMenu,
        name: []const u8,
        icon: []const u8,
        handler: *const fn (usize) void,
    ) void {
        if (self.count < 4) {
            self.actions[self.count] = .{
                .name = name,
                .icon = icon,
                .handler = handler,
            };
            self.count += 1;
        }
    }
    
    pub fn render(self: *InteractionMenu, ui: *nuklear.Context) void {
        _ = ui;
        // Render context menu com Nuklear
    }
};
```

---

## 5. State Machines (FSM)

### 5.1 Enemy AI (Gremlin)

```zig
pub const GremlinAI = struct {
    pub const State = enum {
        idle,
        patrol,
        chase,
        attack,
        flee,
        glitch_out,
    };
    
    pub fn update(
        batch: *EntityBatch,
        idx: usize,
        player_pos: Vec2,
        dt: f32,
    ) void {
        if (!batch.active[idx]) return;
        
        const entity_pos = batch.positions[idx];
        const distance_to_player = entity_pos.distanceTo(player_pos);
        
        switch (batch.states[idx]) {
            .normal => {
                if (distance_to_player < 5.0) {
                    // Start chase
                    batch.velocities[idx] = entity_pos.directionTo(player_pos).normalize().scale(2.0);
                } else if (distance_to_player < 10.0) {
                    // Patrol
                    batch.velocities[idx].x += (std.crypto.random.float(f32) - 0.5) * 0.5;
                    batch.velocities[idx].y += (std.crypto.random.float(f32) - 0.5) * 0.5;
                }
            },
            .possessed => {
                // Aggressive chase
                batch.velocities[idx] = entity_pos.directionTo(player_pos).normalize().scale(3.0);
            },
            .glitched => {
                // Random erratic movement
                batch.velocities[idx].x = (std.crypto.random.float(f32) - 0.5) * 5.0;
                batch.velocities[idx].y = (std.crypto.random.float(f32) - 0.5) * 5.0;
            },
            else => {
                batch.velocities[idx] = .{ .x = 0, .y = 0 };
            },
        }
    }
};
```

### 5.2 NPC AI (Intern)

```zig
pub const InternAI = struct {
    pub const State = enum {
        working,
        coffee_break,
        fleeing,
        possessed,
    };
    
    pub fn update(
        batch: *EntityBatch,
        idx: usize,
        player_pos: Vec2,
        gremlins: *const EntityBatch,
        dt: f32,
    ) void {
        _ = dt;
        
        if (!batch.active[idx]) return;
        
        // Check for nearby gremlins
        const sees_gremlin = checkLineOfSight(batch.positions[idx], player_pos, gremlins);
        
        if (sees_gremlin) {
            // Lose innocence, maybe flee
            batch.states[idx] = .fleeing;
            batch.velocities[idx] = batch.positions[idx]
                .directionTo(player_pos)
                .normalize()
                .scale(4.0); // Run to player
        } else {
            // Working or coffee break
            batch.states[idx] = .working;
            batch.velocities[idx] = .{ .x = 0, .y = 0 };
        }
    }
    
    fn checkLineOfSight(
        intern_pos: Vec2,
        player_pos: Vec2,
        gremlins: *const EntityBatch,
    ) bool {
        // Ray cast para detectar gremlins
        _ = intern_pos;
        _ = player_pos;
        _ = gremlins;
        return false; // Placeholder
    }
};
```

---

## 6. Physics (Simple AABB)

### 6.1 Collision Detection

```zig
pub const AABB = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    
    pub fn intersects(self: AABB, other: AABB) bool {
        return self.x < other.x + other.width and
            self.x + self.width > other.x and
            self.y < other.y + other.height and
            self.y + self.height > other.y;
    }
    
    pub fn contains(self: AABB, point: Vec2) bool {
        return point.x >= self.x and
            point.x <= self.x + self.width and
            point.y >= self.y and
            point.y <= self.y + self.height;
    }
};

pub const CollisionSystem = struct {
    pub fn resolve(
        a: *AABB,
        b: *AABB,
        a_velocity: *Vec2,
        b_velocity: *Vec2,
    ) void {
        // Simple resolution: push apart and reflect velocity
        const overlap_x = @min(
            a.x + a.width - b.x,
            b.x + b.width - a.x,
        );
        const overlap_y = @min(
            a.y + a.height - b.y,
            b.y + b.height - a.y,
        );
        
        if (overlap_x < overlap_y) {
            // Horizontal collision
            if (a.x < b.x) {
                a.x -= overlap_x / 2;
                b.x += overlap_x / 2;
            } else {
                a.x += overlap_x / 2;
                b.x -= overlap_x / 2;
            }
            a_velocity.x *= -0.5;
            b_velocity.x *= -0.5;
        } else {
            // Vertical collision
            if (a.y < b.y) {
                a.y -= overlap_y / 2;
                b.y += overlap_y / 2;
            } else {
                a.y += overlap_y / 2;
                b.y -= overlap_y / 2;
            }
            a_velocity.y *= -0.5;
            b_velocity.y *= -0.5;
        }
    }
};
```

---

## 7. Templates de Documentação

Para documentar novas mecânicas, use:

```markdown
# Mechanic Specification: [Name]

## 1. Functional Description
[O que esta mecânica faz]

## 2. Input & Trigger
[Como é ativada]

## 3. Logical Constraints (Vibe Check)
- [Constraint 1]
- [Constraint 2]

## 4. Technical Implementation (DOD)
- **Primary Components**: [Quais SoA structs]
- **System**: [Qual sistema]
- **Complexity**: [O(1), O(n), etc.]

## 5. Asset Requirements
- [Asset 1]
- [Asset 2]

## 6. Satirical Corporate Note
[Nota humorística sobre a mecânica]
```

---

## 8. Performance Guidelines

### 8.1 Budgets

| System | Budget (60 FPS) | Notes |
|--------|-----------------|-------|
| **Movement** | < 1ms | Cache-friendly SoA |
| **Combat** | < 0.5ms | Branchless quando possível |
| **AI** | < 2ms | LOD: só update entities próximas |
| **Collision** | < 1ms | Spatial partition |
| **Render** | < 8ms | Batch draws |

### 8.2 Optimization Patterns

```zig
// ✅ Pattern: Early exit
for (0..batch.count) |i| {
    if (!batch.active[i]) continue;
    if (batch.states[i] == .dead) continue;
    // Process...
}

// ✅ Pattern: Batch processing
pub fn updateAll(batch: *EntityBatch, dt: f32) void {
    // Update positions (sequential access)
    for (0..batch.count) |i| {
        if (batch.active[i]) {
            batch.positions[i] = batch.positions[i].add(
                batch.velocities[i].scale(dt)
            );
        }
    }
    
    // Update states (separate pass, still sequential)
    for (0..batch.count) |i| {
        if (batch.active[i]) {
            batch.states[i] = updateState(batch.states[i]);
        }
    }
}

// ✅ Pattern: Structure of Arrays for filtering
pub fn getAliveEntities(batch: *const EntityBatch) []usize {
    // Manter lista de índices ativos para iteração rápida
    // Atualizar apenas quando spawn/despawn
    return active_indices;
}
```

---

## 9. Referências Cruzadas

Esta skill referencia:
- `workflow_orchestrator` - Workflow
- `tech_stack_zig_raylib` - Implementação Zig
- `style_guide_retro_fps` - Estética
- `asset_pipeline_qoi` - Sprites 8-direções

É referenciada por:
- Todas as mecânicas específicas

---

**Version**: 1.0  
**Inspired By**: DOOM entity system, Half-Life 2 physics, modern ECS frameworks  
**License**: MIT
