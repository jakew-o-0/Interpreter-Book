const expect = @import("std").testing.expect;
const std = @import("std");
const t = @import("token.zig");

pub fn NewLexer(src: []const u8) Lexer {
    return .{
        .source_code = src,
        .cur_pos = 0,
        .next_pos = 0,
        .ch = undefined,
    };
}

pub const Lexer = struct {
    source_code: []const u8,
    cur_pos: usize, // current char in source_code
    next_pos: usize, // next char in source_code
    ch: u8,

    fn increment(self: *Lexer) void {
        self.cur_pos = self.next_pos;
        self.next_pos += 1;
        if (self.cur_pos >= self.source_code.len) {
            self.ch = 0;
        } else {
            self.ch = self.source_code[self.cur_pos];
        }
    }

    fn peakChar(self: *Lexer, expected: u8) bool {
        if (self.next_pos > self.source_code.len) {
            return false;
        }
        if (expected == self.source_code[self.next_pos]) {
            return true;
        }
        return false;
    }

    fn isLetter(self: Lexer) bool {
        return self.ch <= 'z' and self.ch >= 'a' or
            self.ch <= 'Z' and self.ch >= 'A' or
            self.ch == '_';
    }

    fn isNum(self: Lexer) bool {
        return self.ch <= '9' and self.ch >= '0';
    }

    fn getSlice(self: *Lexer, cond: *const fn (Lexer) bool) []const u8 {
        const start = self.cur_pos;
        while (cond(self.*)) {
            self.increment();
        }
        // decrement count as it is currently sitting on whitespace
        self.cur_pos -= 1;
        self.next_pos -= 1;
        self.ch = self.source_code[self.cur_pos];

        return self.source_code[start..self.next_pos];
    }

    fn consumeWhiteSpace(self: *Lexer) void {
        while (self.ch == ' ' or self.ch == '\n' or self.ch == '\t' or self.ch == '\r') {
            self.increment();
        }
    }

    pub fn nextToken(self: *Lexer) t.Token {
        var tok = t.Token{ .literal = undefined, .type = undefined };
        self.increment();
        self.consumeWhiteSpace();

        switch (self.ch) {
            '+' => tok.setToken(t.TokenType.plus, "+"),
            '-' => tok.setToken(t.TokenType.minus, "-"),
            ',' => tok.setToken(t.TokenType.comma, ","),
            ';' => tok.setToken(t.TokenType.semicolon, ";"),
            '(' => tok.setToken(t.TokenType.l_paren, "("),
            ')' => tok.setToken(t.TokenType.r_paren, ")"),
            '{' => tok.setToken(t.TokenType.l_brace, "{"),
            '}' => tok.setToken(t.TokenType.r_brace, "}"),
            '/' => tok.setToken(t.TokenType.divide, "/"),
            '*' => tok.setToken(t.TokenType.multiply, "*"),
            '<' => tok.setToken(t.TokenType.less_than, "<"),
            '>' => tok.setToken(t.TokenType.greater_than, ">"),
            0 => tok.setToken(t.TokenType.eof, ""),

            '=' => {
                if (self.peakChar('=')) {
                    tok.setToken(t.TokenType.equal, "==");
                    self.increment();
                } else {
                    tok.setToken(t.TokenType.assign, "=");
                }
            },
            '!' => {
                if (self.peakChar('=')) {
                    tok.setToken(t.TokenType.not_equal, "!=");
                    self.increment();
                } else {
                    tok.setToken(t.TokenType.bang, "!");
                }
            },

            else => {
                if (self.isLetter()) {
                    tok.setWord(self.getSlice(Lexer.isLetter));
                } else if (self.isNum()) {
                    tok.setToken(t.TokenType.int, self.getSlice(Lexer.isNum));
                } else {
                    const illegal_literal: *[1]u8 = &self.ch;
                    tok.setToken(t.TokenType.illegal, illegal_literal);
                }
            },
        }
        return tok;
    }
};

