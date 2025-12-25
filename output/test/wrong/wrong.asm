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
    push 10
    pop rax
    mov [rbp - 8], rax
    push 0
    pop rax
    mov [rbp - 16], rax
.L0:
    push qword [rbp - 8]
    push 0
    pop rbx
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    jz .L1
    push qword [rbp - 16]
    push qword [rbp - 8]
    push qword [rbp - 8]
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop rax
    mov [rbp - 16], rax
    push qword [rbp - 8]
    push 1
    pop rbx
    pop rax
    sub rax, rbx
    push rax
    pop rax
    mov [rbp - 8], rax
    jmp .L0
.L1:
    push qword [rbp - 16]
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

