"""
Pcode到四元式转换器核心模块
"""

class Quadruple:
    """四元式类"""
    def __init__(self, op, arg1, arg2, result):
        self.op = op
        self.arg1 = arg1
        self.arg2 = arg2
        self.result = result
    
    def __str__(self):
        return f"({self.op}, {self.arg1}, {self.arg2}, {self.result})"
    
    def __repr__(self):
        return str(self)
    
    def to_tuple(self):
        return (self.op, self.arg1, self.arg2, self.result)

class PcodeToQuadsTranslator:
    """Pcode到四元式转换器"""
    
    def __init__(self, optimize=False):
        """
        初始化转换器
        
        Args:
            optimize: 是否进行优化
        """
        self.quads = []  # 主程序四元式列表
        self.func_quads = {}  # 函数四元式字典 {函数名: [四元式列表]}
        self.current_func = None  # 当前处理的函数名
        self.temp_counter = 0  # 临时变量计数器
        self.label_counter = 0  # 标签计数器
        self.symbol_table = {}  # 符号表
        self.arg_stack = []  # 参数栈
        self.optimize = optimize  # 优化标志
        
    def new_temp(self):
        """生成新的临时变量"""
        temp = f"t{self.temp_counter}"
        self.temp_counter += 1
        return temp
    
    def new_label(self):
        """生成新的标签"""
        label = f"L{self.label_counter}"
        self.label_counter += 1
        return label
    
    def add_quad(self, op, arg1, arg2, result):
        """
        添加一个四元式到当前作用域
        
        Args:
            op: 操作符
            arg1: 操作数1
            arg2: 操作数2
            result: 结果
        """
        quad = Quadruple(op, arg1, arg2, result)
        
        if self.current_func:
            # 添加到当前函数
            if self.current_func not in self.func_quads:
                self.func_quads[self.current_func] = []
            self.func_quads[self.current_func].append(quad)
        else:
            # 添加到主程序
            self.quads.append(quad)
        
        return quad

    def clear(self):
        """清除所有状态"""
        self.quads.clear()
        self.func_quads.clear()
        self.current_func = None
        self.temp_counter = 0
        self.label_counter = 0
        self.symbol_table.clear()
        self.arg_stack.clear()
    
    def translate(self, pcode_code):
        """
        翻译Pcode代码为四元式
        
        Args:
            pcode_code: Pcode代码字符串
            
        Returns:
            dict: 包含四元式的字典
        """
        self.clear()
        lines = pcode_code.strip().split('\n')
        
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            
            if not line or line.startswith('#'):
                # 空行或注释，跳过
                i += 1
                continue
            
            if line.startswith('FUNC'):
                # 处理函数定义
                func_name = line.split()[1].replace('@', '')
                self.current_func = func_name
                i += 1
                
                # 处理参数
                params = []
                while i < len(lines) and lines[i].strip().startswith('ARG'):
                    param = lines[i].strip().split()[1]
                    params.append(param)
                    i += 1
                
                # 处理函数体
                func_body = []
                while i < len(lines) and not lines[i].strip().startswith('END FUNC'):
                    func_body.append(lines[i].strip())
                    i += 1
                
                i += 1  # 跳过 END FUNC
                
                # 翻译函数体
                self._translate_func_body(func_name, params, func_body)
                self.current_func = None
                
            elif line.startswith('INT') or line.startswith('VAR'):
                # 处理变量声明
                parts = line.split()
                if len(parts) >= 2:
                    var_name = parts[1]
                    var_type = 'int' if line.startswith('INT') else 'var'
                    self.symbol_table[var_name] = var_type
                    self.add_quad('declare', var_type, '_', var_name)
                i += 1        
        return self.get_result()
    
    def _translate_func_body(self, func_name, params, body):
        """翻译函数体"""
        # 添加函数入口标签
        self.add_quad('func', '_', '_', func_name)
        
        # 处理参数
        for i, param in enumerate(params):
            self.add_quad('param', param, '_', f"arg{i}")
        
        # 翻译函数体指令
        for line in body:
            if line:
                self._translate_instruction(line)
    
    def _translate_instruction(self, instr):
        """翻译单条指令"""
        if not instr:
            return
        
        parts = instr.split()
        if not parts:
            return
        
        opcode = parts[0]
        
        if opcode == 'LIT':
            # 加载常数: LIT value
            if len(parts) >= 2:
                value = parts[1]
                temp = self.new_temp()
                self.add_quad(':=', value, '_', temp)
                self.arg_stack.append(temp)
        
        elif opcode == 'LOD':
            # 加载变量: LOD var_name
            if len(parts) >= 2:
                var_name = parts[1]
                temp = self.new_temp()
                self.add_quad(':=', var_name, '_', temp)
                self.arg_stack.append(temp)
        
        elif opcode == 'STO':
            # 存储到变量: STO var_name
            if len(parts) >= 2 and self.arg_stack:
                var_name = parts[1]
                value = self.arg_stack.pop()
                self.add_quad(':=', value, '_', var_name)
        
        elif opcode == 'ADD':
            # 加法: ADD
            if len(self.arg_stack) >= 2:
                right = self.arg_stack.pop()
                left = self.arg_stack.pop()
                temp = self.new_temp()
                self.add_quad('+', left, right, temp)
                self.arg_stack.append(temp)
        
        elif opcode == 'SUB':
            # 减法: SUB
            if len(self.arg_stack) >= 2:
                right = self.arg_stack.pop()
                left = self.arg_stack.pop()
                temp = self.new_temp()
                self.add_quad('-', left, right, temp)
                self.arg_stack.append(temp)
        
        elif opcode == 'MUL':
            # 乘法: MUL
            if len(self.arg_stack) >= 2:
                right = self.arg_stack.pop()
                left = self.arg_stack.pop()
                temp = self.new_temp()
                self.add_quad('*', left, right, temp)
                self.arg_stack.append(temp)
        
        elif opcode == 'DIV':
            # 除法: DIV
            if len(self.arg_stack) >= 2:
                right = self.arg_stack.pop()
                left = self.arg_stack.pop()
                temp = self.new_temp()
                self.add_quad('/', left, right, temp)
                self.arg_stack.append(temp)
        
        elif opcode == 'CALL':
            # 函数调用: CALL func_name
            if len(parts) >= 2:
                func_name = parts[1].replace('@', '')
                
                # 获取参数（从栈中弹出）
                args = []
                while self.arg_stack:
                    args.append(self.arg_stack.pop())
                
                # 注意：参数顺序需要反转，因为栈是后进先出
                args.reverse()
                
                # 生成参数传递四元式
                for arg in args:
                    self.add_quad('param', arg, '_', '_')
                
                # 生成调用四元式
                result_temp = self.new_temp()
                self.add_quad('call', func_name, '_', result_temp)
                self.arg_stack.append(result_temp)
        
        elif opcode == 'RET':
            # 返回语句: RET
            if self.arg_stack:
                ret_value = self.arg_stack.pop()
                self.add_quad('return', ret_value, '_', '_')
            else:
                self.add_quad('return', '_', '_', '_')
        
        elif opcode == 'STOP':
            # 程序结束: STOP
            self.add_quad('halt', '_', '_', '_')
        
        elif opcode == 'JMP':
            # 无条件跳转: JMP label
            if len(parts) >= 2:
                label = parts[1]
                self.add_quad('j', '_', '_', label)
        
        elif opcode == 'JZ':
            # 条件跳转（为零跳转）: JZ label
            if len(parts) >= 2 and self.arg_stack:
                label = parts[1]
                condition = self.arg_stack.pop()
                self.add_quad('jz', condition, '_', label)

        elif opcode == 'GT':
            # 条件跳转（大于跳转）: 
            if len(self.arg_stack) >= 2:
                right = self.arg_stack.pop()
                left = self.arg_stack.pop()
                temp = self.new_temp()
                self.add_quad('>', left, right, temp)
                self.arg_stack.append(temp)
        
        elif opcode == 'LT':
            # 条件跳转（小于跳转）: 
            if len(self.arg_stack) >= 2:
                right = self.arg_stack.pop()
                left = self.arg_stack.pop()
                temp = self.new_temp()
                self.add_quad('<', left, right, temp)
                self.arg_stack.append(temp)
        
        elif opcode == 'GE':
            # 条件跳转（大于等于跳转）: 
            if len(self.arg_stack) >= 2:
                right = self.arg_stack.pop()
                left = self.arg_stack.pop()
                temp = self.new_temp()
                self.add_quad('>=', left, right, temp)
                self.arg_stack.append(temp)
        
        elif opcode == 'LE':
            # 条件跳转（小于等于跳转）: 
            if len(self.arg_stack) >= 2:
                right = self.arg_stack.pop()
                left = self.arg_stack.pop()
                temp = self.new_temp()
                self.add_quad('<=', left, right, temp)
                self.arg_stack.append(temp)
        
        elif opcode == 'AND':
            # 条件跳转（小于等于跳转）: 
            if len(self.arg_stack) >= 2:
                right = self.arg_stack.pop()
                left = self.arg_stack.pop()
                temp = self.new_temp()
                self.add_quad('AND', left, right, temp)
                self.arg_stack.append(temp)

        elif opcode == 'OR':
            # 有一个为真: 
            if len(self.arg_stack) >= 2:
                right = self.arg_stack.pop()
                left = self.arg_stack.pop()
                temp = self.new_temp()
                self.add_quad('OR', left, right, temp)
                self.arg_stack.append(temp)

        elif opcode == 'EQ':
            # 条件跳转（等于跳转）: 
            if len(self.arg_stack) >= 2:
                right = self.arg_stack.pop()
                left = self.arg_stack.pop()
                temp = self.new_temp()
                self.add_quad('==', left, right, temp)
                self.arg_stack.append(temp)

        elif opcode == 'INT':
            # 定义变量: INT var_name
            if len(parts) >= 2:
                var_name = parts[1]
                var_type = 'int'
                self.symbol_table[var_name] = var_type
                self.add_quad('declare', var_type, '_', var_name)
        
        elif opcode == 'LABEL':
            # 条件跳转（为零跳转）: JZ label
            if len(parts) >= 2 and self.arg_stack:
                label = parts[1]
                condition = self.arg_stack.pop()
                self.add_quad('LABEL', condition, '_', label)
        
        else:
            # 未知指令，忽略或警告
            print(f"警告: 未知指令 '{instr}'")

    def get_result(self):
        """
        获取翻译结果
        
        Returns:
            dict: 包含所有四元式的字典
        """
        return {
            'functions': {
                func_name: [quad.to_tuple() for quad in quads]
                for func_name, quads in self.func_quads.items()
            }
        }   

    def print_result(self):
        """打印翻译结果"""
        print("=" * 60)
        print("PCODE 到 四元式 转换结果")
        print("=" * 60)
        
        print("\n主程序四元式:")
        print("-" * 50)

        if self.func_quads:
            print("\n函数四元式:")
            for func_name, quads in self.func_quads.items():
                print(f"\n函数 {func_name}:")
                print("-" * 40)
                for i, quad in enumerate(quads, 1):
                    print(f"{i:4d}: {quad}")
        
        for i, quad in enumerate(self.quads, 1):
            print(f"{i:4d}: {quad}")
        
        
        if self.symbol_table:
            print("\n符号表:")
            print("-" * 30)
            for name, type_info in self.symbol_table.items():
                print(f"{name}: {type_info}")
        
        print("\n" + "=" * 60)

pt=PcodeToQuadsTranslator()
pt.translate('''FUNC @foo
ARG a
ARG b
LIT 1
RET
END FUNC

FUNC @main
INT a
INT b
INT c
INT d
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
JMP L1
JMP L0
LABEL L1
LIT 0
STOP
END FUNC
''')
pt.print_result()