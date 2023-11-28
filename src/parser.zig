const std = @import("std");
const token = @import("token.zig");
const lexer = @import("lexer.zig");
const ast = @import("ast.zig");

const Parser = struct {
    allocator: std.mem.Allocator, // Used when creating AST program
    l: *lexer.Lexer,
    cur_token: token.Token = undefined,
    peek_token: token.Token = undefined,

    pub fn create(allocator: std.mem.Allocator, l: *lexer.Lexer) Parser {
        var p: Parser = .{
            .l = l,
            .allocator = allocator,
        };

        // Read two tokens, so cur_token and peek_token are both set.
        p.nextToken();
        p.nextToken();

        return p;
    }

    pub fn destroy(self: *Parser) void {
        _ = self;
    }

    // It is up to the caller to call deinit on the return AST program
    pub fn parseProgam(self: *Parser) ast.Program {
        var program = ast.Program.init(self.allocator);

        while (self.cur_token.type != token.TokenType.EOF) : (self.nextToken()) {
            if (self.parseStatement()) |stmt| {
                try self.statements.append(stmt);
            }
        }

        return program;
    }

    fn nextToken(self: *Parser) void {
        self.cur_token = self.peek_token;
        self.peek_token = self.l.nextToken();
    }

    fn parseStatement(self: *Parser) ?ast.Statement {
        return switch (self.cur_token.type) {
            token.TokenType.LET => .{ .let_statement = self.parseLetStatement() },
            else => null,
        };
    }

    fn parseLetStatement(self: *Parser) ?ast.LetStatement {
        var stmt: ast.LetStatement = ast.LetStatement.init(self.cur_token);

        if (!self.expectPeek(token.TokenType.IDENT)) {
            return null;
        }

        stmt.name = ast.Identifier{
            .token = self.cur_token,
            .value = self.cur_token.literal,
        };

        if (!self.expectPeek(token.TokenType.ASSIGN)) {
            return null;
        }

        // TODO: we're skipping the expressions until we encounter
        // a semicolon
        while (!self.curTokenIs(token.TokenType.SEMICOLON))
            self.nextToken();

        return stmt;
    }

    fn curTokenIs(self: *Parser, tt: token.TokenType) bool {
        return self.cur_token.type == tt;
    }

    fn peekTokenIs(self: *Parser, tt: token.TokenType) bool {
        return self.peek_token.type == tt;
    }

    fn expectPeek(self: *Parser, tt: token.TokenType) bool {
        if (self.peekTokenIs(tt)) {
            self.nextToken();
            return true;
        }
        return false;
    }
};

test "simple statement" {
    const input = "let a = 10;";
    var l = try lexer.Lexer.new(std.testing.allocator, input);
    defer l.free();

    var p = Parser.create(std.testing.allocator, &l);
    defer p.destroy();
}
