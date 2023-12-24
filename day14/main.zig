const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = []u8;
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 136, .wantP2 = 64 },
    .{ .name = "large", .input = input_txt, .wantP1 = 110821, .wantP2 = 83516 },
};

pub fn main() !void {
    std.debug.print("\nDay 14\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

fn preprocess(input: []const u8) In {
    var bufBlock = [_]u8{0} ** (1 << 20);
    var buf = bufBlock[0..input.len];
    std.mem.copyForwards(u8, buf[0..], input);
    return buf;
}

fn reset(input: *In) void {
    _ = input;
}

fn p1(input: *In) !Out {
    tiltNorth(input.*);
    return northLoad(input.*);
}

fn northLoad(data: []const u8) Out {
    const len = std.mem.indexOfScalar(u8, data, '\n').?;

    var sum: Out = 0;
    var rowValue = len;
    for (0..len) |row| {
        const line = data[pos(len, row, 0)..pos(len, row, len)];
        for (line) |ch| {
            if (ch != 'O') continue;
            sum += rowValue;
        }
        rowValue -= 1;
    }
    return sum;
}

fn tiltNorth(data: []u8) void {
    const len = std.mem.indexOfScalar(u8, data, '\n').?;

    var bufBlock = [_]Out{0} ** 128;
    var buf = bufBlock[0..len];

    for (0..len) |row| {
        const line = data[pos(len, row, 0)..pos(len, row, len)];
        for (line, 0..) |ch, col| {
            switch (ch) {
                'O' => {
                    data[pos(len, row, col)] = '.';
                    data[pos(len, buf[col], col)] = 'O';
                    buf[col] += 1;
                },
                '#' => {
                    buf[col] = row + 1;
                },
                else => {},
            }
        }
    }
}

// position considering the new-line character.
fn pos(n: usize, r: usize, c: usize) usize {
    return r * (n + 1) + c;
}

// (r,c) -> (c, n-1-r), but don't forget rows have a new-line character.
fn spinCW(data: []u8) void {
    const len = std.mem.indexOfScalar(u8, data, '\n').?;
    for (0..len / 2) |row| {
        for (0..len / 2) |col| {
            var r = row;
            var c = col;
            var ch = data[pos(len, r, c)];
            for (0..4) |_| {
                r, c = [_]usize{ c, len - 1 - r };
                const index = pos(len, r, c);
                const temp = data[index];
                data[index] = ch;
                ch = temp;
            }
        }
    }
}

fn p2(input: *In) !Out {
    const cycles = 1000000000;

    var seen = std.StringArrayHashMap(usize).init(std.heap.page_allocator);
    defer seen.clearAndFree();
    const cycle, const last = for (0..cycles) |cycle| {
        if (seen.get(input.*)) |last| break [_]usize{ cycle, last };
        seen.put(input.*, cycle) catch unreachable;

        spin(input.*);
    } else unreachable;

    const cycleLen = cycle - last;
    const cyclesLeft = (cycles - cycle) % cycleLen;

    for (0..cyclesLeft) |_| {
        spin(input.*);
    }

    return northLoad(input.*);
}

// Tilts N/W/S/E.
fn spin(input: []u8) void {
    for (0..4) |_| {
        tiltNorth(input);
        spinCW(input);
    }
}
