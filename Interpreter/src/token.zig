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

    pub fn setWord(self: *Token, word: []const u8) void {
        if (Keywords.has(word)) {
            self.type = Keywords.get(word).?;
        } else if (BoolType.has(word)) {
            self.type = BoolType.get(word).?;
        } else {
            self.type = TokenType.identifier;
        }
        self.literal = word[0..];
    }
};

pub const TokenType = enum {
    //operators
    plus,
    minus,
    assign,
    bang,
    divide,
    multiply,
    less_than,
    greater_than,
    equal,
    not_equal,
    //syntax
    comma,
    semicolon,
    l_paren,
    r_paren,
    l_brace,
    r_brace,
    //keywords
    let,
    function,
    _if,
    _else,
    _return,
    //types
    int,
    bool,
    //other
    identifier,
    eof,
    illegal,
};

pub const Keywords = std.ComptimeStringMap(TokenType, .{
    .{ "let", TokenType.let },
    .{ "fn", TokenType.function },
    .{ "if", TokenType._if },
    .{ "else", TokenType._else },
    .{ "return", TokenType._return },
});

pub const BoolType = std.ComptimeStringMap(TokenType, .{
    .{ "true", TokenType.bool },
    .{ "false", TokenType.bool },
});
