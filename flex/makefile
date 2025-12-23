# 1. 基础程序定义
CC      = gcc
FLEX    = flex
SRC     = lex.l
INCLUDE = -I.

# 2. 跨平台变量定义 (核心：分隔符 S)
ifeq ($(OS),Windows_NT)
    # --- Windows 环境 ---
    S      = \\
    TARGET = Lexical.exe
    # 强制指定 shell 为 cmd.exe，确保 if exist 等命令正常运行
    SHELL  = cmd.exe
    
    # 目录创建与清理命令
    # Windows 的 mkdir 不支持 -p，但可以用 if 判断
    MKDIR  = if not exist "$(1)" mkdir "$(1)"
    RM     = del /Q /F
    RMDIR  = rmdir /S /Q
    
    # 自动识别 win_flex
    ifeq (, $(shell where flex 2>nul))
        FLEX = win_flex
    endif
else
    # --- Unix/Linux/macOS 环境 ---
    S      = /
    TARGET = Lexical
    
    MKDIR  = mkdir -p "$(1)"
    RM     = rm -f
    RMDIR  = rm -rf
endif

# 3. 路径定义 (全部通过 $(S) 连接)
OUT_EXE_DIR = ..$(S)output$(S)exe
TMP_DIR     = ..$(S)output$(S)tmp

LEX_C  = $(TMP_DIR)$(S)lex.yy.c
OUTPUT = $(OUT_EXE_DIR)$(S)$(TARGET)

# 4. 编译规则
.PHONY: all clean dirs

all: dirs $(OUTPUT)

# 创建目录
dirs:
	@echo Creating directories...
	@$(call MKDIR,$(OUT_EXE_DIR))
	@$(call MKDIR,$(TMP_DIR))

# 链接阶段
$(OUTPUT): $(LEX_C)
	$(CC) $(INCLUDE) -o "$(OUTPUT)" "$(LEX_C)"

# Flex 生成 C 文件阶段
$(LEX_C): $(SRC)
	$(FLEX) -o "$(LEX_C)" "$(SRC)"

# 5. 清理规则
clean:
ifeq ($(OS),Windows_NT)
	@if exist "$(TMP_DIR)" $(RM) "$(TMP_DIR)$(S)*"
	@if exist "$(OUTPUT)" $(RM) "$(OUTPUT)"
else
	$(RM) $(TMP_DIR)$(S)*
	$(RM) $(OUTPUT)
endif

# 深度清理
distclean: clean
ifeq ($(OS),Windows_NT)
	@if exist "$(TMP_DIR)" $(RMDIR) "$(TMP_DIR)"
	@if exist "$(OUT_EXE_DIR)" $(RMDIR) "$(OUT_EXE_DIR)"
else
	$(RMDIR) $(TMP_DIR) $(OUT_EXE_DIR)
endif