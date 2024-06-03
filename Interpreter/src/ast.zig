const std = @import("std");
const token = @import("token.zig");

pub const Node = union(enum) {
    letStatement: LetStatement,
    returnStatement: ReturnStatement,
    expressionStatement: ExpressionStatement,

    pub fn toString(self: Node, buf: []u8) []const u8 {
        return switch (self) {
            inline else => |n| n.toString(buf),
        };
    }
};

pub const Statement = union(enum) {
    letStatement: LetStatement,
    returnStatement: ReturnStatement,
    expressionStatement: ExpressionStatement,

    pub fn toString(self: Node, buf: []u8) []const u8 {
        return switch (self) {
            inline else => |n| n.toString(buf),
        };
    }
};

pub const Expression = union(enum) {
    identifier: Identifier,
    intLiteral: IntLiteral,
    prefixExpression: PrefixExpression,

    pub fn toString(self: Expression, buf: []u8) []const u8 {
        return switch (self) {
            inline else => |n| n.toString(buf),
        };
    }
};

pub const ExpressionStatement = struct {
    tokenLiteral: token.Token,
    value: Expression,

    pub fn toString(self: ExpressionStatement, buf: []u8) []const u8 {
        var b: [255]u8 = undefined;
        return std.fmt.bufPrint(buf, "{s}", .{self.value.toString(&b)}) catch unreachable;
    }
};

pub const LetStatement = struct {
    tokenLiteral: token.Token,
    ident: []const u8,
    value: Expression,

    pub fn toString(self: LetStatement, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{s} {s}", .{ self.tokenLiteral.literal, self.ident }) catch unreachable;
    }
};

pub const ReturnStatement = struct {
    tokenLiteral: token.Token,
    value: Expression,

    pub fn toString(self: ReturnStatement, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{s}", .{@tagName(self.tokenLiteral.type)}) catch unreachable;
    }
};

pub const Identifier = struct {
    tokenLiteral: token.Token,
    value: []const u8,

    pub fn toString(self: Identifier, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{s} {s}", .{ @tagName(self.tokenLiteral.type), self.value }) catch unreachable;
    }
};

pub const IntLiteral = struct {
    tokenLiteral: token.Token,
    value: i64,

    pub fn toString(self: IntLiteral, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{s} {d}", .{ @tagName(self.tokenLiteral.type), self.value }) catch unreachable;
    }
};

pub const PrefixExpression = struct {
    tokenLiteral: token.Token,
    opperator: []const u8,
    right: Expression,

    pub fn toString(self: PrefixExpression, buf: []u8) []const u8 {
        var b: [255]u8 = undefined;
        return std.fmt.bufPrint(buf, "{s} {s}", .{ self.opperator, self.right.toString(&b) });
    }
};
