#include "ast.h"
#include <stdlib.h>
#include <string.h>

char* ASTTypeName[] = {
    "PROGRAM",
    "FUNCTION",
    "AST_FUNCTION_LIST",
    "PARAM",
    "PARAM_LIST",
    "COMPOUND_STMT",
    "STMT_LIST",
    "DECL",
    "ASSIGN",
    "RETURN",
    "FUNC_CALL",
    "STMT",
    "INT_LIST",
    "ARG_LIST",
    "IF",
    "IF_ELSE",
    "WHILE",
    "BREAK",
    "CONTINUE",
    "WHILE_LABEL",
    "EXPR",
    "BINOP",
    "UNARYOP",
    "ADD",
    "SUB",
    "MUL",
    "DIV",
    "POW",
    "EQ",
    "NE",
    "LT",
    "GT",
    "LE",
    "GE",
    "AND",
    "OR",
    "IDENTIFIER",
    "INT_CONST",
    "INPUT",
    "OUTPUT",
    "TYPE_INT",
    "TYPE_VOID",
    "AST_PUNCT",
    "AST_COMMA",
    "PAREN_EXPR"
};

int get_index(const char* s) {
    for (int i = 0; i < 5; i++) {
        if (!strcmp(ASTTypeName[i], s)) return i;
    }
    return -1;
}

static void indent(int dep) {
    for (int i = 0; i < dep; i++) printf("  ");
}

AST* ast_new(ASTType type,char *name) {
    AST* t = malloc(sizeof(AST));
    t->type = type;
    t->name = name;
    t->value = 0;
    t->son_cnt = 0;
    for (int i = 0; i < MAX_SON; i++) t->son[i] = NULL;
    return t;
}

void ast_add(AST* a, AST* b) {
    a->son[a->son_cnt] = b;
    (a->son_cnt) ++;
    return ;
}

void ast_print(AST* t, int dep) {
    indent(dep);
    printf("{\n");

    indent(dep + 1);
    printf("\"type\": \"%s\",\n",ASTTypeName[t->type]);

    indent(dep + 1);
    if (t->name)
        printf("\"name\": \"%s\",\n", t->name);
    else
        printf("\"name\": null,\n");

    indent(dep + 1);
    if (t->value != 0)
        printf("\"value\": %d,\n", t->value);
    else
        printf("\"value\": null,\n");

    indent(dep + 1);
    printf("\"son\": [\n");

    for (int i = 0; i < t->son_cnt; i++) {
        ast_print(t->son[i], dep + 2);
        if (i + 1 < t->son_cnt) printf(",");
        printf("\n");
    }

    indent(dep + 1);
    printf("]\n");

    indent(dep);
    printf("}");
}
