CC = gcc
FLEX = win_flex
BISON = win_bison.exe
FILENAME = symbol_table
TARGET = $(FILENAME).exe

LEX_SRC = $(FILENAME).l
YACC_SRC = $(FILENAME).y

LEX_C = lex.yy.c
YACC_C = y.tab.c
YACC_H = y.tab.h

all: $(TARGET)

$(TARGET): $(LEX_C) $(YACC_C)
	$(CC) -o ../output/exe/$(TARGET) $(LEX_C) $(YACC_C)

$(LEX_C): $(LEX_SRC) $(YACC_H)
	$(FLEX) $(LEX_SRC)

$(YACC_C) $(YACC_H): $(YACC_SRC)
	$(BISON) -vdty $(YACC_SRC)

clean:
	del /Q $(LEX_C) $(YACC_C) $(YACC_H) y.output $(TARGET)
