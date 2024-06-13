const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const TokenType = @import("tokens.zig").TokenType;

const expect = @import("std").testing.expect;
const test_alloc = @import("std").testing.allocator;
const eql = @import("std").mem.eql;
const print = @import("std").debug.print;

test "parser: test let statements" {
    const input = "let a = 10; let b = 2; let c = 5;";
    const ident_tests = [_][]const u8{ "a", "b", "c" };

    var lexer = Lexer.init(test_alloc, input);
    const tokens = lexer.lexSrc();
    defer test_alloc.free(tokens);

    var parser = Parser.init(test_alloc, tokens);
    defer parser.deinit();
    parser.parseTokens();

    for (parser.ast.items, ident_tests) |node, cond| {
        const tok: @TypeOf(node.ptr.*) = @ptrCast(@alignCast(node.ptr.*));

        try expect(eql(u8, tok.tokenLiteral.literal, "let"));
        try expect(eql(u8, tok.identifier, cond));
    }
}

test "parser: test return statements" {
    const input = "return 5; return 10; return 993322;";
    //const test_values = [_][]const u8 { "5", "10", "993322" };

    var lexer = Lexer.init(test_alloc, input);
    const tokens = lexer.lexSrc();
    defer test_alloc.free(tokens);

    var parser = Parser.init(test_alloc, tokens);
    defer parser.deinit();
    parser.parseTokens();

    for (parser.ast.items) |node| {
        const tok: @TypeOf(node.ptr) = @ptrCast(@alignCast(node.ptr));
        try expect(eql(TokenType, tok.tokenLiteral.type, TokenType.keyw_return));
    }
}

test "parser: test errors" {
    const input = "let x 5; let = 10; let 838383;";

    var lexer = Lexer.init(test_alloc, input);
    const tokens = lexer.lexSrc();
    defer test_alloc.free(tokens);

    var parser = Parser.init(test_alloc, tokens);
    defer parser.deinit();
    parser.parseTokens();

    expect(parser.errors.items.len > 0) catch |err| {
        print("\nExpected: 'more than one error'. Got: 'less than 1'", .{});
        return err;
    };
}

test "parser: test identifier expressions" {
    const input = "foobar;";

    var lexer = Lexer.init(test_alloc, input);
    const tokens = lexer.lexSrc();
    defer test_alloc.free(tokens);

    var parser = Parser.init(test_alloc, tokens);
    defer parser.deinit();
    parser.parseTokens();

    const node = parser.ast.items[0];
    const tok: @TypeOf(node.ptr) = @ptrCast(@alignCast(node.ptr));
    const tok_expression: @TypeOf(tok.value.ptr) = @ptrCast(@alignCast(tok.value.ptr));
    try expect(tok_expression.token_literal == TokenType.type_identifier);
    try expect(eql(u8, tok_expression.value, "foobar"));
}

test "parser: test int literal expressions" {
    const input = "5;";

    var lexer = Lexer.init(test_alloc, input);
    const tokens = lexer.lexSrc();
    defer test_alloc.free(tokens);

    var parser = Parser.init(test_alloc, tokens);
    defer parser.deinit();
    parser.parseTokens();

    const node = parser.ast.items[0];
    const t: @TypeOf(node.ptr) = @ptrCast(@alignCast(node.ptr));
    const tok: @TypeOf(t.value.ptr) = @ptrCast(@alignCast(t.value.ptr));
    try expect(tok.tokenLiteral.type == TokenType.type_int);
    try expect(tok.value == 5);
}

test "parser: test prefix expressions" {
    const input = "-5; !asdf";
    const opperator_tests = [_][]const u8{ "-", "!" };
    const left_type_tests = [_]TokenType{ TokenType.type_int, TokenType.type_identifier };
    const left_value_tests = .{ 5, "asdf" };

    var lexer = Lexer.init(test_alloc, input);
    const tokens = lexer.lexSrc();
    defer test_alloc.free(tokens);

    var parser = Parser.init(test_alloc, tokens);
    defer parser.deinit();
    parser.parseTokens();

    for (parser.ast.items, 0..) |node, idx| {
        const tok: @TypeOf(node.ptr) = @ptrCast(@alignCast(node.ptr));
        const tok_left: @TypeOf(tok.expression.ptr) = @ptrCast(@alignCast(tok.expression.ptr));

        try expect(eql(u8, tok.opperator, opperator_tests[idx]));
        try expect(tok_left.tokenLiteral.type == left_type_tests[idx]);
        try expect(eql(@TypeOf(left_value_tests[idx], tok_left.value, left_value_tests[idx])));
    }
}

test "parser: test infix expressions" {
    const input = "-5; !asdf";
    const opperator_tests = [_][]const u8{ "+", "-", "+", "/", ">", "<", "==", "!=" };

    var lexer = Lexer.init(test_alloc, input);
    const tokens = lexer.lexSrc();
    defer test_alloc.free(tokens);

    var parser = Parser.init(test_alloc, tokens);
    defer parser.deinit();
    parser.parseTokens();

    for (parser.ast.items, opperator_tests) |node, cond| {
        const tok: @TypeOf(node.ptr) = @ptrCast(@alignCast(node.ptr));
        const tok_left: @TypeOf(tok.left.ptr) = @ptrCast(@alignCast(tok.left.ptr));
        const tok_right: @TypeOf(tok.left.ptr) = @ptrCast(@alignCast(tok.right.ptr));

        try expect(eql(u8, tok.opperator, cond));
        try expect(tok_left.tokenLiteral.type == TokenType.type_int);
        try expect(tok_right.tokenLiteral.type == TokenType.type_int);
        try expect(tok_left.value == 5);
        try expect(tok_right.value == 5);
    }
}
