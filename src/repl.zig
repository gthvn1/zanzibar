const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;

const Cmd = enum {
    help,
    quit,
    tokens,

    pub fn fromString(str: []const u8) ?Cmd {
        const map = std.StaticStringMap(Cmd).initComptime(.{
            .{ "#help", .help },
            .{ "#quit", .quit },
            .{ "#tokens", .tokens },
        });
        return map.get(str);
    }
};

fn helperPrintLn(writer: *std.Io.Writer, str: []const u8) !void {
    try writer.writeAll(str);
    try writer.writeAll("\n");
    try writer.flush();
}

pub fn start(reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    var lexer = Lexer.init(gpa.allocator());
    defer lexer.deinit();

    const welcome_str =
        \\Welcome to Monkey Islang REPL!
        \\Type Monkey code to set sail on an adventure.
        \\Use '#help' for guidance, or '#quit' to leave the island.
    ;

    const help_str =
        \\Commands:
        \\  #help   -> show available commands
        \\  #quit   -> exit the REPL
        \\  #tokens -> show current tokens
    ;

    const bye_str =
        \\Farewell, adventurer! May you always find extra
        \\bananas at the bottom of the bag...
    ;

    try helperPrintLn(writer, welcome_str);

    loop: while (true) {
        try writer.writeAll(">> ");
        try writer.flush();

        const line = reader.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                // reached end
                try helperPrintLn(writer, bye_str);
                return;
            },
            error.StreamTooLong => {
                try helperPrintLn(writer, "ERROR: the line was longer than the internal buffer");
                continue :loop;
            },
            error.ReadFailed => {
                try helperPrintLn(writer, "ERROR: the read failed");
                continue :loop;
            },
        };

        // Consume the '\n' before continuing
        reader.toss(1);

        // Is it a command?
        if (Cmd.fromString(line)) |cmd| {
            switch (cmd) {
                .help => try helperPrintLn(writer, help_str),
                .quit => {
                    try helperPrintLn(writer, bye_str);
                    return;
                },
                .tokens => try helperPrintLn(writer, "TODO: show current tokens"),
            }

            continue :loop;
        }

        try writer.print("You typed: <{s}>\n", .{line});
        try writer.flush();

        lexer.transform(line);
    }
}
