const std = @import("std");
const repl = @import("repl.zig");
const l = @import("lexer.zig");
const a = @import("ast.zig");
const t = @import("token.zig");
const Parser = @import("parser.zig").Parser;

const errs = error{
    tokLit,
    tokIdent,
};
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    try repl.start(alloc);
}
