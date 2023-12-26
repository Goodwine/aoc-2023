const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = aoc.AnyCharIterator;
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 1320, .wantP2 = 145 },
    .{ .name = "large", .input = input_txt, .wantP1 = 510273, .wantP2 = 212449 },
};

pub fn main() !void {
    std.debug.print("\nDay 15\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

fn preprocess(input: []const u8) In {
    return aoc.splitAny(input, "\n,");
}

fn reset(input: *In) void {
    input.reset();
}

fn p1(input: *In) !Out {
    var sum: Out = 0;
    while (input.next()) |data| {
        sum += hash(data);
    }
    return sum;
}

fn hash(s: []const u8) Out {
    var sum: Out = 0;
    for (s) |ch| {
        sum += ch;
        sum *= 17;
        sum %= boxCount;
    }
    return sum;
}

const boxCount = 256;

fn p2(input: *In) !Out {
    const allocator = std.heap.page_allocator;
    var boxes = [_]Box{Box.init(allocator)} ** boxCount;

    while (input.next()) |operation| {
        const lens = Lens.parse(operation);
        const id = hash(lens.label);

        if (lens.focalLength) |_| {
            boxes[id].add(lens);
        } else {
            boxes[id].remove(lens.label);
        }
    }

    var focusPower: Out = 0;
    for (boxes, 1..) |box, boxId| {
        var slot: Out = 1;
        for (box.contents.items) |lens| {
            if (lens.label.len == 0) continue;
            focusPower += boxId * lens.focalLength.? * slot;
            slot += 1;
        }
    }
    return focusPower;
}

const Box = struct {
    const Self = @This();

    contents: std.ArrayList(Lens),

    fn init(allocator: std.mem.Allocator) Box {
        return .{
            .contents = std.ArrayList(Lens).init(allocator),
        };
    }

    fn clear(self: *Self) void {
        self.contents.clearAndFree();
    }

    fn add(self: *Self, lens: Lens) void {
        if (self.find(lens.label)) |i| {
            self.contents.items[i].focalLength = lens.focalLength.?;
        } else {
            self.contents.append(lens) catch unreachable;
        }
    }

    fn remove(self: *Self, label: []const u8) void {
        if (self.find(label)) |i| {
            // Wastes memory, but is easier to implement.
            // A better alternative is to use linked lists.
            self.contents.items[i].label = "";
            self.contents.items[i].focalLength = null;
        }
    }

    fn find(self: Self, label: []const u8) ?usize {
        return for (self.contents.items, 0..) |item, i| {
            if (std.mem.eql(u8, item.label, label)) break i;
        } else null;
    }
};

const Lens = struct {
    focalLength: ?Out,
    label: []const u8,

    fn parse(data: []const u8) Lens {
        const last = data[data.len - 1];
        return .{
            .label = if (last == '-') data[0 .. data.len - 1] else data[0 .. data.len - 2],
            .focalLength = if (last == '-') null else @intCast(last - '0'),
        };
    }
};
