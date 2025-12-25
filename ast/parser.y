%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "ast.h"
extern int yylineno;
extern char* yytext;
int has_errors = 0;

void yyerror(const char*,...);
/* ========= 符号表 ========= */
#define MAX_SCOPE 16
#define MAX_SYMBOL 128
int first = 1;
typedef struct {
    char name[64];
    int kind;   // 0=func, 1=INT, 2=param
    int type;   // 0=int
} Symbol;

typedef struct {
    Symbol symbols[MAX_SYMBOL];
    int count;
} Scope;

Scope scope_stack[MAX_SCOPE];
int scope_top = -1;

void enter_scope() {
    if (++scope_top < MAX_SCOPE) scope_stack[scope_top].count = 0;
}


// 在当前作用域查找符号
Symbol* lookup_current_scope(char* name) {
    if (scope_top < 0) return NULL;
    
    Scope* current = &scope_stack[scope_top];
    for (int i = current->count - 1; i >= 0; i--) {
        if (strcmp(current->symbols[i].name, name) == 0) {
            return &current->symbols[i];
        }
    }
    return NULL;
}

// 从内到外查找符号（遵循作用域规则）
Symbol* lookup_symbol(char* name) {
    // 从当前作用域开始，向外层查找
    for (int scope_idx = scope_top; scope_idx >= 0; scope_idx--) {
        Scope* scope = &scope_stack[scope_idx];
        for (int i = scope->count - 1; i >= 0; i--) {
            if (strcmp(scope->symbols[i].name, name) == 0) {
                return &scope->symbols[i];
            }
        }
    }
    return NULL;
}

// 检查符号是否已定义（所有作用域）
int is_symbol_defined(char* name) {
    return lookup_symbol(name) != NULL;
}

// 检查符号是否在当前作用域已定义（防止重复定义）
int is_symbol_defined_in_current_scope(char* name) {
    return lookup_current_scope(name) != NULL;
}

// 修改insert_symbol函数，自动检查重复定义
int insert_symbol(char* name, int kind, int type) {
    if (scope_top < 0) {
        yyerror("No active scope for symbol %s\n", name);
        // fprintf(stderr, "Error: No active scope for symbol %s\n", name);
        return -1;
    }
    
    Scope* s = &scope_stack[scope_top];
    
    // 检查是否在当前作用域已定义
    for (int i = 0; i < s->count; i++) {
        if (strcmp(s->symbols[i].name, name) == 0) {
            // 符号已存在
            yyerror("Symbol '%s' already defined in current scope\n", name);
            // fprintf(stderr, "Error: Symbol '%s' already defined in current scope\n", name);
            // exit(1);
            return -2;  // 返回错误码
        }
    }
    
    // 插入新符号
    if (s->count < MAX_SYMBOL) {
        strncpy(s->symbols[s->count].name, name, 63);
        s->symbols[s->count].name[63] = '\0';
        s->symbols[s->count].kind = kind;
        s->symbols[s->count].type = type;
        s->count++;
        return 0;  // 成功
    }
    yyerror("Symbol table full for scope\n");
    // fprintf(stderr, "Error: Symbol table full for scope\n");
    // exit(1);
    return -3;
}

void leave_scope() {
    // print_current_scope_json();
    if (scope_top >= 0) scope_top--;
}

/* ========= P-code ========= */
int label_cnt = 0;
int new_label() { return label_cnt++; }

void emit(const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    printf("\n");
    va_end(args);
}

/* ========= While Stack ========= */
#define MAX_WHILE 32
typedef struct { int begin; int end; } WhileCtx;
WhileCtx while_stack[MAX_WHILE];
int while_top = -1;

void push_while(int b, int e) { while_stack[++while_top] = (WhileCtx){b, e}; }
void pop_while() { while_top--; }
int cur_while_begin() { return while_stack[while_top].begin; }
int cur_while_end() { return while_stack[while_top].end; }

AST* root=NULL;

