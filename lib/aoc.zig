const std = @import("std");

pub const LineIterator = TokenIterator(std.mem.DelimiterType.scalar);
const CharIterator = TokenIterator(std.mem.DelimiterType.sequence);
const AnyCharIterator = TokenIterator(std.mem.DelimiterType.any);

fn TokenIterator(comptime delimiter_type: std.mem.DelimiterType) type {
    return std.mem.TokenIterator(u8, delimiter_type);
}

pub fn lines(in: []const u8) LineIterator {
    return std.mem.tokenizeScalar(u8, in, '\n');
}

pub fn split(in: []const u8, delimiter: []const u8) CharIterator {
    return std.mem.tokenizeSequence(u8, in, delimiter);
}

pub fn splitAny(in: []const u8, delimiters: []const u8) AnyCharIterator {
    return std.mem.tokenizeAny(u8, in, delimiters);
}

pub fn startsWith(data: []const u8, prefix: []const u8) bool {
    return std.mem.startsWith(u8, data, prefix);
}

pub fn endsWith(data: []const u8, prefix: []const u8) bool {
    return std.mem.endsWith(u8, data, prefix);
}

pub const Error = error{
    BadData,
};

pub fn Input(
    comptime OUT: type,
) type {
    return struct {
        name: []const u8,
        input: []const u8,
        wantP1: Error!OUT,
        wantP2: Error!OUT,
    };
}

pub fn tester(
    comptime IN: type,
    comptime OUT: type,
    inputs: []const Input(OUT),
    preprocess: fn (input: []const u8) IN,
    p1: fn (input: *IN) Error!OUT,
    reset: fn (input: *IN) void,
    p2: fn (input: *IN) Error!OUT,
) !void {
    for (inputs) |input| {
        var data = preprocess(input.input);
        try std.testing.expectEqual(input.wantP1, p1(&data));
        reset(&data);
        try std.testing.expectEqual(input.wantP2, p2(&data));
    }
}

pub fn solver(
    comptime IN: type,
    comptime OUT: type,
    comptime fmt: []const u8,
    inputs: []const Input(OUT),
    preprocess: fn (input: []const u8) IN,
    p1: fn (input: *IN) Error!OUT,
    reset: fn (input: *IN) void,
    p2: fn (input: *IN) Error!OUT,
) void {
    for (inputs) |input| {
        _ = solve(IN, OUT, input.name, fmt, input.input, preprocess, p1, reset, p2);
    }
}

pub fn solve(
    comptime IN: type,
    comptime OUT: type,
    name: []const u8,
    comptime fmt: []const u8,
    input: []const u8,
    preprocess: fn (input: []const u8) IN,
    p1: fn (input: *IN) Error!OUT,
    reset: fn (input: *IN) void,
    p2: fn (input: *IN) Error!OUT,
) [2]Error!OUT {
    var timer = std.time.Timer.start() catch unreachable;
    var data = preprocess(input);
    std.debug.print("\n[{s} - (parsing {})]\n----------------------------\n", .{
        name,
        std.fmt.fmtDuration(timer.read()),
    });
    const result1 = runPart(IN, OUT, fmt, 1, p1, &data, &timer);
    timer.reset();
    reset(&data);
    std.debug.print("(resetting {})\n", .{std.fmt.fmtDuration(timer.read())});
    const result2 = runPart(IN, OUT, fmt, 2, p2, &data, &timer);
    return [_]Error!OUT{ result1, result2 };
}

fn runPart(
    comptime IN: type,
    comptime OUT: type,
    comptime fmt: []const u8,
    comptime partNumber: u8,
    part: fn (input: *IN) Error!OUT,
    data: *IN,
    timer: *std.time.Timer,
) Error!OUT {
    timer.reset();
    if (part(data)) |result| {
        std.debug.print("P{d} [{}]: " ++ fmt ++ "\n", .{
            partNumber,
            std.fmt.fmtDuration(timer.read()),
            result,
        });
        return result;
    } else |err| {
        std.debug.print("P{d} [{}]: {!}\n", .{
            partNumber,
            std.fmt.fmtDuration(timer.read()),
            err,
        });
        return err;
    }
}

pub fn parseInts(comptime T: type, buf: *std.ArrayList(T), input: []const u8, delimeters: []const u8) []const T {
    buf.clearRetainingCapacity();
    var numberIterator = splitAny(input, delimeters);
    while (numberIterator.next()) |numberRaw| {
        buf.append(std.fmt.parseInt(T, numberRaw, 10) catch unreachable) catch unreachable;
    }
    return buf.toOwnedSlice() catch unreachable;
}

pub const Nothing = struct {};

pub fn QueueBlob(comptime T: type, comptime bufSize: usize) type {
    return struct {
        const Self = @This();

        data: [bufSize]T,
        size: usize = bufSize,
        head: usize = 0,
        // non inclusive
        tail: usize = 0,

        pub fn push(self: *Self, v: T) void {
            self.data[self.tail] = v;
            self.tail += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.head == self.tail) return null;
            const v = self.data[self.head];
            self.head += 1;
            return v;
        }

        pub fn init() Self {
            return std.mem.zeroes(Self);
        }
    };
}

pub fn absoluteDiff(comptime T: type, a: T, b: T) T {
    return @max(a, b) - @min(a, b);
}
