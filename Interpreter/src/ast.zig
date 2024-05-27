const std = @import("std");
const token = @import("token.zig");

pub const Node = union(enum) {
    statement: Statement,
    expression: Expression,
};

pub const Statement = union(enum) {
    letStatement: LetStatement,
};

pub const Expression = union(enum) {
    null: ?u8,
};

pub const LetStatement = struct {
    tokenLiteral: token.Token,
    ident: []const u8,
    value: Expression,
};
