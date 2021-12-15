const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const N = usize;

const COORD = u32;
const POINT = u64;

fn toPoint(x: COORD, y: COORD) POINT {
    return @bitCast(POINT, [2]COORD{ x, y });
}

fn toCoords(p: POINT) [2]COORD {
    return @bitCast([2]COORD, p);
}

const Grid = struct {
    const Self = @This();

    points: std.AutoHashMap(POINT, N) = std.AutoHashMap(POINT, N).init(&gpa.allocator),
    width: COORD = 0,
    height: COORD = 0,

    pub fn deinit(self: *Self) void {
        self.points.deinit();
    }

    pub fn append(self: *Self, x: COORD, y: COORD) !void {
        var point = toPoint(x, y);
        try self.points.put(point, 1);
    }

    const Fold_Dir = enum { x, y };
    pub fn fold(self: *Self, comptime dir: Fold_Dir, at: COORD) !void {
        if (dir == .x) {
            self.width = at;
        } else {
            self.height = at;
        }

        var itr = self.points.iterator();
        const C = struct { p: POINT, v: N };
        var buffer = std.ArrayList(C).init(&gpa.allocator);
        defer buffer.deinit();
        while (itr.next()) |e| {
            var coords = toCoords(e.key_ptr.*);
            const index = if (dir == .x) 0 else 1;
            if (coords[index] >= at) {
                var diff = coords[index] - at;

                if (diff <= at and diff != 0) {
                    coords[index] = at - diff;

                    var new_pos = toPoint(coords[0], coords[1]);
                    var v = self.points.get(new_pos) orelse 0;
                    try buffer.append(.{ .p = new_pos, .v = v + e.value_ptr.* });
                    e.value_ptr.* = 0;
                }
            }
        }

        for (buffer.items) |c| {
            try self.points.put(c.p, c.v);
        }
    }

    pub fn count_dots(self: *Self) N {
        var count: N = 0;
        var itr = self.points.iterator();
        while (itr.next()) |e| {
            count += if (e.value_ptr.* > 0) @as(N, 1) else @as(N, 0);
        }
        return count;
    }

    pub fn print(self: *Self) void {
        var y: COORD = 0;
        while (y < self.height) : (y += 1) {
            var x: COORD = 0;
            while (x < self.width) : (x += 1) {
                var pos = toPoint(x, y);
                var v = self.points.get(pos) orelse 0;
                if (v > 0) {
                    std.debug.print(" 8 ", .{});
                } else {
                    std.debug.print("   ", .{});
                }
            }
            std.debug.print("\n", .{});
        }
    }
};

fn solution(buf: []const u8) ![2]?N {
    var part1: ?N = null;
    var part2: ?N = null;

    var grid = Grid{};
    defer grid.deinit();

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |l| {
        if (l[0] != 'f') {
            var nums = std.mem.tokenize(u8, l, ",\n");
            var n1 = try std.fmt.parseInt(COORD, nums.next().?, 10);
            var n2 = try std.fmt.parseInt(COORD, nums.next().?, 10);
            try grid.append(n1, n2);
        } else {
            var nums = std.mem.tokenize(u8, l, " \n");
            _ = nums.next();
            _ = nums.next();
            var fold_expr = nums.next().?;
            switch (fold_expr[0]) {
                'x' => {
                    var at = try std.fmt.parseInt(COORD, fold_expr[2..], 10);
                    try grid.fold(.x, at);
                },
                'y' => {
                    var at = try std.fmt.parseInt(COORD, fold_expr[2..], 10);
                    try grid.fold(.y, at);
                },
                else => {},
            }
            if (part1 == null) {
                part1 = grid.count_dots();
            }
        }
    }

    grid.print();

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
