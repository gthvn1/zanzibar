const token = @import("token.zig");
const std = @import("std");

const Lexer = struct {
    input: []u8,
    position: usize, // current position in input (points to current char)
    readPosition: usize, // current reading position in input (after current char)
    ch: u8, // current char under examination (only ASCII is supported)
    allocator: std.mem.Allocator,

    /// Read the next character and advance the position. If the
    /// end of input is reached then read character is set to 0.
    fn readChar(self: *Lexer) void {
        if (self.readPosition >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.readPosition];
            self.position = self.readPosition;
            self.readPosition += 1;
        }
    }

    pub fn new(allocator: std.mem.Allocator, input: []const u8) !Lexer {
        var l = Lexer{
            .input = try allocator.dupe(u8, input),
            .position = 0,
            .readPosition = 0,
            .ch = 0,
            .allocator = allocator,
        };
        // before returning l update it by reading the first
        // character
        l.readChar();
        return l;
    }

    pub fn free(self: *Lexer) void {
        self.allocator.free(self.input);
    }

    pub fn nextToken(self: *Lexer) token.Token {
        const slice: []u8 = self.input[self.position .. self.position + 1];
        const tok = switch (self.ch) {
            '=' => token.Token.new(.assign, slice),
            ';' => token.Token.new(.semicolon, slice),
            '(' => token.Token.new(.lparen, slice),
            ')' => token.Token.new(.rparen, slice),
            ',' => token.Token.new(.comma, slice),
            '+' => token.Token.new(.plus, slice),
            '{' => token.Token.new(.lbrace, slice),
            '}' => token.Token.new(.rbrace, slice),
            else => token.Token.new(.eof, ""),
        };
        // Before returning the token let's advance pointers into input.
        self.readChar();

        return tok;
    }
};

test "simple tokens" {
    const input = "=+(){},;";
    var l = try Lexer.new(std.testing.allocator, input);
    defer l.free();

    var t = l.nextToken();
    std.debug.assert(t.type == token.TokenType.assign);
    t = l.nextToken();
    std.debug.assert(t.type == token.TokenType.plus);
    t = l.nextToken();
    std.debug.assert(t.type == token.TokenType.lparen);
    t = l.nextToken();
    std.debug.assert(t.type == token.TokenType.rparen);
    t = l.nextToken();
    std.debug.assert(t.type == token.TokenType.lbrace);
    t = l.nextToken();
    std.debug.assert(t.type == token.TokenType.rbrace);
    t = l.nextToken();
    std.debug.assert(t.type == token.TokenType.comma);
    t = l.nextToken();
    std.debug.assert(t.type == token.TokenType.semicolon);
    t = l.nextToken();
    std.debug.assert(t.type == token.TokenType.eof);
    t = l.nextToken();
    std.debug.assert(t.type == token.TokenType.eof);
}
