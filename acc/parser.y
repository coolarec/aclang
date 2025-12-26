%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

extern int yylineno;
extern char* yytext;
int has_errors = 0;

/* ========= 跨平台寄存器定义与 ABI 适配 ========= */
// 定义最大支持 6 个参数（通用 x64 限制）
const char* arg_regs_win[] = {"rcx", "rdx", "r8", "r9"};
const char* arg_regs_sysv[] = {"rdi", "rsi", "rdx", "rcx", "r8", "r9"};

#if defined(_WIN32) || defined(__WIN32__) || defined(__CYGWIN__)
    #define OS_NAME "Windows (x64 ABI)"
    #define MAX_ARGS 4
    #define SHADOW_SPACE 32
    #define ARG_REG(i) arg_regs_win[i]
#else
    #define OS_NAME "Linux/macOS (System V ABI)"
    #define MAX_ARGS 6
    #define SHADOW_SPACE 0
    #define ARG_REG(i) arg_regs_sysv[i]
#endif

// 这里的宏用于获取当前平台的第几个参数寄存器
#define GET_ARG_REG(i) ( (i) < MAX_ARGS ? ARG_REG(i) : "stack" )


/* ========= 跨平台系统识别与 ABI 适配 ========= */
#if defined(_WIN32) || defined(__WIN32__) || defined(__CYGWIN__)
    /* Windows x64 (Microsoft x64 ABI) */
    #define OS_NAME "Windows (x64 ABI)"
    #define ARG1 "rcx"
    #define ARG2 "rdx"
    #define SHADOW_SPACE 32

#elif defined(__APPLE__) && defined(__MACH__) && defined(__i386__)
    /* macOS 32-bit (Mach-O i386 ABI) */
    /* 注意：标准 i386 cdecl 使用栈传参。
       如果你的编译器逻辑需要寄存器名，这里使用 eax/edx 作为通用占位 */
    #define OS_NAME "macOS Mach-O (32-bit i386)"
    #define ARG1 "eax" 
    #define ARG2 "edx"
    #define SHADOW_SPACE 0

#elif defined(__APPLE__) && defined(__MACH__) && defined(__x86_64__)
    /* macOS 64-bit (System V ABI) */
    #define OS_NAME "macOS (System V ABI x64)"
    #define ARG1 "rdi"
    #define ARG2 "rsi"
    #define SHADOW_SPACE 0

#else
    /* Linux/Unix (System V ABI) */
    #define OS_NAME "Linux (System V ABI)"
    #define ARG1 "rdi"
    #define ARG2 "rsi"
    #define SHADOW_SPACE 0
#endif

/* ========= 符号表 (带栈偏移量计算) ========= */
#define MAX_SCOPE 16
#define MAX_SYMBOL 128
int current_param_idx=0;
int call_arg_count=0;
typedef struct {
    char name[64];
    int kind;   // 0=func, 1=INT, 2=param
    int offset; // 栈偏移量: [rbp - offset]
} Symbol;

typedef struct {
    Symbol symbols[MAX_SYMBOL];
    int count;
} Scope;

Scope scope_stack[MAX_SCOPE];
int scope_top = -1;
int current_func_stack_offset = 0; // 当前函数栈指针偏移

void enter_scope() {
    if (++scope_top < MAX_SCOPE) scope_stack[scope_top].count = 0;
}

void leave_scope() {
    if (scope_top >= 0) scope_top--;
}

// 插入符号并分配偏移量
// 修改 insert_symbol 的返回值
int insert_symbol(char* name, int kind) {
    if (scope_top < 0) return -1;
    Scope* s = &scope_stack[scope_top];
    
    for (int i = 0; i < s->count; i++) {
        if (strcmp(s->symbols[i].name, name) == 0) return -2; 
    }
    
    if (s->count < MAX_SYMBOL) {
        strncpy(s->symbols[s->count].name, name, 63);
        s->symbols[s->count].kind = kind;
        if (kind != 0) {
            current_func_stack_offset += 8;
            s->symbols[s->count].offset = current_func_stack_offset;
        } else {
            s->symbols[s->count].offset = 0;
        }
        int res = s->symbols[s->count].offset; // 记录刚分配的偏移量
        s->count++;
        return res; // 返回偏移量
    }
    return -3;
}

