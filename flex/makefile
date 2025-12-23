CC = gcc
SRC = lex.l
INCLUDE = -I.

OUT_EXE = ..\output\exe
TMPDIR  = ..\output\tmp

LEX_C = $(TMPDIR)\lex.yy.c

ifeq ($(OS),Windows_NT)
    TARGET = Lexical.exe
    FLEX = win_flex
    RM_TMP = if exist "$(TMPDIR)" del /Q "$(TMPDIR)\*"
    RM_EXE = del /Q
    MKDIR_EXE = if not exist "$(OUT_EXE)" mkdir "$(OUT_EXE)"
    MKDIR_TMP = if not exist "$(TMPDIR)" mkdir "$(TMPDIR)"
else
    TARGET = Lexical
    FLEX = flex
    RM_TMP = rm -f $(TMPDIR)/*
    RM_EXE = rm -f
    MKDIR_EXE = mkdir -p $(OUT_EXE)
    MKDIR_TMP = mkdir -p $(TMPDIR)
endif

all: clean-tmp dirs $(TARGET)

dirs:
	$(MKDIR_EXE)
	$(MKDIR_TMP)

$(TARGET): $(LEX_C)
	$(CC) $(INCLUDE) -o $(OUT_EXE)/$(TARGET) $(LEX_C)

$(LEX_C): $(SRC)
	$(FLEX) -o $(LEX_C) $(SRC)

clean-tmp:
	$(RM_TMP)

clean:
	$(RM_TMP)
	$(RM_EXE) $(OUT_EXE)\$(TARGET)
