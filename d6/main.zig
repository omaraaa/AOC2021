const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const N = usize;
const State = [9]N;

var s1: State = std.mem.zeroes(State);
var s2: State = std.mem.zeroes(State);

var current = &s1;
var next = &s2;

fn run(days: N) void {
    var d: usize = 0;
    while (d < days) : (d += 1) {
        next.* = std.mem.zeroes(State);
        for (current.*) |f, i| {
            switch (i) {
                0 => {
                    next.*[8] += f;
                    next.*[6] += f;
                },
                else => {
                    next.*[i - 1] += f;
                },
            }
        }
        current = next;
        next = if (current == &s1) &s2 else &s1;
    }
}

fn count() N {
    var c: N = 0;
    for (current.*) |f| {
        c += f;
    }
    return c;
}

fn solution(buf: []const u8) ![2]N {
    var tokens = std.mem.tokenize(u8, buf, ",\n");
    while (tokens.next()) |t| {
        var bank = try std.fmt.parseInt(N, t, 10);

        s1[bank] += 1;
    }
    run(80);
    var count80 = count();
    run(256 - 80);
    return [2]N{ count80, count() };
}

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(&gpa.allocator, 1000000);
    defer gpa.allocator.free(bytes);

    std.debug.print("{any}", .{try solution(bytes)});
}
