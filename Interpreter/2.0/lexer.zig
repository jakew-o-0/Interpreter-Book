const mem = @import("std").mem;
const ArrayList = @import("std").ArrayList;
const Token = @import("tokens.zig").Token;
const TokenType = @import("tokens.zig").TokenType;
const print = @import("std").debug.print;

pub const Lexer = struct {
    src: []const u8,
    tokens: ArrayList(Token),
    pos: usize,
    next_pos: usize,
    ch: u8,
    next: u8,

    pub fn init(alloc: mem.Allocator, src: []const u8) Lexer {
        var l = Lexer{
            .src = src,
            .tokens = ArrayList(Token).init(alloc),
            .pos = 0,
            .next_pos = 0,
            .ch = undefined,
            .next = undefined,
        };
        l.incr();
        l.ch = l.src[l.pos];
        return l;
    }
    pub fn deinit(self: *Lexer) void {
        self.tokens.deinit();
    }

    pub fn lexSrc(self: *Lexer) []Token {
        var cur_token: Token = undefined;
        while (cur_token.type != TokenType.eof) {
            self.consumeWhitespace();
            cur_token = self.parseToken();
            self.tokens.append(cur_token) catch @panic("failed to append token");
            self.incr();
        }
        return self.tokens.toOwnedSlice() catch @panic("allocator error");
    }

    fn parseToken(self: *Lexer) Token {
        var tok = Token.init();

        switch (self.ch) {
            '+' => tok.set(TokenType.op_plus, "+"),
            '-' => tok.set(TokenType.op_minus, "-"),
            '/' => tok.set(TokenType.op_divide, "/"),
            '*' => tok.set(TokenType.op_multiply, "*"),
            '<' => tok.set(TokenType.op_less_than, "<"),
            '>' => tok.set(TokenType.op_greater_than, ">"),
            ',' => tok.set(TokenType.syn_comma, ","),
            '(' => tok.set(TokenType.syn_l_paren, "("),
            ')' => tok.set(TokenType.syn_r_paren, ")"),
            '{' => tok.set(TokenType.syn_l_brace, "{"),
            '}' => tok.set(TokenType.syn_r_brace, "}"),
            ';' => tok.set(TokenType.syn_semicolon, ";"),
            0 => tok.set(TokenType.eof, ""),

            '=' => switch (self.next) {
                '=' => {
                    tok.set(TokenType.op_equal, "==");
                    self.incr();
                },
                else => tok.set(TokenType.op_assign, "="),
            },

            '!' => switch (self.next) {
                '=' => {
                    tok.set(TokenType.op_not_equal, "!=");
                    self.incr();
                },
                else => tok.set(TokenType.op_bang, "!"),
            },

            else => {
                if (self.isLetter()) {
                    tok.setString(self.getSlice());
                } else if (self.isNum()) {
                    tok.set(TokenType.type_int, self.getNum());
                } else {
                    tok.set(TokenType.illegal, "");
                }
            },
        }
        return tok;
    }

    fn incr(self: *Lexer) void {
        self.pos = self.next_pos;
        self.next_pos += 1;
        self.ch = self.next;
        if (self.next_pos < self.src.len) {
            self.next = self.src[self.next_pos];
        } else {
            self.next = 0;
        }
    }
    fn decr(self: *Lexer) void {
        self.next_pos = self.pos;
        self.pos -= 1;
        self.next = self.ch;
        self.ch = self.src[self.pos];
    }

    fn isWhitespce(self: Lexer) bool {
        if (self.ch == ' ' or
            self.ch == '\t' or
            self.ch == '\n' or
            self.ch == '\r')
        {
            return true;
        } else {
            return false;
        }
    }
    fn consumeWhitespace(self: *Lexer) void {
        while (self.isWhitespce()) : (self.incr()) {}
    }

    fn isLetter(self: Lexer) bool {
        if (self.ch <= 'z' and self.ch >= 'a' or
            self.ch <= 'Z' and self.ch >= 'A' or
            self.ch == '_')
        {
            return true;
        } else {
            return false;
        }
    }
    fn getSlice(self: *Lexer) []const u8 {
        const start = self.pos;
        while (self.isLetter()) : (self.incr()) {}
        self.decr();
        return self.src[start..self.next_pos];
    }

    fn isNum(self: Lexer) bool {
        if (self.ch <= '9' and self.ch >= '0') {
            return true;
        } else {
            return false;
        }
    }
    fn getNum(self: *Lexer) []const u8 {
        const start = self.pos;
        while (self.isNum()) : (self.incr()) {}
        self.decr();
        return self.src[start..self.next_pos];
    }
};
