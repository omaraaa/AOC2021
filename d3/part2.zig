const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn isBitSet(n: u12, b: u4) bool {
    return (n & (@as(u12, 1) << (11 - b))) > 0;
}

fn getMCBit(slice: []u12, bit: u4) i32 {
    var mc: i32 = 0;
    for (slice) |n| {
        if (isBitSet(n, bit)) {
            mc += 1;
        } else {
            mc -= 1;
        }
    }
    return mc;
}

const FilterType = enum { ones, zeroes };
fn filter(comptime ft: FilterType, slice: []u12, bit: u4) []u12 {
    var len: usize = slice.len;
    var i: usize = 0;
    while (i < len) {
        var bs = isBitSet(slice[i], bit);
        if (!bs and ft == .zeroes or bs and ft == .ones) {
            len -= 1;
            var tmp = slice[i];
            slice[i] = slice[len];
            slice[len] = tmp;
        } else {
            i += 1;
        }
    }
    return slice[0..len];
}

const ValueType = enum { oxygen, co2 };
pub fn calc(comptime value: ValueType, nums: []u12) u12 {
    var bit: u4 = 0;
    var slice: []u12 = nums[0..];
    while (slice.len > 1) {
        var mc = getMCBit(slice, bit);
        if (mc >= 0 and value == .oxygen or mc < 0 and value == .co2) {
            slice = filter(.zeroes, slice, bit);
        } else {
            slice = filter(.ones, slice, bit);
        }
        bit += 1;
    }
    return slice[0];
}

fn solution(buf: []const u8) !usize {
    var i: usize = 0;
    var j: u4 = 0;
    var number: u12 = 0;

    var nums = std.ArrayList(u12).init(&gpa.allocator);
    defer nums.deinit();

    while (i < buf.len) : (i += 1) {
        switch (buf[i]) {
            '0' => {
                number = number & (@as(u12, 0b111111111110) <<| (11 - j));
                j += 1;
            },
            '1' => {
                number = number | (@as(u12, 1) << (11 - j));
                j += 1;
            },
            '\n' => {
                try nums.append(number);
                number = 0;
                j = 0;
            },
            else => return error.UnexpectChar,
        }
    }

    return @intCast(usize, calc(.oxygen, nums.items[0..])) * @intCast(usize, calc(.co2, nums.items[0..]));
}

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(&gpa.allocator, 1000000);
    defer allocator.free(bytes);

    std.debug.print("{}", .{try solution(bytes)});
}
