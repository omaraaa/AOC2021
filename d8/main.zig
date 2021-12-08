const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const N = usize;

pub fn isPart1(len: usize) N {
    switch (len) {
        2, 3, 4, 7 => return 1,
        else => return 0,
    }
}

fn intoU7(c: u8) u7 {
    return @as(u7, 1) << @intCast(u3, c - 'a');
}

fn intoSet(i: []const u8) u7 {
    var s: u7 = 0;
    for (i) |c| {
        s |= intoU7(c);
    }

    return s;
}

const Decoder = struct {
    segs: [7]u7 = .{0b1111111} ** 7,

    pub fn push(self: *@This(), i: []const u8) void {
        if (i.len == 7) return;
        var set = intoSet(i);
        var segs = &self.segs;

        switch (i.len) {
            2 => {
                segs[0] = segs[0] & ~set;
                segs[1] = segs[1] & ~set;
                segs[2] = segs[2] & set;
                segs[3] = segs[3] & ~set;
                segs[4] = segs[4] & ~set;
                segs[5] = segs[5] & set;
                segs[6] = segs[6] & ~set;
            },
            3 => {
                segs[0] = segs[0] & set;
                segs[1] = segs[1] & ~set;
                segs[2] = segs[2] & set;
                segs[3] = segs[3] & ~set;
                segs[4] = segs[4] & ~set;
                segs[5] = segs[5] & set;
                segs[6] = segs[6] & ~set;
            },
            4 => {
                segs[0] = segs[0] & ~set;
                segs[1] = segs[1] & set;
                segs[2] = segs[2] & set;
                segs[3] = segs[3] & set;
                segs[4] = segs[4] & ~set;
                segs[5] = segs[5] & set;
                segs[6] = segs[6] & ~set;
            },
            5 => {
                segs[0] = segs[0] & set;
                segs[3] = segs[3] & set;
                segs[6] = segs[6] & set;
            },
            6 => {
                segs[0] = segs[0] & set;
                segs[1] = segs[1] & set;
                segs[5] = segs[5] & set;
                segs[6] = segs[6] & set;
            },
            else => unreachable,
        }
    }

    pub fn final_pass(self: *@This()) void {
        var done: usize = 0;
        while (done != 7) {
            done = 0;
            for (self.segs) |seg, i| {
                switch (seg) {
                    1, 2, 4, 8, 16, 32, 64 => {
                        for (self.segs) |_, j| {
                            if (i == j) continue;
                            self.segs[j] = self.segs[j] & ~self.segs[i];
                        }
                        done += 1;
                    },
                    else => {},
                }
            }
        }
    }

    pub fn decode(self: *@This(), i: []const u8) N {
        switch (i.len) {
            2 => {
                return 1;
            },
            3 => {
                return 7;
            },
            4 => {
                return 4;
            },
            7 => {
                return 8;
            },

            5 => {
                for (i) |c| {
                    if (self.segs[1] == intoU7(c)) return 5;
                    if (self.segs[4] == intoU7(c)) return 2;
                }
                return 3;
            },

            6 => {
                var is: u3 = 0b111;
                for (i) |c| {
                    if (self.segs[3] & intoU7(c) != 0) is &= 0b011;
                    if (self.segs[2] & intoU7(c) != 0) is &= 0b101;
                    if (self.segs[4] & intoU7(c) != 0) is &= 0b110;
                }
                switch (is) {
                    0b100 => return 0,
                    0b010 => return 6,
                    0b001 => return 9,
                    else => {
                        unreachable;
                    },
                }
            },
            else => unreachable,
        }
    }
};

fn solution(buf: []const u8) ![2]N {
    var lines = std.mem.tokenize(u8, buf, "\n");

    var part1: N = 0;
    var part2: N = 0;

    while (lines.next()) |l| {
        var mutliple: N = 1000;
        var decoder = Decoder{};
        var split = std.mem.tokenize(u8, l, "|");

        var inputs = std.mem.tokenize(u8, split.next().?, " ");
        var outputs = std.mem.tokenize(u8, split.next().?, " ");

        while (inputs.next()) |i| {
            decoder.push(i);
        }
        decoder.final_pass();

        while (outputs.next()) |o| {
            part1 += isPart1(o.len);
            part2 += decoder.decode(o) * mutliple;
            mutliple /= 10;
        }
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
