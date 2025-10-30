//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const repl = @import("repl.zig");

pub fn startRepl(reader: *std.Io.Reader, writer: *std.Io.Writer) void {
    repl.start(reader, writer) catch std.debug.print("Failed to start the REPL\n", .{});
}
