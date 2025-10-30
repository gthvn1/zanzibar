//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;

pub fn startRepl(reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var lexer = Lexer.init(allocator);
    defer lexer.deinit();

    const menu_str =
        \\Welcome to Monkey Islang !!!
        \\Feel free to type Monkey code or 'quit'
    ;

    const bye_str =
        \\May your trip be as enjoyable as finding extra
        \\bananas at the bottom of the bag!
    ;

    try writer.print("{s}\n", .{menu_str});

    loop: while (true) {
        try writer.writeAll(">> ");
        try writer.flush();

        const line = reader.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                // reached end
                // the normal case
                try writer.print("\n{s}\n", .{bye_str});
                try writer.flush();
                return;
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
                try writer.print("\n{s}\n", .{bye_str});
                try writer.flush();
                return;
            }
        }

        // Consume the '\n' before continuing
        reader.toss(1);

        try writer.print("You typed: <{s}>\n", .{line});
        try writer.flush();

        lexer.transform(line);
    }
}
