const std = @import("std");

const Command = union(enum) {
    forward: u4,
    down: u4,
    up: u4,

    pub fn parse(buf: []const u8) !Command {
        var amount = try std.fmt.parseInt(u4, buf[buf.len - 1 ..], 10);
        return switch (buf[0]) {
            'f' => Command{ .forward = amount },
            'd' => Command{ .down = amount },
            'u' => Command{ .up = amount },
            else => error.InvalidCommand,
        };
    }
};

fn solution(buf: []const u8) !i32 {
    var i: usize = 0;
    var j: usize = 0;

    var hor: i32 = 0;
    var ver: i32 = 0;
    var aim: i32 = 0;

    while (i < buf.len) : (i += 1) {
        if (buf[i] == '\n') {
            var command = try Command.parse(buf[j..i]);

            switch (command) {
                .forward => |a| {
                    hor += a;
                    ver += aim * a;
                },
                .down => |a| {
                    aim += a;
                },
                .up => |a| {
                    aim -= a;
                },
            }

            j = i + 1;
        }
    }
    return hor * ver;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = &gpa.allocator;

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(allocator, 1000000);
    defer allocator.free(bytes);

    std.debug.print("{}", .{try solution(bytes)});
}
