#ifndef AST_H
#define AST_H

#include <stdio.h>
#define MAX_SON 20

extern char* ASTTypeName[];  // 只声明，不定义

typedef enum {
    /* 程序结构 */
    AST_PROGRAM,
    AST_FUNCTION,
    AST_FUNCTION_LIST,
    AST_PARAM,
    AST_PARAM_LIST,
    /* 语句 */
    AST_COMPOUND_STMT,
    AST_STMT_LIST,
    AST_DECL,
    AST_ASSIGN,
    AST_RETURN,
    AST_FUNC_CALL,
    AST_STMT,
    AST_INT_LIST,
    AST_ARG_LIST,
    /* 控制流 */
    AST_IF,
    AST_IF_ELSE,
    AST_WHILE,
    AST_BREAK,
    AST_CONTINUE,
    AST_WHILE_LABEL,
    /* 表达式 */
    AST_EXPR,
    AST_BINOP,
    AST_UNARYOP,
    /* 运算符 */
    AST_ADD,
    AST_SUB,
    AST_MUL,
    AST_DIV,
    AST_POW,
    AST_EQ,
    AST_NE,
    AST_LT,
    AST_GT,
    AST_LE,
    AST_GE,
    AST_AND,
    AST_OR,
    /* 基本元素 */
    AST_IDENTIFIER,
    AST_INT_CONST,
    AST_INPUT,
    AST_OUTPUT,
    /* 类型 */
    AST_TYPE_INT,
    AST_TYPE_VOID,
    
    AST_PUNCT,
    AST_COMMA,
    AST_PAREN_EXPR,
    AST_NULL
} ASTType;

int get_index(const char* s);

typedef struct AST {
    ASTType type;
    char* name;
    int value;
    int son_cnt;
    struct AST* son[MAX_SON];
} AST;

/* 构造函数 */
AST* ast_new(ASTType type,char* name);
void ast_add(AST* a, AST* b);
void ast_print(AST* t, int dep);

#endif
