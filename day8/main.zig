const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = struct { actions: []const u8, nodes: std.StringHashMap([2][]const u8) };
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 6, .wantP2 = 6 },
    .{ .name = "large", .input = input_txt, .wantP1 = 13770, .wantP2 = 13129439557681 },
};

pub fn main() !void {
    std.debug.print("\nDay 8\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

fn preprocess(input: []const u8) In {
    _ = arena.reset(.retain_capacity);
    var nodes = std.StringHashMap([2][]const u8).init(arena.allocator());

    var lines = aoc.lines(input);
    const actions = lines.next() orelse unreachable;
    while (lines.next()) |line| {
        // Only get the letters from this format:
        // AAA = (BBB, BBB)
        var it = aoc.splitAny(line, "() =,");
        const name = it.next() orelse unreachable;
        const left = it.next() orelse unreachable;
        const right = it.next() orelse unreachable;
        nodes.put(name, .{ left, right }) catch unreachable;
    }

    return In{
        .actions = actions,
        .nodes = nodes,
    };
}

fn reset(input: *In) void {
    _ = input;
}

fn p1(input: *In) !Out {
    var current: []const u8 = "AAA"[0..];
    var steps: Out = 0;
    return while (true) : (steps += 1) {
        const action = input.actions[steps % input.actions.len];
        const node = input.nodes.get(current) orelse unreachable;
        current = switch (action) {
            'L' => node[0],
            'R' => node[1],
            else => unreachable,
        };
        if (std.mem.eql(u8, "ZZZ", current)) break steps + 1;
    } else unreachable;
}

const Work = struct {
    name: []const u8,
    z: ?Out = null,
};

fn p2(input: *In) !Out {
    var work = std.ArrayList(Work).init(arena.allocator());
    defer work.deinit();
    var keys = input.nodes.keyIterator();
    while (keys.next()) |key| {
        if (!std.mem.endsWith(u8, key.*, "A")) continue;
        work.append(.{
            .name = key.*,
        }) catch unreachable;
    }

    for (work.items) |*item| {
        var current = item.name;
        var steps: Out = 0;
        item.z = while (true) : (steps += 1) {
            const action = input.actions[steps % input.actions.len];
            const node = input.nodes.get(current) orelse unreachable;
            current = switch (action) {
                'L' => node[0],
                'R' => node[1],
                else => unreachable,
            };
            if (std.mem.endsWith(u8, current, "Z")) {
                break steps + 1;
            }
        } else unreachable;
    }

    var lcm: Out = work.items[0].z orelse unreachable;
    for (work.items[1..]) |item| {
        lcm = aoc.lcm(Out, lcm, item.z orelse unreachable);
    }

    return lcm;
}
