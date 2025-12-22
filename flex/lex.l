%option yylineno

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tokens.h"
int cur_line_num = 1;
int col = 1;
int token_count = 0;
int first = 1;
void print_error_token(const char* , int , int , int, const char*);
%}

DIGIT   [0-9]
LETTER  [a-zA-Z_]
IDENT   {LETTER}({LETTER}|{DIGIT})*
INTEGER  {DIGIT}+
OPERATOR            ([+*-/%=,;!<>(){}])
SINGLE_COMMENT    ("//"[^\n]*)

%%

[\n]        { cur_line_num++;col = 1;                  }
[ \t\r\a]+  {                                          }
[:]         { token_count++; return T_Explain;         }

{OPERATOR}  { token_count++; return yytext[0];         }

{SINGLE_COMMENT}  { }

"int"       { token_count++; return T_Int;             }
"if"        { token_count++; return T_If;              }
"else"      { token_count++; return T_Else;            }
"while"     { token_count++; return T_While;           }
"return"    { token_count++; return T_Return;          }
"break"     { token_count++; return T_Break;           }
"continue"  { token_count++; return T_Continue;        }
"void"      { token_count++; return T_Void;            }

"input"     { token_count++; return T_inputInt;        }
"print"     { token_count++; return T_outputInt;       }

"=="        { token_count++; return T_Eq;              }
"!="        { token_count++; return T_Ne;              }
">="        { token_count++; return T_Ge;              }
"<="        { token_count++; return T_Le;              }
"**"        { token_count++; return T_Factorial;       }

[0-9]+[a-zA-Z_][a-zA-Z0-9_]* {
    print_error_token(yytext,yylineno,col,col,"Invalid identifier starting with digit");
}

[0-9]+   { token_count++; return T_IntConstant;     }


{IDENT}     { token_count++; return T_Identifier;      }

.           { print_error_token(yytext,yylineno,col,col,"Unrecognized character"); col++; }
%%


int main(int argc, char* argv[]) {
    int token;
    printf(" [\n");
    while (token = yylex()) {
        if(!first){
            printf(",\n");
        }
        first=0;
        print_token(token,token_count,yytext,yylineno,col,yyleng);
        col+=yyleng;
    }
    printf("\n  ]\n");
    return 0;
}


void print_error_token(const char* text, int line, int col_start, int col_end, const char* msg) {
    if(!first){
        printf(",\n");
    }
    first=0;
    printf(
        "  {\n"
        "    \"type\": \"LEX_ERROR\",\n"
        "    \"value\": \"%s\",\n"
        "    \"line\": %d,\n"
        "    \"col_start\": %d,\n"
        "    \"col_end\": %d,\n"
        "    \"message\": \"%s\"\n"
        "   }",
        text,
        line,
        col_start,
        col_end,
        msg
    );
}


int yywrap(void) {
    return 1;
}