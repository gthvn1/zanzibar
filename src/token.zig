const std = @import("std");

pub const TokenType = enum {
    // Special types
    illegal,
    eof,

    // Identifiers and litterals
    ident, // add, foobar, x, y, ...
    int, // 1234

    // Operators
    assign,
    plus,

    // Delimiters
    comma,
    semicolon,
    lparen,
    rparen,
    lbrace,
    rbrace,

    // Keywords
    function,
    let,

    pub fn lookupIdent(ident: []u8) TokenType {
        if (std.mem.eql(u8, ident, "fn"))
            return .function;
        if (std.mem.eql(u8, ident, "let"))
            return .let;

        return .ident;
    }

    pub fn string_of_tokenType(tok: TokenType) []const u8 {
        return switch (tok) {
            // Special types
            .illegal => "ILLEGAL",
            .eof => "EOF",

            // Identifiers and litterals
            .ident => "IDENT", // add, foobar, x, y, ...
            .int => "INT", // 1234

            // Operators
            .assign => "=",
            .plus => "+",

            // Delimiters
            .comma => ",",
            .semicolon => ";",
            .lparen => "(",
            .rparen => ")",
            .lbrace => "{",
            .rbrace => "}",

            // Keywords
            .function => "FUNCTION",
            .let => "LET",
        };
    }
};

pub const Token = struct {
    type: TokenType,
    literal: []u8, // slice

    pub fn new(ttype: TokenType, literal: []u8) Token {
        return .{
            .type = ttype,
            .literal = literal,
        };
    }
};

test "token" {}
