CC = gcc
FILENAME = Pcode

LEX_SRC = $(FILENAME).l
YACC_SRC = $(FILENAME).y

LEX_C = lex.yy.c
YACC_C = y.tab.c
YACC_H = y.tab.h

# 平台判断
ifeq ($(OS),Windows_NT)
    TARGET = $(FILENAME).exe
    FLEX = win_flex
    BISON = win_bison
    RM = del /Q
else
    TARGET = $(FILENAME)
    FLEX = flex
    BISON = bison
    RM = rm -f
endif

all: $(TARGET)

$(TARGET): $(LEX_C) $(YACC_C)
	$(CC) -o ../output/exe/$(TARGET) $(LEX_C) $(YACC_C)

$(LEX_C): $(LEX_SRC) $(YACC_H)
	$(FLEX) $(LEX_SRC)

$(YACC_C) $(YACC_H): $(YACC_SRC)
	$(BISON) -vdty $(YACC_SRC)

clean:
	$(RM) $(LEX_C) $(YACC_C) $(YACC_H) y.output ../output/exe/$(TARGET)
