const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const N = usize;
var field: [1000][1000]N = std.mem.zeroes([1000][1000]N);

const Line = struct {
    from: [2]N,
    to: [2]N,
};

fn renderLine(line: Line) void {
    var x = line.from[0];
    var y = line.from[1];

    var xdif: i32 = @intCast(i32, line.to[0]) - @intCast(i32, line.from[0]);
    var ydif: i32 = @intCast(i32, line.to[1]) - @intCast(i32, line.from[1]);

    while (y != line.to[1] or x != line.to[0]) {
        field[y][x] += 1;

        if (xdif > 0) {
            x += 1;
        } else if (xdif < 0) {
            x -= 1;
        }

        if (ydif > 0) {
            y += 1;
        } else if (ydif < 0) {
            y -= 1;
        }
    }

    field[line.to[1]][line.to[0]] += 1;
}

fn countOverlaps() N {
    var count: N = 0;
    for (field) |row| {
        for (row) |cell| {
            if (cell > 1) count += 1;
        }
    }
    return count;
}

fn solution(buf: []const u8) !N {
    var tokens = std.mem.tokenize(u8, buf, "\n ,->");
    while (tokens.next()) |t| {
        var x1 = try std.fmt.parseInt(N, t, 10);
        var y1 = try std.fmt.parseInt(N, tokens.next().?, 10);
        var x2 = try std.fmt.parseInt(N, tokens.next().?, 10);
        var y2 = try std.fmt.parseInt(N, tokens.next().?, 10);
        var line = Line{
            .from = .{ x1, y1 },
            .to = .{ x2, y2 },
        };

        renderLine(line);
    }
    return countOverlaps();
}

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(&gpa.allocator, 1000000);
    defer gpa.allocator.free(bytes);

    std.debug.print("{}", .{try solution(bytes)});
}
