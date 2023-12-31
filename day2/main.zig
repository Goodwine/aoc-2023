const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = []const [32]Draw;
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 8, .wantP2 = 2286 },
    .{ .name = "large", .input = input_txt, .wantP1 = 2776, .wantP2 = 68638 },
};

pub fn main() !void {
    std.debug.print("\nDay 2\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

fn preprocess(input: []const u8) In {
    var lines = aoc.lines(input);

    // Aaaand... I hate Zig now. So if I want a dynamic buffer I must deal with
    // allocations myself because Zig is not as powerful as Rust. Like it's a
    // plus tat I don't have to worry about the borrowing and Box<> shenanigans
    // from Rust, but now I have to remember to call `allocator.free()`, or else
    // we all become unhappy, and there's no static analysis to remember that.
    // Because I don't want to deal with that, here we have a memory blob.
    // I guess it's not too bad, just not used to this kinda thing >_<.
    var gameBuf: [128][32]Draw = std.mem.zeroes([128][32]Draw);
    var gameId: u8 = 0;
    while (lines.next()) |line| : (gameId += 1) {
        var gameSplitter = aoc.split(line, ": ");
        _ = gameSplitter.next();
        const rawDraws = gameSplitter.next().?;

        var drawId: u8 = 0;
        var draws = aoc.split(rawDraws, "; ");
        while (draws.next()) |rawDraw| : (drawId += 1) {
            var cubeSplitter = aoc.split(rawDraw, ", ");

            while (cubeSplitter.next()) |cube| {
                var countColorSplitter = aoc.split(cube, " ");
                const countString = countColorSplitter.next().?;
                const count = std.fmt.parseUnsigned(u8, countString, 10) catch unreachable;
                const color = countColorSplitter.next().?;
                switch (color[0]) {
                    'r' => {
                        gameBuf[gameId][drawId].red += count;
                    },
                    'g' => {
                        gameBuf[gameId][drawId].green += count;
                    },
                    'b' => {
                        gameBuf[gameId][drawId].blue += count;
                    },
                    else => {
                        unreachable;
                    },
                }
            }
        }
    }

    return gameBuf[0..gameId];
}

fn reset(input: *In) void {
    _ = input;
}

fn Game(maxSize: usize) type {
    return struct {
        len: usize = maxSize,
        draws: []const Draw = [_]Draw{.{}} ** maxSize,
    };
}

const Draw =
    struct {
    red: u8 = 0,
    green: u8 = 0,
    blue: u8 = 0,
};

fn p1(input: *In) !Out {
    const threshold: Draw = .{ .red = 12, .green = 13, .blue = 14 };

    var sum: Out = 0;
    for (input.*, 1..) |game, id| {
        const possible = for (game) |draw| {
            if (draw.red > threshold.red) break false;
            if (draw.green > threshold.green) break false;
            if (draw.blue > threshold.blue) break false;
        } else true;
        if (possible) sum += id;
    }
    return sum;
}

fn p2(input: *In) !Out {
    var sum: Out = 0;
    for (input.*) |game| {
        var minRequired: Draw = .{};
        for (game) |draw| {
            minRequired.red = @max(minRequired.red, draw.red);
            minRequired.green = @max(minRequired.green, draw.green);
            minRequired.blue = @max(minRequired.blue, draw.blue);
        }
        const power = @as(Out, minRequired.red) *
            @as(Out, minRequired.green) *
            @as(Out, minRequired.blue);
        sum += power;
    }
    return sum;
}
