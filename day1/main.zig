const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const medium_txt = @embedFile("medium.txt");
const input_txt = @embedFile("input.txt");

const In = aoc.LineIterator;
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 142, .wantP2 = 142 },
    .{ .name = "medium", .input = medium_txt, .wantP1 = aoc.Error.BadData, .wantP2 = 281 },
    .{ .name = "large", .input = input_txt, .wantP1 = 54388, .wantP2 = 53515 },
};

pub fn main() !void {
    std.debug.print("\nDay 1\n==========\n", .{});
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
    return solve(input, false);
}

fn p2(input: *In) !Out {
    return solve(input, true);
}

fn solve(input: *In, textDigits: bool) !Out {
    var sum: usize = 0;
    while (input.next()) |line| {
        const first =
            loop: for (line, 0..) |char, i|
        {
            switch (char) {
                '0'...'9' => {
                    break :loop char - '0';
                },
                else => {
                    if (!textDigits) continue;
                    if (tryNumber(line[i..])) |value| {
                        break :loop value;
                    }
                },
            }
        } else return aoc.Error.BadData;
        const last =
            loop: for (1..line.len + 1) |i|
        {
            switch (line[line.len - i]) {
                '0'...'9' => |char| {
                    break :loop char - '0';
                },
                else => {
                    if (!textDigits) continue;
                    if (reverseTryNumber(line[0 .. line.len - i + 1])) |value| {
                        break :loop value;
                    }
                },
            }
        } else return aoc.Error.BadData;

        sum += first * 10 + last;
    }

    return sum;
}

const digitNames = [_][]const u8{ "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

fn tryNumber(line: []const u8) ?usize {
    return for (digitNames, 0..) |name, i| {
        if (aoc.startsWith(line, name)) {
            return i;
        }
    } else null;
}

fn reverseTryNumber(line: []const u8) ?usize {
    return for (digitNames, 0..) |name, i| {
        if (aoc.endsWith(line, name)) {
            return i;
        }
    } else null;
}
