const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = struct {
    emptyRows: std.ArrayList(usize),
    emptyCols: std.ArrayList(usize),
    nodes: std.ArrayList([2]Out),
};
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 374, .wantP2 = 82000210 },
    .{ .name = "large", .input = input_txt, .wantP1 = 9418609, .wantP2 = 593821230983 },
};

pub fn main() !void {
    std.debug.print("\nDay 11\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

fn preprocess(input: []const u8) In {
    _ = arena.reset(.retain_capacity);

    var nodes = std.ArrayList([2]usize).initCapacity(arena.allocator(), 512) catch unreachable;

    var lines = aoc.lines(input);
    var row: usize = 0;
    const cols = (lines.peek().?).len;
    while (lines.next()) |line| : (row += 1) {
        for (line, 0..) |ch, col| {
            if (ch != '#') continue;
            nodes.append(.{ row, col }) catch unreachable;
        }
    }

    var seen = std.AutoHashMap(usize, aoc.Nothing).init(arena.allocator());
    defer seen.clearAndFree();

    for (nodes.items) |node| seen.put(node[0], .{}) catch unreachable;
    var emptyRows = std.ArrayList(usize).initCapacity(arena.allocator(), 128) catch unreachable;
    for (0..row) |r| {
        if (seen.contains(r)) continue;
        emptyRows.append(r) catch unreachable;
    }

    seen.clearRetainingCapacity();
    for (nodes.items) |node| seen.put(node[1], .{}) catch unreachable;
    var emptyCols = std.ArrayList(usize).initCapacity(arena.allocator(), 128) catch unreachable;
    for (0..cols) |c| {
        if (seen.contains(c)) continue;
        emptyCols.append(c) catch unreachable;
    }

    return .{ .emptyRows = emptyRows, .emptyCols = emptyCols, .nodes = nodes };
}

fn reset(input: *In) void {
    _ = input;
}

fn p1(input: *In) !Out {
    return solve(input, 2);
}

fn p2(input: *In) !Out {
    return solve(input, 1000000);
}

fn solve(input: *In, spaceGrowth: Out) Out {
    var sum: Out = 0;
    for (input.nodes.items, 0..) |from, i| {
        for (input.nodes.items[i..]) |to| {
            sum += spaceManhattan(input, from, to, spaceGrowth);
        }
    }
    return sum;
}

fn spaceManhattan(input: *In, from: [2]Out, to: [2]Out, spaceGrowth: Out) Out {
    const distance = aoc.absoluteDiff(Out, from[0], to[0]) + aoc.absoluteDiff(Out, from[1], to[1]);
    const offsets = countInBetween(input.emptyRows.items, from[0], to[0]) + countInBetween(input.emptyCols.items, from[1], to[1]);
    return distance + offsets * (spaceGrowth - 1);
}

fn countInBetween(empty: []const Out, a: Out, b: Out) Out {
    var count: Out = 0;
    const low = @min(a, b);
    const high = @max(a, b);
    for (empty) |v| {
        if (v >= low and v <= high) count += 1;
    }
    return count;
}
