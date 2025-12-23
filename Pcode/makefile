CC = gcc
FILENAME = pcode

OUT_EXE = ..\output\exe
TMPDIR  = ..\output\tmp

LEX_SRC = $(FILENAME).l
YACC_SRC = $(FILENAME).y

LEX_C = $(TMPDIR)\lex.yy.c
YACC_C = $(TMPDIR)\y.tab.c
YACC_H = $(TMPDIR)\y.tab.h
YACC_OUT = $(TMPDIR)\y.output

# 平台判断
ifeq ($(OS),Windows_NT)
    TARGET = $(FILENAME).exe
    FLEX = win_flex
    BISON = win_bison
    RM_TMP = if exist "$(TMPDIR)" rd /s /q "$(TMPDIR)"
    MKDIR_EXE = if not exist "$(OUT_EXE)" mkdir "$(OUT_EXE)"
    MKDIR_TMP = if not exist "$(TMPDIR)" mkdir "$(TMPDIR)"
else
    TARGET = $(FILENAME)
    FLEX = flex
    BISON = bison
    RM_TMP = rm -rf $(TMPDIR)\*
    MKDIR_EXE = mkdir -p $(OUT_EXE)
    MKDIR_TMP = mkdir -p $(TMPDIR)
endif



all: clean-tmp dirs $(TARGET)

dirs:
	$(MKDIR_EXE)
	$(MKDIR_TMP)

$(TARGET): $(LEX_C) $(YACC_C)
	$(CC) -o $(OUT_EXE)\$(TARGET) $(LEX_C) $(YACC_C)

$(LEX_C): $(LEX_SRC) $(YACC_H)
	$(FLEX) -o $(LEX_C) $(LEX_SRC)

$(YACC_C) $(YACC_H): $(YACC_SRC)
	$(BISON) -vdty -o $(YACC_C) $(YACC_SRC)
	$(MV_H)
	$(MV_OUT)


clean-tmp:
	$(RM_TMP)
	$(MKDIR_TMP)

clean:
	$(RM_TMP)
	$(RM) $(OUT_EXE)\$(TARGET)
