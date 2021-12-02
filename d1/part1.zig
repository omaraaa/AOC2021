const std = @import("std");

fn countIncreasing(buf: []const u8) !usize {
    var i: usize = 0;
    var j: usize = 0;
    var pdepth: u16 = 0;
    var count: usize = 0;
    while (i < buf.len) : (i += 1) {
        if (buf[i] == '\n') {
            var depth = try std.fmt.parseInt(u16, buf[j..i], 10);
            if (depth > pdepth) count += 1;
            pdepth = depth;
            j = i + 1;
        }
    }
    return count - 1;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = &gpa.allocator;

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(allocator, 1000000);
    defer allocator.free(bytes);

    std.debug.print("{}", .{try countIncreasing(bytes)});
}
