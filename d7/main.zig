const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const N = usize;

fn findGeometricMean(nums: []const N, min: N, max: N) N {
    var i = min;
    var min_fuel: N = std.math.maxInt(N);
    while (i < max) : (i += 1) {
        var fuel: N = 0;
        for (nums) |n| {
            fuel += if (n < i) i - n else n - i;
        }

        if (fuel < min_fuel) min_fuel = fuel;
    }
    return min_fuel;
}

fn newFuel(n: N) N {
    var nn = @intToFloat(f64, n);
    return @floatToInt(N, (nn) * (nn + 1) / 2);
}

fn findGeometricMean2(nums: []const N, min: N, max: N) N {
    var i = min;
    var min_fuel: N = std.math.maxInt(N);
    while (i < max) : (i += 1) {
        var fuel: N = 0;
        for (nums) |n| {
            fuel += if (n < i) newFuel(i - n) else newFuel(n - i);
        }

        if (fuel < min_fuel) min_fuel = fuel;
    }
    return min_fuel;
}

fn solution(buf: []const u8) ![2]N {
    var tokens = std.mem.tokenize(u8, buf, ",\n");
    var nums = std.ArrayList(N).init(&gpa.allocator);
    defer nums.deinit();
    var max: N = 0;
    var min: N = std.math.maxInt(N);

    while (tokens.next()) |t| {
        var n = try std.fmt.parseInt(N, t, 10);
        try nums.append(n);
        if (n < min) min = n;
        if (n > max) max = n;
    }

    return [2]N{ findGeometricMean(nums.items, min, max), findGeometricMean2(nums.items, min, max) };
}

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(&gpa.allocator, 1000000);
    defer gpa.allocator.free(bytes);

    std.debug.print("{any}", .{try solution(bytes)});
}
