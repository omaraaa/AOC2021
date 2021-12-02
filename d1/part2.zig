const std = @import("std");

fn countIncreasingWindows(buf: []const u8) !usize {
    var i: usize = 0;
    var j: usize = 0;
    var w: [3]u16 = .{ 0, 0, 0 };
    var w_i: u8 = 0;
    var count: usize = 0;
    while (i < buf.len) : (i += 1) {
        if (buf[i] == '\n') {
            var depth = try std.fmt.parseInt(u16, buf[j..i], 10);

            if (w_i == 3) {
                var window = w[0] + w[1] + w[2];
                var nwindow = w[1] + w[2] + depth;
                if (nwindow > window) count += 1;
                w[0] = w[1];
                w[1] = w[2];
                w[2] = depth;
            } else {
                w[w_i] = depth;
                w_i += 1;
            }

            j = i + 1;
        }
    }
    return count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = &gpa.allocator;

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(allocator, 1000000);
    defer allocator.free(bytes);

    std.debug.print("{}", .{try countIncreasingWindows(bytes)});
}
