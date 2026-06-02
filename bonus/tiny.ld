/* Force a single R+X PT_LOAD and drop everything we don't need, so the Zig
   binary shrinks toward the hand-written ASM size. */
ENTRY(_start)
PHDRS { all PT_LOAD FLAGS(5); }
SECTIONS {
  . = 0x10000 + SIZEOF_HEADERS;
  .text : { *(.text*) *(.rodata*) *(.data*) } :all
  /DISCARD/ : {
    *(.eh_frame*)
    *(.eh_frame_hdr*)
    *(.comment)
    *(.note*)
    *(.got*)
  }
}
