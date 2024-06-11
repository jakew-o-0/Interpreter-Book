const mem = @import("std").mem;
const ArrayList = @import("std").ArrayList;
const Token = @import("tokens.zig").Token;
const TokenType = @import("tokens.zig").TokenType;

pub const Lexer = struct {
    src: []const u8,
    tokens: ArrayList(Token),
    pos: usize,
    ch: u8,
    next: u8,

    pub fn init(alloc: mem.Allocator, src: []const u8) Lexer {
        var l = Lexer{
            .src = src,
            .tokens = ArrayList(Token).init(alloc),
            .pos = 0,
            .ch = undefined,
            .next = undefined,
        };
        l.incr();
        l.incr();
        return l;
    }
    pub fn deinit(self: *Lexer) void {
        self.tokens.deinit();
    }

    pub fn getTokens(self: *Lexer) []Token {
        var cur_token: Token = undefined;
        while (cur_token.type != TokenType.eof) : (cur_token = self.parseToken()) {
            self.tokens.append(cur_token) catch @panic("failed to append token");
        }
        return self.tokens.toOwnedSlice() catch @panic("allocator error");
    }

    fn incr(self: *Lexer) void {
        self.ch = self.next;
        self.pos += 1;
        if (self.pos <= self.src.len) {
            self.next = self.src[self.pos];
        } else {
            self.next = 0;
        }
    }

    fn parseToken(self: *Lexer) Token {
        var tok = Token.init();
        self.consumeWhitespace();

        switch (self.ch) {
            '+' => tok.set(TokenType.op_plus, "+"),
            '-' => tok.set(TokenType.op_minus, "-"),
            '/' => tok.set(
                TokenType.op_divide,
            ),
            '*' => tok.set(TokenType.op_multiply, self.ch),
            '(' => tok.set(TokenType.syn_l_paren, self.ch),
            ')' => tok.set(TokenType.syn_r_paren, self.ch),
            '{' => tok.set(TokenType.syn_l_brace, self.ch),
            '}' => tok.set(TokenType.syn_r_brace, self.ch),
            ';' => tok.set(TokenType.syn_semicolon, self.ch),
            '<' => tok.set(TokenType.op_less_than, self.ch),
            '>' => tok.set(TokenType.op_greater_than, self.ch),
            0 => tok.set(TokenType.eof, 0),

            '=' => switch (self.next) {
                '=' => tok.set(TokenType.op_equal, "=="),
                else => tok.set(TokenType.op_assign, self.ch),
            },

            '!' => switch (self.next) {
                '=' => tok.set(TokenType.op_not_equal, "!="),
                else => tok.set(TokenType.op_bang, self.ch),
            },

            else => {
                if (self.isLetter()) {
                    tok.set(TokenType.type_identifier, self.getSlice());
                } else if (self.isNum()) {
                    tok.set(TokenType.type_int, self.getNum());
                } else {
                    tok.set(TokenType.illegal, "");
                }
            },
        }
    }

    fn consumeWhitespace(self: *Lexer) void {
        while (self.ch == ' ' or self.ch == '\t' or self.ch == '\n' or self.ch == '\r') : (self.incr()) {}
    }

    fn isLetter(self: Lexer) bool {
        if (self.ch <= 'z' and self.ch >= 'a' or
            self.ch <= 'Z' and self.ch >= 'A' or
            self.ch == '_')
        {
            return true;
        }
        return false;
    }
    fn getSlice(self: *Lexer) []const u8 {
        const start = self.pos;
        while (self.isLetter) : (self.incr) {}
        return self.src[start..self.pos];
    }

    fn isNum(self: Lexer) bool {
        if (self.ch <= '9' and self.ch >= 0) {
            return true;
        }
        return false;
    }
    fn getNum(self: *Lexer) []const u8 {
        const start = self.pos;
        while (self.isNum) : (self.incr) {}
        return self.src[start..self.pos];
    }
};
