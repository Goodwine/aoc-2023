const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = []const PartNumberGroup;
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 4361, .wantP2 = 467835 },
    .{ .name = "large", .input = input_txt, .wantP1 = 529618, .wantP2 = 77509019 },
};

pub fn main() !void {
    std.debug.print("\nDay 3\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

const PartNumberGroup = struct {
    parts: [6]?Out = [_]?Out{null} ** 6,
    op: u8 = 0,
};

fn preprocess(input: []const u8) In {
    const lineSize = (std.mem.indexOfScalar(u8, input, '\n').?) + 1;

    // Compile-time buffer. I don't want to deal with the allocator yet.
    var groups = [_]PartNumberGroup{.{}} ** 1024;
    var groupCount: usize = 0;

    for (input, 0..) |char, pos| {
        switch (char) {
            '.', '0'...'9', '\n' => continue,
            else => {
                const row = pos / lineSize;
                const col = pos - row * lineSize;
                groups[groupCount] = parseGroup(
                    input,
                    lineSize,
                    row,
                    col,
                );
                groupCount += 1;
            },
        }
    }

    return groups[0..groupCount];
}

fn parseGroup(
    input: []const u8,
    lineSize: usize,
    row: usize,
    col: usize,
) PartNumberGroup {
    var group: PartNumberGroup = .{ .op = input[row * lineSize + col] };
    if (extractNumber(input, lineSize, row - 1, col)) |part| {
        group.parts[0] = part;
    } else {
        group.parts[0] = extractNumber(input, lineSize, row - 1, col - 1);
        group.parts[1] = extractNumber(input, lineSize, row - 1, col + 1);
    }
    group.parts[2] = extractNumber(input, lineSize, row, col - 1);
    group.parts[3] = extractNumber(input, lineSize, row, col + 1);
    if (extractNumber(input, lineSize, row + 1, col)) |part| {
        group.parts[4] = part;
    } else {
        group.parts[4] = extractNumber(input, lineSize, row + 1, col - 1);
        group.parts[5] = extractNumber(input, lineSize, row + 1, col + 1);
    }
    return group;
}

fn extractNumber(input: []const u8, lineSize: usize, row: usize, col: usize) ?Out {
    // This should check for negative numbers, however there are no negative
    // unsigned numbers. The program will crash instead. I didn't bother to
    // handle it because the input doesn't have an operator at row or column 0.
    if (row * lineSize >= input.len or col == lineSize) return null;

    const target = input[row * lineSize + col];
    if (target < '0' or target > '9') return null;

    const first = for (0..col + 1) |c| { //+1 because we do want to get down to zero when doing col - c, and the range is non-inclusive.
        const char = input[row * lineSize + col - c];
        if (char < '0' or char > '9') break col - c + 1; // +1 because the index would point to a non-number value.
    } else 0;
    const last = for (col..lineSize) |c| {
        const char = input[row * lineSize + c];
        if (char < '0' or char > '9') break c; // no need for +1 because the large number range is non-inclusive.
    } else {
        return null;
    };
    return std.fmt.parseInt(Out, input[row * lineSize + first .. row * lineSize + last], 10) catch null;
}

fn reset(input: *In) void {
    _ = input;
}

fn p1(input: *In) !Out {
    var sum: Out = 0;
    for (input.*) |group| {
        for (group.parts) |part| {
            sum += part orelse 0;
        }
    }
    return sum;
}

fn p2(input: *In) !Out {
    var sum: Out = 0;
    for (input.*) |group| {
        if (group.op != '*') continue;
        var gearCount: u8 = 0;
        var gearRatio: Out = 1;
        for (group.parts) |part| {
            gearCount += if (part) |_| 1 else 0;
            gearRatio *= part orelse 1;
        }
        if (gearCount == 2) sum += gearRatio;
    }
    return sum;
}
