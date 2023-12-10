const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const bufSize = 1024;

const In = struct {
    const Self = @This();
    hands: [bufSize]Hand = [_]Hand{.{}} ** 1024,
    len: usize = 0,
    fn slice(self: *Self) []Hand {
        return self.hands[0..self.len];
    }
};
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 6440, .wantP2 = 5905 },
    .{ .name = "large", .input = input_txt, .wantP1 = 249204891, .wantP2 = 249666369 },
};

pub fn main() !void {
    std.debug.print("\nDay 7\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

const Hand = struct {
    cards: []const u8 = "",
    bid: usize = 0,
    kind: Kind = .None,
};

fn preprocess(input: []const u8) In {
    var buf: In = .{};
    var hands = &buf.hands;
    var lines = aoc.lines(input);
    while (lines.next()) |line| : (buf.len += 1) {
        hands[buf.len].cards = line[0..5];
        hands[buf.len].bid = std.fmt.parseInt(usize, line[6..], 10) catch unreachable;
    }

    return buf;
}

fn evalHand(cards: []const u8, hasJoker: bool) Kind {
    var counter = [_]u4{0} ** 128;
    for (cards) |c| counter[c] += 1;

    const jokerOffset: u4 = if (hasJoker) counter['J'] else 0;
    if (hasJoker) counter['J'] = 0;

    std.mem.sortUnstable(u4, &counter, {}, std.sort.desc(u4));

    return switch (counter[0] + jokerOffset) {
        1 => .None,
        2 => switch (counter[1]) {
            1 => .Pair,
            2 => .TwoPairs,
            else => unreachable,
        },
        3 => switch (counter[1]) {
            1 => .Three,
            2 => .Full,
            else => unreachable,
        },
        4 => .Four,
        5, 6 => .Five,
        else => unreachable,
    };
}

fn evalCard(c: u8, hasJoker: bool) u8 {
    return switch (c) {
        '2'...'9' => c - '0',
        'T' => 10,
        'J' => if (hasJoker) 0 else 11,
        'Q' => 12,
        'K' => 13,
        'A' => 14,
        else => unreachable,
    };
}

fn reset(input: *In) void {
    _ = input;
}

fn cmpByValue(hasJoker: bool, a: Hand, b: Hand) bool {
    if (a.kind == b.kind) {
        return for (a.cards, b.cards) |cardA, cardB| {
            if (cardA == cardB) continue;
            return evalCard(cardA, hasJoker) < evalCard(cardB, hasJoker);
        } else unreachable;
    }
    return @intFromEnum(a.kind) < @intFromEnum(b.kind);
}

fn p1(input: *In) !Out {
    return solve(false, input);
}

fn p2(input: *In) !Out {
    return solve(true, input);
}

fn solve(hasJoker: bool, input: *In) usize {
    var slice = input.slice();

    for (slice, 0..) |h, i| slice[i].kind = evalHand(h.cards, hasJoker);
    std.mem.sortUnstable(Hand, slice, hasJoker, cmpByValue);

    var sum: usize = 0;
    for (slice, 1..) |h, rank| {
        sum += h.bid * rank;
    }

    return sum;
}

const Kind = enum { None, Pair, TwoPairs, Three, Full, Four, Five };
