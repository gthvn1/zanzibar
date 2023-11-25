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

    fn isLetter(c: u8) bool {
        // It will allow to use identifier like "foo_bar"
        return ('a' <= c and c <= 'z') or ('A' <= c and c <= 'Z') or (c == '_');
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

    fn skipWhitespace(self: *Lexer) void {
        while (std.ascii.isWhitespace(self.ch))
            self.readChar();
    }

    pub fn nextToken(self: *Lexer) token.Token {
        const slice: []u8 = self.input[self.position .. self.position + 1];

        self.skipWhitespace();

        const tok = switch (self.ch) {
            '=' => token.Token.new(.assign, slice),
            ';' => token.Token.new(.semicolon, slice),
            '(' => token.Token.new(.lparen, slice),
            ')' => token.Token.new(.rparen, slice),
            ',' => token.Token.new(.comma, slice),
            '+' => token.Token.new(.plus, slice),
            '{' => token.Token.new(.lbrace, slice),
            '}' => token.Token.new(.rbrace, slice),
            0 => token.Token.new(.eof, ""),
            else => if (isLetter(self.ch)) return self.readIdentifier() else token.Token.new(.illegal, ""),
        };

        // Before returning the token let's advance pointers into input.
        // Note that for readIdentifier we return directly because we already
        // point to the next character.
        self.readChar();

        return tok;
    }
};

test "simple tokens" {
    const input = "=+(){},;";
    var l = try Lexer.new(std.testing.allocator, input);
    defer l.free();

    var t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.assign);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.plus);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.lparen);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.rparen);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.lbrace);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.rbrace);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.comma);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.semicolon);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.eof);
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
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.assign);
}
