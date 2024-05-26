const std = @import("std");
const lexer = @import("lexer.zig");
const token = @import("token.zig");

pub fn start(alloc: std.mem.Allocator) !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Monkey REPL\n\n", .{});
    const prompt = ">> ";

    while (true) {
        try stdout.print("{s}", .{prompt});
        var buff = try stdin.readUntilDelimiterAlloc(alloc, '\n', 1024 * 1024);

        var lex = lexer.Lexer{
            .source_code = buff[0..],
            .cur_pos = 0,
            .next_pos = 0,
            .ch = undefined,
        };

        lexer: while (true) {
            const tok = lex.nextToken();
            try stdout.print("[type:{s}, literal:\"{s}\"],\n", .{ @tagName(tok.type), tok.literal });
            if (std.mem.eql(u8, tok.literal, "")) {
                break :lexer;
            }
        }
        try stdout.print("\n", .{});
    }
}
