const Token = @import("tokens.zig").Token;

pub const Node = struct {
    ptr: *anyopaque,
    tokenLiteral_ptr: *const fn (self: *anyopaque) ?Token,
    value_ptr: *const fn (self: *anyopaque) ?Expression,
    ident_ptr: *const fn (self: *anyopaque) ?[]const u8,

    pub fn init(pointer: anytype) Node {
        const T = @TypeOf(pointer);
        const T_info = @typeInfo(T);
        const gen = struct {
            pub fn tokenLiteral(p: *anyopaque) ?Token {
                const self: T = @ptrCast(@alignCast(p));
                return T_info.Pointer.child.tokenLiteral(self);
            }
            pub fn value(p: *anyopaque) ?Expression {
                const self: T = @ptrCast(@alignCast(p));
                return T_info.Pointer.child.value(self);
            }
            pub fn ident(p: *anyopaque) ?[]const u8 {
                const self: T = @ptrCast(@alignCast(p));
                return T_info.Pointer.child.ident(self);
            }
        };
        return .{
            .ptr = pointer,
            .tokenLiteral_ptr = gen.tokenLiteral,
            .value_ptr = gen.value,
            .ident_ptr = gen.ident,
        };
    }

    pub fn tokenLiteral(self: *Node) ?Token {
        return self.tokenLiteral_ptr(self.ptr);
    }
    pub fn value(self: *Node) ?Expression {
        return self.value_ptr(self.ptr);
    }
    pub fn ident(self: *Node) ?[]const u8 {
        return self.ident_ptr(self.ptr);
    }
};

pub const Expression = struct {
    ptr: *anyopaque,
    tokenLiteral_ptr: *const fn (self: *anyopaque) ?Token,
    left_ptr: *const fn (self: *anyopaque) ?Expression,
    right_ptr: *const fn (self: *anyopaque) ?Expression,
    value_ptr: *const fn (self: *anyopaque, t: type) ?t,

    pub fn init(pointer: anytype) Expression {
        const T = @TypeOf(pointer);
        const T_info = @typeInfo(T);
        const gen = struct {
            pub fn tokenLiteral(p: *anyopaque) ?Token {
                const self: T = @ptrCast(@alignCast(p));
                return T_info.Pointer.child.tokenLiteral(self);
            }
            pub fn left(p: *anyopaque) ?Expression {
                const self: T = @ptrCast(@alignCast(p));
                return T_info.Pointer.child.left(self);
            }
            pub fn right(p: *anyopaque) ?Expression {
                const self: T = @ptrCast(@alignCast(p));
                return T_info.Pointer.child.right(self);
            }
            pub fn value(p: *anyopaque, t: type) ?t {
                const self: T = @ptrCast(@alignCast(p));
                return T_info.Pointer.child.right(self);
            }
        };
        return .{
            .ptr = pointer,
            .tokenLiteral_ptr = gen.tokenLiteral,
            .left_ptr = gen.left,
            .right_ptr = gen.right,
            .value_ptr = gen.value,
        };
    }

    pub fn tokenLiteral(self: *Expression) ?Token {
        return self.tokenLiteral_ptr(self.ptr);
    }
    pub fn left(self: *Expression) ?Expression {
        return self.left_ptr(self.ptr);
    }
    pub fn right(self: *Expression) ?Expression {
        return self.right_ptr(self.ptr);
    }
    pub fn value(self: *Expression, t: type) ?t {
        return self.value_ptr(self.ptr, t);
    }
};

// statements {{{
pub const ExpressionStatement = struct {
    tokenLiteral: Token,
    value: Expression,

    pub fn node(self: *ExpressionStatement) Node {
        return Node.init(self);
    }
    pub fn value() void {}
};

pub const LetStatement = struct {
    tokenLiteral: Token,
    ident: []const u8,
    value: Expression,

    pub fn node(self: *LetStatement) Node {
        return Node.init(self);
    }
};

pub const ReturnStatement = struct {
    tokenLiteral: Token,
    value: Expression,

    pub fn node(self: *ReturnStatement) Node {
        return Node.init(self);
    }
};
// }}}

// expressions {{{
pub const Identifier = struct {
    tokenLiteral: Token,
    value: []const u8,

    pub fn expression(self: *Identifier) Expression {
        return Expression.init(self);
    }
};

pub const IntLiteral = struct {
    tokenLiteral: Token,
    value: i64,

    pub fn expression(self: *IntLiteral) Expression {
        return Expression.init(self);
    }
};

pub const PrefixExpression = struct {
    tokenLiteral: Token,
    opperator: []const u8,
    right: Expression,

    pub fn expression(self: *PrefixExpression) Expression {
        return Expression.init(self);
    }
};

pub const InfixExpression = struct {
    tokenLiteral: Token,
    opperator: []const u8,
    left: Expression,
    right: Expression,

    pub fn expression(self: *InfixExpression) Expression {
        return Expression.init(self);
    }
};
// }}}
