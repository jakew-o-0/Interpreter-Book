const Lexer = @import("lexer.zig").Lexer;
const Token = @import("tokens.zig").Token;
const TokenType = @import("tokens.zig").TokenType;

const test_alloc = @import("std").testing.allocator;
const print = @import("std").debug.print;
const eql = @import("std").mem.eql;
const expect = @import("std").testing.expect;

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

    const tests = [_]Token{
        // variable decliration
        Token{ .type = TokenType.keyw_let, .literal = "let" },
        Token{ .type = TokenType.type_identifier, .literal = "five" },
        Token{ .type = TokenType.op_assign, .literal = "=" },
        Token{ .type = TokenType.type_int, .literal = "5" },
        Token{ .type = TokenType.syn_semicolon, .literal = ";" },

        // variable decliration
        Token{ .type = TokenType.keyw_let, .literal = "let" },
        Token{ .type = TokenType.type_identifier, .literal = "ten" },
        Token{ .type = TokenType.op_assign, .literal = "=" },
        Token{ .type = TokenType.type_int, .literal = "10" },
        Token{ .type = TokenType.syn_semicolon, .literal = ";" },

        // function decliration
        Token{ .type = TokenType.keyw_let, .literal = "let" },
        Token{ .type = TokenType.type_identifier, .literal = "add" },
        Token{ .type = TokenType.op_assign, .literal = "=" },
        Token{ .type = TokenType.keyw_function, .literal = "fn" },
        Token{ .type = TokenType.syn_l_paren, .literal = "(" },
        Token{ .type = TokenType.type_identifier, .literal = "x" },
        Token{ .type = TokenType.syn_comma, .literal = "," },
        Token{ .type = TokenType.type_identifier, .literal = "y" },
        Token{ .type = TokenType.syn_r_paren, .literal = ")" },
        Token{ .type = TokenType.syn_l_brace, .literal = "{" },
        // function body
        Token{ .type = TokenType.type_identifier, .literal = "x" },
        Token{ .type = TokenType.op_plus, .literal = "+" },
        Token{ .type = TokenType.type_identifier, .literal = "y" },
        Token{ .type = TokenType.syn_semicolon, .literal = ";" },
        // end of function
        Token{ .type = TokenType.syn_r_brace, .literal = "}" },
        Token{ .type = TokenType.syn_semicolon, .literal = ";" },

        // variable decliration and calling function
        Token{ .type = TokenType.keyw_let, .literal = "let" },
        Token{ .type = TokenType.type_identifier, .literal = "result" },
        Token{ .type = TokenType.op_assign, .literal = "=" },
        Token{ .type = TokenType.type_identifier, .literal = "add" },
        Token{ .type = TokenType.syn_l_paren, .literal = "(" },
        Token{ .type = TokenType.type_identifier, .literal = "five" },
        Token{ .type = TokenType.syn_comma, .literal = "," },
        Token{ .type = TokenType.type_identifier, .literal = "ten" },
        Token{ .type = TokenType.syn_r_paren, .literal = ")" },
        Token{ .type = TokenType.syn_semicolon, .literal = ";" },

        //extra ops
        Token{ .type = TokenType.op_bang, .literal = "!" },
        Token{ .type = TokenType.op_minus, .literal = "-" },
        Token{ .type = TokenType.op_divide, .literal = "/" },
        Token{ .type = TokenType.op_multiply, .literal = "*" },
        Token{ .type = TokenType.type_int, .literal = "5" },
        Token{ .type = TokenType.syn_semicolon, .literal = ";" },
        Token{ .type = TokenType.type_int, .literal = "5" },
        Token{ .type = TokenType.op_less_than, .literal = "<" },
        Token{ .type = TokenType.type_int, .literal = "10" },
        Token{ .type = TokenType.op_greater_than, .literal = ">" },
        Token{ .type = TokenType.type_int, .literal = "5" },
        Token{ .type = TokenType.syn_semicolon, .literal = ";" },

        //if/else
        Token{ .type = TokenType.keyw_if, .literal = "if" },
        Token{ .type = TokenType.syn_l_paren, .literal = "(" },
        Token{ .type = TokenType.type_int, .literal = "5" },
        Token{ .type = TokenType.op_less_than, .literal = "<" },
        Token{ .type = TokenType.type_int, .literal = "10" },
        Token{ .type = TokenType.syn_r_paren, .literal = ")" },
        Token{ .type = TokenType.syn_l_brace, .literal = "{" },
        Token{ .type = TokenType.keyw_return, .literal = "return" },
        Token{ .type = TokenType.type_bool, .literal = "true" },
        Token{ .type = TokenType.syn_semicolon, .literal = ";" },
        Token{ .type = TokenType.syn_r_brace, .literal = "}" },
        Token{ .type = TokenType.keyw_else, .literal = "else" },
        Token{ .type = TokenType.syn_l_brace, .literal = "{" },
        Token{ .type = TokenType.keyw_return, .literal = "return" },
        Token{ .type = TokenType.type_bool, .literal = "false" },
        Token{ .type = TokenType.syn_semicolon, .literal = ";" },
        Token{ .type = TokenType.syn_r_brace, .literal = "}" },

        //equal/not equal
        Token{ .type = TokenType.type_int, .literal = "10" },
        Token{ .type = TokenType.op_equal, .literal = "==" },
        Token{ .type = TokenType.type_int, .literal = "10" },
        Token{ .type = TokenType.syn_semicolon, .literal = ";" },
        Token{ .type = TokenType.type_int, .literal = "10" },
        Token{ .type = TokenType.op_not_equal, .literal = "!=" },
        Token{ .type = TokenType.type_int, .literal = "9" },
        Token{ .type = TokenType.syn_semicolon, .literal = ";" },

        // eof
        Token{ .type = TokenType.eof, .literal = "" },
    };
    var lexer = Lexer.init(test_alloc, input);
    defer lexer.deinit();
    const tokens = lexer.lexSrc();

    for (tokens, tests) |token, test_cond| {
        expect(eql(u8, test_cond.literal, token.literal)) catch |err| {
            print("\n\nExpected literal: {s}   Got: {s}\n\n", .{
                test_cond.literal,
                token.literal,
            });
            return err;
        };
        expect(test_cond.type == token.type) catch |err| {
            print("\n\ntestype: {s}. token.type: {s}\n\n", .{
                @tagName(test_cond.type),
                @tagName(token.type),
            });
            return err;
        };
    }
}
