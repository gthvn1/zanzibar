const token = @import("token.zig");
const std = @import("std");

pub const Lexer = struct {
    input: []u8,
    position: usize, // current position in input (points to current char)
    read_position: usize, // current reading position in input (after current char)
    ch: u8, // current char under examination (only ASCII is supported)
    allocator: std.mem.Allocator,

    pub fn new(allocator: std.mem.Allocator, input: []const u8) !Lexer {
        var l = Lexer{
            .input = try allocator.dupe(u8, input),
            .position = 0,
            .read_position = 0,
            .ch = 0,
            .allocator = allocator,
        };
        // before returning l update it by reading the first character
        l.readChar();
        return l;
    }

    pub fn free(self: *Lexer) void {
        self.allocator.free(self.input);
    }

    pub fn nextToken(self: *Lexer) token.Token {
        const pos = self.position;
        var ttype: token.TokenType = undefined;

        self.skipWhitespace();

        switch (self.ch) {
            '=' => ttype = .assign,
            ';' => ttype = .semicolon,
            '(' => ttype = .lparen,
            ')' => ttype = .rparen,
            ',' => ttype = .comma,
            '+' => ttype = .plus,
            '{' => ttype = .lbrace,
            '}' => ttype = .rbrace,
            0 => return token.Token.new(.eof, ""),
            else => {
                if (isLetter(self.ch))
                    return self.readIdentifier();
                if (std.ascii.isDigit(self.ch))
                    return self.readNumber();
                ttype = .illegal;
            },
        }

        // Before returning the token let's advance pointers into input.
        // Note that for readIdentifier we return directly because we already
        // point to the next character and the slice is the identifier.

        self.readChar();

        return token.Token.new(ttype, self.input[pos .. pos + 1]);
    }

    fn isLetter(c: u8) bool {
        // It will allow to use identifier like "foo_bar"
        return switch (c) {
            'A'...'Z', 'a'...'z', '_' => true,
            else => false,
        };
    }

    /// Read the next character and advance the position. If the
    /// end of input is reached then read character is set to 0.
    fn readChar(self: *Lexer) void {
        if (self.read_position >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.read_position];
            self.position = self.read_position;
            self.read_position += 1;
        }
    }

    fn readIdentifier(self: *Lexer) token.Token {
        const pos = self.position;
        while (isLetter(self.ch))
            self.readChar();

        const ident = self.input[pos..self.position];
        return token.Token.new(token.TokenType.lookupIdent(ident), ident);
    }

    fn readNumber(self: *Lexer) token.Token {
        const pos = self.position;
        while (std.ascii.isDigit(self.ch))
            self.readChar();

        const ident = self.input[pos..self.position];
        return token.Token.new(token.TokenType.int, ident);
    }

    fn skipWhitespace(self: *Lexer) void {
        while (std.ascii.isWhitespace(self.ch))
            self.readChar();
    }
};

test "simple tokens" {
    const input = "=+(){},;";
    var l = try Lexer.new(std.testing.allocator, input);
    defer l.free();

    var t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.assign);
    try std.testing.expectEqualStrings(t.literal, "=");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.plus);
    try std.testing.expectEqualStrings(t.literal, "+");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.lparen);
    try std.testing.expectEqualStrings(t.literal, "(");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.rparen);
    try std.testing.expectEqualStrings(t.literal, ")");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.lbrace);
    try std.testing.expectEqualStrings(t.literal, "{");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.rbrace);
    try std.testing.expectEqualStrings(t.literal, "}");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.comma);
    try std.testing.expectEqualStrings(t.literal, ",");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.semicolon);
    try std.testing.expectEqualStrings(t.literal, ";");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.eof);
    try std.testing.expectEqualStrings(t.literal, "");
}

test "all tokens" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\
        \\ let result = add(five, ten);
    ;
    var l = try Lexer.new(std.testing.allocator, input);
    defer l.free();

    var t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.let);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ident);
    try std.testing.expectEqualStrings(t.literal, "five");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.assign);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.int);
    try std.testing.expectEqualStrings(t.literal, "5");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.semicolon);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.let);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ident);
    try std.testing.expectEqualStrings(t.literal, "ten");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.assign);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.int);
    try std.testing.expectEqualStrings(t.literal, "10");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.semicolon);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.let);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ident);
    try std.testing.expectEqualStrings(t.literal, "add");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.assign);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.function);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.lparen);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ident);
    try std.testing.expectEqualStrings(t.literal, "x");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.comma);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ident);
    try std.testing.expectEqualStrings(t.literal, "y");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.rparen);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.lbrace);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ident);
    try std.testing.expectEqualStrings(t.literal, "x");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.plus);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ident);
    try std.testing.expectEqualStrings(t.literal, "y");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.semicolon);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.rbrace);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.semicolon);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.let);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ident);
    try std.testing.expectEqualStrings(t.literal, "result");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.assign);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ident);
    try std.testing.expectEqualStrings(t.literal, "add");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.lparen);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ident);
    try std.testing.expectEqualStrings(t.literal, "five");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.comma);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ident);
    try std.testing.expectEqualStrings(t.literal, "ten");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.rparen);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.semicolon);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.eof);
}
