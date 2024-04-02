const std = @import("std");
const token = @import("token.zig");
const lexer = @import("lexer.zig");
const ast = @import("ast.zig");

const Parser = struct {
    const Precedence = enum(u4) {
        lowest = 1,
        equals, // ==
        lessgreater, // > or <
        sum, // +
        product, // *
        prefix, // -X or !X
        call, // myFunction(X)
    };

    const PrefixParseFn = *const fn (*Parser) ?ast.Expression;
    const InfixParseFn = *const fn (*Parser, ast.Expression) ?ast.Expression;

    allocator: std.mem.Allocator,
    l: *lexer.Lexer,
    cur_token: token.Token,
    peek_token: token.Token,
    errors: std.ArrayList([]const u8),
    prefix_parse_fns: std.EnumArray(token.TokenType, ?PrefixParseFn),
    infix_parse_fns: std.EnumArray(token.TokenType, ?InfixParseFn),

    pub fn new(allocator: std.mem.Allocator, l: *lexer.Lexer) Parser {
        var ppf = std.EnumArray(token.TokenType, ?PrefixParseFn).initFill(null);
        const ipf = std.EnumArray(token.TokenType, ?InfixParseFn).initFill(null);

        ppf.set(token.TokenType.IDENT, parseIdentifier);
        ppf.set(token.TokenType.INT, parseIntegerLiteral);

        return .{
            .l = l,
            .cur_token = l.nextToken(),
            .peek_token = l.nextToken(),
            .allocator = allocator,
            .errors = std.ArrayList([]const u8).init(allocator),
            .prefix_parse_fns = ppf,
            .infix_parse_fns = ipf,
        };
    }

    pub fn free(self: *Parser) void {
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

    fn registerPrefix(self: *Parser, tt: token.TokenType, f: PrefixParseFn) void {
        self.prefix_parse_fns.set(tt, f);
    }

    fn registerInfix(self: *Parser, tt: token.TokenType, f: InfixParseFn) void {
        self.infix_parse_fns.set(tt, f);
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
            token.TokenType.LET => self.parseLetStatement(),
            token.TokenType.RETURN => self.parseReturnStatement(),
            else => self.parseExpressionStatement(),
        };
    }

    //   - let <identifier> = <expression>;
    fn parseLetStatement(self: *Parser) ?ast.Statement {
        var ls: ast.LetStatement = ast.LetStatement.init(self.cur_token);

        if (!self.expectPeek(token.TokenType.IDENT)) {
            return null;
        }

        ls.name = ast.Identifier{
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

        return .{ .let_stmt = ls };
    }

    //   - return <expression>;
    fn parseReturnStatement(self: *Parser) ?ast.Statement {
        // TODO: Will become var when will update it with expression
        const rs: ast.ReturnStatement = ast.ReturnStatement.init(self.cur_token);

        self.nextToken();

        // TODO: we're skipping the expressions until we encounter
        // a semicolon
        while (!self.curTokenIs(token.TokenType.SEMICOLON))
            self.nextToken();

        return .{ .return_stmt = rs };
    }

    fn parseExpressionStatement(self: *Parser) ?ast.Statement {
        var es: ast.ExpressionStatement = ast.ExpressionStatement.init(self.cur_token);

        if (self.parseExpression(Precedence.lowest)) |expr| {
            es.expression = expr;
        } else {
            std.debug.print("got null from parse expression\n", .{});
            return null;
        }

        if (self.peekTokenIs(token.TokenType.SEMICOLON)) {
            self.nextToken();
        }

        return .{ .expression_stmt = es };
    }

    fn parseExpression(self: *Parser, p: Precedence) ?ast.Expression {
        _ = p;
        const prefix_fn = self.prefix_parse_fns.get(self.cur_token.type);

        // Check if a function is associated with token.
        if (prefix_fn) |pfn| {
            const left_expr = pfn(self);
            return left_expr;
        }

        return null;
    }

    fn parseIdentifier(self: *Parser) ?ast.Expression {
        return .{ .identifier = ast.Identifier{ .token = self.cur_token, .value = self.cur_token.literal } };
    }

    fn parseIntegerLiteral(self: *Parser) ?ast.Expression {
        const value = std.fmt.parseInt(i64, self.cur_token.literal, 10) catch return null;

        return .{ .integer_literal = ast.IntegerLiteral{
            .token = self.cur_token,
            .value = value,
        } };
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

test "literal expression" {
    const input = "5;";

    var l = try lexer.Lexer.new(std.testing.allocator, input);
    defer l.free();

    var p = Parser.new(std.testing.allocator, &l);
    defer p.free();

    var prog = try p.parseProgam();
    defer prog.deinit();

    // We expect no error
    try std.testing.expectEqual(@as(usize, 0), p.errors.items.len);
    // We have only one statement
    try std.testing.expectEqual(@as(usize, 1), prog.statements.items.len);
}

test "error in let statement" {
    const input =
        \\ let x if 5;
    ;

    var l = try lexer.Lexer.new(std.testing.allocator, input);
    defer l.free();

    var p = Parser.new(std.testing.allocator, &l);
    defer p.free();

    var prog = try p.parseProgam();
    defer prog.deinit();

    try std.testing.expectEqual(@as(usize, 1), p.errors.items.len);

    const expected_error = "expected next token to be '=', got 'IF' instead";
    for (p.errors.items) |err| {
        // There is only one error...
        try std.testing.expectEqualSlices(u8, err, expected_error);
    }
}

test "return statement" {
    const input =
        \\ return 5;
        \\ return 10;
    ;

    var l = try lexer.Lexer.new(std.testing.allocator, input);
    defer l.free();

    var p = Parser.new(std.testing.allocator, &l);
    defer p.free();

    var prog = try p.parseProgam();
    defer prog.deinit();

    // We expect no errors
    try std.testing.expectEqual(@as(usize, 0), p.errors.items.len);
    try std.testing.expectEqual(@as(usize, 2), prog.statements.items.len);

    for (prog.statements.items) |stmt|
        try std.testing.expectEqualSlices(u8, "return", stmt.tokenLiteral());
}

test "let statement" {
    const input =
        \\ let x = 5;
        \\ let y = 10;
        \\ let foobar = 1234;
    ;

    var l = try lexer.Lexer.new(std.testing.allocator, input);
    defer l.free();

    var p = Parser.new(std.testing.allocator, &l);
    defer p.free();

    var prog = try p.parseProgam();
    defer prog.deinit();

    try std.testing.expectEqual(@as(usize, 0), p.errors.items.len);
    try std.testing.expectEqual(@as(usize, 3), prog.statements.items.len);

    const expected_ident = [_][]const u8{ "x", "y", "foobar" };

    for (prog.statements.items, 0..) |stmt, idx| {
        // // Keep this comment to show how print statement...
        // const str_debug = try stmt.string(std.testing.allocator);
        // defer std.testing.allocator.free(str_debug);
        // std.debug.print("{s}\n", .{str_debug});

        if (stmt.nameLiteral()) |ident| {
            try std.testing.expectEqualSlices(u8, expected_ident[idx], ident);
        } else {
            // We shouldn't be here so failed with explicit message
            try std.testing.expectEqualSlices(u8, "", "not a let statement, what are we doing here?");
        }
    }
}
