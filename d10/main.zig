const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const N = usize;

fn getCloser(c: u8) u8 {
    switch (c) {
        '(' => return ')',
        '[' => return ']',
        '{' => return '}',
        '<' => return '>',
        else => unreachable,
    }
}

fn expected(c: u8, expect_stack: std.ArrayList(u8)) bool {
    if (expect_stack.items.len == 0) return false;
    return c == expect_stack.items[expect_stack.items.len - 1];
}

fn getPart1Score(c: u8) N {
    switch (c) {
        ')' => return 3,
        ']' => return 57,
        '}' => return 1197,
        '>' => return 25137,
        else => unreachable,
    }
}

fn getPart2Score(c: u8) N {
    switch (c) {
        ')' => return 1,
        ']' => return 2,
        '}' => return 3,
        '>' => return 4,
        else => unreachable,
    }
}

fn solution(buf: []const u8) ![2]N {
    var lines = std.mem.tokenize(u8, buf, "\n");

    var part1: N = 0;
    var part2: N = 0;

    var expect_stack = std.ArrayList(u8).init(&gpa.allocator);
    defer expect_stack.deinit();

    var scores = std.ArrayList(N).init(&gpa.allocator);
    defer scores.deinit();

    while (lines.next()) |l| {
        var err = false;
        for (l) |c| {
            switch (c) {
                '(', '[', '{', '<' => {
                    try expect_stack.append(getCloser(c));
                },
                ')', ']', '}', '>' => {
                    if (!expected(c, expect_stack)) {
                        part1 += getPart1Score(c);
                        err = true;
                        break;
                    } else {
                        _ = expect_stack.pop();
                    }
                },
                else => unreachable,
            }
        }

        if (!err) {
            var score: N = 0;
            var c = expect_stack.items.len;
            while (c > 0) : (c -= 1) {
                score *= 5;
                score += getPart2Score(expect_stack.items[c - 1]);
            }
            try scores.append(score);
        }

        expect_stack.clearRetainingCapacity();
    }

    std.sort.sort(N, scores.items, {}, comptime std.sort.desc(N));
    part2 = scores.items[scores.items.len / 2];

    return [2]N{ part1, part2 };
}

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(&gpa.allocator, 1000000);
    defer gpa.allocator.free(bytes);

    std.debug.print("{any}", .{try solution(bytes)});
}
