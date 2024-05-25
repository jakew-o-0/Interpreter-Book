const expect = @import("std").testing.expect;
const std = @import("std");
const token = @import("token.zig").Token;
const token_type = @import("token.zig").TokenType;

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

    fn nextToken(self: *Lexer) token {
        var tok = token{ .literal = undefined, .type = undefined };
        self.increment();

        switch (self.ch) {
            '+' => tok.setToken(token_type.plus, "+"),
            '-' => tok.setToken(token_type.minus, "-"),
            '=' => tok.setToken(token_type.assign, "="),
            ',' => tok.setToken(token_type.comma, ","),
            ';' => tok.setToken(token_type.semicolon, ";"),
            '(' => tok.setToken(token_type.l_paren, "("),
            ')' => tok.setToken(token_type.r_paren, ")"),
            '{' => tok.setToken(token_type.l_brace, "{"),
            '}' => tok.setToken(token_type.r_brace, "}"),
            0 => tok.setToken(token_type.eof, ""),

            else => unreachable,
        }

        return tok;
    }
};

test "Lexer Test" {
    const input = "+-=,;(){}";
    var lex = Lexer{
        .source_code = input,
        .cur_pos = 0,
        .next_pos = 0,
        .ch = undefined,
    };

    const tests = [_]token{
        token{ .literal = "+", .type = token_type.plus },
        token{ .literal = "-", .type = token_type.minus },
        token{ .literal = "=", .type = token_type.assign },
        token{ .literal = ",", .type = token_type.comma },
        token{ .literal = ";", .type = token_type.semicolon },
        token{ .literal = "(", .type = token_type.l_paren },
        token{ .literal = ")", .type = token_type.r_paren },
        token{ .literal = "{", .type = token_type.l_brace },
        token{ .literal = "}", .type = token_type.r_brace },
        token{ .literal = "", .type = token_type.eof },
    };

    std.debug.print("\n", .{});
    for (tests) |t| {
        const tok = lex.nextToken();
        try expect(std.mem.eql(u8, t.literal, tok.literal));
        try expect(std.mem.eql(u8, @tagName(t.type), @tagName(tok.type)));
    }
}
