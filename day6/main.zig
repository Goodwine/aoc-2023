const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = Data;
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 288, .wantP2 = 71503 },
    .{ .name = "large", .input = input_txt, .wantP1 = 861300, .wantP2 = 28101347 },
};

const Data = struct {
    races: []const Race,
    finalRace: Race,
};

const BSOutcome = enum { High, Low, Flat };

const Race = struct {
    time: usize = 0,
    distance: usize = 0,

    fn charge(self: *const Race, t: usize) usize {
        const speed = t;
        const timeLeft = self.time - t;
        return timeLeft * speed;
    }

    fn trend(self: *const Race, curr: usize) BSOutcome {
        const left = self.charge(curr - 1);
        const probe = self.charge(curr);
        if (left == probe) return .Flat;
        if (left < probe) return .High;
        return .Low;
    }
};

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

pub fn main() !void {
    std.debug.print("\nDay 6\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

const bufSize = 4;

fn preprocess(input: []const u8) In {
    _ = arena.reset(.retain_capacity);

    var races = std.ArrayList(Race).init(arena.allocator());
    var intBuf = std.ArrayList(usize).init(arena.allocator());
    defer intBuf.clearAndFree();
    var strBuf = std.ArrayList(u8).init(arena.allocator());
    defer strBuf.clearAndFree();

    var lines = aoc.lines(input);

    const rawTimes = (lines.next() orelse unreachable)["Distance:".len..];
    const times = aoc.parseInts(usize, &intBuf, rawTimes, " ");
    var it = aoc.splitAny(rawTimes, " ");
    while (it.next()) |numberRaw| strBuf.appendSlice(numberRaw) catch unreachable;
    const finalTime = std.fmt.parseInt(usize, strBuf.items, 10) catch unreachable;
    strBuf.clearRetainingCapacity();

    const rawDistances = (lines.next() orelse unreachable)["Distance:".len..];
    const distances = aoc.parseInts(usize, &intBuf, rawDistances, " ");
    it = aoc.splitAny(rawDistances, " ");
    while (it.next()) |numberRaw| strBuf.appendSlice(numberRaw) catch unreachable;
    const finalDistance = std.fmt.parseInt(usize, strBuf.items, 10) catch unreachable;

    for (times, distances) |t, d| {
        races.append(.{ .time = t, .distance = d }) catch unreachable;
    }

    return .{
        .races = races.toOwnedSlice() catch unreachable,
        .finalRace = Race{ .time = finalTime, .distance = finalDistance },
    };
}

fn reset(input: *In) void {
    _ = input;
}

fn p1(input: *In) !Out {
    return solve(input.races);
}

fn p2(input: *In) !Out {
    return solve(&[_]Race{input.finalRace});
}

fn solve(races: []const Race) !Out {
    var mult: Out = 1;
    for (races) |race| {
        var lo: usize = 0; // inclusive
        var hi: usize = race.time + 1; // non-inclusive
        const best = while (lo + 1 < hi) {
            const mid = (lo + hi) / 2;
            switch (race.trend(mid)) {
                .High => lo = mid + 1,
                .Low => hi = mid,
                else => {
                    lo = mid;
                    hi = mid;
                },
            }
        } else lo;

        // reset to find left point where it goes Best.
        lo = 0;
        hi = best + 1;
        const start = while (lo < hi) {
            const mid = (lo + hi) / 2;
            if (race.charge(mid) <= race.distance) {
                lo = mid + 1;
            } else {
                hi = mid;
            }
        } else lo;

        // reset to find left point where it goes Best.
        lo = best;
        hi = race.time + 1;
        const end = while (lo < hi) {
            const mid = (lo + hi) / 2;
            if (race.charge(mid) > race.distance) {
                lo = mid + 1;
            } else {
                hi = mid;
            }
        } else lo; // not inclusive end.

        mult *= end - start;
    }
    return mult;
}