Symbol* lookup_symbol(char* name) {
    for (int scope_idx = scope_top; scope_idx >= 0; scope_idx--) {
        Scope* scope = &scope_stack[scope_idx];
        for (int i = scope->count - 1; i >= 0; i--) {
            if (strcmp(scope->symbols[i].name, name) == 0) return &scope->symbols[i];
        }
    }
    return NULL;
}

/* ========= 汇编发射与标签管理 ========= */
int label_cnt = 0;
int new_label() { return label_cnt++; }

void emit(const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    printf("    "); // 汇编缩进
    vprintf(fmt, args);
    printf("\n");
    va_end(args);
}

/* ========= While 栈 (支持 Break/Continue) ========= */
#define MAX_WHILE 32
typedef struct { int begin; int end; } WhileCtx;
WhileCtx while_stack[MAX_WHILE];
int while_top = -1;

void push_while(int b, int e) { while_stack[++while_top] = (WhileCtx){b, e}; }
void pop_while() { while_top--; }

extern int yylex(void);
void yyerror(const char* fmt, ...);
%}

%union {
    int ival;
    char* str;
}

%token <ival> T_IntConstant
%token <str>  T_Identifier
%token T_Void T_Int T_While T_If T_Else T_Return T_Explain T_Break T_Continue 
%token T_Le T_Ge T_Eq T_Ne T_And T_Or T_inputInt T_outputInt T_Power

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

%type <ival> if_start while_start while_cond dtype

%%

program
    : { 
        printf("; Generated for %s\n", OS_NAME);
        printf("default rel\n");
        printf("section .data\n");
        printf("    fmt_out db \"%%ld\", 10, 0\n");
        printf("    fmt_in  db \"%%ld\", 0\n");
        printf("section .text\n");
        printf("    extern printf, scanf\n");
        printf("    global main\n\n");
        enter_scope();
      } 
      function_list { leave_scope();}
    ;

function_list 
    : function_list function 
    | function ;

function
    : T_Identifier T_Explain dtype
      {
          insert_symbol($1, 0); 
          enter_scope();
          current_func_stack_offset = 0;
          current_param_idx = 0; // 重置参数计数器
          printf("%s:\n", $1);
          emit("push rbp");
          emit("mov rbp, rsp");
          emit("sub rsp, 512"); // 预留局部变量空间
      }
      '(' param_list ')' compound_stmt
      {
          emit("leave");
          emit("ret\n");
          leave_scope();
      }
    ;

dtype : T_Int  | T_Void ;

param_list : param_list ',' param | param | ;

param : T_Int T_Identifier 
    { 
        int off = insert_symbol($2, 2); 
        if (off < 0) {
            yyerror("Redefinition or Symbol Table Full: %s", $2);
        } else {
            if (current_param_idx < MAX_ARGS) {
                // 现在 off 是正确的偏移量（如 8, 16...）
                emit("mov [rbp - %d], %s", off, GET_ARG_REG(current_param_idx));
            }
        }
        current_param_idx++;
    };

compound_stmt : '{' stmt_list '}' ;

stmt_list : stmt_list stmt | ;

INT_list
    : INT_list ',' T_Identifier { insert_symbol($3, 1); }
    | T_Identifier { insert_symbol($1, 1); }
    ;

