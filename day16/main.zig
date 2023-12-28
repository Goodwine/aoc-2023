const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = aoc.StringGrid;
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 46, .wantP2 = 9 },
    .{ .name = "large", .input = input_txt, .wantP1 = 5, .wantP2 = 25 },
};

pub fn main() !void {
    std.debug.print("\nDay 16\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

fn preprocess(input: []const u8) In {
    return aoc.StringGrid.init(input);
}

fn reset(input: *In) void {
    _ = input;
}

fn p1(input: *In) !Out {
    const allocator = std.heap.page_allocator;
    var energized = std.AutoHashMap(Point, Direction).init(allocator);

    dfs(input, energized, .{ 0, 0 }, RIGHT);

    return energized.count();
}

fn dfs(input: *In, energized: std.AutoHashMap(Point, Direction), point: Point, dir: Direction) void {
    const old = energized.get(point) orelse 0;
    if ((dir & HORIZONTAL) != 0 and (old & HORIZONTAL) != 0) return;
    if ((dir & VERTICAL) != 0 and (old & VERTICAL) != 0) return;

    energized.put(point, old | dir);

    const next: Point = switch (dir) {
        LEFT => .{ .r = point.r, .c = std.math.sub(usize, point.c, 1) catch return },
        RIGHT => .{ .r = point.r, .c = point.c + 1 },
        UP => .{ .r = std.math.sub(usize, point.r, 1) catch return, .c = point.c },
        DOWN => .{ .r = point.r + 1, .c = point.c },
        else => unreachable,
    };

    const ch = input.at(point.r, point.c) orelse return;
    switch (ch) {
        '.' => dfs(input, energized, next, dir),
        '|' => switch (dir) {
            LEFT, RIGHT => todo,
            UP, DOWN => dfs(input, energized, next, dir),
            else => unreachable,
        },
        '-' => switch (dir) {
            LEFT, RIGHT => dfs(input, energized, next, dir),
            UP, DOWN => ,
            else => unreachable,
        },
        '/' => null,
        '\\' => null,
    }
}

const Point = struct { r: usize, c: usize };

const Direction = u4;
const LEFT: Direction = 0x1;
const RIGHT: Direction = 0x10;
const UP: Direction = 0x100;
const DOWN: Direction = 0x1000;
const HORIZONTAL: Direction = LEFT | RIGHT;
const VERTICAL: Direction = UP | DOWN;

fn p2(input: *In) !Out {
    _ = input;

    return 0;
}
