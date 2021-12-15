const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

const N = usize;
const W = 100;
const H = 100;
const Map = [H][W]u8;

const COORD = struct {
    x: u32,
    y: u32,

    pub fn get_connected(self: @This(), w: N, h: N) [4]?COORD {
        var coords: [4]?COORD = .{null} ** 4;
        if (self.x != 0) coords[0] = .{ .x = self.x - 1, .y = self.y };
        if (self.x != w - 1) coords[1] = .{ .x = self.x + 1, .y = self.y };
        if (self.y != 0) coords[2] = .{ .x = self.x, .y = self.y - 1 };
        if (self.y != h - 1) coords[3] = .{ .x = self.x, .y = self.y + 1 };
        return coords;
    }
};

fn hr(c: COORD, w: N, h: N) N {
    return (h - 1 - c.y) + (w - 1 - c.x);
}

fn cost(map: Map, c: COORD) N {
    var y = c.y / H;
    var x = c.x / W;
    return @mod(map[@mod(c.y, H)][@mod(c.x, W)] + x + y - 1, 9) + 1;
}

const P = struct {
    coord: COORD,
    cost: N,
};

fn solve(map: Map, w: N, h: N) !N {
    var costs = std.AutoHashMap(COORD, N).init(allocator);
    defer costs.deinit();

    var done = std.AutoHashMap(COORD, void).init(allocator);
    defer done.deinit();

    var active = std.ArrayList(P).init(allocator);
    defer active.deinit();

    try active.append(.{ .coord = .{ .x = 0, .y = 0 }, .cost = 0 });
    var current_index: usize = 0;

    while (active.items.len > 0) {
        var min: N = std.math.maxInt(N);
        var min_index: usize = 0;
        for (active.items) |a, i| {
            if (done.contains(a.coord)) continue;
            if (a.cost + hr(a.coord, w, h) < min) {
                min = a.cost + hr(a.coord, w, h);
                min_index = i;
            }
        }
        var current = active.items[min_index];
        current_index = min_index;

        _ = active.swapRemove(current_index);
        if (current.coord.x == w - 1 and current.coord.y == h - 1) return current.cost;

        var connected = current.coord.get_connected(w, h);
        for (connected) |edge| {
            if (edge != null) {
                var o_cost = costs.get(edge.?) orelse std.math.maxInt(N);
                var e_cost = current.cost + cost(map, edge.?);
                if (e_cost < o_cost) {
                    try costs.put(edge.?, e_cost);
                    try active.append(.{ .coord = edge.?, .cost = e_cost });
                }
            }
        }
    }
    unreachable;
}

fn solution(buf: []const u8) ![2]?N {
    var part1: ?N = null;
    var part2: ?N = null;

    var map = std.mem.zeroes(Map);
    var lines = std.mem.tokenize(u8, buf, "\n");

    var y: usize = 0;
    while (lines.next()) |l| {
        var x: usize = 0;
        while (x < W) : (x += 1) {
            map[y][x] = l[x] - '0';
        }
        y += 1;
    }

    part1 = try solve(map, W, H);
    part2 = try solve(map, W * 5, H * 5);

    return [2]?N{ part1, part2 };
}

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(&gpa.allocator, 1000000);
    defer gpa.allocator.free(bytes);

    std.debug.print("{any}", .{try solution(bytes)});
}
