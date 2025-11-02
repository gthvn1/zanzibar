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
    bang,

    function,
    let,

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
        .{ "fn", .function },
        .{ "let", .let },
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
                '=' => .assign,
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
                '!' => .bang,
                '<' => .lt,
                '>' => .gt,
                else => {
                    if (isLetter(carlu)) {
                        // When we read char we update the index so we can now substract one
                        self.index -= 1;
                        _ = self.readIdentifier();
                    } else {
                        std.debug.print("TODO: unknown character {c}, skipping for now\n", .{carlu});
                        self.index += 1;
                    }
                    continue :loop;
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

    fn peekChar(self: *const Lexer) ?u8 {
        if (self.input) |s| {
            if (self.index + 1 >= s.len) {
                return null;
            }
            return s[self.index + 1];
        } else return null;
    }

    fn readIdentifier(self: *Lexer) []const u8 {
        // If we are here we know that self.index is on a character
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

        if (keywords_map.get(ident)) |_| {
            std.debug.print("TODO: found keyword {s}\n", .{ident});
        } else {
            std.debug.print("TODO: found identifier {s}\n", .{ident});
        }

        return ident;
    }
};

fn isLetter(c: u8) bool {
    return switch (c) {
        'a'...'z', 'A'...'Z', '_' => true,
        else => false,
    };
}
