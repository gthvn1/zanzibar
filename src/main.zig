const std = @import("std");
const zanzibar = @import("zanzibar");

pub fn main() void {
    var log_buffer: [256]u8 = undefined;
    var log_writer = std.fs.File.stdout().writer(&log_buffer);
    const log = &log_writer.interface;

    var stdin_buffer: [256]u8 = undefined;
    var stdin_reader = std.fs.File.stdout().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    zanzibar.startRepl(stdin, log) catch std.debug.print("Failed to start the REPL\n", .{});
}
