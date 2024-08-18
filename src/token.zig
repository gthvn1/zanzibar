const std = @import("std");

pub const TokenType = enum {
    illegal,
    eof,
    // identifiers + literals
    ident,
    int,
    // operators
    assign,
    plus,
    // delimiters
    comma,
    semicolon,
    lparen,
    rparen,
    lbrace,
    rbrace,
    // keywords
    function,
    let,
};

pub const Token = struct {
    tt: TokenType,
    lit: []const u8,
};

test "token always work" {
    try std.testing.expect(true);
}
