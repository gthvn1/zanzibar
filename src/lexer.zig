const std = @import("std");

const Token = struct {};

pub const Lexer = struct {
    tokens: std.ArrayList(Token),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Lexer {
        return .{
            .tokens = std.ArrayList(Token).empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Lexer) void {
        self.tokens.deinit(self.allocator);
    }

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
    pub fn transform(self: *Lexer, input: []const u8) void {
        _ = self; // TODO: Add new token into the list of tokens of the lexer

        var it = std.mem.tokenizeScalar(u8, input, ' ');

        while (it.next()) |item| {
            std.debug.print("  found: {s}\n", .{item});
        }

        std.debug.print("TODO: lexical analysis\n", .{});
    }
};
