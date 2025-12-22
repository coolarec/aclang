%{
#include "y.tab.h"
#include <string.h>
#include <stdlib.h>
%}

%option noyywrap

%%

"int"           { return T_Int; }
"if"            { return T_If; }
"else"          { return T_Else; }
"while"         { return T_While; }
"return"        { return T_Return; }
"break"         { return T_Break; }
"continue"      { return T_Continue; }

"factorial"     { return T_Factorial; }
":"            { return T_Explain; }

"inputInt"      { return T_inputInt; }
"outputInt"     { return T_outputInt; }

"=="            { return T_Eq; }
"!="            { return T_Ne; }
"<="            { return T_Le; }
">="            { return T_Ge; }
"&&"            { return T_And; }
"||"            { return T_Or; }

[0-9]+          { yylval.ival = atoi(yytext); return T_IntConstant; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = _strdup(yytext); return T_Identifier; }

[ \t\n\r]       { /* skip */ }
"//".*          { /* comment */ }

.               { return yytext[0]; }

%%