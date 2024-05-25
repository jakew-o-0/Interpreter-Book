const std = @import("std");

pub const Token = struct {
    literal: []const u8,
    type: TokenType,

    pub fn setToken(
        self: *Token,
        tok_type: TokenType,
        tok_literal: []const u8,
    ) void {
        self.type = tok_type;
        self.literal = tok_literal[0..];
    }
};

pub const TokenType = enum {
    plus,
    minus,
    assign,

    l_paren,
    r_paren,
    l_brace,
    r_brace,

    comma,
    semicolon,
    eof,
};
