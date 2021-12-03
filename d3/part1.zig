const std = @import("std");

fn solution(buf: []const u8) !usize {
    var i: usize = 0;
    var j: usize = 0;

    var bits: [12]i32 = .{0} ** 12;

    while (i < buf.len) : (i += 1) {
        switch (buf[i]) {
            '0' => {
                bits[j] -= 1;
                j += 1;
            },
            '1' => {
                bits[j] += 1;
                j += 1;
            },
            '\n' => {
                j = 0;
            },
            else => return error.UnexpectChar,
        }
    }

    var gamma: u12 = 0;
    for (bits) |b, ii| {
        if (b > 0) {
            gamma = gamma | (@as(u12, 1) << @intCast(u4, 11 - ii));
        } else if (b < 0) {
            gamma = gamma & (@as(u12, 0b111111111110) <<| @intCast(u4, 11 - ii));
        }
    }

    return @intCast(usize, gamma) * @intCast(usize, ~gamma);
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