stmt
    : T_Return expr ';' { emit("pop rax"); emit("leave"); emit("ret"); }
    | T_Int INT_list ';' 
    | T_Identifier '=' expr ';'
      {
          Symbol* s = lookup_symbol($1);
          if (s) {
              emit("pop rax");
              emit("mov [rbp - %d], rax", s->offset);
          } else { yyerror("Undefined variable %s", $1); }
      }
    | compound_stmt
    | if_start stmt %prec LOWER_THAN_ELSE { printf(".L%d:\n", $1); }
    | if_start stmt T_Else {
          int lab_end = new_label();
          emit("jmp .L%d", lab_end);
          printf(".L%d:\n", $1);
          $<ival>$ = lab_end;
      } stmt { printf(".L%d:\n", $<ival>4); }
    | while_start '(' while_cond ')' stmt
      {
          emit("jmp .L%d", $1);
          printf(".L%d:\n", $3);
          pop_while();
      }
    | T_Break ';' { if(while_top >= 0) emit("jmp .L%d", while_stack[while_top].end); }
    | T_Continue ';' { if(while_top >= 0) emit("jmp .L%d", while_stack[while_top].begin); }
    | T_outputInt '(' expr ')' ';'
      {
          emit("pop %s", ARG2);
          emit("lea %s, [fmt_out]", ARG1);
          if (SHADOW_SPACE) emit("sub rsp, %d", SHADOW_SPACE);
          emit("xor al, al");
          emit("call printf");
          if (SHADOW_SPACE) emit("add rsp, %d", SHADOW_SPACE);
      }
    | T_Identifier '(' { call_arg_count = 0; } arg_list ')' ';' 
      {
          // 纯函数调用语句（丢弃返回值）
          emit("call %s", $1);
          if (SHADOW_SPACE) emit("add rsp, %d", SHADOW_SPACE);
      }
    ;

if_start
    : T_If '(' expr ')' {
        int lab = new_label();
        emit("pop rax");
        emit("test rax, rax");
        emit("jz .L%d", lab);
        $$ = lab;
    }
    ;

while_start
    : T_While {
        int lab = new_label();
        printf(".L%d:\n", lab);
        $$ = lab;
    }
    ;

while_cond
    : expr {
        int lab = new_label();
        emit("pop rax");
        emit("test rax, rax");
        emit("jz .L%d", lab);
        push_while($<ival>-1, lab);
        $$ = lab;
    }
    ;

arg_list 
    : arg_list_node 
    | ;
arg_list_node 
    : arg_list_node ',' expr { call_arg_count++; }
    | expr { call_arg_count++; }
    ;

