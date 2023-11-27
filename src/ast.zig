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

pub const Statement = struct {};

// Will be the root of the AST
pub const AstProgram = struct {
    statements: std.ArrayList(Statement),
};

test "simple" {}
