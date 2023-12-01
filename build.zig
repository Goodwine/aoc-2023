const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const aoc = b.addModule("aoc", .{
        .source_file = .{ .path = "lib/aoc.zig" },
    });

    const run_step = b.step("all", "Runs all AOC");
    const test_step = b.step("all_tests", "Runs all AOC tests (Use 'zig build --summary all all_tests')");

    var prev_step: ?*std.Build.Step = null;
    for (0..25) |i| {
        const day_steps = try day(b, aoc, i + 1);
        if (prev_step) |s| day_steps[0].dependOn(s);
        prev_step = day_steps[0];
        test_step.dependOn(day_steps[1]);
    }

    if (prev_step) |s| run_step.dependOn(s);
}

fn day(b: *std.build.Builder, aoc: *std.build.Module, d: usize) ![2]*std.build.Step {
    const allocator = std.heap.page_allocator;

    const name = try std.fmt.allocPrint(allocator, "day{d}", .{d});
    defer allocator.free(name);

    const test_name = try std.fmt.allocPrint(allocator, "test_day{d}", .{d});
    defer allocator.free(test_name);

    const path = try std.fmt.allocPrint(allocator, "day{d}/main.zig", .{d});
    defer allocator.free(path);

    const desc = try std.fmt.allocPrint(allocator, "Runs AOC 2023 Day {d}", .{d});
    defer allocator.free(desc);

    const exe = b.addExecutable(.{ .name = name, .root_source_file = .{ .path = path } });
    exe.addModule("aoc", aoc);
    b.installArtifact(exe);

    const run_step = b.step(name, desc);
    run_step.dependOn(&b.addRunArtifact(exe).step);

    const unit_tests = b.addTest(.{ .root_source_file = .{ .path = path } });
    unit_tests.addModule("aoc", aoc);
    const test_step = b.step(test_name, desc);
    test_step.dependOn(&b.addRunArtifact(unit_tests).step);

    return [2]*std.build.Step{ run_step, test_step };
}