expr
    : T_IntConstant { emit("push %d", $1); }
    | T_Identifier
      {
          Symbol* s = lookup_symbol($1);
          if (s) emit("push qword [rbp - %d]", s->offset);
          else yyerror("Undefined variable %s", $1);
      }
    | T_Identifier '(' { $<ival>$ = call_arg_count; call_arg_count = 0; } arg_list ')'
      {
          // 关键修复：函数调用表达式
          // 根据参数个数，将栈上的值弹出到寄存器
          for(int i = call_arg_count - 1; i >= 0; i--) {
              if (i < MAX_ARGS) emit("pop %s", GET_ARG_REG(i));
          }
          if (SHADOW_SPACE) emit("sub rsp, %d", SHADOW_SPACE); // Windows 影子空间
          emit("call %s", $1);
          if (SHADOW_SPACE) emit("add rsp, %d", SHADOW_SPACE);
          emit("push rax"); // 将返回值压栈
          call_arg_count = $<ival>3; // 恢复之前的计数
      }
    | T_inputInt '(' ')'
      {
          emit("lea %s, [rbp - 512]", ARG2); // 使用预留的安全区
          emit("lea %s, [fmt_in]", ARG1);
          if (SHADOW_SPACE) emit("sub rsp, %d", SHADOW_SPACE);
          emit("xor al, al");
          emit("call scanf");
          if (SHADOW_SPACE) emit("add rsp, %d", SHADOW_SPACE);
          emit("push qword [rbp - 512]");
      }
    | expr '+' expr { emit("pop rbx"); emit("pop rax"); emit("add rax, rbx"); emit("push rax"); }
    | expr '-' expr { emit("pop rbx"); emit("pop rax"); emit("sub rax, rbx"); emit("push rax"); }
    | expr '*' expr { emit("pop rbx"); emit("pop rax"); emit("imul rax, rbx"); emit("push rax"); }
    | expr '/' expr { emit("pop rbx"); emit("pop rax"); emit("cqo"); emit("idiv rbx"); emit("push rax"); }
    | expr T_Eq expr { emit("pop rbx"); emit("pop rax"); emit("cmp rax, rbx"); emit("sete al"); emit("movzx rax, al"); emit("push rax"); }
    | expr T_Ne expr { emit("pop rbx"); emit("pop rax"); emit("cmp rax, rbx"); emit("setne al"); emit("movzx rax, al"); emit("push rax"); }
    | expr '<' expr { emit("pop rbx"); emit("pop rax"); emit("cmp rax, rbx"); emit("setl al"); emit("movzx rax, al"); emit("push rax"); }
    | expr '>' expr { emit("pop rbx"); emit("pop rax"); emit("cmp rax, rbx"); emit("setg al"); emit("movzx rax, al"); emit("push rax"); }
    | expr T_Le expr { emit("pop rbx"); emit("pop rax"); emit("cmp rax, rbx"); emit("setle al"); emit("movzx rax, al"); emit("push rax"); }
    | expr T_Ge expr { emit("pop rbx"); emit("pop rax"); emit("cmp rax, rbx"); emit("setge al"); emit("movzx rax, al"); emit("push rax"); }
    | expr T_And expr 
      {
          int lab_f = new_label(), lab_e = new_label();
          emit("pop rbx"); emit("pop rax");
          emit("test rax, rax"); emit("jz .L%d", lab_f);
          emit("test rbx, rbx"); emit("jz .L%d", lab_f);
          emit("push 1"); emit("jmp .L%d", lab_e);
          printf(".L%d:\n", lab_f); emit("push 0");
          printf(".L%d:\n", lab_e);
      }
    | expr T_Or expr
      {
          int lab_t = new_label(), lab_e = new_label();
          emit("pop rbx"); emit("pop rax");
          emit("test rax, rax"); emit("jnz .L%d", lab_t);
          emit("test rbx, rbx"); emit("jnz .L%d", lab_t);
          emit("push 0"); emit("jmp .L%d", lab_e);
          printf(".L%d:\n", lab_t); emit("push 1");
          printf(".L%d:\n", lab_e);
      }
    | expr T_Power expr
      {
          int l_loop = new_label();
          int l_even = new_label();
          int l_done = new_label();

          emit("pop rcx");          // 指数 (exp)
          emit("pop rsi");          // 底数 (base)
          emit("mov rax, 1");       // 结果 (res = 1)

          // 快速幂循环开始
          printf(".L%d:\n", l_loop);
          emit("test rcx, rcx");    // 检查指数是否为 0
          emit("jz .L%d", l_done);  // 如果为 0，结束循环

          // 检查指数当前最低位是否为 1 (奇数检查)
          emit("test rcx, 1");
          emit("jz .L%d", l_even);  // 如果是偶数，跳过累乘结果
          emit("imul rax, rsi");    // res = res * base

          printf(".L%d:\n", l_even);
          emit("imul rsi, rsi");    // base = base * base
          emit("shr rcx, 1");       // rcx = rcx >> 1
          emit("jmp .L%d", l_loop);

          printf(".L%d:\n", l_done);
          emit("push rax");         // 将最终结果压栈
      }
    | '(' expr ')' { }
    ;

%%

int main() {
    int status=yyparse();
    status|=has_errors;
    return status;
}

void yyerror(const char* fmt, ...)
{
    has_errors = 1;
    va_list args;
    fprintf(stderr, "Error at line %d: ", yylineno);
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);
    if (yytext && yytext[0] != '\0') {
        fprintf(stderr, " (near '%s')", yytext);
    }
    fprintf(stderr, "\n");
    exit(1);
}