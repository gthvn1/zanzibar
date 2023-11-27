const std = @import("std");
const repl = @import("repl.zig");

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var buf = std.io.bufferedWriter(stdout);
    var w = buf.writer();
    try w.print("Welcome to Monkey Islang!!!\n", .{});
    try w.print("This is the REPL for Monkey programming language.\n", .{});
    try w.print("Feel free to type commands or 'quit;'\n", .{});
    try buf.flush();

    try repl.Repl.start(stdin, stdout);

    try w.print("\nMay your trip be as enjoyable as finding extra bananas at the bottom of the bag!\n", .{});
    try buf.flush();
}
