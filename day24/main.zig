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
    std.debug.print("\nDay 24\n==========\n", .{});
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
    return len(input);
}

fn p2(input: *In) !Out {
    const l = len(input);
    return l * l;
}

fn len(input: *In) Out {
    var c: usize = 0;
    while (input.next()) |_| c += 1;
    return c;
}
