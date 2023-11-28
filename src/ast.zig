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

// Let's create a Node interface. Each node in our AST has to
// implement it.
pub const Node = struct {
    tokenLiteralFn: *const fn (*Node) []const u8,

    pub fn tokenLiteral(self: *Node) []const u8 {
        return self.tokenLiteralFn(self);
    }
};

pub const Statement = struct {
    node: Node,

    fn init() Statement {
        .{ .node = Node{ .tokenLiteralFn = tokenLiteral } };
    }

    fn tokenLiteral(node: *Node) []const u8 {
        const self = @fieldParentPtr(Statement, "node", node);
        _ = self;
        @panic("tokenLiteral not implemented for Statement");
    }
};

pub const Expression = struct {
    node: Node,

    fn init() Expression {
        .{ .node = Node{ .tokenLiteralFn = tokenLiteral } };
    }

    fn tokenLiteral(node: *Node) []const u8 {
        const self = @fieldParentPtr(Expression, "node", node);
        _ = self;
        @panic("tokenLiteral not implemented for Expression");
    }
};

// Will be the root of the AST
pub const Program = struct {
    statements: std.ArrayList(Statement),
};

test "simple" {}
