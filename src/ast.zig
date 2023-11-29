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

pub const Statement = union {
    let_statement: ?LetStatement,
};

// Statement
pub const LetStatement = struct {
    token: token.Token, // the token.LET
    name: Identifier = undefined,
    value: Expression = undefined,

    pub fn init(t: token.Token) LetStatement {
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
