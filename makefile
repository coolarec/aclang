all: lex.exe

lex.exe: lex.yy.c
	g++ -o lex.exe lex.yy.c

lex.yy.c: lex.l
	win_flex lex.l

clean:
	del lex.yy.c lex.exe
