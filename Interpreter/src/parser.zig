const std = @import("std");
const t = @import("token.zig");
const l = @import("lexer.zig");
const a = @import("ast.zig");

const OperatorPrecidence = enum(u16) {
    lowest = 1,
    equals,
    less_than,
    greater_than,
    sum,
    product,
    prefix,
    infix,
};

pub fn NewParser(alloc: std.mem.Allocator, lex: *l.Lexer) Parser {
    var p = Parser{
        .lexer = lex,
        .cur_token = undefined,
        .next_token = undefined,
        .ast = std.ArrayList(a.Node).init(alloc),
        .errors = std.ArrayList([]const u8).init(alloc),
    };
    p.increment();
    p.increment();
    return p;
}

pub const Parser = struct {
    lexer: *l.Lexer,
    cur_token: t.Token,
    next_token: t.Token,
    ast: std.ArrayList(a.Node),
    errors: std.ArrayList([]const u8),

    pub fn deinit(self: *Parser) void {
        self.ast.deinit();
        self.errors.deinit();
    }

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

    pub fn parseTokens(self: *Parser) void {
        while (self.cur_token.type != t.TokenType.eof) {
            const node = switch (self.cur_token.type) {
                t.TokenType.let => self.parseLetToken(),
                t.TokenType._return => self.parseReturnToken(),
                else => self.parseExpressionStatement(),
            };

            if (node) |n| {
                self.ast.append(n) catch unreachable;
            }
            self.increment();
        }
    }

    // Parsing Expressions {{{
    fn parseExpressionStatement(self: *Parser) ?a.Node {
        var stmt = a.ExpressionStatement{
            .tokenLiteral = self.cur_token,
            .value = undefined,
        };

        // parse expression
        if (self.parseExpression(OperatorPrecidence.lowest)) |val| {
            stmt.value = val;
        } else {
            self.errors.append("invalid expression") catch unreachable;
            return null;
        }

        if (self.next_token.type == t.TokenType.semicolon) {
            self.increment();
        }
        return a.Node{ .expressionStatement = stmt };
    }

    fn parseExpression(self: *Parser, precidence: OperatorPrecidence) ?a.Expression {
        _ = precidence;
        return switch (self.cur_token.type) {
            t.TokenType.identifier => self.parseIdentifier(),
            t.TokenType.int => self.parseIntLiteral(),
            t.TokenType.minus => self.parsePrefixExpression(),
            t.TokenType.bang => self.parsePrefixExpression(),
            else => null,
        };
    }

    fn parsePrefixExpression(self: *Parser) ?a.Expression {
        var exp = a.PrefixExpression{
            .tokenLiteral = self.cur_token,
            .opperator = self.cur_token.literal,
            .right = undefined,
        };
        self.increment();

        // parse right side to expression
        if (self.parseExpression(OperatorPrecidence.prefix)) |e| {
            exp.right = e;
        } else {
            self.errors.append("no expression after prefix") catch unreachable;
            return null;
        }

        return a.Expression{ .prefixExpression = exp };
    }

    fn parseIntLiteral(self: *Parser) a.Expression {
        return a.Expression{ .intLiteral = .{
            .tokenLiteral = self.cur_token,
            .value = std.fmt.parseInt(i64, self.cur_token.literal, '0') catch unreachable,
        } };
    }

    fn parseIdentifier(self: *Parser) a.Expression {
        return a.Expression{ .identifier = .{
            .tokenLiteral = self.cur_token,
            .value = self.cur_token.literal,
        } };
    }
    // }}}

    // Parsing Statements {{{
    fn parseReturnToken(self: *Parser) ?a.Node {
        var return_statement = a.ReturnStatement{
            .tokenLiteral = self.cur_token,
            .value = undefined,
        };

        return_statement.value = a.Expression{ .identifier = a.Identifier{ .value = undefined, .tokenLiteral = undefined } };
        while (self.cur_token.type != t.TokenType.semicolon) {
            self.increment();
        }

        return a.Node{ .returnStatement = return_statement };
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
        let_statement.ident = self.cur_token.literal;

        // check assign
        if (!self.assertPeek(t.TokenType.assign, "Expected '='")) {
            return null;
        } else {
            self.increment();
        }

        // parse expression
        let_statement.value = a.Expression{ .identifier = a.Identifier{ .value = undefined, .tokenLiteral = undefined } }; // todo change
        while (self.cur_token.type != t.TokenType.semicolon) {
            self.increment();
        }

        // check semicolon
        if (!self.assert(t.TokenType.semicolon, "Expected ';'")) {
            return null;
        }

        return a.Node{ .letStatement = let_statement };
    }
    // }}}
};
