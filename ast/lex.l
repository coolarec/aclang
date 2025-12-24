%{
#include "ast.h"
#include "y.tab.h"
#include <string.h>
#include <stdlib.h>
%}

%option noyywrap
%option yylineno

%%

"int"           { return T_Int; }
"if"            { return T_If; }
"else"          { return T_Else; }
"while"         { return T_While; }
"return"        { return T_Return; }
"break"         { return T_Break; }
"continue"      { return T_Continue; }
"void"          { return T_Void; }
":"             { return T_Explain; }

"inputInt"      { return T_inputInt; }
"outputInt"     { return T_outputInt; }

"=="            { return T_Eq; }
"!="            { return T_Ne; }
"<="            { return T_Le; }
">="            { return T_Ge; }
"&&"            { return T_And; }
"||"            { return T_Or; }
"**"            { return T_Power; }
[0-9]+          { yylval.ival = atoi(yytext); return T_IntConstant; }
[a-zA-Z_][a-zA-Z0-9_]* { 
    yylval.str = strdup(yytext); // 必须分配新空间
    return T_Identifier; 
}
[\n]          { yylineno++; }
[ \t\r]       { /* skip */ }
"//".*          { /* comment */ }

.               { return yytext[0]; }

%%