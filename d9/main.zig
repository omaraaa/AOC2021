const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const N = usize;

const Flow = enum {
    low,
    high,
    left,
    right,
    top,
    bottom,
};

var vMap: [100][100]u4 = undefined;
var fMap: [100][100]Flow = undefined;

fn solution(buf: []const u8) ![2]N {
    var lines = std.mem.tokenize(u8, buf, "\n");

    var part1: N = 0;
    var part2: N = 0;

    var y: usize = 0;
    while (lines.next()) |l| {
        for (l) |c, x| {
            vMap[y][x] = try std.fmt.parseInt(u4, &.{c}, 10);
            fMap[y][x] = .high;
        }
        y += 1;
    }
    for (vMap) |row, yy| {
        for (row) |c, x| {
            if (c == 9) continue;

            var isLow: bool = true;
            var minDir: u4 = 9;
            var flow: Flow = .low;
            if (x < 99) {
                isLow = isLow and c < vMap[yy][x + 1];
                if (vMap[yy][x + 1] < minDir) {
                    minDir = vMap[yy][x + 1];
                    flow = .right;
                }
            }
            if (x > 0) {
                isLow = isLow and c < vMap[yy][x - 1];
                if (vMap[yy][x - 1] < minDir) {
                    minDir = vMap[yy][x - 1];
                    flow = .left;
                }
            }
            if (yy < 99) {
                isLow = isLow and c < vMap[yy + 1][x];
                if (vMap[yy + 1][x] < minDir) {
                    minDir = vMap[yy + 1][x];
                    flow = .bottom;
                }
            }
            if (yy > 0) {
                isLow = isLow and c < vMap[yy - 1][x];
                if (vMap[yy - 1][x] < minDir) {
                    minDir = vMap[yy - 1][x];
                    flow = .top;
                }
            }

            if (isLow) {
                fMap[yy][x] = .low;
            } else {
                fMap[yy][x] = flow;
            }
        }
    }

    var basins: [3]N = .{0} ** 3;

    for (fMap) |row, yy| {
        for (row) |c, x| {
            if (c == .low) {
                part1 += vMap[yy][x] + 1;
                var basin = findBasinSize(x, yy);
                for (basins) |b, i| {
                    if (basin > b) {
                        basins[i] = basin;
                        basin = b;
                    }
                }
            }
        }
    }

    part2 = 1;
    for (basins) |b| {
        part2 *= b;
    }

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

fn findBasinSize(x: N, y: N) N {
    var b: N = 1;
    if (x > 0) {
        b += findBasinSize2(x, y, x - 1, y);
    }
    if (x < 99) {
        b += findBasinSize2(x, y, x + 1, y);
    }
    if (y > 0) {
        b += findBasinSize2(x, y, x, y - 1);
    }
    if (y < 99) {
        b += findBasinSize2(x, y, x, y + 1);
    }

    return b;
}

fn findBasinSize2(px: N, py: N, x: N, y: N) N {
    var c = vMap[y][x];
    var f = fMap[y][x];
    if (c == 9) return 0;
    if (px != x) {
        if (px > x and f != .right) return 0;
        if (px < x and f != .left) return 0;
    }
    if (py != y) {
        if (py > y and f != .bottom) return 0;
        if (py < y and f != .top) return 0;
    }

    var b: N = 1;
    if (x > 0 and x - 1 != px) {
        b += findBasinSize2(x, y, x - 1, y);
    }
    if (x < 99 and x + 1 != px) {
        b += findBasinSize2(x, y, x + 1, y);
    }
    if (y > 0 and y - 1 != py) {
        b += findBasinSize2(x, y, x, y - 1);
    }
    if (y < 99 and y + 1 != py) {
        b += findBasinSize2(x, y, x, y + 1);
    }

    return b;
}
