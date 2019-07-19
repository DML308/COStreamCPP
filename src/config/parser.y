%{
//#define DEBUG
#include "defines.h"
#include "node.h"
#include "symbol.h"
#include "unfoldComposite.h"
SymbolTable *top=new SymbolTable(NULL);
SymbolTable *saved=top;
extern SymbolTable S;
extern list<Node*> *Program;
extern int yylex ();
extern void yyerror (const char *msg);

%}

/*在 union 里声明 %token 可能有的类型*/
%union{
    long long  num;
    double doubleNum;
    std::string *str;
    Node * node;
    std::list<Node*> *list;
}
/* A. 下面是从词法分析器传进来的 token ,其中大部分都是换名字符串*/
%token integerConstant  stringConstant      doubleConstant  IDENTIFIER
%token STRING     INT   DOUBLE  FLOAT       LONG    CONST   DEFINE
%token WHILE      FOR   BREAK   CONTINUE    SWITCH  CASE DEFAULT IF ELSE DO RETURN
%token POUNDPOUND ICR   DECR    ANDAND      OROR    LS  RS LE GE EQ NE
%token MULTassign DIVassign     PLUSassign  MINUSassign MODassign
%token LSassign   RSassign ANDassign ERassign ORassign
    /* A.1 ----------------- COStream 特有关键字 ---------------*/
%token COMPOSITE  INPUT OUTPUT  STREAM    FILEREADER  FILEWRITER  ADD
%token PARAM      INIT  WORK    WINDOW    TUMBLING    SLIDING
%token SPLITJOIN  PIPELINE      SPLIT     JOIN        DUPLICATE ROUNDROBIN
%token MATRIX

/* B.下面是语法分析器自己拥有的文法结构和类型声明 */

/* 语法分析器自己的结构 1. 文法一级入口*/
%type<list> translation.unit 
%type<node> external.definition
/* 语法分析器自己的结构   1.1.declaration */

%type<node> declaration declaring.list stream.declaring.list
%type<node> stream.type.specifier
%type<node> stream.declaration.list 
/* 语法分析器自己的结构     1.1.3.array */
%type<node> array.declarator
/* 语法分析器自己的结构     1.1.4.initializer */
%type<node> initializer.opt initializer initializer.list
/* 语法分析器自己的结构   1.2 function.definition 函数声明 */
%type<node> function.definition function.body  parameter.declaration
%type<list> statement.list  parameter.list
/* 语法分析器自己的结构   1.3 composite.definition 数据流计算单元声明 */
%type<node> composite.definition  composite.head  composite.head.inout
%type<node> composite.head.inout.member
%type<list> composite.head.inout.member.list
%type<node> operator.pipeline
/* 语法分析器自己的结构      1.3.2 composite.body */
%type<node> composite.body  composite.body.param.opt
%type<node> costream.composite.statement
%type<list> composite.body.statement.list
/* 语法分析器自己的结构 2. composite.body.operator  composite体内的init work window等组件  */
%type<node> composite.body.operator   operator.file.writer  operator.add
%type<node> operator.splitjoin  split.statement
%type<list> splitjoinPipeline.statement.list
%type<node> roundrobin.statement   duplicate.statement  join.statement  operator.default.call
%type<list> argument.expression.list
/* 语法分析器自己的结构 3.statement 花括号内以';'结尾的结构是statement  */
%type<node> statement labeled.statement compound.statement
%type<node> expression.statement  selection.statement   iteration.statement jump.statement
/* 语法分析器自己的结构 4.exp 计算表达式头节点  */
%type<str>  assignment.operator
%type<node> exp
%type<node> operator.selfdefine.body  operator.selfdefine.body.init operator.selfdefine.body.work
%type<node> operator.selfdefine.body.window.list operator.selfdefine.window
%type<list> operator.selfdefine.window.list 
%type<node> window.type
/* 语法分析器自己的结构 5.basic 从词法TOKEN直接归约得到的节点 */
%type<node>constant type.specifier basic.type.name idNode
%type<num> integerConstant
%type<doubleNum> doubleConstant
%type<str> stringConstant IDENTIFIER



/* C. 优先级标记,从上至下优先级从低到高排列 */
%right '='
%left OROR
%left ANDAND
%left '|'
%left '^'
%left '&'
%left EQ NE
%left '<' '>' LE GE
%left LS RS
%left '-' '+'
%left '*' '/' '%'
%left '.'
%left ')' ']'
%left '(' '['

/* D. 语法分析器的起点和坐标声明 */
%start prog.start
%locations

%%


%%
/* ----语法树结束----*/
void yyerror (const char *msg)
{
    Error(msg,yylloc.first_line,yylloc.first_column);
}
