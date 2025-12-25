; Generated for Windows (x64 ABI)
default rel
section .data
    fmt_out db "%ld", 10, 0
    fmt_in  db "%ld", 0
section .text
    extern printf, scanf
    global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 512
    push 2134
    pop rdx
    lea rcx, [fmt_out]
    sub rsp, 32
    xor al, al
    call printf
    add rsp, 32
    push 0
    pop rax
    leave
    ret
    leave
    ret

