const Token = @import("tokens.zig").Token;
const TokenType = @import("tokens.zig").TokenType;

const Node = @import("ast.zig").Node;
const Expression = @import("ast.zig").Expression;
const InfixExpression = @import("ast.zig").InfixExpression;
const Identifier = @import("ast.zig").Identifier;
const IntLiteral = @import("ast.zig").IntLiteral;
const LetStatement = @import("ast.zig").LetStatement;
const ReturnStatement = @import("ast.zig").ReturnStatement;
const PrefixExpression = @import("ast.zig").PrefixExpression;
const ExpressionStatement = @import("ast.zig").ExpressionStatement;

const ArrayList = @import("std").ArrayList;
const ArenaAllocator = @import("std").heap.ArenaAllocator;
const Allocator = @import("std").mem.Allocator;
const AutoHashMap = @import("std").AutoHashMap;
const parseInt = @import("std").fmt.parseInt;

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
    tokens: []Token,
    cur_token: Token,
    next_token: Token,
    pos: usize,
    ast: ArrayList(Node),
    parsed_tokens_arena: ArenaAllocator,
    parsed_tokens_alloc: Allocator,
    errors: ArrayList([]const u8),
    precidenceMap: AutoHashMap(TokenType, OperatorPrecidence),

    pub fn init(alloc: Allocator, tokens: []Token) Parser {
        var p = Parser{
            .tokens = tokens,
            .cur_token = undefined,
            .next_token = undefined,
            .pos = 0,
            .ast = ArrayList(Node).init(alloc),
            .parsed_tokens_arena = ArenaAllocator.init(alloc),
            .parsed_tokens_alloc = undefined,
            .errors = ArrayList([]const u8).init(alloc),
            .precidenceMap = AutoHashMap(TokenType, OperatorPrecidence).init(alloc),
        };

        p.parsed_tokens_alloc = p.parsed_tokens_arena.allocator();

        p.precidenceMap.put(TokenType.equal, OperatorPrecidence.equals) catch unreachable;
        p.precidenceMap.put(TokenType.not_equal, OperatorPrecidence.equals) catch unreachable;
        p.precidenceMap.put(TokenType.less_than, OperatorPrecidence.less_than) catch unreachable;
        p.precidenceMap.put(TokenType.greater_than, OperatorPrecidence.less_than) catch unreachable;
        p.precidenceMap.put(TokenType.plus, OperatorPrecidence.sum) catch unreachable;
        p.precidenceMap.put(TokenType.minus, OperatorPrecidence.sum) catch unreachable;
        p.precidenceMap.put(TokenType.divide, OperatorPrecidence.product) catch unreachable;
        p.precidenceMap.put(TokenType.multiply, OperatorPrecidence.product) catch unreachable;

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
        self.pos += 1;
        if (self.pos > self.tokens.len) {
            return;
        } else {
            self.next_token = self.tokens[self.pos];
        }
    }

    fn assert(self: *Parser, expected: TokenType, err: []const u8) bool {
        if (self.cur_token.type == expected) {
            return true;
        }
        self.errors.append(err) catch unreachable;
        return false;
    }

    fn assertPeek(self: *Parser, expected: TokenType, err: []const u8) bool {
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
        while (self.cur_token.type != TokenType.eof) {
            const node = switch (self.cur_token.type) {
                TokenType.let => self.parseLetToken(),
                TokenType._return => self.parseReturnToken(),
                else => self.parseExpressionStatement(),
            };

            if (node) |n| {
                self.ast.append(n) catch unreachable;
            }
            self.increment();
        }
    }

    // Parsing Expressions {{{

    fn parseExpression(self: *Parser, precidence: OperatorPrecidence) ?Expression {
        var left_expr = switch (self.cur_token.type) {
            TokenType.identifier => self.parseIdentifier(),
            TokenType.int => self.parseIntLiteral(),
            TokenType.minus => self.parsePrefixExpression(),
            TokenType.bang => self.parsePrefixExpression(),

            else => null,
        };
        if (left_expr == null) return null;

        while (self.next_token.type != TokenType.semicolon and
            @intFromEnum(precidence) < @intFromEnum(self.peekPrecidence()))
        {
            self.increment();
            left_expr = switch (self.cur_token.type) {
                TokenType.plus => self.parseInfixExpression(left_expr),
                TokenType.minus => self.parseInfixExpression(left_expr),
                TokenType.multiply => self.parseInfixExpression(left_expr),
                TokenType.divide => self.parseInfixExpression(left_expr),
                TokenType.less_than => self.parseInfixExpression(left_expr),
                TokenType.greater_than => self.parseInfixExpression(left_expr),
                TokenType.equal => self.parseInfixExpression(left_expr),
                TokenType.not_equal => self.parseInfixExpression(left_expr),
                else => null,
            };
            if (left_expr == null) {
                return null;
            }
        }
        return left_expr;
    }

    fn parseInfixExpression(self: *Parser, left: ?Expression) ?Expression {
        if (left == null) {
            return null;
        }

        var expr = InfixExpression{
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

    fn parsePrefixExpression(self: *Parser) ?Expression {
        var exp = self.parsed_tokens_alloc.create(PrefixExpression) catch unreachable;
        exp.* = PrefixExpression{
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

    fn parseIntLiteral(self: *Parser) Expression {
        var expr = self.parsed_tokens_alloc.create(IntLiteral) catch unreachable;
        expr.* = IntLiteral{
            .tokenLiteral = self.cur_token,
            .value = parseInt(i64, self.cur_token.literal, '0') catch unreachable,
        };
        return expr.expression();
    }

    fn parseIdentifier(self: *Parser) Expression {
        var expr = self.parsed_tokens_alloc.create(Identifier) catch unreachable;
        expr.* = Identifier{
            .tokenLiteral = self.cur_token,
            .value = self.cur_token.literal,
        };
        return expr.expression();
    }
    // }}}

    // Parsing Statements {{{
    fn parseReturnToken(self: *Parser) ?Node {
        var stmt = self.parsed_tokens_alloc.create(ReturnStatement) catch unreachable;
        stmt.* = ReturnStatement{
            .tokenLiteral = self.cur_token,
            .value = undefined,
        };
        stmt.value = Expression{
            .ptr = undefined,
            .toStringFn = undefined,
        };

        while (self.cur_token.type != TokenType.semicolon) {
            self.increment();
        }

        return stmt.node();
    }

    fn parseLetToken(self: *Parser) ?Node {
        var stmt = self.parsed_tokens_alloc.create(LetStatement) catch unreachable;
        stmt.* = LetStatement{
            .tokenLiteral = self.cur_token,
            .ident = undefined,
            .value = undefined,
        };

        // parse identifier
        if (!self.assertPeek(TokenType.identifier, "Expected Identifier")) {
            return null;
        }
        stmt.ident = self.cur_token.literal;

        // check assign
        if (!self.assertPeek(TokenType.assign, "Expected '='")) {
            return null;
        } else {
            self.increment();
        }

        // parse expression
        stmt.value = Expression{
            .ptr = undefined,
            .toStringFn = undefined,
        };

        while (self.cur_token.type != TokenType.semicolon) {
            self.increment();
        }

        // check semicolon
        if (!self.assert(TokenType.semicolon, "Expected ';'")) {
            return null;
        }

        return stmt.node();
    }

    fn parseExpressionStatement(self: *Parser) ?Node {
        var stmt = self.parsed_tokens_alloc.create(ExpressionStatement) catch unreachable;
        stmt.* = ExpressionStatement{
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

        if (self.next_token.type == TokenType.semicolon) {
            self.increment();
        }

        // return interface
        return stmt.node();
    }
    // }}}
};
