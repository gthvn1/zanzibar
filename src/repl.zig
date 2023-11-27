const std = @import("std");
const File = std.fs.File;

const lexer = @import("lexer.zig");

pub const Repl = struct {
    pub fn start(in: File.Reader, out: File.Writer) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const prompt = ">> ";
        var buffer: [1024]u8 = undefined; // We suppose that command of 1024 chars will be enough

        // Look https://zig.news/kristoff/how-to-add-buffering-to-a-writer-reader-in-zig-7jd
        // In the case of our REPL we don't need to buffered reads/writes because we
        // interact with the user so even if doing a syscall for each read/write is slow
        // it is really ok in our case.

        brk: while (true) {
            try out.print("{s}", .{prompt});

            // (R)ead the input
            var code = try in.readUntilDelimiterOrEof(&buffer, '\n');

            if (code) |c| {
                var l = try lexer.Lexer.new(gpa.allocator(), c);
                defer l.free();

                while (true) {
                    // (E)val
                    var t = l.nextToken();
                    if (t.type == .EOF) break;

                    // (P)rint
                    try out.print("{?}\n", .{t});

                    // (L)oop or quit
                    if (std.mem.startsWith(u8, c, "quit")) break :brk;
                }
            }
        }
    }
};
