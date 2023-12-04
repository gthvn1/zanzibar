//! Abstract Syntax Tree
//!
//! Some notes:
//!   - Use Context Free Grammar (CFG)
//!     - Set of rules that describe how to form correct sentence
//!     - Notation used is Backus-Naur Form (BNF)
//!   - We can do top-down or bottom-up parsing
//!     - We use "Top Down operator precedence" (Pratt parser)

const std = @import("std");
const token = @import("token.zig");

const StatementType = enum {
    let_stmt,
    return_stmt,
    expression_stmt,
};

// Using tagged union allows us to use with switch
pub const Statement = union(StatementType) {
    let_stmt: LetStatement,
    return_stmt: ReturnStatement,
    expression_stmt: ExpressionStatement,

    pub fn tokenLiteral(self: Statement) []u8 {
        return switch (self) {
            inline else => |stmt| stmt.tokenLiteral(),
        };
    }

    // Use to print statement to help the debugging
    // It allocates memory for the string, it is up to the caller
    // to free it.
    pub fn string(self: Statement, allocator: std.mem.Allocator) ![]u8 {
        return switch (self) {
            inline else => |stmt| try stmt.string(allocator),
        };
    }

    pub fn nameLiteral(self: Statement) ?[]u8 {
        return switch (self) {
            .let_stmt => |stmt| stmt.nameLiteral(),
            inline else => null,
        };
    }
};

// Statements
pub const LetStatement = struct {
    token: token.Token, // the token.LET
    name: Identifier = undefined,
    expression: Expression = undefined,

    pub fn init(t: token.Token) LetStatement {
        return .{ .token = t };
    }

    pub fn tokenLiteral(self: LetStatement) []u8 {
        return self.token.literal;
    }

    pub fn string(self: LetStatement, allocator: std.mem.Allocator) ![]u8 {
        // TODO: currently value is not updated by the parser. We will
        //       update it when expression are parsed...
        return std.fmt.allocPrint(
            allocator,
            "{s} {s} = {s};",
            .{ self.token.literal, self.name.value, "<expression is not parsed yet>" },
        );
    }

    pub fn nameLiteral(self: LetStatement) []u8 {
        return self.name.value;
    }
};

pub const ReturnStatement = struct {
    token: token.Token,
    expression: Expression = undefined,

    pub fn init(t: token.Token) ReturnStatement {
        return .{ .token = t };
    }

    pub fn tokenLiteral(self: ReturnStatement) []u8 {
        return self.token.literal;
    }

    pub fn string(self: ReturnStatement, allocator: std.mem.Allocator) ![]u8 {
        // TODO: currently value is not updated by the parser. We will
        //       update it when expression are parsed...
        return std.fmt.allocPrint(
            allocator,
            "{s} {s}",
            .{ self.token.literal, "<expression is not parsed yet>" },
        );
    }
};

pub const ExpressionStatement = struct {
    token: token.Token,
    expression: Expression = undefined,

    pub fn init(t: token.Token) ExpressionStatement {
        return .{ .token = t };
    }

    pub fn tokenLiteral(self: ExpressionStatement) []u8 {
        return self.token.literal;
    }

    pub fn string(self: ExpressionStatement, allocator: std.mem.Allocator) ![]u8 {
        _ = self;
        // TODO: currently value is not updated by the parser. We will
        //       update it when expression are parsed...
        return std.fmt.allocPrint(allocator, "<expression is not yet parsed>", .{});
    }
};

// Expression
// In Monkey everything besides let and return is an expression.
// There is many varieties of expressions:
//  5 + 4
//  foo == bare
//  5 * ( 5 + 5)
// --a
// b++
// add(2, 3)
// fn(x, y) {return x + y}; // function are first class citizen
// ...
const ExpressionType = enum {
    identifier,
};

pub const Expression = union(ExpressionType) {
    identifier: Identifier,
};

pub const Identifier = struct {
    token: token.Token,
    value: []u8,
};

// Will be the root of the AST
pub const Program = struct {
    statements: std.ArrayList(Statement),

    pub fn init(allocator: std.mem.Allocator) Program {
        return .{
            .statements = std.ArrayList(Statement).init(allocator),
        };
    }

    pub fn deinit(self: *Program) void {
        self.statements.deinit();
    }
};

test "nop" {}
