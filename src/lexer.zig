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

    pub fn init(allocator: std.mem.Allocator) Lexer {
        return .{
            .tokens = std.ArrayList(Token).empty,
            .allocator = allocator,
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
        var index: usize = 0;
        var tokens_added: usize = 0;

        loop: while (index < input.len) {
            const tok_type: TokenType = switch (input[index]) {
                '\n', '\t', ' ', '\r' => {
                    index += 1;
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
                    std.debug.print("TODO: found {c}, skipping for now\n", .{c});
                    index += 1;
                    continue :loop;
                },
            };

            const token = Token{
                .tt = tok_type,
            };

            try self.tokens.append(self.allocator, token);
            tokens_added += 1;

            index += 1;
        }

        std.debug.print("OK: added {d} tokens, total is {d}\n", .{ tokens_added, self.tokens.items.len });
    }
};
