; --- test.asm ---
default rel

section .data
    a dq 0
    b dq 0
    c dq 0
    d dq 5

section .text
    global main

main:
    ; 环境准备
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; --- 逻辑开始 ---
    ; LOD b, LOD c, ADD, STO a
    mov rax, [b]
    mov rbx, [c]
    add rax, rbx
    mov [a], rax

    ; LOD d, LOD c, ADD, STO b
    mov rax, [d]
    mov rbx, [c]
    add rax, rbx
    mov [b], rax

L0: ; LABEL L0
    mov rax, [b]
    cmp rax, 0
    jle L1              ; 如果 b <= 0，跳转到 L1 (对应 JZ L1)

    ; LOD a, LOD d, SUB, STO b
    mov rax, [a]
    mov rbx, [d]
    sub rax, rbx
    mov [b], rax

    jmp L0

L1: ; LABEL L1
    ; 将 a 的值存入 eax 作为程序退出码
    mov rax, [a]
    
    ; 环境清理
    add rsp, 32
    pop rbp
    ret