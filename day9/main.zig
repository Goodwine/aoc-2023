const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = []const []const Out;
const Out = isize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 114, .wantP2 = 2 },
    .{ .name = "large", .input = input_txt, .wantP1 = 2174807968, .wantP2 = 1208 },
};

pub fn main() !void {
    std.debug.print("\nDay 9\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

fn preprocess(input: []const u8) In {
    var buf = std.ArrayList(Out).init(arena.allocator());
    defer buf.deinit();
    var lines = aoc.lines(input);
    var pascal = std.ArrayList([]const Out).init(arena.allocator());
    defer pascal.deinit();
    while (lines.next()) |line| {
        pascal.append(aoc.parseInts(Out, &buf, line, " ")) catch unreachable;
    }
    return pascal.toOwnedSlice() catch unreachable;
}

fn reset(input: *In) void {
    _ = input;
}

fn p1(input: *In) !Out {
    var buffer = [_]Out{0} ** 1024;
    defer arena.allocator().free(&buffer);
    var sum: Out = 0;
    for (input.*) |row| {
        std.mem.copyForwards(Out, &buffer, row);
        var curr = buffer[0..row.len];
        while (curr.len > 1) : (curr = curr[0 .. curr.len - 1]) {
            for (curr[1..], 0..) |v, i| {
                curr[i] = v - curr[i];
            }
        }
        for (buffer[0..row.len]) |v| {
            sum += v;
        }
    }
    return sum;
}

fn p2(input: *In) !Out {
    var buffer = [_]Out{0} ** 1024;
    defer arena.allocator().free(&buffer);
    var sum: Out = 0;
    for (input.*) |row| {
        std.mem.copyForwards(Out, &buffer, row);
        var curr = buffer[0..row.len];
        while (curr.len > 1) : (curr = curr[1..curr.len]) {
            for (curr[1..], 0..) |_, i| {
                const idx = curr.len - 1 - i;
                const v = curr[idx - 1];
                curr[idx] = v - curr[idx];
            }
        }
        for (buffer[0..row.len]) |v| {
            sum += v;
        }
    }
    return sum;
}

fn len(input: *In) Out {
    _ = input;
}
