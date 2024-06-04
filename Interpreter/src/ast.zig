const std = @import("std");
const token = @import("token.zig");

/// interfaces
/// these will be emitted by the objects
/// these will have the type of the object
pub const Node = struct {
    typePtr: *anyopaque,
    toStringFn: *const fn (self: *anyopaque, buf: []u8) []const u8,

    pub fn init(ptr: anytype) Node {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        // zig has no anonymous functions, it is defined here and given to the returned struct
        const gen = struct {
            pub fn toString(pointer: *anyopaque, buf: []u8) []const u8 {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.Pointer.child.toString(self, buf);
            }
        };

        return .{
            .typePtr = ptr,
            .toStringFn = gen.toString,
        };
    }

    // indirection to the function of the object using the interface
    pub fn toString(self: Node, buf: []u8) []const u8 {
        return self.toStringFn(self.typePtr, buf);
    }
};

pub const Expression = struct {
    ptr: *anyopaque,
    toStringFn: *const fn (self: *anyopaque, buf: []u8) []const u8,

    pub fn init(ptr: anytype) Expression {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn toString(pointer: *anyopaque, buf: []u8) []const u8 {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.Pointer.child.toString(self, buf);
            }
        };

        return .{
            .ptr = ptr,
            .toStringFn = gen.toString,
        };
    }

    pub fn toString(self: Expression, buf: []u8) []const u8 {
        return self.toStringFn(self.ptr, buf);
    }
};

// statements {{{
pub const ExpressionStatement = struct {
    tokenLiteral: token.Token,
    value: Expression,

    pub fn node(self: *ExpressionStatement) Node {
        return Node.init(self);
    }

    pub fn toString(self: *ExpressionStatement, buf: []u8) []const u8 {
        var b: [255]u8 = undefined;
        return std.fmt.bufPrint(buf, "{s}", .{self.value.toString(&b)}) catch unreachable;
    }
};

pub const LetStatement = struct {
    tokenLiteral: token.Token,
    ident: []const u8,
    value: Expression,

    pub fn node(self: *LetStatement) Node {
        return Node.init(self);
    }

    pub fn toString(self: *LetStatement, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{s} {s}", .{ self.tokenLiteral.literal, self.ident }) catch unreachable;
    }
};

pub const ReturnStatement = struct {
    tokenLiteral: token.Token,
    value: Expression,

    pub fn node(self: *ReturnStatement) Node {
        return Node.init(self);
    }

    pub fn toString(self: *ReturnStatement, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{s}", .{@tagName(self.tokenLiteral.type)}) catch unreachable;
    }
};
// }}}

// expressions {{{
pub const Identifier = struct {
    tokenLiteral: token.Token,
    value: []const u8,

    pub fn expression(self: *Identifier) Expression {
        return Expression.init(self);
    }

    pub fn toString(self: *Identifier, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{s} {s}", .{ @tagName(self.tokenLiteral.type), self.value }) catch unreachable;
    }
};

pub const IntLiteral = struct {
    tokenLiteral: token.Token,
    value: i64,

    pub fn expression(self: *IntLiteral) Expression {
        return Expression.init(self);
    }

    pub fn toString(self: *IntLiteral, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{s} {d}", .{ @tagName(self.tokenLiteral.type), self.value }) catch unreachable;
    }
};

pub const PrefixExpression = struct {
    tokenLiteral: token.Token,
    opperator: []const u8,
    right: Expression,

    pub fn expression(self: *PrefixExpression) Expression {
        return Expression.init(self);
    }

    pub fn toString(self: *PrefixExpression, buf: []u8) []const u8 {
        var b: [255]u8 = undefined;
        return std.fmt.bufPrint(buf, "{s} {s}", .{ self.opperator, self.right.toString(&b) }) catch unreachable;
    }
};
// }}}
