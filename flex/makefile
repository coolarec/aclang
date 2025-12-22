all: Lexical.exe

Lexical.exe: lex.yy.c
	gcc -o ../Lexical.exe lex.yy.c

lex.yy.c: lex.l
	win_flex lex.l

clean:
	del /Q lex.yy.c
