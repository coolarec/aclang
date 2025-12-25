%{
#include <string.h>
#include <stdlib.h>
#include "y.tab.h"
%}

%option yylineno

%%
"int"           { return T_Int; }
"void"          { return T_Void; }
"while"         { return T_While; }
"if"            { return T_If; }
"else"          { return T_Else; }
"return"        { return T_Return; }
"break"         { return T_Break; }
"continue"      { return T_Continue; }
"explain"       { return T_Explain; }
"inputInt"      { return T_inputInt; }
"outputInt"     { return T_outputInt; }

[0-9]+          { yylval.ival = atoi(yytext); return T_IntConstant; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); return T_Identifier; }
":"             { return T_Explain; }
"=="            { return T_Eq; }
"!="            { return T_Ne; }
"<="            { return T_Le; }
">="            { return T_Ge; }
"&&"            { return T_And; }
"||"            { return T_Or; }
"**"            { return T_Power; }

"+"|"-"|"*"|"/"|"<"|">"|"="|"("|")"|"{"|"}"|","|";"|":" { return yytext[0]; }

"//".*          { /* 忽略单行注释 */ }
[ \t\n\r]+      { /* 忽略空白 */ }
.               { fprintf(stderr, "Lexer Error: Unknown char %s\n", yytext); }

%%
int yywrap() { return 1; }