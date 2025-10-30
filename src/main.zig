const std = @import("std");
const zanzibar = @import("zanzibar");

pub fn main() void {
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stdin_buffer: [256]u8 = undefined;
    var stdin_reader = std.fs.File.stdout().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    zanzibar.startRepl(stdin, stdout);
}
