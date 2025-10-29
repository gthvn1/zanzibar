const std = @import("std");

// We want to transform the following string: "let x = 5 + 5"
// into a list of tokens:
// [
//   LET,
//   IDENTIFIER("x"),
//   EQUAL_SIGN,
//   INTEGER(5),
//   PLUS_SIGN,
//   INTEGER(5),
//   SEMICOLON
// ]
pub fn transform(input: []const u8) void {
    var it = std.mem.tokenizeScalar(u8, input, ' ');

    while (it.next()) |item| {
        std.debug.print("  found: {s}\n", .{item});
    }

    std.debug.print("TODO: lexical analysis\n", .{});
}
