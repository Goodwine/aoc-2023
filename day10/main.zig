const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const medium_txt = @embedFile("medium.txt");
const medium_2_txt = @embedFile("medium_2.txt");
const medium_3_txt = @embedFile("medium_3.txt");
const input_txt = @embedFile("input.txt");

fn In(comptime T: type) type {
    return struct {
        const Self = @This();

        data: T,
        cols: usize,
        rows: usize,

        fn at(self: *Self, i: isize, j: isize) ?BitMask {
            const index = if (self.pos(i, j)) |p| p else return 0;
            const char = self.data[index];

            // | is a vertical pipe connecting north and south.
            // - is a horizontal pipe connecting east and west.
            // L is a 90-degree bend connecting north and east.
            // J is a 90-degree bend connecting north and west.
            // 7 is a 90-degree bend connecting south and west.
            // F is a 90-degree bend connecting south and east.
            // . is ground; there is no pipe in this tile.
            // S is the starting position of the animal; there is a pipe on this tile, but your sketch doesn't show what shape the pipe has.
            return switch (char) {
                '|' => NORTH | SOUTH,
                '-' => EAST | WEST,
                'L' => NORTH | EAST,
                'J' => NORTH | WEST,
                '7' => SOUTH | WEST,
                'F' => SOUTH | EAST,
                'S' => NORTH | EAST | WEST | SOUTH,
                ' ' => null,
                else => 0,
            };
        }

        fn pos(self: *Self, i: isize, j: isize) ?usize {
            if (i < 0 or j < 0 or i >= self.rows or j >= self.cols) return null;
            const u_i: usize = @intCast(i);
            const u_j: usize = @intCast(j);

            return u_i * self.cols + u_j;
        }

        fn coord(self: *Self, index: usize) [2]isize {
            const i = index / self.cols;
            const j = index % self.cols;
            return .{ @intCast(i), @intCast(j) };
        }

        fn start(self: *Self) [2]isize {
            const index = std.mem.indexOfScalar(u8, self.data, 'S').?;
            return self.coord(index);
        }
    };
}

const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 4, .wantP2 = 1 },
    .{ .name = "medium", .input = medium_txt, .wantP1 = 8, .wantP2 = 1 },
    .{ .name = "medium_2", .input = medium_2_txt, .wantP1 = 80, .wantP2 = 10 },
    .{ .name = "medium_3", .input = medium_3_txt, .wantP1 = 70, .wantP2 = 8 },
    .{ .name = "large", .input = input_txt, .wantP1 = 6649, .wantP2 = 601 },
};

pub fn main() !void {
    std.debug.print("\nDay 10\n==========\n", .{});
    aoc.solver(In([]const u8), Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In([]const u8), Out, &inputs, preprocess, p1, reset, p2);
}

fn preprocess(input: []const u8) In([]const u8) {
    var lines = aoc.lines(input);

    const firstLine = lines.next().?;
    const cols = firstLine.len;

    var rows: usize = 1;
    while (lines.next()) |_| rows += 1;

    return .{ .data = input, .rows = rows, .cols = cols + 1 };
}

fn reset(input: *In([]const u8)) void {
    _ = input;
}

const Work = struct {
    // i, j
    coord: [2]isize,
    from: BitMask,
    dist: usize,
};

const BitMask = u4;

// Direction
const SOUTH: BitMask = 1 << 0;
const EAST: BitMask = 1 << 1;
const WEST: BitMask = 1 << 2;
const NORTH: BitMask = 1 << 3;

const bufferSize = 20 * 1 << 10;

fn p1(input: *In([]const u8)) !Out {
    const seen = solve(input);
    var max: usize = 0;
    for (seen) |v| max = @max(max, v);
    return max - 1;
}

const token = 1 << 20;

fn p2(input: *In([]const u8)) !Out {
    const seen = solve(input);
    var blownUp = blowUp3(input, seen);

    exploreOutside(&blownUp, 0, 0);

    var count: usize = 0;
    var i: isize = 1;
    while (i < blownUp.rows) : (i += 3) {
        var j: isize = 1;
        while (j < blownUp.cols) : (j += 3) {
            if (blownUp.pos(i, j)) |pos| {
                if (blownUp.data[pos] == ' ') count += 1;
            }
        }
    }
    return count;
}