extern int yylex(void);

void my_itoa(int x, char *s) {
    int i = 0;
    int neg = 0;

    if (x == 0) {
        s[i++] = '0';
        s[i] = '\0';
        return;
    }

    if (x < 0) {
        neg = 1;
        x = -x;
    }

    while (x > 0) {
        s[i++] = x % 10 + '0';
        x /= 10;
    }

    if (neg) s[i++] = '-';
    s[i] = '\0';

    for (int l = 0, r = i - 1; l < r; l++, r--) {
        char t = s[l];
        s[l] = s[r];
        s[r] = t;
    }
}

%}
%locations

%union {
    int ival;
    char* str;
    AST* ast;
}

%token <ival> T_IntConstant
%token <str>  T_Identifier
%token T_Void T_Int T_While T_If T_Else T_Return T_Explain T_Break T_Continue 
%token T_Le T_Ge T_Eq T_Ne T_And T_Or T_inputInt T_outputInt T_Power

/* 优先级定义 */
%nonassoc LOWER_THAN_ELSE
%nonassoc T_Else

%right '='
%left T_Or
%left T_And
%left T_Eq T_Ne
%left '<' '>' T_Le T_Ge
%left '+' '-'
%left '*' '/'
%right '!'
%left T_Power

%type <ast> program function_list function dtype
%type <ast> param_list param INT_list
%type <ast> compound_stmt stmt_list stmt
%type <ast> if_prefix while_label
%type <ast> arg_list expr


%%

/* 程序由一个或多个函数组成 */
program
    : { 
        enter_scope();
      } 
    function_list 
      { 
        $$ = ast_new(AST_PROGRAM, "program");
        ast_add($$, $2);
        root=$$;
      }
    ;

function_list
    : function_list function
     {
        $$ = ast_new(AST_FUNCTION_LIST, "function_list");
        ast_add($$, $1);
        ast_add($$, $2);
      }
    | function
      {
        $$ = ast_new(AST_FUNCTION, "function");
        ast_add($$, $1);
      }
    ;

/* 将 main 和普通函数统一，解决 Reduce/Reduce 冲突 */
function
    : T_Identifier T_Explain dtype
      {
          insert_symbol($1, 0, 0);
          enter_scope();
      }
      '(' param_list ')' compound_stmt
      {
          $$ = ast_new(AST_FUNCTION,$1);
          ast_add($$, $3);
          ast_add($$, $6);
          ast_add($$, $8);

          leave_scope();
      }
    ;


dtype
    : T_Int
      {
          $$ = ast_new(AST_TYPE_INT, "int");
      }
    | T_Void
      {
          $$ = ast_new(AST_TYPE_VOID, "void");
      }
    ;


