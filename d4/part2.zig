const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const Cell = struct {
    marked: bool = false,
    number: usize,
};
const Board = struct {
    cells: [5][5]Cell,
    won: bool = false,
};

fn bingo(board: *Board, num: usize) bool {
    if (board.won) return false;
    var col_bingo: [5]u3 = .{0} ** 5;
    for (board.cells) |*row| {
        var row_bingo: u3 = 0;
        for (row) |*cell, c| {
            if (num == cell.number) {
                cell.marked = true;
            }
            if (cell.marked) {
                col_bingo[c] += 1;
                row_bingo += 1;
            }
            if (row_bingo == 5 or col_bingo[c] == 5) {
                board.won = true;
                return true;
            }
        }
    }
    return false;
}

const Winner = struct {
    board: *Board,
    number: usize,
};

fn runBingo(nums: []const usize, boards: []Board) !Winner {
    var draw: usize = 0;
    var last_winner: Winner = undefined;
    var winner_count: usize = 0;
    while (draw < nums.len and winner_count < boards.len) : (draw += 1) {
        var num = nums[draw];
        for (boards) |*b| {
            if (bingo(b, num)) {
                last_winner = Winner{ .board = b, .number = num };
                winner_count += 1;
            }
        }
    }
    return last_winner;
}

fn getFinalScore(winner: Winner) usize {
    var sum: usize = 0;
    for (winner.board.cells) |row| {
        for (row) |c| {
            if (!c.marked) sum += c.number;
        }
    }
    return sum * winner.number;
}

const ParsingState = enum {
    numbers,
    boards,
};

fn solution(buf: []const u8) !usize {
    var state: ParsingState = .numbers;

    var i: usize = 0;
    var j: usize = 0;

    var nums = std.ArrayList(usize).init(&gpa.allocator);
    defer nums.deinit();

    var boards = std.ArrayList(Board).init(&gpa.allocator);
    defer boards.deinit();
    var bindex: usize = 0;
    var col: usize = 0;
    var row: usize = 0;

    while (i < buf.len) : (i += 1) {
        switch (state) {
            .numbers => {
                switch (buf[i]) {
                    ',' => {
                        try nums.append(try std.fmt.parseInt(usize, buf[j..i], 10));
                        j = i + 1;
                    },
                    '\n' => {
                        try nums.append(try std.fmt.parseInt(usize, buf[j..i], 10));
                        j = i;
                        state = .boards;
                        i += 1;
                    },
                    else => {},
                }
            },
            .boards => {
                switch (buf[i]) {
                    ' ', '\n' => {},
                    else => {
                        if (bindex == boards.items.len) {
                            _ = try boards.addOne();
                        }

                        var add: usize = 1;
                        if (buf[i + 1] != ' ' and buf[i + 1] != '\n') {
                            add = 2;
                        }
                        var n = try std.fmt.parseInt(usize, buf[i .. i + add], 10);
                        boards.items[bindex].cells[row][col] = .{ .number = n };

                        col += 1;
                        if (col == 5) {
                            col = 0;
                            row += 1;
                        }
                        if (row == 5) {
                            col = 0;
                            row = 0;
                            bindex += 1;
                        }
                        i += add;
                    },
                }
            },
        }
    }
    var winner = try runBingo(nums.items[0..], boards.items[0..]);
    return getFinalScore(winner);
}

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(&gpa.allocator, 1000000);
    defer gpa.allocator.free(bytes);

    std.debug.print("{}", .{try solution(bytes)});
}
