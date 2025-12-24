import sys

def compile_pcode(input_lines):
    asm = [
        "section .data",
        "  a dq 0", "  b dq 0", "  c dq 0", "  d dq 5", # 假设 d=5 方便测试循环
        "section .text",
        "  global _start",
        "_start:"
    ]
    
    for line in input_lines:
        parts = line.strip().split()
        if not parts: continue
        op = parts[0]
        
        if op == "LIT": asm.append(f"  push {parts[1]}")
        elif op == "LOD": asm.append(f"  push qword [{parts[1]}]")
        elif op == "STO": 
            asm.append(f"  pop rax")
            asm.append(f"  mov [{parts[1]}], rax")
        elif op == "ADD":
            asm.append("  pop rbx\n  pop rax\n  add rax, rbx\n  push rax")
        elif op == "SUB":
            asm.append("  pop rbx\n  pop rax\n  sub rax, rbx\n  push rax")
        elif op == "GT":
            asm.append("  pop rbx\n  pop rax\n  cmp rax, rbx\n  setg al\n  movzx rax, al\n  push rax")
        elif op == "JZ": asm.append(f"  pop rax\n  test rax, rax\n  jz {parts[1]}")
        elif op == "JMP": asm.append(f"  jmp {parts[1]}")
        elif op == "LABEL": asm.append(f"{parts[1]}:")
        elif op == "STOP": 
            asm.append("  mov rdi, [a]\n  mov eax, 60\n  syscall")
            
    return "\n".join(asm)

# 你的代码块
my_code = """
LOD b
LOD c
ADD
STO a
LOD c
LOD d
ADD
STO a
LOD d
LOD c
ADD
STO b
LABEL L0
LOD b
LIT 0
GT
JZ L1
LOD a
LOD b
ADD
STO a
LOD a
LOD d
SUB
STO b
JMP L0
LABEL L1
STOP
"""

print(compile_pcode(my_code.split('\n')))