import re

class AsmOptimizer:
    def __init__(self, asm_code):
        # 预处理：按行分割，去除前后空格，保留非空行
        self.lines = [line.strip() for line in asm_code.split('\n') if line.strip()]
        self.original_count = len(self.lines)

    def optimize(self):
        """执行多轮优化，直到不再产生变化或达到上限"""
        passes = 0
        changed = True
        
        while changed and passes < 10:
            old_count = len(self.lines)
            self._apply_rules()
            changed = len(self.lines) < old_count
            passes += 1
        
        optimized_code = "\n    ".join(self.lines) # 格式化输出，带缩进
        return {
            "data": "    " + optimized_code,
            "stats": {
                "original": self.original_count,
                "optimized": len(self.lines),
                "reduction": self.original_count - len(self.lines),
                "passes": passes
            }
        }

    def _apply_rules(self):
        new_lines = []
        i = 0
        while i < len(self.lines):
            line1 = self.lines[i]
            line2 = self.lines[i+1] if i+1 < len(self.lines) else ""
            line3 = self.lines[i+2] if i+2 < len(self.lines) else ""

            # --- 模式 1: 消除冗余 push/pop ---
            # push rax / pop rax -> 直接删除
            match_push = re.match(r"push\s+(\w+)", line1)
            match_pop = re.match(r"pop\s+(\w+)", line2)
            if match_push and match_pop and match_push.group(1) == match_pop.group(1):
                i += 2
                continue

            # --- 模式 2: 消除冗余加载 (Store-Load Elimination) ---
            # mov [rbp-8], rax / mov rax, [rbp-8] -> 只保留存，删掉取
            m1 = re.match(r"mov\s+(\[.*\]),\s*(\w+)", line1)
            m2 = re.match(r"mov\s+(\w+),\s*(\[.*\])", line2)
            if m1 and m2 and m1.group(1) == m2.group(2) and m1.group(2) == m2.group(1):
                new_lines.append(line1)
                i += 2
                continue

            # --- 模式 3: 代数简化 (加减0, 乘除1) ---
            if re.search(r"(add|sub)\s+\w+,\s*0", line1) or re.search(r"imul\s+\w+,\s*1", line1):
                i += 1
                continue

            # --- 模式 4: 强度削弱 (乘 2, 4, 8 转换为移位) ---
            m_mul = re.match(r"imul\s+(\w+),\s*(2|4|8|16)", line1)
            if m_mul:
                reg = m_mul.group(1)
                val = int(m_mul.group(2))
                shift = {2:1, 4:2, 8:3, 16:4}[val]
                new_lines.append(f"shl {reg}, {shift}")
                i += 1
                continue

            # --- 模式 5: 消除连续跳转 ---
            # jmp .L1 / .L1: -> 删掉 jmp
            m_jmp = re.match(r"jmp\s+(\.\w+)", line1)
            if m_jmp and line2 == f"{m_jmp.group(1)}:":
                new_lines.append(line2)
                i += 2
                continue

            # 无匹配模式，保留原样
            new_lines.append(line1)
            i += 1
            
        self.lines = new_lines

# --- 使用示例 ---
# raw_asm = """
#     push rax
#     pop rax
#     mov [rbp-8], rax
#     mov rax, [rbp-8]
#     add rbx, 0
#     imul rcx, 8
#     jmp .L1
# .L1:
# """

# optimizer = AsmOptimizer(raw_asm)
# result = optimizer.optimize()
# print(result["data"])
# print(f"优化统计: {result['stats']}")