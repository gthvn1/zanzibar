const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;

const Cmd = enum {
    help,
    load,
    quit,
    tokens,

    pub fn fromString(str: []const u8) ?Cmd {
        const map = std.StaticStringMap(Cmd).initComptime(.{
            .{ "#help", .help },
            .{ "#load", .load },
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
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var lexer = Lexer.init(allocator);
    defer lexer.deinit();

    const welcome_str =
        \\Welcome to Monkey Islang REPL!
        \\Type Monkey code to set sail on an adventure.
        \\Use '#help' for guidance, or '#quit' to leave the island.
    ;

    const help_str =
        \\Commands:
        \\  #help   -> show available commands
        \\  #load   -> load the file (you will be prompted for the filename)
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
                .load => {
                    if (loadFile(allocator, reader, writer)) |str| {
                        defer allocator.free(str);
                        try writer.print("file loaded\n", .{});
                        try writer.flush();

                        try lexer.tokenize(str);
                        try writer.print("done\n", .{});
                        try writer.flush();
                    }
                },
                .quit => {
                    try helperPrintLn(writer, bye_str);
                    return;
                },
                .tokens => try lexer.printTokens(writer),
            }

            continue :loop;
        }

        try writer.print("You typed: <{s}>\n", .{line});
        try writer.flush();

        try lexer.tokenize(line);
    }
}

fn loadFile(allocator: std.mem.Allocator, reader: *std.Io.Reader, writer: *std.Io.Writer) ?[]u8 {
    writer.writeAll("enter filename > ") catch {
        std.debug.print("Failed to print on the screen\n", .{});
        return null;
    };

    writer.flush() catch {
        std.debug.print("Failed to flush\n", .{});
        return null;
    };

    const filename = reader.takeDelimiterExclusive('\n') catch {
        std.debug.print("Failed to read the filename\n", .{});
        return null;
    };

    reader.toss(1);

    const file = std.fs.cwd().openFile(filename, .{}) catch {
        std.debug.print("Failed to open the file\n", .{});
        return null;
    };

    const contents = file.readToEndAlloc(allocator, std.math.maxInt(usize)) catch {
        std.debug.print("Failed read the file\n", .{});
        return null;
    };

    file.close();
    return contents;
}
