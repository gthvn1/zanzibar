const std = @import("std");
const lexer = @import("lexer.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var l = try lexer.Lexer.new(gpa.allocator(), "let a = 10;");
    defer l.free();

    var t = l.nextToken();
    std.log.debug("{?}", .{t});
    t = l.nextToken();
    std.log.debug("{?}", .{t});
    t = l.nextToken();
    std.log.debug("{?}", .{t});
    t = l.nextToken();
    std.log.debug("{?}", .{t});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
