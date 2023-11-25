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
        var ttype: token.TokenType = undefined;
        var tsize: usize = 1; // Most of tokens are 1 char so by default
        // we set token size to one but some are 2 or more. Note that
        // ident are not using tsize and are returned by their own function.

        self.skipWhitespace();

        const pos = self.position; // save position after skipping whitespace...

        switch (self.ch) {
            '=' => {
                if (self.peekChar() == '=') {
                    self.readChar();
                    ttype = .EQ;
                    tsize = 2;
                } else {
                    ttype = .ASSIGN;
                }
            },
            ';' => ttype = .SEMICOLON,
            '(' => ttype = .LPAREN,
            ')' => ttype = .RPAREN,
            ',' => ttype = .COMMA,
            '+' => ttype = .PLUS,
            '-' => ttype = .MINUS,
            '*' => ttype = .ASTERIX,
            '/' => ttype = .SLASH,
            '!' => {
                if (self.peekChar() == '=') {
                    self.readChar();
                    ttype = .NOT_EQ;
                    tsize = 2;
                } else {
                    ttype = .BANG;
                }
            },
            '<' => ttype = .LT,
            '>' => ttype = .GT,
            '{' => ttype = .LBRACE,
            '}' => ttype = .RBRACE,
            0 => return token.Token.new(.EOF, ""),
            else => {
                if (isLetter(self.ch))
                    return self.readIdentifier();
                if (std.ascii.isDigit(self.ch))
                    return self.readNumber();
                ttype = .ILLEGAL;
            },
        }

        // Before returning the token let's advance pointers into input.
        // Note that for readIdentifier we return directly because we already
        // point to the next character and the slice is the identifier.

        self.readChar();

        return token.Token.new(ttype, self.input[pos .. pos + tsize]);
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

    /// peekChar is similar to readChar except that it doesn't increment the positions
    /// It is a dry run version of readChar.
    fn peekChar(self: *Lexer) u8 {
        return if (self.read_position >= self.input.len) 0 else self.input[self.read_position];
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
        return token.Token.new(token.TokenType.INT, ident);
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
    try std.testing.expectEqual(t.type, token.TokenType.ASSIGN);
    try std.testing.expectEqualStrings(t.literal, "=");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.PLUS);
    try std.testing.expectEqualStrings(t.literal, "+");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LPAREN);
    try std.testing.expectEqualStrings(t.literal, "(");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.RPAREN);
    try std.testing.expectEqualStrings(t.literal, ")");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LBRACE);
    try std.testing.expectEqualStrings(t.literal, "{");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.RBRACE);
    try std.testing.expectEqualStrings(t.literal, "}");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.COMMA);
    try std.testing.expectEqualStrings(t.literal, ",");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SEMICOLON);
    try std.testing.expectEqualStrings(t.literal, ";");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.EOF);
    try std.testing.expectEqualStrings(t.literal, "");
}

test "simple program" {
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
    try std.testing.expectEqual(t.type, token.TokenType.LET);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.IDENT);
    try std.testing.expectEqualStrings(t.literal, "five");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ASSIGN);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.INT);
    try std.testing.expectEqualStrings(t.literal, "5");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SEMICOLON);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LET);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.IDENT);
    try std.testing.expectEqualStrings(t.literal, "ten");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ASSIGN);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.INT);
    try std.testing.expectEqualStrings(t.literal, "10");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SEMICOLON);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LET);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.IDENT);
    try std.testing.expectEqualStrings(t.literal, "add");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ASSIGN);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.FUNCTION);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LPAREN);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.IDENT);
    try std.testing.expectEqualStrings(t.literal, "x");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.COMMA);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.IDENT);
    try std.testing.expectEqualStrings(t.literal, "y");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.RPAREN);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LBRACE);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.IDENT);
    try std.testing.expectEqualStrings(t.literal, "x");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.PLUS);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.IDENT);
    try std.testing.expectEqualStrings(t.literal, "y");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SEMICOLON);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.RBRACE);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SEMICOLON);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LET);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.IDENT);
    try std.testing.expectEqualStrings(t.literal, "result");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ASSIGN);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.IDENT);
    try std.testing.expectEqualStrings(t.literal, "add");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LPAREN);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.IDENT);
    try std.testing.expectEqualStrings(t.literal, "five");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.COMMA);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.IDENT);
    try std.testing.expectEqualStrings(t.literal, "ten");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.RPAREN);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SEMICOLON);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.EOF);
}

test "new tokens" {
    const input =
        \\ !-/*5;
        \\ 5 < 10 > 5;
        \\ if (5 < 10) {
        \\   return true;
        \\ } else {
        \\   return false;
        \\ }
        \\ 10 == 10;
        \\ 9 != 10; 
    ;
    var l = try Lexer.new(std.testing.allocator, input);
    defer l.free();

    var t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.BANG);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.MINUS);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SLASH);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ASTERIX);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.INT);
    try std.testing.expectEqualStrings(t.literal, "5");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SEMICOLON);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.INT);
    try std.testing.expectEqualStrings(t.literal, "5");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LT);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.INT);
    try std.testing.expectEqualStrings(t.literal, "10");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.GT);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.INT);
    try std.testing.expectEqualStrings(t.literal, "5");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SEMICOLON);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.IF);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LPAREN);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.INT);
    try std.testing.expectEqualStrings(t.literal, "5");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LT);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.INT);
    try std.testing.expectEqualStrings(t.literal, "10");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.RPAREN);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LBRACE);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.RETURN);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.TRUE);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SEMICOLON);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.RBRACE);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.ELSE);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.LBRACE);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.RETURN);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.FALSE);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SEMICOLON);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.RBRACE);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.INT);
    try std.testing.expectEqualStrings(t.literal, "10");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.EQ);
    try std.testing.expectEqualStrings(t.literal, "==");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.INT);
    try std.testing.expectEqualStrings(t.literal, "10");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SEMICOLON);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.INT);
    try std.testing.expectEqualStrings(t.literal, "9");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.NOT_EQ);
    try std.testing.expectEqualStrings(t.literal, "!=");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.INT);
    try std.testing.expectEqualStrings(t.literal, "10");
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.SEMICOLON);
    t = l.nextToken();
    try std.testing.expectEqual(t.type, token.TokenType.EOF);
}
