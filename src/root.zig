//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const lexer = @import("lexer.zig");

pub fn startRepl(reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
    const bye =
        \\May your trip be as enjoyable as finding extra
        \\bananas at the bottom of the bag!
    ;
    loop: while (true) {
        try writer.writeAll(">> ");
        try writer.flush();

        const line = reader.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                // reached end
                // the normal case
                try writer.print("\n{s}\n", .{bye});
                try writer.flush();
                break :loop;
            },
            error.StreamTooLong => {
                try writer.writeAll("ERROR: the line was longer than the internal buffer\n");
                continue :loop;
            },
            error.ReadFailed => {
                try writer.writeAll("ERROR: the read failed\n");
                continue :loop;
            },
        };

        // Should we quit?
        if (line.len == "quit".len) {
            var buf: [4]u8 = undefined;
            const quit = std.ascii.lowerString(&buf, line);

            if (std.mem.eql(u8, "quit", quit)) {
                try writer.print("\n{s}\n", .{bye});
                try writer.flush();
                return;
            }
        }

        // Consume the '\n' before continuing
        reader.toss(1);

        try writer.writeAll("You typed: ");
        try writer.print("<{s}>\n", .{line});

        lexer.analyse(line);
    }
}
