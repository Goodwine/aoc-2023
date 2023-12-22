const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = []const Board;
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 405, .wantP2 = 400 },
    .{ .name = "large", .input = input_txt, .wantP1 = 35538, .wantP2 = 30442 },
};

const Board = struct {
    horizontal: []Out,
    vertical: []Out,
    lineLen: usize,
};

pub fn main() !void {
    std.debug.print("\nDay 13\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

fn preprocess(input: []const u8) In {
    var horizontalBuf = std.ArrayList(Out).init(std.heap.page_allocator);
    defer horizontalBuf.deinit();
    var verticalBuf = std.ArrayList(Out).init(std.heap.page_allocator);
    defer verticalBuf.deinit();
    var boardBuf = std.ArrayList(Board).init(std.heap.page_allocator);
    defer boardBuf.deinit();

    var boards = aoc.split(input, "\n\n");
    while (boards.next()) |board| {
        var lines = aoc.lines(board);
        const lineLen = lines.peek().?.len;
        // Converts a 2D array of "#" and "." into binary numbers where "#" is
        // 1 and "." is 0. Each row and column are transformed into a different
        // number, and added to the appropriate list.
        while (lines.next()) |line| {
            var number: Out = 0;
            for (line) |c| {
                number <<= 1;
                if (c == '#') number += 1;
            }
            verticalBuf.append(number) catch unreachable;
        }
        for (0..lineLen) |i| {
            const shiftAmount: u6 = @intCast(lineLen - i - 1);
            const mask = @as(Out, 1) << shiftAmount;
            var number: Out = 0;
            for (verticalBuf.items) |v| {
                number <<= 1;
                if (mask & v > 0) number += 1;
            }
            horizontalBuf.append(number) catch unreachable;
        }

        boardBuf.append(.{
            .horizontal = horizontalBuf.toOwnedSlice() catch unreachable,
            .vertical = verticalBuf.toOwnedSlice() catch unreachable,
            .lineLen = lineLen,
        }) catch unreachable;
    }
    return boardBuf.toOwnedSlice() catch unreachable;
}

fn reset(input: *In) void {
    _ = input;
}

fn p1(input: *In) !Out {
    var sum: Out = 0;
    for (input.*) |board| {
        sum += findReflection(board.horizontal, null) orelse
            (findReflection(board.vertical, null).? * 100);
    }

    return sum;
}

// First, we find a pair of consecutive numbers with the same value.
// Then, we figure out whether it's a reflection.
// A reflection is valid if walking outwards from the pair of numbers,
// all numbers are equal unil we hit the end of the array on either direction.
// We can ignore the lines that are left after hitting the end of the array.
fn findReflection(numbers: []const Out, ignore: ?Out) ?Out {
    for (numbers[1..], 0..) |n, prevIdx| {
        if (prevIdx + 1 == ignore) continue;
        const prev = numbers[prevIdx];
        if (prev != n) continue;
        const len = @min(prevIdx, numbers.len - prevIdx - 2);
        const isReflection = for (0..len) |i| {
            if (numbers[prevIdx - i - 1] != numbers[prevIdx + i + 2]) {
                break false;
            }
        } else true;
        if (isReflection) return prevIdx + 1;
    }
    return null;
}

fn p2(input: *In) !Out {
    var sum: Out = 0;

    for (input.*) |board| {
        const originalVertical = findReflection(board.vertical, null);
        const originalHorizontal = findReflection(board.horizontal, null);

        sum += for (0..board.vertical.len) |row| {
            const x = for (0..board.lineLen) |col| {
                // flip vertical[row] bit at col
                const verticalShiftAmount: u6 = @intCast(board.lineLen - col - 1);
                const verticalMask = @as(Out, 1) << verticalShiftAmount;
                board.vertical[row] ^= verticalMask;

                // flip horizontal[col] bit at row
                const horizontalShiftAmount: u6 = @intCast(board.vertical.len - row - 1);
                const horizontalMask = @as(Out, 1) << horizontalShiftAmount;
                board.horizontal[col] ^= horizontalMask;

                // Skip reflection if it matches the original one.
                if (findReflection(board.horizontal, originalHorizontal)) |h| {
                    break h;
                } else if (findReflection(board.vertical, originalVertical)) |v| {
                    break v * 100;
                }

                // flip back
                board.vertical[row] ^= verticalMask;
                board.horizontal[col] ^= horizontalMask;
            } else null;
            if (x) |v| break v;
        } else unreachable;
    }

    return sum;
}
