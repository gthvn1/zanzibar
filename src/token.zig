const std = @import("std");

pub const TokenType = enum {
    // We use uppercase to avoid conflict with existing symbol like
    // false, true, ...

    // Special types
    ILLEGAL,
    EOF,

    // Identifiers and litterals
    IDENT, // add, foobar, x, y, ...
    INT, // 1234

    // Operators
    ASSIGN,
    PLUS,

    // Delimiters
    COMMA,
    SEMICOLON,
    LPAREN,
    RPAREN,
    LBRACE,
    RBRACE,

    // Keywords
    FUNCTION,
    LET,

    pub fn lookupIdent(ident: []u8) TokenType {
        return if (keywordsFromString(ident)) |ttype|
            ttype
        else
            .IDENT;
    }

    pub fn keywordsFromString(str: []const u8) ?TokenType {
        if (std.mem.eql(u8, "fn", str)) return .FUNCTION;
        if (std.mem.eql(u8, "let", str)) return .LET;
        return null;
    }

    pub fn stringFromTokenType(tok: TokenType) []const u8 {
        return switch (tok) {
            // Special types
            .ILLEGAL => "ILLEGAL",
            .EOF => "EOF",

            // Identifiers and litterals
            .IDENT => "IDENT",
            .INT => "INT",

            // Operators
            .ASSIGN => "=",
            .PLUS => "+",

            // Delimiters
            .COMMA => ",",
            .SEMICOLON => ";",
            .LPAREN => "(",
            .RPAREN => ")",
            .LBRACE => "{",
            .RBRACE => "}",

            // Keywords
            .FUNCTION => "FUNCTION",
            .LET => "LET",
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
