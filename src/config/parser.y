%{
//#define DEBUG
#include "defines.h"
#include "node.h"
#include "symbol.h"
#include "unfoldComposite.h"
#include <vector>
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

/************************************************************************/
/*              1. 文法一级入口,由下面三种文法组成                           */
/*                 1.1. declaration 声明                                 */
/*                 1.2. function.definition 函数声明                      */
/*                 1.3. composite.definition 数据流计算单元声明             */
/*************************************************************************/
prog.start:translation.unit {Program=$1;};

translation.unit:
            external.definition     {
                                        line("Line:%-4d",@1.first_line);
                                        debug("translation.unit::=external.definition\n");
                                        $$ = new list<Node*>({$1});
                                    }
        | translation.unit external.definition  {
                                                    line("Line:%-4d",@1.first_line);
                                                    debug("translation.unit::=external.definition\n");
                                                    $$->push_back($2);
                                                }
        ;
external.definition:
            declaration             {
                                        line("Line:%-4d",@1.first_line);
                                        debug("external.definition::=declaration\n");
                                        $$=$1;
                                    }
        |   function.definition     {
                                        line("Line:%-4d",@1.first_line);
                                        debug("external.definition::=function.definition\n");
                                        $$=$1;
                                    }
        |   composite.definition    {   
                                        line("Line:%-4d",@1.first_line);
                                        debug("external.definition::=composite.definition\n");
                                        $$=$1;
                                    }
        ;
/*************************************************************************/
/*              1.1 declaration 由下面2种文法+2个基础组件组成                */
/*                      1.1.1 declaring.list                             */
/*                      1.1.2 stream.declaring.list                      */
/*                      1.1.3 array                                      */
/*                      1.1.4 initializer                                */
/*************************************************************************/

declaration:
            declaring.list ';'      {
                                        line("Line:%-4d",@1.first_line); 
                                        debug("declaration::=declaring.list\n");
                                        $$=$1;
                                    }
        |   stream.declaring.list';'{
                                        line("Line:%-4d",@1.first_line);
                                        debug("declaration::=stream.declaring.list\n");
                                        $$=$1;
                                    }
        ;
declaring.list:
            type.specifier  idNode  initializer.opt{
                top->put(static_cast<idNode*>($2)->name,static_cast<idNode*>($2));
                (static_cast<idNode*>$2)->init=$3;
                $$=new declareNode((primNode*)$1,(static_cast<idNode*>$2),@2);
                line("Line:%-4d",@1.first_line);
                debug("declaring.list::=type.specifier(%s) IDENTIFIER(%s) initializer.opt \n",
                $1->toString().c_str(),$2->toString().c_str());
                }
        ;
        |   declaring.list  ',' idNode  initializer.opt{
                top->put(static_cast<idNode*>($3)->name,static_cast<idNode*>($3));
                (static_cast<idNode*>$3)->init=$4;
                $$=$1;
                line("Line:%-4d",@1.first_line);
                debug("declaring.list::=declaring.list ','IDENTIFIER(%s) initializer.opt \n",($3)->toString().c_str());
                }
        ;

/*************************************************************************/
/*                      1.1.2 stream .declaring.list                     */
/*                         stream<double x,int y>S;                      */
/*************************************************************************/
stream.declaring.list:
            stream.type.specifier IDENTIFIER    {
                line("Line:%-4d",@1.first_line);
                debug("stream.declaring.list::=stream.type.specifier %s \n", $2->c_str());
                idNode *id=new idNode(*($2),@2);
                top->put(*($2),id);
                ((strdclNode*)($1))->id_list.push_back(id);
                $$=$1;
            }
        ;
            stream.declaring.list ',' IDENTIFIER    {
                line("Line:%-4d",@1.first_line);
                debug("stream.declaring.list::=stream.type.specifier %s \n", $3->c_str());
                idNode *id=new idNode(*($3),@3);
                top->put(*($3),id);
                ((strdclNode*)($1))->id_list.push_back(id);
                $$=$1;
            }
        ;
stream.type.specifier:
            STREAM '<' stream.declaration.list '>'{
                line("Line:%-4d",@1.first_line);
                debug("stream.type.specifier::= STREAM'<'stream.declaration.list(%s) '>' \n",$3->toString().c_str());
                $$=$3;
            }
        ;
stream.declaration.list:
            type.specifier idNode   {
                top->put(static_cast<idNode*>($2)->name,static_cast<idNode*>($2));
                (static_cast<idNode*>->$2)->valType=(static_cast<primNode*>$1)->name;
                $$=new strdclNode((idNode*)$2,@1);
            }
        ;
            stream.declaration.list ',' type.specifier idNode{
                top->put(static_cast<idNode*>($4)->name,static_cast<idNode*>($4));
                (static_cast<idNode*>->$4)->valType=(static_cast<primNode*>$3)->name;
                (static_cast<strdclNode*>$1)->id_list.push_back((idNode*)$4);
                $$=$1;
            }
        ;

/*************************************************************************/
/*                      1.1.3 array ( int a[] )                          */
/*************************************************************************/







%%
/* ----语法树结束----*/
void yyerror (const char *msg)
{
    Error(msg,yylloc.first_line,yylloc.first_column);
}
