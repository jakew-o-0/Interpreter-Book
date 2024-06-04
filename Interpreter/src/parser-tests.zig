const std = @import("std");
const t = @import("token.zig");
const l = @import("lexer.zig");
const a = @import("ast.zig");
const p = @import("parser.zig");

test "parser: test let statements" {
    const input = "let a = 10; let b = 2; let c = 5;";

    var lexer = l.NewLexer(input);
    var parser = p.NewParser(std.testing.allocator, &lexer);
    defer parser.deinit();
    parser.parseTokens();

    const tests = [_][]const u8{
        "let a",
        "let b",
        "let c",
    };

    for (parser.ast.items, tests) |node, te| {
        var buff: [255]u8 = undefined;
        const n = node.toString(&buff);

        std.testing.expect(std.mem.eql(u8, n, te)) catch |err| {
            std.debug.print("\nExpected: {s} Got: {s}\n", .{ te, n });
            return err;
        };
    }

    std.testing.expect(parser.errors.items.len <= 0) catch |err| {
        for (parser.errors.items) |e| {
            std.debug.print("\nerror: {s}", .{e});
        }
        return err;
    };
}

test "parser: test return statements" {
    const return_input = "return 5; return 10; return 993322;";

    var lexer = l.NewLexer(return_input);
    var parser = p.NewParser(std.testing.allocator, &lexer);
    defer parser.deinit();
    parser.parseTokens();

    const tests = [_][]const u8{
        "_return",
        "_return",
        "_return",
    };

    for (parser.ast.items, tests) |node, te| {
        var buff: [255]u8 = undefined;
        const n = node.toString(&buff);

        std.testing.expect(std.mem.eql(u8, n, te)) catch |err| {
            std.debug.print("\nExpected: {s}. Got: {s}\n", .{ n, te });
            return err;
        };
    }

    std.testing.expect(parser.errors.items.len <= 0) catch |err| {
        for (parser.errors.items) |e| {
            std.debug.print("\nerror: {s}", .{e});
        }
        return err;
    };
}

test "parser: test errors" {
    const error_input = "let x 5; let = 10; let 838383;";

    var lexer = l.NewLexer(error_input);
    var parser = p.NewParser(std.testing.allocator, &lexer);
    defer parser.deinit();
    parser.parseTokens();

    std.testing.expect(parser.errors.items.len > 0) catch |err| {
        std.debug.print("\nExpected: 'more than one error'. Got: 'less than 1'", .{});
        return err;
    };
}

test "parser: test identifier expressions" {
    const input = "foobar;";
    const tests = "identifier foobar";

    var lexer = l.NewLexer(input);
    var parser = p.NewParser(std.testing.allocator, &lexer);
    defer parser.deinit();
    parser.parseTokens();

    var buff: [255]u8 = undefined;
    const s = parser.ast.items[0].toString(&buff);
    std.testing.expect(std.mem.eql(u8, s, tests)) catch |err| {
        std.debug.print("\nExpected: {s} Got: {s}  \n", .{ tests, s });
        return err;
    };
}

test "parser: test int literal expressions" {
    const input = "5;";
    const tests = "int 5";

    var lexer = l.NewLexer(input);
    var parser = p.NewParser(std.testing.allocator, &lexer);
    defer parser.deinit();
    parser.parseTokens();

    var buf: [255]u8 = undefined;
    const s = parser.ast.items[0].toString(&buf);
    std.testing.expect(std.mem.eql(u8, s, tests)) catch |err| {
        std.debug.print("\nExpected: {s} Got: {s}", .{ tests, s });
        return err;
    };
}

test "parser: test prefix expressions" {
    const input = "-5; !asdf";
    const tests = [_][]const u8{
        "- int 5",
        "! identifier asdf",
    };

    var lexer = l.NewLexer(input);
    var parser = p.NewParser(std.testing.allocator, &lexer);
    defer parser.deinit();
    parser.parseTokens();

    for (parser.ast.items, tests) |n, tes| {
        var buf: [255]u8 = undefined;
        const s = n.toString(&buf);
        std.testing.expect(std.mem.eql(u8, s, tes)) catch |err| {
            std.debug.print("\nExpected: {s} Got: {s}\n", .{ tes, s });
            return err;
        };
    }
}
