// numbers.zig — prints the numbers 0..10000 (one per line) to stdout.
//
// Freestanding: no libc, no Zig runtime. We provide our own `_start` and talk
// to the kernel through raw `syscall` instructions, so the binary stays tiny.
// Build (smallest): see build.sh / Dockerfile.zig.

// Minimal entry point: the kernel jumps here with no return address, so a naked
// stub just calls into real code (which never returns).
comptime {
    asm (
        \\.global _start
        \\_start:
        \\  xor %ebp, %ebp
        \\  call run
    );
}

fn syscall3(n: usize, a: usize, b: usize, c: usize) usize {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> usize),
        : [n] "{rax}" (n),
          [a] "{rdi}" (a),
          [b] "{rsi}" (b),
          [c] "{rdx}" (c),
        : .{ .rcx = true, .r11 = true, .memory = true });
}

export fn run() callconv(.c) noreturn {
    var buf: [8]u8 = undefined;
    var i: usize = 0;
    while (i <= 10000) : (i += 1) {
        var n = i;
        var pos: usize = buf.len - 1;
        buf[pos] = '\n'; // trailing newline
        while (true) {
            pos -= 1;
            buf[pos] = @intCast('0' + n % 10);
            n /= 10;
            if (n == 0) break;
        }
        _ = syscall3(1, 1, @intFromPtr(&buf[pos]), buf.len - pos); // write(1, ..)
    }
    _ = syscall3(60, 0, 0, 0); // exit(0)
    unreachable;
}
