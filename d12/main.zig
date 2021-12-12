const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const N = usize;

const NODE_COUNT = 16;
const NODE_TYPE = u4;

const State = struct {
    const Self = @This();

    name_index: NODE_TYPE = 0,
    start: NODE_TYPE = 0,
    end: NODE_TYPE = 0,
    graph: [NODE_COUNT][NODE_COUNT]bool = std.mem.zeroes([NODE_COUNT][NODE_COUNT]bool),
    node_small: [NODE_COUNT]bool = std.mem.zeroes([NODE_COUNT]bool),
    name_map: std.StringHashMap(NODE_TYPE),

    pub fn init() Self {
        return Self{
            .name_map = std.StringHashMap(NODE_TYPE).init(&gpa.allocator),
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

    pub fn toID(self: *Self, n: []const u8) !NODE_TYPE {
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

    const Part = enum { part1, part2 };
    pub fn pathItr(self: *Self, comptime part: Part) PathIterator(part) {
        return PathIterator(part){
            .state = self,
        };
    }

    const PathStack = struct {
        nodes: [NODE_COUNT]NODE_TYPE = undefined,
        len: usize = 0,
        itr: usize = 0,

        pub fn append(self: *@This(), node: NODE_TYPE) !void {
            self.nodes[self.len] = node;
            self.len += 1;
        }

        pub fn next(self: *@This()) ?NODE_TYPE {
            self.itr += 1;
            if (self.itr <= self.len) {
                return self.nodes[self.itr - 1];
            } else {
                return null;
            }
        }
    };

    pub fn PathIterator(comptime part: Part) type {
        return struct {
            started: bool = false,
            state: *Self,
            path_found: bool = false,
            stack: std.ArrayList(PathStack) = undefined,

            pub fn next(self: *@This()) !bool {
                if (!self.started) {
                    self.stack = std.ArrayList(PathStack).init(&gpa.allocator);
                    var stack = PathStack{};
                    try stack.append(self.state.start);
                    try self.stack.append(stack);
                    self.started = true;
                }
                try self.path();
                if (!self.path_found) {
                    self.stack.deinit();
                }
                return self.path_found;
            }

            fn path(self: *@This()) anyerror!void {
                while (self.stack.items.len > 0) {
                    var stack = &self.stack.items[self.stack.items.len - 1];
                    var next_node = stack.next();
                    if (next_node == null) {
                        _ = self.stack.pop();
                        continue;
                    }
                    var node = next_node.?;

                    if (node == self.state.end) {
                        self.path_found = true;
                        return;
                    }

                    var ps = PathStack{};
                    var visit_count: [NODE_COUNT]NODE_TYPE = std.mem.zeroes([NODE_COUNT]NODE_TYPE);
                    var twice: bool = false;

                    for (self.stack.items) |s| {
                        var n = s.nodes[s.itr - 1];
                        if (self.state.node_small[n] and visit_count[n] < 2) {
                            visit_count[n] += 1;
                            if (twice)
                                visit_count[n] += 1;
                        }
                        if (visit_count[n] == 2 and n != self.state.start and n != self.state.end) {
                            twice = true;
                        }
                    }

                    var cmp: u2 = if (twice or part == .part1) 1 else 2;
                    for (self.state.graph[node]) |e, n| {
                        var nn = @intCast(NODE_TYPE, n);
                        if (e and visit_count[nn] < cmp and nn != self.state.start) {
                            try ps.append(nn);
                        }
                    }
                    try self.stack.append(ps);
                }
                self.path_found = false;
            }
        };
    }
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
        var itr = state.pathItr(.part1);
        var path_count: usize = 0;
        while (try itr.next()) {
            path_count += 1;
        }
        part1 = path_count;
    }

    {
        var itr = state.pathItr(.part2);
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
