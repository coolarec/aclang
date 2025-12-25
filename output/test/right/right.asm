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
    push 3
    pop rax
    mov [rbp - 8], rax
    push 998244353
    pop rdx
    lea rcx, [fmt_out]
    sub rsp, 32
    xor al, al
    call printf
    add rsp, 32
    push qword [rbp - 8]
    push 3
    pop rcx
    pop rsi
    mov rax, 1
.L0:
    test rcx, rcx
    jz .L2
    test rcx, 1
    jz .L1
    imul rax, rsi
.L1:
    imul rsi, rsi
    shr rcx, 1
    jmp .L0
.L2:
    push rax
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

