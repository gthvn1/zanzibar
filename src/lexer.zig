const std = @import("std");

const TokenType = enum {
    assign,
    comma,
    semicolon,
    lparen,
    rparen,
    lbrace,
    rbrace,
    plus,
    minus,
    asterisk,
    slash,
    lt,
    gt,
    eq,
    not_eq,
    bang,

    ident,
    number,

    // As keywords are also reserved keywords in Zig we prefix them
    kw_function,
    kw_let,
    kw_true,
    kw_false,
    kw_if,
    kw_else,
    kw_return,

    pub fn toString(self: TokenType) []const u8 {
        return @tagName(self);
    }
};

const Token = struct {
    tt: TokenType,

    pub fn toString(self: Token) []const u8 {
        return self.tt.toString();
    }
};

const LexerError = error{
    AlreadyInUse,
};

pub const Lexer = struct {
    tokens: std.ArrayList(Token),
    allocator: std.mem.Allocator,
    index: usize,
    input: ?[]const u8,

    const keywords = [_]struct { []const u8, TokenType }{
        .{ "fn", .kw_function },
        .{ "let", .kw_let },
        .{ "true", .kw_true },
        .{ "false", .kw_false },
        .{ "if", .kw_if },
        .{ "else", .kw_else },
        .{ "return", .kw_return },
    };

    const keywords_map = std.StaticStringMap(TokenType).initComptime(keywords);

    pub fn init(allocator: std.mem.Allocator) Lexer {
        return .{
            .tokens = std.ArrayList(Token).empty,
            .allocator = allocator,
            .index = 0,
            .input = null,
        };
    }

    pub fn deinit(self: *Lexer) void {
        self.tokens.deinit(self.allocator);
        std.debug.assert(self.input == null);
    }

    pub fn printTokens(self: *const Lexer, writer: *std.Io.Writer) !void {
        var buf: [64]u8 = undefined;

        for (self.tokens.items) |token| {
            const slice = try std.fmt.bufPrint(buf[0..], "Token.{s}\n", .{token.toString()});
            try writer.writeAll(slice);
        }

        try writer.flush();
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
    pub fn tokenize(self: *Lexer, input: []const u8) !void {
        if (self.input) |_| {
            std.debug.print("ERROR: input already used", .{});
            return LexerError.AlreadyInUse;
        }

        // Ensure that we have our own copy of input. It is not strictly
        // required but tokenize can be now async.
        const buf = try self.allocator.alloc(u8, input.len);
        std.mem.copyForwards(u8, buf, input);
        self.input = buf;
        defer {
            self.allocator.free(buf);
            self.input = null;
        }

        self.index = 0;

        var tokens_added: usize = 0;

        loop: while (self.readChar()) |carlu| {
            const tok_type: TokenType = switch (carlu) {
                '\n', '\t', ' ', '\r' => {
                    continue :loop;
                },
                '=' => self.matchTwoCharToken('=', .eq, .assign),
                ';' => .semicolon,
                ',' => .comma,
                '(' => .lparen,
                ')' => .rparen,
                '{' => .lbrace,
                '}' => .rbrace,
                '+' => .plus,
                '-' => .minus,
                '*' => .asterisk,
                '/' => .slash,
                '!' => self.matchTwoCharToken('=', .not_eq, .bang),
                '<' => .lt,
                '>' => .gt,
                else => blk: {
                    if (isLetter(carlu)) {
                        // When we read char we update the index so we can now substract one.
                        // And we go back to one char to have the whole identifier.
                        self.index -= 1;
                        break :blk self.readIdentifier();
                    }
                    if (isDigit(carlu)) {
                        // Same as above, it is safe to substract one here.
                        self.index -= 1;
                        break :blk self.readNumber();
                    } else {
                        std.debug.print("TODO: unknown character {c}, skipping for now\n", .{carlu});
                        // Don't try to append something, ignore and continue
                        continue :loop;
                    }
                },
            };

            const token = Token{
                .tt = tok_type,
            };

            try self.tokens.append(self.allocator, token);
            tokens_added += 1;
        }

        std.debug.print("OK: added {d} tokens, total is {d}\n", .{ tokens_added, self.tokens.items.len });
    }

    /// return the current character and update the index position
    fn readChar(self: *Lexer) ?u8 {
        if (self.input) |s| {
            if (self.index >= s.len) {
                // We are at the end of the string
                return null;
            }
            const c = s[self.index];
            self.index += 1;
            return c;
        } else return null;
    }

    /// look the current character without updating the index
    fn peekChar(self: *const Lexer) ?u8 {
        if (self.input) |s| {
            if (self.index >= s.len) {
                return null;
            }
            return s[self.index];
        } else return null;
    }

    fn readIdentifier(self: *Lexer) TokenType {
        // If we are here we know that self.index is at the first character
        // of the identifier.
        std.debug.assert(self.input != null);

        const start: usize = self.index;
        var pos: usize = 0;

        while (true) {
            if (self.readChar()) |c| {
                if (isLetter(c)) {
                    pos += 1;
                } else {
                    // Take a step back since it is not a letter
                    self.index -= 1;
                    break;
                }
            } else break;
        }

        const ident = self.input.?[start .. start + pos];

        if (keywords_map.get(ident)) |tt| {
            return tt;
        }

        return .ident;
    }

    fn readNumber(self: *Lexer) TokenType {
        const start: usize = self.index;
        var pos: usize = 0;
        var fractional = false;

        while (true) {
            if (self.readChar()) |c| {
                if (isDigit(c)) {
                    pos += 1;
                } else if (c == '.' and !fractional) {
                    fractional = true;
                    pos += 1;
                } else {
                    self.index -= 1;
                    break;
                }
            } else break;
        }

        const number = self.input.?[start .. start + pos];
        std.debug.print("TODO: keep number {s} somewhere\n", .{number});
        return .number;
    }

    fn matchTwoCharToken(
        self: *Lexer,
        expected: u8,
        two_char_tt: TokenType,
        one_char_tt: TokenType,
    ) TokenType {
        if (self.peekChar()) |c| {
            if (c == expected) {
                self.index += 1;
                return two_char_tt;
            }
        }

        return one_char_tt;
    }
};

fn isLetter(c: u8) bool {
    return switch (c) {
        'a'...'z', 'A'...'Z', '_' => true,
        else => false,
    };
}

fn isDigit(c: u8) bool {
    return switch (c) {
        '0'...'9' => true,
        else => false,
    };
}
