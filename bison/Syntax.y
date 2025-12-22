%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

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

void insert_symbol(char* name, int kind, int type) {
    Scope* s = &scope_stack[scope_top];
    if (s->count < MAX_SYMBOL) {
        strncpy(s->symbols[s->count].name, name, 63);
        s->symbols[s->count].kind = kind;
        s->symbols[s->count].type = type;
        s->count++;
    }
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
void yyerror(const char* s) { fprintf(stderr, "Syntax Error: %s\n", s); exit(1);}

%}

%union {
    int ival;
    char* str;
}

%token <ival> T_IntConstant
%token <str>  T_Identifier
%token T_Void T_Int T_While T_If T_Else T_Return T_Explain T_Break T_Continue
%token T_Le T_Ge T_Eq T_Ne T_And T_Or T_inputInt T_outputInt T_Factorial

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
    : T_Identifier T_Explain T_Int 
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

stmt
    : T_Return expr ';'           { emit("RET"); }
    | T_Int T_Identifier ';'      { insert_symbol($2, 1, 0); }
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
    | T_Factorial '(' expr ')' { emit("FAC"); }
    | '(' expr ')'           { /* $$ = $2 */ }
    ;

%%

int main() {
    return yyparse();
}