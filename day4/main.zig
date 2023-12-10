const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = []const u6; // Map of ticket ID => number of wins.
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 13, .wantP2 = 30 },
    .{ .name = "large", .input = input_txt, .wantP1 = 25010, .wantP2 = 9924412 },
};

const Nothing = struct {};

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

pub fn main() !void {
    std.debug.print("\nDay 4\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

fn preprocess(input: []const u8) In {
    _ = arena.reset(.retain_capacity);

    var list = std.ArrayList(u6).init(arena.allocator());
    var winning = std.AutoHashMap(usize, Nothing).init(arena.allocator());
    defer winning.deinit();
    var numBuf = std.ArrayList(usize).init(arena.allocator());
    defer numBuf.deinit();

    var lineIterator = aoc.lines(input);
    while (lineIterator.next()) |line| {
        var splitter = aoc.splitAny(line, ":|");
        _ = splitter.next(); // Skip "Card {d}:"

        const winningList = aoc.parseInts(usize, &numBuf, splitter.next() orelse "", " ");
        winning.clearRetainingCapacity();
        for (winningList) |w| winning.put(w, .{}) catch unreachable;

        const numbers = aoc.parseInts(usize, &numBuf, splitter.next() orelse "", " ");
        var matches: u6 = 0;
        for (numbers) |n| {
            if (winning.contains(n)) matches += 1;
        }
        list.append(matches) catch unreachable;
    }
    return list.items;
}

fn reset(input: *In) void {
    _ = input;
}

fn p1(input: *In) !Out {
    var sum: usize = 0;
    for (input.*) |wins| {
        if (wins == 0) continue;
        sum += @as(usize, 1) << (wins - 1);
    }
    return sum;
}

fn p2(input: *In) !Out {
    var listMaker = std.ArrayList(usize).init(arena.allocator());
    listMaker.appendNTimes(1, input.len) catch unreachable;
    var ticketTracker = listMaker.items;

    for (input.*, 0..) |wins, id| {
        for (0..wins) |prize| {
            // Supposedly this will never ever go out of bouds.
            ticketTracker[id + prize + 1] += ticketTracker[id];
        }
    }
    var sum: usize = 0;
    for (ticketTracker) |ticket| sum += ticket;
    return sum;
}
