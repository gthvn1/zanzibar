const Token = struct {
    type: TokenType,
    literal: []const u8,
};

const TokenType = enum([]const u8) {
    // Special types
    illegal = "ILLEGAL",
    eof = "EOF",

    // Identifiers and litterals
    ident = "IDENT", // add, foobar, x, y, ...
    int = "INT", // 1234

    // Operators
    assign = "=",
    plus = "+",

    // Delimiters
    comma = ",",
    semicolon = ";",
    lparen = "(",
    rparen = ")",
    lbrace = "{",
    rbrace = "}",

    // Keywords
    function = "FUNCTION",
    let = "LET",
};

test "token" {}
