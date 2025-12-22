#ifndef TOKEN_H
#define TOKEN_H
#include<stdio.h>
typedef enum {
    T_Le = 256, T_Ge, T_Eq, T_Ne, T_And, T_Or, T_IntConstant,
    T_StringConstant, T_Identifier, T_Void, T_Int, T_While,
    T_If, T_Else, T_Return, T_Break, T_Continue, T_outputInt,
    T_inputInt,T_Factorial,T_Explain
} TokenType;

static void print_token(int token, int token_count,char* yytext,int yylineno,int col,int yyleng) {
    static char* token_strs[] = {
        "T_Le", "T_Ge", "T_Eq", "T_Ne", "T_And", "T_Or", "T_IntConstant",
        "T_StringConstant", "T_Identifier", "T_Void", "T_Int", "T_While",
        "T_If", "T_Else", "T_Return", "T_Break", "T_Continue",
        "T_outputInt", "T_inputInt", "T_Factorial", "T_Explain"
    };

    const char* type;

    if (token < 256) {
        static char buf[2];
        buf[0] = (char)token;
        buf[1] = '\0';
        type = buf;
    } else {
        type = token_strs[token - 256];
    }

    printf(
        "  {\n"
        "    \"type\": \"%s\",\n"
        "    \"value\": \"%s\",\n"
        "    \"line\": %d,\n"
        "    \"col_start\": %d,\n"
        "    \"col_end\": %d\n"
        "  },\n",
        type,
        yytext,
        yylineno,
        col,
        col + yyleng - 1
    );
}


#endif