param_list
    : param_list ',' param
      {
          $$ = ast_new(AST_STMT_LIST, "param_list");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | param
      {
          $$ = ast_new(AST_PARAM_LIST, "param_list");
          ast_add($$, $1);
      }
    | /* empty */
      {
          $$ = ast_new(AST_PARAM_LIST, "param_list");
          ast_add($$, ast_new(AST_NULL,"∅"));
      }
    ;


param
    : T_Int T_Identifier
      {
          insert_symbol($2, 2, 0);

          $$ = ast_new(AST_PARAM, "param");
          ast_add($$, ast_new(AST_TYPE_INT, "int"));
          ast_add($$, ast_new(AST_IDENTIFIER, $2));
      }
    ;

compound_stmt
    : '{' stmt_list '}'
      {
          $$ = ast_new(AST_COMPOUND_STMT, "compound_stmt");
          ast_add($$, $2);
      }
    ;



stmt_list
    : stmt_list stmt
      {
          $$ = ast_new(AST_STMT_LIST, "stmt_list");
          ast_add($$, $1);
          ast_add($$, $2);
      }
    | /* empty */
      {
          $$ = ast_new(AST_STMT_LIST, "stmt_list");
          ast_add($$, ast_new(AST_NULL,"∅"));
      }
    ;


if_prefix
    : T_If '(' expr ')' 
      {
          $$ = ast_new(AST_IF, "if");
          ast_add($$, $3);
      }
    ;

while_label
    : T_While
      {
          // 创建AST节点并存储开始标签
          $$ = ast_new(AST_WHILE_LABEL, "while_lable");
          ast_add($$,ast_new(AST_WHILE,"while"));
      }
    ;

INT_list
    : INT_list ',' T_Identifier
      {
          insert_symbol($3, 1, 0);
          $$ = ast_new(AST_INT_LIST, "int_list");
          ast_add($$, $1);
          ast_add($$, ast_new(AST_IDENTIFIER, $3));
      }
    | T_Identifier
      {
          insert_symbol($1, 1, 0);
          $$ = ast_new(AST_INT_LIST, "int_list");
          ast_add($$, ast_new(AST_IDENTIFIER, $1));
      }
    ;


stmt
    : T_Return expr ';'
      {
          $$ = ast_new(AST_STMT, "stmt");
          ast_add($$, ast_new(AST_RETURN,"return"));
          ast_add($$, $2);
      }
    | T_Int INT_list ';'
      {
          $$ = ast_new(AST_STMT, "stmt");
          ast_add($$, ast_new(AST_TYPE_INT,"int"));
          ast_add($$, $2);
      }
    | T_Identifier '=' expr ';'
      {
          $$ = ast_new(AST_STMT, "stmt");
          ast_add($$, ast_new(AST_IDENTIFIER,$1));
          ast_add($$, ast_new(AST_ASSIGN,"="));
          ast_add($$, $3);
      }
    | T_Identifier '(' arg_list ')' ';'
      {
          $$ = ast_new(AST_STMT, "stmt");
          ast_add($$, ast_new(AST_FUNC_CALL, $1));
          ast_add($$, $3);
      }
    | compound_stmt
      {
          $$ = ast_new(AST_STMT, "stmt");
          ast_add($$, $1);   /* 将复合语句挂在 stmt 下 */
      }
    | if_prefix stmt %prec LOWER_THAN_ELSE
    {
        AST* if_node = ast_new(AST_IF, "if");
        ast_add(if_node, $1);
        ast_add(if_node, $2);

        $$ = ast_new(AST_STMT, "stmt");
        ast_add($$, if_node);
    }
    | if_prefix stmt T_Else stmt
    {
        AST* ifelse_node = ast_new(AST_IF_ELSE, "if_else");
        ast_add(ifelse_node, $1);  /* condition */
        ast_add(ifelse_node, $2);  /* then */
        ast_add(ifelse_node, $4);  /* else */

        $$ = ast_new(AST_STMT, "stmt");
        ast_add($$, ifelse_node);
    }

    | while_label '(' expr ')' stmt
    {
        AST* while_node = ast_new(AST_WHILE, NULL);
        ast_add(while_node, $3);  /* condition */
        ast_add(while_node, $5);  /* body */

        $$ = ast_new(AST_STMT, "stmt");
        ast_add($$, while_node);
    }
    | T_Break ';'
      {
          $$ = ast_new(AST_STMT, "stmt");
          ast_add($$, ast_new(AST_BREAK, "break"));
      }
    | T_Continue ';'
      {
          $$ = ast_new(AST_STMT, "stmt");
          ast_add($$, ast_new(AST_CONTINUE, "continue"));
      }
    | T_outputInt '(' expr ')' ';'
      {
          $$ = ast_new(AST_STMT, "stmt");
          ast_add($$, ast_new(AST_OUTPUT, "output"));
          ast_add($$, ast_new(AST_PUNCT, "("));
          ast_add($$, $3);
          ast_add($$, ast_new(AST_PUNCT, ")"));
      }
    ;


arg_list
    : arg_list ',' expr
      {
          $$ = ast_new(AST_ARG_LIST, NULL);
          ast_add($$, $1);     /* 之前的参数列表 */
          ast_add($$, ast_new(AST_PUNCT, ",")); /* 保留逗号 */
          ast_add($$, $3);     /* 新参数 */
      }
    | expr
      {
          $$ = ast_new(AST_ARG_LIST, NULL);
          ast_add($$, $1);
      }
    | /* empty */
      {
          $$ = ast_new(AST_ARG_LIST, NULL);
          ast_add($$, ast_new(AST_NULL,"∅"));
      }
    ;



expr
    : T_IntConstant
      {
          $$ = ast_new(AST_EXPR, "EXPR");
          char buff[10] = {0};
          my_itoa($1,buff);
          ast_add($$,ast_new(AST_INT_CONST,buff));
      }
    | T_Identifier
      {
          if(!is_symbol_defined($1)){
              yyerror("Undefined variable '%s'\n", $1);
          }
          $$ = ast_new(AST_EXPR, "EXPR");
          ast_add($$,ast_new(AST_IDENTIFIER, $1));
      }
    | T_Identifier '(' arg_list ')'
      {
          if(!is_symbol_defined($1)){
              yyerror("Undefined function '%s'\n", $1);
          }
          $$ = ast_new(AST_EXPR, "EXPR");
          ast_add($$, ast_new(AST_FUNC_CALL, $1));
          ast_add($$, ast_new(AST_PUNCT, "("));
          ast_add($$, $3);   /* 参数列表 */
          ast_add($$, ast_new(AST_PUNCT, ")"));
      }
    | T_inputInt '(' ')'
      {
          $$ = ast_new(AST_INPUT, "input");
      }
    | expr '+' expr
      {
          $$ = ast_new(AST_ADD, "+");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | expr '-' expr
      {
          $$ = ast_new(AST_SUB, "-");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | expr '*' expr
      {
          $$ = ast_new(AST_MUL, "*");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | expr '/' expr
      {
          $$ = ast_new(AST_DIV, "/");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | expr T_Eq expr
      {
          $$ = ast_new(AST_EQ, "==");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | expr T_Ne expr
      {
          $$ = ast_new(AST_NE, "!=");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | expr '<' expr
      {
          $$ = ast_new(AST_LT, "<");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | expr '>' expr
      {
          $$ = ast_new(AST_GT, ">");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | expr T_Le expr
      {
          $$ = ast_new(AST_LE, "<=");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | expr T_Ge expr
      {
          $$ = ast_new(AST_GE, ">=");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | expr T_Or expr
      {
          $$ = ast_new(AST_OR, "||");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | expr T_And expr
      {
          $$ = ast_new(AST_AND, "&&");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | expr T_Power expr
      {
          $$ = ast_new(AST_POW, "pow");
          ast_add($$, $1);
          ast_add($$, $3);
      }
    | '(' expr ')'
      {
          $$ = ast_new(AST_PAREN_EXPR, ASTTypeName[AST_PAREN_EXPR]);
          ast_add($$, ast_new(AST_PUNCT, "("));
          ast_add($$, $2);
          ast_add($$, ast_new(AST_PUNCT, ")"));
      }
    ;

%%


int main() {
    int status=yyparse();
    ast_print(root,1);
    return status | has_errors;
}
#include <stdarg.h>

// 增强版 yyerror
void yyerror(const char* fmt, ...)
{
    has_errors = 1;
    va_list args;
    
    // 打印位置信息
    fprintf(stderr, "EEEOR at line %d", yylineno);
    if (yylloc.first_line != yylloc.last_line) {
        fprintf(stderr, " to %d", yylloc.last_line);
    }
    fprintf(stderr, ": ");
    
    // 打印提供的错误信息
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);
    
    // 可选：打印附近的token
    if (yytext && yytext[0] != '\0') {
        fprintf(stderr, " (near '%s')", yytext);
    }
    fprintf(stderr, "\n");
}
