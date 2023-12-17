const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = Almanac;
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 35, .wantP2 = 46 },
    .{ .name = "large", .input = input_txt, .wantP1 = 261668924, .wantP2 = 24261545 },
};

const Almanac = struct {
    const Self = @This();

    seeds: []const Out,
    maps: []InstructionSet,
};

const InstructionSet = struct {
    const Self = @This();

    set: []Instruction,

    fn intersections(self: *const Self, fromSet: InstructionSet) InstructionSet {
        var set = std.ArrayList(Instruction).init(arena.allocator());
        defer set.deinit();

        for (fromSet.set) |from| {
            for (self.set) |target| {
                if (from.intersect(target)) |intersection| {
                    set.append(intersection) catch unreachable;
                }
            }
        }

        return .{ .set = set.toOwnedSlice() catch unreachable };
    }

    fn fillGaps(self: *Self) void {
        std.mem.sortUnstable(Instruction, self.set, {}, lessThan);

        var missing = std.ArrayList(Instruction).init(arena.allocator());
        defer missing.deinit();
        var prev: Out = 0;
        for (self.set) |instruction| {
            if (instruction.source != prev) {
                missing.append(.{
                    .destination = prev,
                    .source = prev,
                    .count = instruction.source - prev,
                }) catch unreachable;
            }
            prev = instruction.source + instruction.count;
        }
        missing.append(.{
            .destination = prev,
            .source = prev,
            .count = 1e9,
        }) catch unreachable;
        missing.appendSlice(self.set) catch unreachable;
        self.set = missing.toOwnedSlice() catch unreachable;
    }
};

fn lessThan(context: void, lhs: Instruction, rhs: Instruction) bool {
    _ = context;
    return lhs.source < rhs.source;
}

const Instruction = struct {
    const Self = @This();

    destination: Out,
    source: Out,
    count: Out,

    fn intersect(self: *const Self, target: Instruction) ?Instruction {
        if (self.destination + self.count <= target.source) return null;
        if (self.destination >= target.source + target.count) return null;

        const diff = aoc.absoluteDiff(Out, target.destination, target.source);
        const add = target.destination >= target.source;
        const transformedSource = if (add) self.destination + diff else if (diff >= self.destination) 0 else self.destination - diff;
        const newEnd = @min(
            target.destination + target.count,
            transformedSource + self.count,
        );
        const newDestination = @max(target.destination, transformedSource);

        return .{
            .destination = newDestination,
            .source = 0, // doesn't matter
            .count = newEnd - newDestination,
        };
    }
};

pub fn main() !void {
    std.debug.print("\nDay 5\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

fn preprocess(input: []const u8) In {
    _ = arena.reset(.retain_capacity);

    // All buffers
    var buffer = std.ArrayList(Out).init(arena.allocator());
    defer buffer.deinit();
    var instructions = std.ArrayList(Instruction).init(arena.allocator());
    defer instructions.deinit();
    var maps = std.ArrayList(InstructionSet).init(arena.allocator());
    defer maps.deinit();

    // Split data by almanac entries.
    var almanacEntries = aoc.split(input, "\n\n");

    // Parse the seeds.
    const seedsRaw = almanacEntries.next().?;
    const seeds = aoc.parseInts(Out, &buffer, seedsRaw["seeds: ".len..], " ");

    // Parse all the almanac maps.
    while (almanacEntries.next()) |entry| {
        instructions.clearRetainingCapacity();
        const splitAt = 1 + (std.mem.indexOfScalar(u8, entry, ':').?);

        const data = aoc.parseInts(Out, &buffer, entry[splitAt..], " \n");
        var window = std.mem.window(Out, data, 3, 3);
        while (window.next()) |instructionRaw| {
            instructions.append(.{
                .destination = instructionRaw[0],
                .source = instructionRaw[1],
                .count = instructionRaw[2],
            }) catch unreachable;
        }
        var set: InstructionSet = .{ .set = instructions.toOwnedSlice() catch unreachable };
        set.fillGaps();
        maps.append(set) catch unreachable;
    }

    return .{
        .seeds = seeds,
        .maps = maps.toOwnedSlice() catch unreachable,
    };
}

fn reset(input: *In) void {
    _ = input;
}

fn p1(input: *In) !Out {
    var buffer = std.ArrayList(Instruction).init(arena.allocator());
    defer buffer.deinit();

    for (input.seeds) |seed| {
        buffer.append(.{
            .destination = seed,
            .source = 0,
            .count = 1,
        }) catch unreachable;
    }

    return solve(input, buffer.items);
}

fn p2(input: *In) !Out {
    var buffer = std.ArrayList(Instruction).init(arena.allocator());
    defer buffer.deinit();

    var window = std.mem.window(Out, input.seeds, 2, 2);
    while (window.next()) |range| {
        buffer.append(.{
            .destination = range[0],
            .source = 0,
            .count = range[1],
        }) catch unreachable;
    }

    return solve(input, buffer.items);
}

fn solve(input: *In, seeds: []Instruction) Out {
    var current: InstructionSet = .{ .set = seeds };
    for (input.maps) |map| {
        current = map.intersections(current);
    }
    var min = current.set[0].destination;
    for (current.set[1..]) |instruction| {
        min = @min(min, instruction.destination);
    }
    return min;
}
