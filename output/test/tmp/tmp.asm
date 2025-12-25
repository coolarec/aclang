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
    lea rdx, [rbp - 512]
    lea rcx, [fmt_in]
    sub rsp, 32
    xor al, al
    call scanf
    add rsp, 32
    push qword [rbp - 512]
    pop rax
    mov [rbp - 8], rax
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

