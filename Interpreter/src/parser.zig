const std = @import("std");
const t = @import("token.zig");
const l = @import("lexer.zig");
const a = @import("ast.zig");

pub const Parser = struct {
    lexer: *l.Lexer,
    ast: *std.ArrayList(a.Node),
    errors: *std.ArrayList([]const u8),
    cur_token: t.Token,
    next_token: t.Token,

    fn increment(self: *Parser) void {
        self.cur_token = self.next_token;
        self.next_token = self.lexer.nextToken();
    }

    fn peakToken(self: Parser, expected: t.TokenType) bool {
        return self.next_token.type == expected;
    }

    fn evalToken(self: Parser, expected: t.TokenType) bool {
        return self.cur_token.type == expected;
    }

    pub fn parseTokens(self: *Parser) !void {
        self.increment();
        self.increment();

        while (self.cur_token.type != t.TokenType.eof) {
            if (self.parse()) |node| {
                try self.ast.append(node);
            }
            self.increment();
        }
    }

    fn parse(self: *Parser) ?a.Node {
        switch (self.cur_token.type) {
            t.TokenType.let => return self.parseLetToken(),
            else => unreachable,
        }
    }

    fn parseLetToken(self: *Parser) ?a.Node {
        var let_statement = a.LetStatement{
            .tokenLiteral = self.cur_token,
            .ident = undefined,
            .value = undefined,
        };

        self.increment();
        if (self.evalToken(t.TokenType.assign)) {
            return null;
        }

        self.increment();
        let_statement.ident = self.cur_token.literal[0..];
        let_statement.value = a.Expression{ .null = null };

        while (!self.evalToken(t.TokenType.semicolon)) {
            self.increment();
        }

        return a.Node{ .statement = .{ .letStatement = let_statement } };
    }
};

test "parser test" {
    const intput = "let a = 10; let b = 2; let c = 5;";
    var lexer = l.Lexer{
        .source_code = intput,
        .cur_pos = 0,
        .next_pos = 0,
        .ch = undefined,
    };

    var ast_list = std.ArrayList(a.Node).init(std.testing.allocator);
    defer ast_list.deinit();

    var parser = Parser{
        .lexer = &lexer,
        .ast = &ast_list,
        .cur_token = undefined,
        .next_token = undefined,
    };
    try parser.parseTokens();

    const tests = [_]t.TokenType{ t.TokenType.let, t.TokenType.let, t.TokenType.let };
    for (ast_list.items, 0..) |node, i| {
        const n = switch (node) {
            .statement => |n1| switch (n1) {
                .letStatement => |n2| n2,
            },
            else => unreachable,
        };

        std.testing.expect(std.mem.eql(
            u8,
            @tagName(n.tokenLiteral.type),
            @tagName(tests[i]),
        )) catch |err| {
            std.debug.print("\nnode.type: {s}, test: {s}", .{
                @tagName(n.tokenLiteral.type),
                @tagName(tests[i]),
            });
            return err;
        };
    }
}
