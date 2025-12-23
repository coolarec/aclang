%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

extern int yylineno;
extern char* yytext;

/* ========= 符号表 ========= */
#define MAX_SCOPE 16
#define MAX_SYMBOL 128

typedef struct {
    char name[64];
    int kind;   // 0=func, 1=var, 2=param
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

void leave_scope() {
    if (scope_top >= 0) scope_top--;
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
        fprintf(stderr, "Error: No active scope for symbol %s\n", name);
        exit(1);
        return -1;
    }
    
    Scope* s = &scope_stack[scope_top];
    
    // 检查是否在当前作用域已定义
    for (int i = 0; i < s->count; i++) {
        if (strcmp(s->symbols[i].name, name) == 0) {
            // 符号已存在
            fprintf(stderr, "Error: Symbol '%s' already defined in current scope\n", name);
            exit(1);
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
    
    fprintf(stderr, "Error: Symbol table full for scope\n");
    exit(1);
    return -3;
}

void print_symbol_table() {
    int i, j;
    printf("========== Symbol Table ==========\n");
    for (i = 0; i <= scope_top; i++) {
        printf("Scope %d:\n", i);
        Scope* s = &scope_stack[i];
        for (j = 0; j < s->count; j++) {
            Symbol* sym = &s->symbols[j];
            printf("  name=%s  kind=%d  type=%d\n",
                   sym->name, sym->kind, sym->type);
        }
    }
    printf("=================================\n");
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

extern int yylex(void);
void yyerror(const char* s);

%}
%locations

%union {
    int ival;
    char* str;
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

%type <ival> expr if_prefix while_label 

%%

/* 程序由一个或多个函数组成 */
program
    : { enter_scope(); } function_list { leave_scope(); }
    ;

function_list
    : function_list function
    | function
    ;

/* 将 main 和普通函数统一，解决 Reduce/Reduce 冲突 */
function
    : T_Identifier T_Explain dtype 
      {
          insert_symbol($1, 0, 0);
          emit("LABEL %s", $1);
          enter_scope();
      }
      '(' param_list ')' compound_stmt
      {
          // 如果是 main 函数，生成 STOP，否则生成 RET
          if (strcmp($1, "main") == 0) 
              emit("STOP");
          else 
              emit("RET");
          leave_scope();
      }
    ;
dtype 
    : T_Int
    | T_Void
    ;

param_list
    : param_list ',' param
    | param
    | /* empty */
    ;

param
    : T_Int T_Identifier { insert_symbol($2, 2, 0); }
    ;

compound_stmt
    : '{' stmt_list '}'
    ;

stmt_list
    : stmt_list stmt
    | /* empty */
    ;

if_prefix
    : T_If '(' expr ')' 
      {
          int l_false = new_label();
          emit("JZ L%d", l_false);
          $$ = l_false;
      }
    ;

while_label
    : T_While 
      {
          int l_begin = new_label();
          emit("LABEL L%d", l_begin);
          $$ = l_begin;
      }
    ;
var_list
    : var_list ',' T_Identifier
      {
          insert_symbol($3, 1, 0);
      }
    | T_Identifier
      {
          insert_symbol($1, 1, 0);
      }
    ;


stmt
    : T_Return expr ';'           { }
    | T_Int var_list ';'      { }
    | T_Identifier '=' expr ';'   { emit("STO %s", $1); }
    | T_Identifier '(' arg_list ')' ';' { emit("CALL %s", $1); }
    | compound_stmt
    
    /* 解决悬空 else */
    | if_prefix stmt %prec LOWER_THAN_ELSE
      {
          emit("LABEL L%d", $1);
      }
    | if_prefix stmt T_Else 
      {
          int l_end = new_label();
          emit("JMP L%d", l_end);
          emit("LABEL L%d", $1);
          $<ival>$ = l_end;
      }
      stmt
      {
          emit("LABEL L%d", $<ival>4);
      }

    | while_label '(' expr ')' 
      {
          int l_end = new_label();
          emit("JZ L%d", l_end);
          push_while($1, l_end);
          $<ival>$ = l_end;
      }
      stmt
      {
          emit("JMP L%d", $1);
          emit("LABEL L%d", $<ival>5);
          pop_while();
      }

    | T_Break ';'     { if(while_top<0) yyerror("break loop"); else emit("JMP L%d", cur_while_end()); }
    | T_Continue ';'  { if(while_top<0) yyerror("cont loop"); else emit("JMP L%d", cur_while_begin()); }
    | T_outputInt '(' expr ')' ';' { emit("OUT"); }
    ;

arg_list
    : arg_list ',' expr
    | expr
    | /* empty */
    ;

expr
    : T_IntConstant          { emit("LIT %d", $1); }
    | T_Identifier           { emit("LOD %s", $1); }
    | T_Identifier '(' arg_list ')' { emit("CALL %s", $1); }
    | T_inputInt '(' ')'     { emit("IN"); }
    | expr '+' expr          { emit("ADD"); }
    | expr '-' expr          { emit("SUB"); }
    | expr '*' expr          { emit("MUL"); }
    | expr '/' expr          { emit("DIV"); }
    | expr T_Eq expr         { emit("EQ"); }
    | expr T_Ne expr         { emit("NE"); }
    | expr '<' expr          { emit("LT"); }
    | expr '>' expr          { emit("GT"); }
    | expr T_Le expr         { emit("LE"); }
    | expr T_Ge expr         { emit("GE"); }
    | expr T_Or expr         { emit("OR"); }
    | expr T_And expr        { emit("AND"); }
    | expr T_Power expr      { emit("POW"); }
    | '(' expr ')'           { $$ = $2;  }
    ;

%%


int main() {
    return yyparse();
}
void yyerror(const char* s)
{
    fprintf(stderr,
        "Syntax error at %d:%d - %d:%d, near '%s'\n",
        yylloc.first_line,
        yylloc.first_column,
        yylloc.last_line,
        yylloc.last_column,
        yytext
    );
}
