# 1. 项目基础定义
CC       = gcc
FILENAME = ast

FLEX  = flex
BISON = bison
# 2. 跨平台变量与分隔符定义
ifeq ($(OS),Windows_NT)
    # --- Windows 环境 ---
    S     = \\
    TARGET = $(FILENAME).exe
    
    # 命令宏
    # $(subst /,\,$(1)) 确保路径中即使残留 / 也会被转为 \ 适配 CMD
    MKDIR = if not exist "$(1)" mkdir "$(1)"
    RM    = del /Q /F
    RD    = rd /S /Q
else
    # --- Unix/Linux/macOS 环境 ---
    S      = /
    TARGET = $(FILENAME)
    
    MKDIR = mkdir -p "$(1)"
    RM    = rm -f
    RD    = rm -rf
endif

# 3. 目录路径定义 (全部使用 $(S))
OUT_EXE_DIR = ..$(S)output$(S)exe
TMP_DIR     = ..$(S)output$(S)tmp

# 4. 文件路径定义
LEX_SRC  = $(FILENAME).l
YACC_SRC = $(FILENAME).y

LEX_C    = lex.yy.c
YACC_C   = $(TMP_DIR)$(S)y.tab.c
YACC_H   = $(TMP_DIR)$(S)y.tab.h
YACC_OUT = $(TMP_DIR)$(S)y.output
OUTPUT   = $(OUT_EXE_DIR)$(S)$(TARGET)

# 5. 编译规则
.PHONY: all clean dirs

# 默认目标：先建目录，再编译
all: dirs $(OUTPUT)
	$(MAKE) clean

# 创建目录
dirs:
	@$(call MKDIR,$(OUT_EXE_DIR))
	@$(call MKDIR,$(TMP_DIR))

# 链接阶段：将生成的两个 C 文件编译为可执行文件
$(OUTPUT): $(LEX_C) $(YACC_C)
	$(CC) -I. -I$(TMP_DIR) -o "$(OUTPUT)" "$(LEX_C)" "$(YACC_C)"

# Bison 阶段：生成 y.tab.c 和 y.tab.h
# -d: 生成头文件, -v: 生成 y.output, -y: yacc 兼容模式(生成 y.tab.c)
$(YACC_C) $(YACC_H): $(YACC_SRC)
	$(BISON) -vdty -o "$(YACC_C)" "$(YACC_SRC)"


# Flex 阶段：生成 lex.yy.c
# 注意：Lex 依赖于 Yacc 生成的头文件以获取 Token 定义
$(LEX_C): $(LEX_SRC) $(YACC_H)
	$(FLEX) "$(LEX_SRC)"

# 6. 清理规则
clean:
ifeq ($(OS),Windows_NT)
	@if exist "$(TMP_DIR)" $(RD) "$(TMP_DIR)"
	@if exist "$(LEX_C)" $(RM) "$(LEX_C)"
else
	$(RD) $(TMP_DIR)
	$(RM) $(LEX_C)
endif