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

pub const Lexer = struct {
    tokens: std.ArrayList(Token),
    allocator: std.mem.Allocator,
    index: usize,

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
        };
    }

    pub fn deinit(self: *Lexer) void {
        self.tokens.deinit(self.allocator);
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
        // We need to read char by char
        self.index = 0;
        var tokens_added: usize = 0;

        loop: while (self.index < input.len) {
            const tok_type: TokenType = switch (input[self.index]) {
                '\n', '\t', ' ', '\r' => {
                    self.index += 1;
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
                else => |c| {
                    if (isLetter(c)) {
                        _ = self.readIdentifier(input[self.index..]);
                    } else {
                        std.debug.print("TODO: unknown character {c}, skipping for now\n", .{c});
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

            self.index += 1;
        }

        std.debug.print("OK: added {d} tokens, total is {d}\n", .{ tokens_added, self.tokens.items.len });
    }

    fn readIdentifier(self: *Lexer, input: []const u8) []const u8 {
        // If we are here we know that self.index is on a character
        var pos: usize = 0;

        for (input) |c| {
            if (isLetter(c)) {
                pos += 1;
            } else {
                break;
            }
        }

        const ident = input[0..pos];

        if (keywords_map.get(ident)) |_| {
            std.debug.print("TODO: found keyword {s}\n", .{ident});
        } else {
            std.debug.print("TODO: found identifier {s}\n", .{ident});
        }

        self.index += pos;

        return ident;
    }
};

fn isLetter(c: u8) bool {
    return switch (c) {
        'a'...'z', 'A'...'Z', '_' => true,
        else => false,
    };
}
