//! Abstract Syntax Tree
//!
//! Some notes:
//!   - Use Context Free Grammar (CFG)
//!     - Set of rules that describe how to form correct sentence
//!     - Notation used is Backus-Naur Form (BNF)
//!   - We can do top-down or bottom-up parsing
//!     - We use "Top Down operator precedence" (Pratt parser)
//!
//! Let's start with variable bindings that are statements:
//!   - let x = 5;
//!   - let foobar = add(2, 3);
//!   - let foo = bar;
//!
//!
//! This are let statement and the have the following form:
//!   - let <identifier> = <expression>;
const std = @import("std");
const token = @import("token.zig");
const lexer = @import("lexer.zig");

const Statement = struct {};

// Will be the root of the AST
const AstProgram = struct {
    statements: std.ArrayList(Statement),
};

const Parser = struct {
    allocator: std.mem.Allocator,
    l: *lexer.Lexer,
    cur_token: token.Token = undefined,
    peek_token: token.Token = undefined,
    statements: std.ArrayList(Statement),

    pub fn create(allocator: std.mem.Allocator, l: *lexer.Lexer) Parser {
        var p: Parser = .{
            .l = l,
            .allocator = allocator,
            .statements = std.ArrayList(Statement).init(allocator),
        };

        // Read two tokens, so cur_token and peek_token are both set.
        p.nextToken();
        p.nextToken();

        return p;
    }

    pub fn destroy(self: *Parser) void {
        _ = self;
    }

    pub fn parseProgam(self: *Parser) !AstProgram {
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

    fn parseStatement(self: *Parser) ?Statement {
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
