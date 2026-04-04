const std = @import("std");

pub const Rect = struct {
    x: f64,
    y: f64,
    w: f64,
    h: f64,

    pub fn contains(self: Rect, px: f64, py: f64) bool {
        return px >= self.x and px < self.x + self.w and
               py >= self.y and py < self.y + self.h;
    }

    pub fn intersects(self: Rect, other: Rect) bool {
        return !(other.x > self.x + self.w or
                 other.x + other.w < self.x or
                 other.y > self.y + self.h or
                 other.y + other.h < self.y);
    }
};

pub const Point = struct {
    x: f64,
    y: f64,
    data: u32,
};

pub fn QuadTree(comptime capacity: usize) type {
    const Node = struct {
        bounds: Rect,
        points: [capacity]Point,
        count: usize = 0,
        children: ?*[4]@This() = null,
        is_divided: bool = false,
    };

    return struct {
        const Self = @This();

        root: *Node,
        allocator: std.mem.Allocator,
        arena: std.heap.ArenaAllocator,

        pub fn init(bounds: Rect, allocator: std.mem.Allocator) !Self {
            var arena = std.heap.ArenaAllocator.init(allocator);
            const arena_allocator = arena.allocator();
            
            const root = try arena_allocator.create(Node);
            root.* = .{
                .bounds = bounds,
                .points = undefined,
                .count = 0,
                .children = null,
                .is_divided = false,
            };

            return Self{
                .root = root,
                .allocator = allocator,
                .arena = arena,
            };
        }

        pub fn deinit(self: *Self) void {
            self.arena.deinit();
        }

        pub fn insert(self: *Self, point: Point) anyerror!bool {
            return self.insertNode(self.root, point);
        }

        fn insertNode(self: *Self, node: *Node, point: Point) anyerror!bool {
            if (!node.bounds.contains(point.x, point.y)) {
                return false;
            }

            if (node.count < capacity and !node.is_divided) {
                node.points[node.count] = point;
                node.count += 1;
                return true;
            }

            if (!node.is_divided) {
                try self.subdivide(node);
            }

            // Tentar inserir em um dos filhos
            if (node.children) |children| {
                for (children) |*child| {
                    if (try self.insertNode(child, point)) return true;
                }
            }

            return false;
        }

        fn subdivide(self: *Self, node: *Node) anyerror!void {
            const x = node.bounds.x;
            const y = node.bounds.y;
            const w = node.bounds.w / 2.0;
            const h = node.bounds.h / 2.0;

            const arena_allocator = self.arena.allocator();
            const children = try arena_allocator.create([4]Node);
            
            children[0] = .{ .bounds = Rect{ .x = x,     .y = y,     .w = w, .h = h }, .points = undefined, .count = 0, .children = null, .is_divided = false };
            children[1] = .{ .bounds = Rect{ .x = x + w, .y = y,     .w = w, .h = h }, .points = undefined, .count = 0, .children = null, .is_divided = false };
            children[2] = .{ .bounds = Rect{ .x = x,     .y = y + h, .w = w, .h = h }, .points = undefined, .count = 0, .children = null, .is_divided = false };
            children[3] = .{ .bounds = Rect{ .x = x + w, .y = y + h, .w = w, .h = h }, .points = undefined, .count = 0, .children = null, .is_divided = false };

            node.children = children;
            node.is_divided = true;

            // Redistribuir os pontos atuais do nó para os filhos
            var i: usize = 0;
            while (i < node.count) : (i += 1) {
                const p = node.points[i];
                for (node.children.?) |*child| {
                    if (try self.insertNode(child, p)) break;
                }
            }
            node.count = 0;
        }

        pub fn query(self: Self, query_allocator: std.mem.Allocator, range: Rect, results: *std.ArrayList(Point)) anyerror!void {
            try self.queryNode(query_allocator, self.root, range, results);
        }

        fn queryNode(self: Self, query_allocator: std.mem.Allocator, node: *Node, range: Rect, results: *std.ArrayList(Point)) anyerror!void {
            if (!node.bounds.intersects(range)) {
                return;
            }

            if (node.is_divided) {
                if (node.children) |children| {
                    for (children) |*child| {
                        try self.queryNode(query_allocator, child, range, results);
                    }
                }
            } else {
                var i: usize = 0;
                while (i < node.count) : (i += 1) {
                    const p = node.points[i];
                    if (range.contains(p.x, p.y)) {
                        try results.append(query_allocator, p);
                    }
                }
            }
        }
    };
}
