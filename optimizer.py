"""
四元式优化器模块
"""

class QuadOptimizer:
    """四元式优化器"""
    
    @staticmethod
    def constant_folding(quads):
        """
        常数折叠优化
        
        Args:
            quads: 四元式列表
            
        Returns:
            list: 优化后的四元式列表
        """
        optimized = []
        const_map = {}  # 临时变量到常数的映射
        
        for quad in quads:
            op, arg1, arg2, result = quad
            
            # 检查是否可以进行常数折叠
            if op == ':=' and arg1.isdigit():
                const_map[result] = arg1
                optimized.append(quad)
                continue
            
            # 如果是二元运算，且两个操作数都是常数
            if op in '+-*/' and arg1 in const_map and arg2 in const_map:
                try:
                    val1 = int(const_map[arg1])
                    val2 = int(const_map[arg2])
                    if op == '+':
                        result_val = val1 + val2
                    elif op == '-':
                        result_val = val1 - val2
                    elif op == '*':
                        result_val = val1 * val2
                    elif op == '/':
                        if val2 != 0:
                            result_val = val1 // val2
                        else:
                            optimized.append(quad)
                            continue
                    
                    const_map[result] = str(result_val)
                    # 用赋值替换运算
                    optimized.append((':=', str(result_val), '_', result))
                except:
                    optimized.append(quad)
            else:
                optimized.append(quad)
        
        return optimized
    
    @staticmethod
    def dead_code_elimination(quads):
        """
        死代码消除
        
        Args:
            quads: 四元式列表
            
        Returns:
            list: 优化后的四元式列表
        """
        used_vars = set()
        optimized = []
        
        # 反向扫描，标记使用的变量
        for quad in reversed(quads):
            op, arg1, arg2, result = quad
            
            # 收集使用的变量
            if arg1 and not arg1.isdigit() and arg1 not in '_-':
                used_vars.add(arg1)
            if arg2 and not arg2.isdigit() and arg2 not in '_-':
                used_vars.add(arg2)
            
            # 如果是赋值给临时变量，但临时变量未被使用，则是死代码
            if op == ':=' and result.startswith('t') and result not in used_vars:
                continue  # 跳过这个四元式
            
            optimized.append(quad)
        
        optimized.reverse()
        return optimized
    
    @staticmethod
    def optimize(quads):
        """
        综合优化
        
        Args:
            quads: 四元式列表
            
        Returns:
            list: 优化后的四元式列表
        """
        optimized = quads.copy()
        
        # 多次优化，直到不再变化
        while True:
            old_len = len(optimized)
            
            # 应用各种优化
            optimized = QuadOptimizer.constant_folding(optimized)
            optimized = QuadOptimizer.dead_code_elimination(optimized)
            
            if len(optimized) == old_len:
                break
        
        return optimized