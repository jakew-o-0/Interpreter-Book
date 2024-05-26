const std = @import("std");
const repl = @import("repl.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    try repl.start(alloc);
}
