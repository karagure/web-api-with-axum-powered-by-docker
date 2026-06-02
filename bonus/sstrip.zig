// sstrip.zig — removes the (runtime-useless) ELF section-header table.
//
// Run as a build helper: `zig run sstrip.zig -- <elf-file>`. It zeroes the
// section-header fields in the ELF64 header and truncates the file right where
// the section-header table began, shaving off the last ~190 bytes.

const std = @import("std");

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    if (args.len < 2) {
        std.debug.print("usage: sstrip <elf-file>\n", .{});
        return error.MissingArg;
    }

    const file = try std.fs.cwd().openFile(args[1], .{ .mode = .read_write });
    defer file.close();

    const data = try file.readToEndAlloc(gpa, 1 << 20);
    defer gpa.free(data);

    // ELF64 header: e_shoff @0x28 (u64), e_shnum @0x3c (u16), e_shstrndx @0x3e.
    const e_shoff = std.mem.readInt(u64, data[0x28..][0..8], .little);
    std.mem.writeInt(u64, data[0x28..][0..8], 0, .little); // e_shoff
    std.mem.writeInt(u16, data[0x3c..][0..2], 0, .little); // e_shnum
    std.mem.writeInt(u16, data[0x3e..][0..2], 0, .little); // e_shstrndx

    try file.seekTo(0);
    try file.writeAll(data[0..@intCast(e_shoff)]);
    try file.setEndPos(@intCast(e_shoff));
}
