const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const N = usize;

const State = struct {
    cells: [10][10]u8 = undefined,
    flash_count: N = 0,
    flash_count_per_step: N = 0,

    pub fn step(self: *@This()) void {
        self.flash_count_per_step = 0;
        for (self.cells) |row, y| {
            for (row) |_, x| {
                self.increment(@intCast(i32, x), @intCast(i32, y));
            }
        }

        for (self.cells) |row, y| {
            for (row) |_, x| {
                self.flash(x, y);
            }
        }
    }

    fn increment(self: *@This(), x: i32, y: i32) void {
        if (x < 0) return;
        if (x >= 10) return;
        if (y < 0) return;
        if (y >= 10) return;

        var xx = @intCast(usize, x);
        var yy = @intCast(usize, y);

        if (self.cells[yy][xx] > 9) return;

        self.cells[yy][xx] += 1;
        if (self.cells[yy][xx] > 9) {
            self.increment(x + 1, y);
            self.increment(x - 1, y);
            self.increment(x, y + 1);
            self.increment(x, y - 1);
            self.increment(x + 1, y + 1);
            self.increment(x - 1, y - 1);
            self.increment(x + 1, y - 1);
            self.increment(x - 1, y + 1);
        }
    }

    fn flash(self: *@This(), x: usize, y: usize) void {
        if (self.cells[y][x] <= 9) return;

        self.cells[y][x] = 0;
        self.flash_count += 1;
        self.flash_count_per_step += 1;
    }
};

fn solution(buf: []const u8) ![2]N {
    var lines = std.mem.tokenize(u8, buf, "\n");

    var part1: ?N = null;
    var part2: ?N = null;

    var state: State = .{};
    var y: usize = 0;
    while (lines.next()) |l| {
        for (l) |c, x| {
            state.cells[y][x] = c - '0';
        }
        y += 1;
    }

    var i: usize = 0;
    while (part1 == null or part2 == null) : (i += 1) {
        state.step();
        if (i == 99) {
            part1 = state.flash_count;
        }
        if (state.flash_count_per_step == 100 and part2 == null) {
            part2 = i + 1;
        }
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
