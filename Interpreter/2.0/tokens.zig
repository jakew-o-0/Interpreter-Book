const ComptimeStringMap = @import("std").ComptimeStringMap;

pub const Token = struct {
    type: TokenType,
    literal: []const u8,

    pub fn init() Token {
        return .{
            .type = undefined,
            .literal = undefined,
        };
    }

    pub fn set(self: *Token, ttype: TokenType, lit: []const u8) void {
        self.type = ttype;
        self.literal = lit;
    }

    pub fn setString(self: *Token, str: []const u8) void {
        self.literal = str;
        self.type = keywordMap.get(str) orelse TokenType.type_identifier;
    }
};

pub const TokenType = enum {
    op_plus,
    op_minus,
    op_assign,
    op_bang,
    op_divide,
    op_multiply,
    op_less_than,
    op_greater_than,
    op_equal,
    op_not_equal,
    //syntax
    syn_comma,
    syn_semicolon,
    syn_l_paren,
    syn_r_paren,
    syn_l_brace,
    syn_r_brace,
    //keywords
    keyw_let,
    keyw_function,
    keyw_if,
    keyw_else,
    keyw_return,
    //types
    type_int,
    type_bool,
    type_identifier,
    //other
    eof,
    illegal,
};

const keywordMap = ComptimeStringMap(
    TokenType,
    .{ .key = "Let", .value = TokenType.keyw_let },
    .{ .key = "fn", .value = TokenType.keyw_function },
    .{ .key = "if", .value = TokenType.keyw_if },
    .{ .key = "else", .value = TokenType.keyw_else },
    .{ .key = "return", .value = TokenType.keyw_return },
    .{ .key = "true", .value = TokenType.type_bool },
    .{ .key = "false", .value = TokenType.type_bool },
);
