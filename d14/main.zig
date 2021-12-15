const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

const N = usize;

const Pair = struct {
    l: u8,
    r: u8,
};

const Map = std.AutoHashMap(Pair, u8);
const CountMap = std.AutoHashMap(Pair, N);

fn add(map: anytype, key: anytype, value: anytype) !void {
    if (map.getPtr(key)) |ptr| {
        ptr.* += value;
    } else {
        try map.put(key, value);
    }
}

fn solve(template: []const u8, steps: N, map: *Map) !N {
    var count_map = CountMap.init(allocator);
    defer count_map.deinit();

    for (template) |c, i| {
        if (i == template.len - 1) break;
        var pair = Pair{ .l = c, .r = template[i + 1] };
        try add(&count_map, pair, 1);
    }

    var i: usize = 0;
    while (i < steps) : (i += 1) {
        var split_map = CountMap.init(allocator);

        var itr = count_map.iterator();
        while (itr.next()) |e| {
            var p = e.key_ptr.*;
            var c = e.value_ptr.*;

            var new = map.get(p).?;
            var l_p = Pair{ .l = p.l, .r = new };
            var r_p = Pair{ .l = new, .r = p.r };

            try add(&split_map, l_p, c);
            try add(&split_map, r_p, c);
        }

        count_map.deinit();
        count_map = split_map;
    }

    var histrogram = std.AutoHashMap(u8, N).init(allocator);
    defer histrogram.deinit();

    var itr = count_map.iterator();
    while (itr.next()) |e| {
        var p = e.key_ptr.*;
        var c = e.value_ptr.*;

        try add(&histrogram, p.l, c / 2);
        try add(&histrogram, p.r, c / 2);
    }

    var h_itr = histrogram.iterator();
    var max: N = 0;
    var min: N = std.math.maxInt(N);
    while (h_itr.next()) |e| {
        var v = e.value_ptr.*;
        if (v > max) max = v;
        if (v < min) min = v;
    }

    return (max - min) + 1;
}

fn solution(buf: []const u8) ![2]?N {
    var part1: ?N = null;
    var part2: ?N = null;

    var map = Map.init(allocator);
    defer map.deinit();

    var lines = std.mem.tokenize(u8, buf, "\n ->");
    var template = lines.next().?;

    while (lines.next()) |l| {
        var to = lines.next().?;
        var pair = Pair{ .l = l[0], .r = l[1] };
        try map.put(pair, to[0]);
    }

    part1 = try solve(template, 10, &map);
    part2 = try solve(template, 40, &map);

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