/// The reason we blow up a matrix to 3 is to properly identify what counts as
/// being inside or outside a loop. Given this with no obious spaces:
/// ```
/// F7
/// LJ
/// ```
/// This becomes:
/// ```
/// ......
/// .F--7.
/// .|..|.
/// .|..|.
/// .L--J.
/// ......
/// ```
///
/// Then we just have to "probe" the center point of each 3x3 block to know
/// whether the space was actually a blank or a pipe.
fn blowUp3(input: *In([]const u8), seen: []const Out) In([bufferSize * 9]u8) {
    const data = [_]u8{' '} ** (bufferSize * 9);

    var blownUp: In([bufferSize * 9]u8) = .{
        // This can't be a slice, when passed as a slice Zig will corrupt this
        // block when doing the exploration, probably too big for the stack.
        .data = data,
        .cols = input.cols * 3,
        .rows = input.rows * 3,
    };

    for (seen, 0..) |d, originalPos| {
        if (d == 0) continue;

        const originalCoords = input.coord(originalPos);
        const pipe = input.at(originalCoords[0], originalCoords[1]).?;

        const blownPosCenter = blownUp.pos(originalCoords[0] * 3 + 1, originalCoords[1] * 3 + 1).?;
        const row, const col = blownUp.coord(blownPosCenter);
        const pipeCoords = [_]?[2]isize{
            .{ row, col },
            if (pipe & SOUTH != 0) .{ row + 1, col } else null,
            if (pipe & NORTH != 0) .{ row - 1, col } else null,
            if (pipe & EAST != 0) .{ row, col + 1 } else null,
            if (pipe & WEST != 0) .{ row, col - 1 } else null,
        };
        for (pipeCoords) |maybeCoord| {
            if (maybeCoord) |coord| {
                if (blownUp.pos(coord[0], coord[1])) |pos| {
                    blownUp.data[pos] = 'S';
                }
            }
        }
    }

    return blownUp;
}

fn exploreOutside(input: *In([bufferSize * 9]u8), row: isize, col: isize) void {
    const pipe = input.at(row, col);
    if (pipe != null) return;
    const pos = input.pos(row, col).?;
    input.data[pos] = 'O';

    const adjacent = [_][2]isize{
        .{ row - 1, col },
        .{ row + 1, col },
        .{ row, col - 1 },
        .{ row, col + 1 },
    };

    for (adjacent) |n| {
        exploreOutside(input, n[0], n[1]);
    }
}

fn solve(input: *In([]const u8)) []const Out {
    var seen = [_]Out{0} ** bufferSize;
    var work = aoc.QueueBlob(Work, bufferSize * 2).init();

    work.push(.{ .coord = input.start(), .from = NORTH, .dist = 1 });
    while (work.pop()) |next| {
        const i, const j = next.coord;
        const pos = if (input.pos(i, j)) |p| p else continue;
        if (seen[pos] != 0) continue;
        const pipe = input.at(i, j).?;
        if (pipe & next.from == 0) continue; // impossible case like offbounds, no connection

        seen[pos] = next.dist; // commit distance.

        const potentialWork = [_]?Work{
            if (pipe & SOUTH != 0) .{ .coord = .{ i + 1, j }, .dist = next.dist + 1, .from = NORTH } else null,
            if (pipe & NORTH != 0) .{ .coord = .{ i - 1, j }, .dist = next.dist + 1, .from = SOUTH } else null,
            if (pipe & EAST != 0) .{ .coord = .{ i, j + 1 }, .dist = next.dist + 1, .from = WEST } else null,
            if (pipe & WEST != 0) .{ .coord = .{ i, j - 1 }, .dist = next.dist + 1, .from = EAST } else null,
        };
        for (potentialWork) |maybeWork| if (maybeWork) |w| work.push(w);
    }

    return seen[0..input.data.len];
}
