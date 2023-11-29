const std = @import("std");
const token = @import("token.zig");
const lexer = @import("lexer.zig");
const ast = @import("ast.zig");

const Parser = struct {
    allocator: std.mem.Allocator,
    l: *lexer.Lexer,
    cur_token: token.Token,
    peek_token: token.Token,
    errors: std.ArrayList([]const u8),

    pub fn create(allocator: std.mem.Allocator, l: *lexer.Lexer) Parser {
        return .{
            .l = l,
            .cur_token = l.nextToken(),
            .peek_token = l.nextToken(),
            .allocator = allocator,
            .errors = std.ArrayList([]const u8).init(allocator),
        };
    }

    pub fn destroy(self: *Parser) void {
        for (self.errors.items) |item| {
            self.allocator.free(item);
        }
        self.errors.deinit();
    }

    // It is up to the caller to call deinit on the return AST program
    pub fn parseProgam(self: *Parser) !ast.Program {
        var program = ast.Program.init(self.allocator);

        while (self.cur_token.type != token.TokenType.EOF) : (self.nextToken()) {
            if (self.parseStatement()) |stmt| {
                try program.statements.append(stmt);
            }
        }

        return program;
    }

    // err string is created using allocPrint so we are now
    // owner of the allocated memory.
    fn logError(self: *Parser, err: []const u8) !void {
        try self.errors.append(err);
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

        // Log the error before returning false
        const m = std.fmt.allocPrint(
            self.allocator,
            "expected next token to be '{s}', got '{s}' instead",
            .{ tt.stringFromTokenType(), self.peek_token.type.stringFromTokenType() },
        ) catch @panic("Failed to create string to log error");
        self.logError(m) catch @panic("Failed to log error");

        return false;
    }
};

test "error in let statement" {
    const input =
        \\ let x if 5;
    ;

    var l = try lexer.Lexer.new(std.testing.allocator, input);
    defer l.free();

    var p = Parser.create(std.testing.allocator, &l);
    defer p.destroy();

    var prog = try p.parseProgam();
    defer prog.deinit();

    for (p.errors.items) |err| {
        std.debug.print("[ERROR] {s}\n", .{err});
    }
}

test "let statement" {
    const input =
        \\ let x = 5;
        \\ let y = 10;
        \\ let foobar = 1234;
    ;

    var l = try lexer.Lexer.new(std.testing.allocator, input);
    defer l.free();

    var p = Parser.create(std.testing.allocator, &l);
    defer p.destroy();

    var prog = try p.parseProgam();
    defer prog.deinit();

    try std.testing.expectEqual(prog.statements.items.len, 3);

    const expected_ident = [_][]const u8{ "x", "y", "foobar" };

    for (prog.statements.items, 0..) |item, idx| {
        if (item.let_statement) |stmt| {
            try std.testing.expectEqualSlices(u8, stmt.name.value, expected_ident[idx]);
        }
    }
}