test "Lexer Test" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\
        \\let add = fn(x,y) {
        \\    x + y;
        \\};
        \\
        \\let result = add(five, ten);
        \\!-/*5; 5 < 10 > 5;
        \\if (5 < 10) { return true; } else { return false; }
        \\10 == 10; 10 != 9;
    ;
    var lex = NewLexer(input);

    const tests = [_]t.Token{
        // variable decliration
        t.Token{ .type = t.TokenType.let, .literal = "let" },
        t.Token{ .type = t.TokenType.identifier, .literal = "five" },
        t.Token{ .type = t.TokenType.assign, .literal = "=" },
        t.Token{ .type = t.TokenType.int, .literal = "5" },
        t.Token{ .type = t.TokenType.semicolon, .literal = ";" },

        // variable decliration
        t.Token{ .type = t.TokenType.let, .literal = "let" },
        t.Token{ .type = t.TokenType.identifier, .literal = "ten" },
        t.Token{ .type = t.TokenType.assign, .literal = "=" },
        t.Token{ .type = t.TokenType.int, .literal = "10" },
        t.Token{ .type = t.TokenType.semicolon, .literal = ";" },

        // function decliration
        t.Token{ .type = t.TokenType.let, .literal = "let" },
        t.Token{ .type = t.TokenType.identifier, .literal = "add" },
        t.Token{ .type = t.TokenType.assign, .literal = "=" },
        t.Token{ .type = t.TokenType.function, .literal = "fn" },
        t.Token{ .type = t.TokenType.l_paren, .literal = "(" },
        t.Token{ .type = t.TokenType.identifier, .literal = "x" },
        t.Token{ .type = t.TokenType.comma, .literal = "," },
        t.Token{ .type = t.TokenType.identifier, .literal = "y" },
        t.Token{ .type = t.TokenType.r_paren, .literal = ")" },
        t.Token{ .type = t.TokenType.l_brace, .literal = "{" },
        // function body
        t.Token{ .type = t.TokenType.identifier, .literal = "x" },
        t.Token{ .type = t.TokenType.plus, .literal = "+" },
        t.Token{ .type = t.TokenType.identifier, .literal = "y" },
        t.Token{ .type = t.TokenType.semicolon, .literal = ";" },
        // end of function
        t.Token{ .type = t.TokenType.r_brace, .literal = "}" },
        t.Token{ .type = t.TokenType.semicolon, .literal = ";" },

        // variable decliration and calling function
        t.Token{ .type = t.TokenType.let, .literal = "let" },
        t.Token{ .type = t.TokenType.identifier, .literal = "result" },
        t.Token{ .type = t.TokenType.assign, .literal = "=" },
        t.Token{ .type = t.TokenType.identifier, .literal = "add" },
        t.Token{ .type = t.TokenType.l_paren, .literal = "(" },
        t.Token{ .type = t.TokenType.identifier, .literal = "five" },
        t.Token{ .type = t.TokenType.comma, .literal = "," },
        t.Token{ .type = t.TokenType.identifier, .literal = "ten" },
        t.Token{ .type = t.TokenType.r_paren, .literal = ")" },
        t.Token{ .type = t.TokenType.semicolon, .literal = ";" },

        //extra ops
        t.Token{ .type = t.TokenType.bang, .literal = "!" },
        t.Token{ .type = t.TokenType.minus, .literal = "-" },
        t.Token{ .type = t.TokenType.divide, .literal = "/" },
        t.Token{ .type = t.TokenType.multiply, .literal = "*" },
        t.Token{ .type = t.TokenType.int, .literal = "5" },
        t.Token{ .type = t.TokenType.semicolon, .literal = ";" },
        t.Token{ .type = t.TokenType.int, .literal = "5" },
        t.Token{ .type = t.TokenType.less_than, .literal = "<" },
        t.Token{ .type = t.TokenType.int, .literal = "10" },
        t.Token{ .type = t.TokenType.greater_than, .literal = ">" },
        t.Token{ .type = t.TokenType.int, .literal = "5" },
        t.Token{ .type = t.TokenType.semicolon, .literal = ";" },

        //if/else
        t.Token{ .type = t.TokenType._if, .literal = "if" },
        t.Token{ .type = t.TokenType.l_paren, .literal = "(" },
        t.Token{ .type = t.TokenType.int, .literal = "5" },
        t.Token{ .type = t.TokenType.less_than, .literal = "<" },
        t.Token{ .type = t.TokenType.int, .literal = "10" },
        t.Token{ .type = t.TokenType.r_paren, .literal = ")" },
        t.Token{ .type = t.TokenType.l_brace, .literal = "{" },
        t.Token{ .type = t.TokenType._return, .literal = "return" },
        t.Token{ .type = t.TokenType.bool, .literal = "true" },
        t.Token{ .type = t.TokenType.semicolon, .literal = ";" },
        t.Token{ .type = t.TokenType.r_brace, .literal = "}" },
        t.Token{ .type = t.TokenType._else, .literal = "else" },
        t.Token{ .type = t.TokenType.l_brace, .literal = "{" },
        t.Token{ .type = t.TokenType._return, .literal = "return" },
        t.Token{ .type = t.TokenType.bool, .literal = "false" },
        t.Token{ .type = t.TokenType.semicolon, .literal = ";" },
        t.Token{ .type = t.TokenType.r_brace, .literal = "}" },

        //equal/not equal
        t.Token{ .type = t.TokenType.int, .literal = "10" },
        t.Token{ .type = t.TokenType.equal, .literal = "==" },
        t.Token{ .type = t.TokenType.int, .literal = "10" },
        t.Token{ .type = t.TokenType.semicolon, .literal = ";" },
        t.Token{ .type = t.TokenType.int, .literal = "10" },
        t.Token{ .type = t.TokenType.not_equal, .literal = "!=" },
        t.Token{ .type = t.TokenType.int, .literal = "9" },
        t.Token{ .type = t.TokenType.semicolon, .literal = ";" },

        // eof
        t.Token{ .type = t.TokenType.eof, .literal = "" },
    };

    std.debug.print("\n", .{});
    for (tests) |tes| {
        const tok = lex.nextToken();
        expect(std.mem.eql(u8, tes.literal, tok.literal)) catch |err| {
            std.debug.print("Expected literal: {s}   Got: {s}\n", .{ tes.literal, tok.literal });
            return err;
        };
        expect(std.mem.eql(u8, @tagName(tes.type), @tagName(tok.type))) catch |err| {
            std.debug.print("test.type: {s}. token.type: {s}\n", .{ @tagName(tes.type), @tagName(tok.type) });
            return err;
        };
    }
}
