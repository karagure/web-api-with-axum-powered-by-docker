; numbers.asm — prints the numbers 0..10000 (one per line) to stdout.
;
; Hand-crafted, statically self-contained x86-64 ELF executable. Assembled as a
; flat binary (`nasm -f bin`) so there is NO linker padding: the file is exactly
; the ELF header + one program header + the code, ~170 bytes. Dropped onto a
; `scratch` image this yields a Docker image well under 500 bytes.

BITS 64
        org     0x400000

; ---- ELF64 header (64 bytes) ----------------------------------------------
ehdr:
        db      0x7F, "ELF"     ; EI_MAG
        db      2               ; EI_CLASS   = ELFCLASS64
        db      1               ; EI_DATA    = little-endian
        db      1               ; EI_VERSION
        db      0               ; EI_OSABI   = System V
        dq      0               ; EI_ABIVERSION + 7 bytes padding
        dw      2               ; e_type     = ET_EXEC
        dw      0x3E            ; e_machine  = AMD x86-64
        dd      1               ; e_version
        dq      _start          ; e_entry
        dq      phdr - $$       ; e_phoff
        dq      0               ; e_shoff
        dd      0               ; e_flags
        dw      ehdrsz          ; e_ehsize
        dw      phdrsz          ; e_phentsize
        dw      1               ; e_phnum
        dw      0               ; e_shentsize
        dw      0               ; e_shnum
        dw      0               ; e_shstrndx
ehdrsz  equ     $ - ehdr

; ---- Program header (56 bytes): one R+X PT_LOAD covering the whole file ----
phdr:
        dd      1               ; p_type   = PT_LOAD
        dd      5               ; p_flags  = R + X
        dq      0               ; p_offset
        dq      $$              ; p_vaddr
        dq      $$              ; p_paddr
        dq      filesz          ; p_filesz
        dq      filesz          ; p_memsz
        dq      0x1000          ; p_align
phdrsz  equ     $ - phdr

; ---- Code -----------------------------------------------------------------
_start:
        xor     r12, r12        ; i = 0
.next:
        mov     rax, r12        ; rax = i
        mov     rbx, 10         ; divisor (preserved across syscalls)
        lea     rsi, [rsp-1]    ; scratch buffer in the red zone
        mov     byte [rsi], 10  ; trailing newline
.digit:
        xor     rdx, rdx
        div     rbx             ; rax = rax/10, rdx = rax%10
        add     dl, '0'
        dec     rsi
        mov     [rsi], dl       ; prepend ASCII digit
        test    rax, rax
        jnz     .digit
        mov     rdx, rsp
        sub     rdx, rsi        ; length = rsp - rsi
        mov     rax, 1          ; sys_write
        mov     rdi, 1          ; fd = stdout
        syscall                 ; write(1, rsi, rdx)
        inc     r12
        cmp     r12, 10001      ; loop through 10000 inclusive
        jne     .next
        mov     rax, 60         ; sys_exit
        xor     rdi, rdi        ; status 0
        syscall
filesz  equ     $ - $$
