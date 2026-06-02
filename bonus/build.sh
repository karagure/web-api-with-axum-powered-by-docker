#!/usr/bin/env sh
# Build the smallest possible Zig binary that prints 0..10000, then strip the
# section-header table (sstrip) so only loadable content remains.
set -e
cd "$(dirname "$0")"

ZIG="${ZIG:-zig}"

# 1) Compile: freestanding (no libc/runtime), smallest codegen, single PT_LOAD
#    via the custom linker script, stripped of symbols and debug info.
"$ZIG" build-exe numbers.zig \
  -target x86_64-freestanding \
  -O ReleaseSmall -fstrip -fsingle-threaded \
  -T tiny.ld --name numbers-zig

# 2) sstrip the section-header table — done in Zig too (no python), so the
#    toolchain stays 100% Zig. Skip this step and you still get a 456-byte
#    binary (< 500), which is already enough for the bonus.
"$ZIG" run sstrip.zig -- numbers-zig

chmod +x numbers-zig
echo "numbers-zig: $(wc -c < numbers-zig) bytes"
