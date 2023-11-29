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
};

// Using tagged union allows us to use with switch
pub const Statement = union(StatementType) {
    let_stmt: ?LetStatement,
    return_stmt: ?ReturnStatement,
};

// Statements
pub const LetStatement = struct {
    token: token.Token, // the token.LET
    name: Identifier = undefined,
    value: Expression = undefined,

    pub fn init(t: token.Token) LetStatement {
        return .{ .token = t };
    }
};

pub const ReturnStatement = struct {
    token: token.Token,
    value: Expression = undefined,

    pub fn init(t: token.Token) ReturnStatement {
        return .{ .token = t };
    }
};

// Expression
pub const Expression = struct {};

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
