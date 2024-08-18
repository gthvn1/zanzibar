const std = @import("std");
const token = @import("token.zig");

pub const Lexer = struct {
    input: []const u8,
    position: usize, // current position in input (points to current char)
    readPosition: usize, // current reading position in input (after current char)
    ch: u8, // current char under examination
    allocator: std.mem.Allocator,

    pub fn alloc(input: []const u8, allocator: std.mem.Allocator) !Lexer {
        // Keep our own copy of the input to be sure that input is always available
        const myInput = try allocator.alloc(u8, input.len);
        std.mem.copyForwards(u8, myInput, input);

        var l = Lexer{
            .input = myInput,
            .position = 0,
            .readPosition = 0,
            .ch = 0,
            .allocator = allocator,
        };

        // Read the first character before returning the lexer
        l.read_char();
        return l;
    }

    pub fn free(self: *Lexer) void {
        self.allocator.free(self.input);
    }

    pub fn next_token(self: *Lexer) token.Token {
        //std.debug.print("current char is {}\n", .{self.ch});
        const tok = switch (self.ch) {
            '=' => new_token(.assign, self.ch_as_slice()),
            '+' => new_token(.plus, self.ch_as_slice()),
            '(' => new_token(.lparen, self.ch_as_slice()),
            ')' => new_token(.rparen, self.ch_as_slice()),
            '{' => new_token(.lbrace, self.ch_as_slice()),
            '}' => new_token(.rbrace, self.ch_as_slice()),
            ',' => new_token(.comma, self.ch_as_slice()),
            ';' => new_token(.semicolon, self.ch_as_slice()),
            0 => new_token(.eof, ""),
            else => new_token(.illegal, ""),
        };

        self.read_char();
        return tok;
    }

    fn new_token(tt: token.TokenType, lit: []const u8) token.Token {
        return token.Token{
            .tt = tt,
            .lit = lit,
        };
    }

    fn ch_as_slice(self: *Lexer) []const u8 {
        return self.input[self.position .. self.position + 1];
    }

    fn read_char(self: *Lexer) void {
        if (self.readPosition >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.readPosition];
            self.position = self.readPosition;
            self.readPosition += 1;
        }
    }
};

test "read simple tokens" {
    var l = try Lexer.alloc("=+{}(),;", std.testing.allocator);
    defer l.free();

    const expectedTokens = [_]token.Token{
        .{ .tt = .assign, .lit = "=" },
        .{ .tt = .plus, .lit = "+" },
        .{ .tt = .lbrace, .lit = "{" },
        .{ .tt = .rbrace, .lit = "}" },
        .{ .tt = .lparen, .lit = "(" },
        .{ .tt = .rparen, .lit = ")" },
        .{ .tt = .comma, .lit = "," },
        .{ .tt = .semicolon, .lit = ";" },
        .{ .tt = .eof, .lit = "" },
    };

    var t: token.Token = undefined;
    for (expectedTokens) |tok| {
        t = l.next_token();
        try std.testing.expectEqual(t.tt, tok.tt);
        try std.testing.expectEqualSlices(u8, t.lit, tok.lit);
    }
}

test "create lexer for hello" {
    var l = try Lexer.alloc("hello", std.testing.allocator);
    defer l.free();
    try std.testing.expectEqual(l.ch, 'h');
    try std.testing.expectEqual(l.position, 0);
    try std.testing.expectEqual(l.readPosition, 1);
}

test "read char from hi" {
    var l = try Lexer.alloc("hi", std.testing.allocator);
    defer l.free();
    try std.testing.expectEqual(l.ch, 'h');
    try std.testing.expectEqual(l.position, 0);
    try std.testing.expectEqual(l.readPosition, 1);

    l.read_char();
    try std.testing.expectEqual(l.ch, 'i');
    try std.testing.expectEqual(l.position, 1);
    try std.testing.expectEqual(l.readPosition, 2);

    l.read_char();
    try std.testing.expectEqual(l.ch, 0);
    try std.testing.expectEqual(l.position, 1);
    try std.testing.expectEqual(l.readPosition, 2);
}
