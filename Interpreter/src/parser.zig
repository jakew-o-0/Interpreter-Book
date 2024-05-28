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

    fn assert(self: *Parser, expected: t.TokenType, err: []const u8) bool {
        if (self.cur_token.type == expected) {
            return true;
        }
        self.errors.append(err) catch unreachable;
        return false;
    }

    fn assertPeek(self: *Parser, expected: t.TokenType, err: []const u8) bool {
        if (self.next_token.type == expected) {
            self.increment();
            return true;
        }
        self.errors.append(err) catch unreachable;
        return false;
    }

    pub fn parseTokens(self: *Parser) !void {
        self.increment();
        self.increment();

        while (self.cur_token.type != t.TokenType.eof) {
            if (self.parse()) |node| {
                self.ast.append(node) catch unreachable;
            }
            self.increment();
        }
    }

    fn parse(self: *Parser) ?a.Node {
        return switch (self.cur_token.type) {
            t.TokenType.let => self.parseLetToken(),
            else => undefined,
        };
    }

    fn parseLetToken(self: *Parser) ?a.Node {
        var let_statement = a.LetStatement{
            .tokenLiteral = self.cur_token,
            .ident = undefined,
            .value = undefined,
        };

        // parse identifier
        if (!self.assertPeek(t.TokenType.identifier, "Expected Identifier")) {
            return null;
        }
        let_statement.ident = self.cur_token.literal[0..];

        // check assign
        if (!self.assertPeek(t.TokenType.assign, "Expected '='")) {
            return null;
        } else {
            self.increment();
        }

        // parse expression
        let_statement.value = a.Expression{ .null = null };
        while (self.cur_token.type != t.TokenType.semicolon) {
            self.increment();
        }

        // check semicolon
        if (!self.assert(t.TokenType.semicolon, "Expected ';'")) {
            return null;
        }

        return a.Node{ .statement = .{ .letStatement = let_statement } };
    }
};

test "parser test" {
    const input = "let a = 10; let b = 2; let c = 5;";
    // const error_input = "let x 5; let = 10; let 838383;";
    var lexer = l.Lexer{
        .source_code = input,
        .cur_pos = 0,
        .next_pos = 0,
        .ch = undefined,
    };

    var ast_list = std.ArrayList(a.Node).init(std.testing.allocator);
    defer ast_list.deinit();
    var error_list = std.ArrayList([]const u8).init(std.testing.allocator);
    defer error_list.deinit();

    var parser = Parser{
        .lexer = &lexer,
        .ast = &ast_list,
        .errors = &error_list,
        .cur_token = undefined,
        .next_token = undefined,
    };
    try parser.parseTokens();

    const type_tests = [_]t.TokenType{ t.TokenType.let, t.TokenType.let, t.TokenType.let };
    const ident_tests = [_][]const u8{ "a", "b", "c" };

    for (ast_list.items, 0..) |node, i| {
        const n = switch (node) {
            .statement => |n1| switch (n1) {
                .letStatement => |n2| n2,
            },
            else => unreachable,
        };

        std.testing.expect(n.tokenLiteral.type == type_tests[i]) catch |err| {
            std.debug.print("\nnode.type: {s}, test: {s}\n", .{ @tagName(n.tokenLiteral.type), @tagName(type_tests[i]) });
            return err;
        };
        std.testing.expect(std.mem.eql(u8, n.ident, ident_tests[i])) catch |err| {
            std.debug.print("\nnode.ident: {s}, test: {s}\n", .{ n.ident, ident_tests[i] });
            return err;
        };
    }

    std.testing.expect(error_list.items.len <= 0) catch |err| {
        for (error_list.items) |e| {
            std.debug.print("\nerror: {s}", .{e});
        }
        return err;
    };
}
