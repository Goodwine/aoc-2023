const aoc = @import("aoc");
const std = @import("std");

const small_txt = @embedFile("small.txt");
const input_txt = @embedFile("input.txt");

const In = []Spring;
const Out = usize;
const Input = aoc.Input(Out);
const inputs = [_]Input{
    .{ .name = "small", .input = small_txt, .wantP1 = 21, .wantP2 = 525152 },
    .{ .name = "large", .input = input_txt, .wantP1 = 7694, .wantP2 = 5071883216318 },
};

pub fn main() !void {
    std.debug.print("\nDay 12\n==========\n", .{});
    aoc.solver(In, Out, "{d}", &inputs, preprocess, p1, reset, p2);
}

test {
    try aoc.tester(In, Out, &inputs, preprocess, p1, reset, p2);
}

const DPKey = struct {
    recordIdx: usize,
    numbersIdx: usize,
};

const Spring = struct {
    const Self = @This();

    record: []const u8,
    numbers: []const u8,
    count: u8,

    fn countCombinations(self: Self) Out {
        var dp = std.AutoHashMap(DPKey, Out).init(std.heap.page_allocator);
        defer dp.deinit();

        return self.generateCombinations(&dp, 0, 0);
    }

    fn generateCombinations(
        self: Self,
        dp: *std.AutoHashMap(DPKey, Out),
        recordIdx: usize,
        numberIdx: usize,
    ) Out { // TODO: memoize
        const dpKey = DPKey{
            .recordIdx = recordIdx,
            .numbersIdx = numberIdx,
        };
        if (dp.get(dpKey)) |val| return val;

        if (recordIdx >= self.record.len) {
            return if (numberIdx >= self.numbers.len) 1 else 0;
        }
        if (numberIdx >= self.numbers.len) {
            return if (std.mem.indexOfScalar(u8, self.record[recordIdx..], '#')) |_| 0 else 1;
        }

        // Check for the next hash or question mark.
        if (std.mem.indexOfAny(u8, self.record[recordIdx..], "#?")) |idx| {
            const nextRecordIdx = recordIdx + idx;
            // Skip all preceeding periods.
            if (nextRecordIdx != recordIdx) {
                return self.generateCombinations(dp, nextRecordIdx, numberIdx);
            }
        } else {
            // No more hashes or question marks, only periods left.
            return self.generateCombinations(dp, self.record.len, numberIdx);
        }

        const number = self.numbers[numberIdx];

        var sum: Out = 0;
        for (recordIdx..self.record.len) |idx| {
            if (self.match(numberIdx, idx)) {
                // +1 to make space for the period expected at the end of the spring.
                const nextIdx = @min(idx + number + 1, self.record.len);
                sum += self.generateCombinations(
                    dp,
                    nextIdx,
                    numberIdx + 1,
                );
            }
            // Stop after we hit a hash, because that's a part of the spring, and we can't skip over it.
            if (self.record[idx] == '#') break;
        }
        dp.putNoClobber(dpKey, sum) catch unreachable;
        return sum;
    }

    fn match(self: Self, numberIdx: usize, recordIdx: usize) bool {
        const number = self.numbers[numberIdx];
        const limit = self.record.len - recordIdx;
        if (number > limit) return false;

        var bufBlock = [_]u8{'#'} ** 128;
        // Add one for the period expected at the end.
        // However, it's OK if there is no dot.
        const bufSize = @min(number + 1, limit);
        var buf = bufBlock[0..bufSize];
        if (number < limit) buf[number] = '.';

        for (buf, self.record[recordIdx .. recordIdx + buf.len]) |b, r| {
            if (r == '?') continue;
            if (b != r) return false;
        }
        return true;
    }
};

fn preprocess(input: []const u8) In {
    var lines = aoc.lines(input);
    var buf = std.ArrayList(Spring).init(std.heap.page_allocator);
    defer buf.deinit();
    var numberBuf = std.ArrayList(u8).init(std.heap.page_allocator);
    defer numberBuf.deinit();

    while (lines.next()) |line| {
        var chunks = aoc.splitAny(line, " ");
        const record = chunks.next().?;
        const numbers = aoc.parseInts(u8, &numberBuf, chunks.next().?, ",");
        var count: u8 = 0;
        for (numbers) |n| count += n;
        buf.append(.{
            .record = record,
            .numbers = numbers,
            .count = count,
        }) catch unreachable;
    }

    return buf.toOwnedSlice() catch unreachable;
}

fn reset(input: *In) void {
    _ = input;
}

fn p1(input: *In) !Out {
    var sum: Out = 0;
    for (input.*) |spring| {
        const count = spring.countCombinations();
        sum += count;
    }

    return sum;
}

fn repeat(comptime T: type, value: []const T, count: usize) []T {
    var buf = std.ArrayList(T).initCapacity(std.heap.page_allocator, count * value.len) catch unreachable;
    defer buf.deinit();
    for (0..count) |_| buf.appendSlice(value) catch unreachable;
    return buf.toOwnedSlice() catch unreachable;
}

fn repeatSeparatedBy(comptime T: type, value: []const T, count: usize, separator: T) []T {
    var buf = std.ArrayList(T).initCapacity(std.heap.page_allocator, count * value.len + count) catch unreachable;
    defer buf.deinit();
    if (count > 0) buf.appendSlice(value) catch unreachable;
    for (1..count) |_| {
        buf.append(separator) catch unreachable;
        buf.appendSlice(value) catch unreachable;
    }
    return buf.toOwnedSlice() catch unreachable;
}

fn p2(input: *In) !Out {
    var sum: Out = 0;

    for (input.*) |spring| {
        const bigSpring = Spring{
            .record = repeatSeparatedBy(u8, spring.record, 5, '?'),
            .numbers = repeat(u8, spring.numbers, 5),
            .count = spring.count * 5,
        };
        const count = bigSpring.countCombinations();
        sum += count;
    }

    return sum;
}
