const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = aoc.LineIterator;
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 3, .wantP2 = 9 },
    .{ .name = "large", .input = input_txt, .wantP1 = 5, .wantP2 = 25 },
};

pub fn main() !void {
    std.debug.print("\nDay 14\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

fn preprocess(input: []const u8) In {
    return aoc.lines(input);
}

fn reset(input: *In) void {
    input.reset();
}

fn p1(input: *In) !Out {
    var lineCount: usize = 0;
    while (input.next()) |_| : (lineCount += 1) {}
    input.reset();

    var bufBlock = [_]Out{lineCount} ** 128;
    const buf = bufBlock[0..input.peek().?.len];

    var sum: Out = 0;
    var row = lineCount;
    while (input.next()) |line| : (row -= 1) {
        for (line, 0..) |ch, col| {
            switch (ch) {
                'O' => {
                    sum += buf[col];
                    buf[col] -= 1;
                },
                '#' => {
                    // sum += row; // Part 1 doesn't count round rocks.
                    buf[col] = row - 1;
                },
                else => {},
            }
        }
    }
    return sum;
}

fn p2(input: *In) !Out {
    _ = input;

    return 0;
}
