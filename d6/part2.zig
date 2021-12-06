const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const N = usize;

const State = struct {
    new: [2]usize = .{0} ** 2,
    normal: [7]usize = .{0} ** 7,
};

var s1: State = .{};
var s2: State = .{};

var current = &s1;
var next = &s2;

fn run(days: usize) void {
    var d: usize = 0;
    while (d < days) : (d += 1) {
        next.* = .{};
        for (current.new) |f, i| {
            switch (i) {
                0 => {
                    next.normal[6] += f;
                },
                1 => {
                    next.new[0] += f;
                },
                else => {},
            }
        }
        for (current.normal) |f, i| {
            switch (i) {
                0 => {
                    next.new[1] += f;
                    next.normal[6] += f;
                },
                else => {
                    next.normal[i - 1] += f;
                },
            }
        }
        current = next;
        next = if (current == &s1) &s2 else &s1;
    }
}

fn count() usize {
    var c: usize = 0;
    for (current.new) |f| {
        c += f;
    }
    for (current.normal) |f| {
        c += f;
    }
    return c;
}

fn solution(buf: []const u8) !N {
    var tokens = std.mem.tokenize(u8, buf, ",\n");
    while (tokens.next()) |t| {
        var bank = try std.fmt.parseInt(N, t, 10);

        s1.normal[bank] += 1;
    }
    run(256);
    return count();
}

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(&gpa.allocator, 1000000);
    defer gpa.allocator.free(bytes);

    std.debug.print("{}", .{try solution(bytes)});
}
