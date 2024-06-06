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

pub const Parser = struct {
    lexer: *l.Lexer,
    cur_token: t.Token,
    next_token: t.Token,
    ast: std.ArrayList(a.Node),
    parsed_tokens_arena: std.heap.ArenaAllocator,
    parsed_tokens_alloc: std.mem.Allocator,
    errors: std.ArrayList([]const u8),
    precidenceMap: std.AutoHashMap(t.TokenType, OperatorPrecidence),

    pub fn init(alloc: std.mem.Allocator, lex: *l.Lexer) Parser {
        var p = Parser{
            .lexer = lex,
            .cur_token = undefined,
            .next_token = undefined,
            .ast = std.ArrayList(a.Node).init(alloc),
            .parsed_tokens_arena = std.heap.ArenaAllocator.init(alloc),
            .parsed_tokens_alloc = undefined,
            .errors = std.ArrayList([]const u8).init(alloc),
            .precidenceMap = std.AutoHashMap(t.TokenType, OperatorPrecidence).init(alloc),
        };

        p.parsed_tokens_alloc = p.parsed_tokens_arena.allocator();

        p.precidenceMap.put(t.TokenType.equal, OperatorPrecidence.equals) catch unreachable;
        p.precidenceMap.put(t.TokenType.not_equal, OperatorPrecidence.equals) catch unreachable;
        p.precidenceMap.put(t.TokenType.less_than, OperatorPrecidence.less_than) catch unreachable;
        p.precidenceMap.put(t.TokenType.greater_than, OperatorPrecidence.less_than) catch unreachable;
        p.precidenceMap.put(t.TokenType.plus, OperatorPrecidence.sum) catch unreachable;
        p.precidenceMap.put(t.TokenType.minus, OperatorPrecidence.sum) catch unreachable;
        p.precidenceMap.put(t.TokenType.divide, OperatorPrecidence.product) catch unreachable;
        p.precidenceMap.put(t.TokenType.multiply, OperatorPrecidence.product) catch unreachable;

        p.increment();
        p.increment();
        return p;
    }
    pub fn deinit(self: *Parser) void {
        self.ast.deinit();
        self.errors.deinit();
        self.parsed_tokens_arena.deinit();
        self.precidenceMap.deinit();
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

    fn peekPrecidence(self: *Parser) OperatorPrecidence {
        if (self.precidenceMap.get(self.next_token.type)) |p| {
            return p;
        }
        return OperatorPrecidence.lowest;
    }

    fn curPrecidence(self: *Parser) OperatorPrecidence {
        if (self.precidenceMap.get(self.cur_token.type)) |p| {
            return p;
        }
        return OperatorPrecidence.lowest;
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

    fn parseExpression(self: *Parser, precidence: OperatorPrecidence) ?a.Expression {
        var left_expr = switch (self.cur_token.type) {
            t.TokenType.identifier => self.parseIdentifier(),
            t.TokenType.int => self.parseIntLiteral(),
            t.TokenType.minus => self.parsePrefixExpression(),
            t.TokenType.bang => self.parsePrefixExpression(),

            else => null,
        };
        if (left_expr == null) return null;

        while (self.next_token.type != t.TokenType.semicolon and
            @intFromEnum(precidence) < @intFromEnum(self.peekPrecidence()))
        {
            self.increment();
            left_expr = switch (self.cur_token.type) {
                t.TokenType.plus => self.parseInfixExpression(left_expr),
                t.TokenType.minus => self.parseInfixExpression(left_expr),
                t.TokenType.multiply => self.parseInfixExpression(left_expr),
                t.TokenType.divide => self.parseInfixExpression(left_expr),
                t.TokenType.less_than => self.parseInfixExpression(left_expr),
                t.TokenType.greater_than => self.parseInfixExpression(left_expr),
                t.TokenType.equal => self.parseInfixExpression(left_expr),
                t.TokenType.not_equal => self.parseInfixExpression(left_expr),
                else => null,
            };
            if (left_expr == null) {
                return null;
            }
        }
        return left_expr;
    }

    fn parseInfixExpression(self: *Parser, left: ?a.Expression) ?a.Expression {
        if (left == null) {
            return null;
        }

        var expr = a.InfixExpression{
            .tokenLiteral = self.cur_token,
            .opperator = self.cur_token.literal,
            .left = left.?,
            .right = undefined,
        };

        const precidence = self.curPrecidence();
        self.increment();
        if (self.parseExpression(precidence)) |e| {
            expr.right = e;
            return expr.expression();
        } else {
            self.errors.append("unable to parse right side to infix") catch unreachable;
            return null;
        }
    }

    fn parsePrefixExpression(self: *Parser) ?a.Expression {
        var exp = self.parsed_tokens_alloc.create(a.PrefixExpression) catch unreachable;
        exp.* = a.PrefixExpression{
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

        return exp.expression();
    }

    fn parseIntLiteral(self: *Parser) a.Expression {
        var expr = self.parsed_tokens_alloc.create(a.IntLiteral) catch unreachable;
        expr.* = a.IntLiteral{
            .tokenLiteral = self.cur_token,
            .value = std.fmt.parseInt(i64, self.cur_token.literal, '0') catch unreachable,
        };
        return expr.expression();
    }

    fn parseIdentifier(self: *Parser) a.Expression {
        var expr = self.parsed_tokens_alloc.create(a.Identifier) catch unreachable;
        expr.* = a.Identifier{
            .tokenLiteral = self.cur_token,
            .value = self.cur_token.literal,
        };
        return expr.expression();
    }
    // }}}

    // Parsing Statements {{{
    fn parseReturnToken(self: *Parser) ?a.Node {
        var stmt = self.parsed_tokens_alloc.create(a.ReturnStatement) catch unreachable;
        stmt.* = a.ReturnStatement{
            .tokenLiteral = self.cur_token,
            .value = undefined,
        };
        stmt.value = a.Expression{
            .ptr = undefined,
            .toStringFn = undefined,
        };

        while (self.cur_token.type != t.TokenType.semicolon) {
            self.increment();
        }

        return stmt.node();
    }

    fn parseLetToken(self: *Parser) ?a.Node {
        var stmt = self.parsed_tokens_alloc.create(a.LetStatement) catch unreachable;
        stmt.* = a.LetStatement{
            .tokenLiteral = self.cur_token,
            .ident = undefined,
            .value = undefined,
        };

        // parse identifier
        if (!self.assertPeek(t.TokenType.identifier, "Expected Identifier")) {
            return null;
        }
        stmt.ident = self.cur_token.literal;

        // check assign
        if (!self.assertPeek(t.TokenType.assign, "Expected '='")) {
            return null;
        } else {
            self.increment();
        }

        // parse expression
        stmt.value = a.Expression{
            .ptr = undefined,
            .toStringFn = undefined,
        };

        while (self.cur_token.type != t.TokenType.semicolon) {
            self.increment();
        }

        // check semicolon
        if (!self.assert(t.TokenType.semicolon, "Expected ';'")) {
            return null;
        }

        return stmt.node();
    }

    fn parseExpressionStatement(self: *Parser) ?a.Node {
        var stmt = self.parsed_tokens_alloc.create(a.ExpressionStatement) catch unreachable;
        stmt.* = a.ExpressionStatement{
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

        // return interface
        return stmt.node();
    }
    // }}}
};
