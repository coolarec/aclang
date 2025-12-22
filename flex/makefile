all: lex.exe

lex.exe: lex.yy.c
	gcc -o ../lex.exe lex.yy.c

lex.yy.c: lex.l
	win_flex lex.l

clean:
	del lex.yy.c lex.exe
