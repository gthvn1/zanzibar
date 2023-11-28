const std = @import("std");
const token = @import("token.zig");
const lexer = @import("lexer.zig");
const ast = @import("ast.zig");

const Parser = struct {
    allocator: std.mem.Allocator,
    l: *lexer.Lexer,
    cur_token: token.Token = undefined,
    peek_token: token.Token = undefined,
    statements: std.ArrayList(ast.Statement),

    pub fn create(allocator: std.mem.Allocator, l: *lexer.Lexer) Parser {
        var p: Parser = .{
            .l = l,
            .allocator = allocator,
            .statements = std.ArrayList(ast.Statement).init(allocator),
        };

        // Read two tokens, so cur_token and peek_token are both set.
        p.nextToken();
        p.nextToken();

        return p;
    }

    pub fn destroy(self: *Parser) void {
        _ = self;
    }

    pub fn parseProgam(self: *Parser) !ast.Program {
        while (self.cur_token.type != token.TokenType.EOF) : (self.nextToken()) {
            if (self.parseStatement()) |stmt| {
                try self.statements.append(stmt);
            }
        }

        return .{
            .statements = self.statements,
        };
    }

    fn nextToken(self: *Parser) void {
        self.cur_token = self.peek_token;
        self.peek_token = self.l.nextToken();
    }

    fn parseStatement(self: *Parser) ?ast.Statement {
        _ = self;
        @panic("not implemented");
    }
};

test "simple statement" {
    const input = "let a = 10;";
    var l = try lexer.Lexer.new(std.testing.allocator, input);
    defer l.free();

    var p = Parser.create(std.testing.allocator, &l);
    defer p.destroy();
}
