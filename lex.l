%{

#include <stdio.h>

#include <stdlib.h>

int count = 0;

%}

delim [" "\n\t\r]

whitespace {delim}+

operator \+|-|\*|\/|:=|>=|<=|#|=|<<|>>|\+\+

reservedWord int|include|main|return|using|if|namespace

delimiter [,\.;\(\)\"\<\>\{\}]

constant ([0-9])+

identfier [A-Za-z]([A-Za-z]|[0-9])*

%%

{reservedWord} {count++;printf("%d\t(rw,%s)\n",count,yytext);}

\"[^\"]*\" {count++;printf("%d\t(ct,%s)\n",count,yytext);}

{operator} { count++;printf("%d\t(op,%s)\n",count,yytext); }

{delimiter} {count++;printf("%d\t(de,%s)\n",count,yytext);}

{constant} {count++;printf("%d\t(ct,%s)\n",count,yytext);}

{identfier} {count++;printf("%d\t(id,%s)\n",count,yytext);}

{whitespace} { /* do nothing*/ }

%%

int main()

{
yylex();
printf("%d lines\n",count);

}

int yywrap()

{

return 1;

}