const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const N = usize;
const NCount = 16;

const State = struct {
    const Self = @This();

    name_index: u8 = 0,
    start: u8 = 0,
    end: u8 = 0,
    graph: [NCount][NCount]bool = std.mem.zeroes([NCount][NCount]bool),
    node_small: [NCount]bool = std.mem.zeroes([NCount]bool),
    name_map: std.StringHashMap(u8),

    pub fn init() Self {
        return Self{
            .name_map = std.StringHashMap(u8).init(&gpa.allocator),
        };
    }
    pub fn deinit(self: *Self) void {
        self.name_map.deinit();
    }

    pub fn insert(self: *Self, n1: []const u8, n2: []const u8) !void {
        var id1 = try self.toID(n1);
        var id2 = try self.toID(n2);

        self.graph[id1][id2] = true;
        self.graph[id2][id1] = true;
    }

    pub fn toID(self: *Self, n: []const u8) !u8 {
        var n_id = self.name_map.get(n);
        if (n_id == null) {
            if (std.mem.eql(u8, n, "start")) {
                self.start = self.name_index;
            } else if (std.mem.eql(u8, n, "end")) {
                self.end = self.name_index;
            }

            var node_small: bool = false;
            for (n) |c| {
                if (c >= 97 and c <= 122) {
                    node_small = true;
                    break;
                }
            }

            self.node_small[self.name_index] = node_small;

            n_id = self.name_index;
            try self.name_map.put(n, self.name_index);
            self.name_index += 1;
        }
        return n_id.?;
    }

    pub fn pathItr1(self: *Self) PathIterator1 {
        return PathIterator1{
            .state = self,
        };
    }

    pub fn pathItr2(self: *Self) PathIterator2 {
        return PathIterator2{
            .state = self,
        };
    }

    pub const PathIterator1 = struct {
        const PathStack = struct {
            nodes: [NCount]u8 = undefined,
            len: usize = 0,
            itr: usize = 0,

            pub fn append(self: *@This(), node: u8) !void {
                self.nodes[self.len] = node;
                self.len += 1;
            }

            pub fn next(self: *@This()) ?u8 {
                self.itr += 1;
                if (self.itr <= self.len) {
                    return self.nodes[self.itr - 1];
                } else {
                    return null;
                }
            }
        };

        started: bool = false,
        state: *Self,
        path_found: bool = false,
        visited: std.AutoHashMap(u8, void) = undefined,
        to_visit: std.ArrayList(PathStack) = undefined,

        pub fn next(self: *@This()) !bool {
            if (!self.started) {
                self.visited = std.AutoHashMap(u8, void).init(&gpa.allocator);

                self.to_visit = std.ArrayList(PathStack).init(&gpa.allocator);
                var stack = PathStack{};
                try stack.append(self.state.start);
                try self.to_visit.append(stack);
                self.started = true;
            }
            try self.path();
            if (!self.path_found) {
                self.visited.deinit();
                self.to_visit.deinit();
            }
            return self.path_found;
        }

        fn path(self: *@This()) anyerror!void {
            while (self.to_visit.items.len > 0) {
                var stack = &self.to_visit.items[self.to_visit.items.len - 1];
                var next_node = stack.next();
                if (next_node == null) {
                    for (stack.nodes[0..stack.len]) |n| {
                        _ = self.visited.remove(n);
                    }
                    _ = self.to_visit.pop();
                    continue;
                }

                var node = next_node.?;
                for (stack.nodes[0..stack.itr]) |n| {
                    _ = self.visited.remove(n);
                }

                if (self.state.node_small[node]) {
                    try self.visited.put(node, {});
                }

                if (node == self.state.end) {
                    self.path_found = true;

                    return;
                }

                var ps = PathStack{};
                for (self.state.graph[node]) |e, n| {
                    var nn = @intCast(u8, n);
                    if (e and self.visited.get(nn) == null) {
                        try ps.append(nn);
                    }
                }
                try self.to_visit.append(ps);
            }
            self.path_found = false;
        }
    };

    pub const PathIterator2 = struct {
        const PathStack = struct {
            nodes: [NCount]u8 = undefined,
            visit_count: [NCount]u8 = std.mem.zeroes([NCount]u8),
            twice: bool = false,
            len: usize = 0,
            itr: usize = 0,

            pub fn append(self: *@This(), node: u8) !void {
                self.nodes[self.len] = node;
                self.len += 1;
            }

            pub fn next(self: *@This()) ?u8 {
                self.itr += 1;
                if (self.itr <= self.len) {
                    return self.nodes[self.itr - 1];
                } else {
                    return null;
                }
            }
        };

        started: bool = false,
        state: *Self,
        path_found: bool = false,
        visited: [256]u2 = std.mem.zeroes([256]u2),
        to_visit: std.ArrayList(PathStack) = undefined,

        pub fn next(self: *@This()) !bool {
            if (!self.started) {
                self.to_visit = std.ArrayList(PathStack).init(&gpa.allocator);
                var stack = PathStack{};
                try stack.append(self.state.start);
                try self.to_visit.append(stack);
                self.started = true;
            }
            try self.path();
            if (!self.path_found) {
                self.to_visit.deinit();
            }
            return self.path_found;
        }

        fn path(self: *@This()) anyerror!void {
            while (self.to_visit.items.len > 0) {
                var stack = &self.to_visit.items[self.to_visit.items.len - 1];
                var next_node = stack.next();
                if (next_node == null) {
                    _ = self.to_visit.pop();
                    continue;
                }

                var node = next_node.?;

                if (node == self.state.end) {
                    self.path_found = true;
                    stack.visit_count[node] = 2;

                    return;
                }

                var ps = PathStack{};
                for (self.to_visit.items) |s| {
                    var n = s.nodes[s.itr - 1];
                    if (self.state.node_small[n] and ps.visit_count[n] < 2) {
                        ps.visit_count[n] += 1;
                        if (ps.twice)
                            ps.visit_count[n] += 1;
                    }
                    if (ps.visit_count[n] == 2 and n != self.state.start and n != self.state.end) {
                        ps.twice = true;
                    }
                }
                var cmp: u2 = if (ps.twice) 1 else 2;
                for (self.state.graph[node]) |e, n| {
                    var nn = @intCast(u8, n);
                    if (e and ps.visit_count[nn] < cmp and nn != self.state.start) {
                        try ps.append(nn);
                    }
                }
                try self.to_visit.append(ps);
            }
            self.path_found = false;
        }
    };
};

fn solution(buf: []const u8) ![2]N {
    var lines = std.mem.tokenize(u8, buf, "-\n");

    var part1: ?N = null;
    var part2: ?N = null;

    var state: State = State.init();
    defer state.deinit();

    while (lines.next()) |l| {
        var n2 = lines.next().?;
        try state.insert(l, n2);
    }

    {
        var itr = state.pathItr1();
        var path_count: usize = 0;
        while (try itr.next()) {
            path_count += 1;
        }
        part1 = path_count;
    }

    {
        var itr = state.pathItr2();
        var path_count: usize = 0;
        while (try itr.next()) {
            path_count += 1;
        }
        part2 = path_count;
    }

    return [2]N{ part1.?, part2.? };
}

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(&gpa.allocator, 1000000);
    defer gpa.allocator.free(bytes);

    std.debug.print("{any}", .{try solution(bytes)});
}
