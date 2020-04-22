%{
//#define DEBUG
#include "defines.h"
#include "node.h"
extern list<Node*> *Program;
extern int yylex ();
extern void yyerror (const char *msg);

%}

/*在 union 里声明 %token 可能有的类型*/
%union{
    long long  num;
    double doubleNum;
    std::string* str;
    Node * node;
    std::list<Node*> *list;
    winType* winTypeUnion;
}
/* A. 下面是从词法分析器传进来的 token ,其中大部分都是换名字符串*/
%token integerConstant  stringConstant      doubleConstant  IDENTIFIER
%token STRING     INT   DOUBLE  FLOAT       LONG    CONST   DEFINE MATRIX
%token WHILE      FOR   BREAK   CONTINUE    SWITCH  CASE DEFAULT IF ELSE DO RETURN
%token POUNDPOUND ICR   DECR    ANDAND      OROR    LS  RS LE GE EQ NE
%token MULTassign DIVassign     PLUSassign  MINUSassign MODassign
%token LSassign   RSassign ANDassign ERassign ORassign
    /* A.1 ----------------- COStream 特有关键字 ---------------*/
%token COMPOSITE  INPUT OUTPUT  STREAM    FILEREADER  FILEWRITER  ADD
%token PARAM      INIT  WORK    WINDOW    TUMBLING    SLIDING
%token SPLITJOIN  PIPELINE      SPLIT     JOIN        DUPLICATE ROUNDROBIN
%token SEQUENTIAL DENSE CONV2D MAXPOOLING2D AVERAGEPOOLING2D ACTIVATION DROPOUT
/* B.下面是语法分析器自己拥有的文法结构和类型声明 */

/* 语法分析器自己的结构 1. 文法一级入口*/
%type<list> translation_unit 
%type<node> external_definition
/* 语法分析器自己的结构   1.1.declaration */
%type<list> init_declarator_list
%type<node>init_declarator
%type<node>declarator
%type<node> declaration declaring_list stream_declaring_list 
%type<node> stream_type_specifier
%type<node> stream_declaration_list 
/* 语法分析器自己的结构     1.1.4.initializer */
%type<node> initializer initializer_list
/* 语法分析器自己的结构   1.2 function_definition 函数声明 */
%type<node> function_definition  parameter_declaration
%type<list> statement_list parameter_type_list
/* 语法分析器自己的结构   1.3 composite_definition 数据流计算单元声明 */
%type<node> composite_definition  composite_head  composite_head_inout
%type<node> composite_head_inout_member
%type<list> composite_head_inout_member_list
%type<node> operator_pipeline
/* 语法分析器自己的结构      1.3.2 composite_body */
%type<node> composite_body  composite_body_param_opt
/* 语法分析器自己的结构 2. composite_body_operator  composite体内的init work window等组件  */
%type<node> /*operator_file_writer*/  operator_add
%type<node> operator_splitjoin  split_statement
%type<node> roundrobin_statement   duplicate_statement  join_statement  operator_default_call
%type<list> argument_expression_list
/* 语法分析器自己的结构 3.statement 花括号内以';'结尾的结构是statement  */
%type<node> statement labeled_statement compound_statement
%type<node> expression_statement  selection_statement   iteration_statement jump_statement
/* 语法分析器自己的结构 4.exp 计算表达式头节点  */
%type<node> multi_expression primary_expression postfix_expression unary_expression conditional_expression assignment_expression constant_expression
%type<list> operator_arguments
%type<str>  assignment_operator unary_operator
%type<node> exp expression
%type<node> operator_selfdefine_body  operator_selfdefine_body_init operator_selfdefine_body_work
%type<node>  operator_selfdefine_window
%type<list> operator_selfdefine_body_window_list
%type<list> operator_selfdefine_window_list 
%type<winTypeUnion> window_type
/* 语法分析器自己的结构 5.basic 从词法TOKEN直接归约得到的节点 */
%type<str>basic_type_name type_specifier
%type<num> integerConstant
%type<doubleNum> doubleConstant
%type<str> stringConstant  IDENTIFIER ':' '{' '}' '(' ')' ';' '+' '-' '*' '/' '.' '^' '|' '&' '<' '>' '%' '~' '!'
%type<str> STRING     INT   DOUBLE  FLOAT       LONG    CONST   DEFINE MATRIX
%type<str> WHILE      FOR   BREAK   CONTINUE    SWITCH  CASE DEFAULT IF ELSE DO RETURN
%type<str> POUNDPOUND ICR   DECR    ANDAND      OROR    LS  RS LE GE EQ NE
%type<str> MULTassign DIVassign     PLUSassign  MINUSassign MODassign
%type<str> LSassign   RSassign ANDassign ERassign ORassign
    /* A.1 ----------------- COStream 特有关键字 ---------------*/
%type<str> COMPOSITE  INPUT OUTPUT  STREAM    FILEREADER  FILEWRITER  ADD
%type<str> PARAM      INIT  WORK    WINDOW    TUMBLING    SLIDING
%type<str> SPLITJOIN  PIPELINE      SPLIT     JOIN        DUPLICATE ROUNDROBIN

/* 语法分析器自己的结构 6. 深度学习扩展文法*/
%type<str> DENSE CONV2D MAXPOOLING2D AVERAGEPOOLING2D ACTIVATION DROPOUT
%type<node> operator_layer
/* 矩阵相关 */
%type<node> matrix_slice_pair matrix_slice vector_expression
%type<list> matrix_slice_pair_list
/* C. 优先级标记,从上至下优先级从低到高排列 */
%nonassoc IF_WITHOUT_ELSE
%nonassoc ELSE

%left OROR
%left ANDAND
%left '|'
%left '^'
%left '&'
%left EQ NE
%left '<' '>' LE GE
%left LS RS
%left '+' '-'
%left '*' '/' '%'

/* D. 语法分析器的起点和坐标声明 */
%start prog_start
%locations

%%
/************************************************************************/
/*              1. 文法一级入口,由下面三种文法组成                           */
/*                 1.1. declaration 声明                                 */
/*                 1.2. function_definition 函数声明                      */
/*                 1.3. composite_definition 数据流计算单元声明             */
/*************************************************************************/
prog_start: translation_unit { Program = $1; };

translation_unit:
          external_definition   { $$ = new list<Node*>({$1}); }
        | translation_unit external_definition  { $$->push_back($2); }
        ;
external_definition:
          declaration           {
                                      $$ = $1;
                                }
        | function_definition   {
                                      $$ = $1 ;
                                }
        | composite_definition  {
                                      $$ = $1 ;
                                }
        ;
/*************************************************************************/
/*              1.1 declaration 由下面2种文法+2个基础组件组成                */
/*                      1.1.1 declaring_list                             */
/*                      1.1.2 stream_declaring_list                      */
/*                      1.1.3 array                                      */
/*                      1.1.4 initializer                                */
/*************************************************************************/
declaration:
      declaring_list ';'        {
                                      line("Line:%-4d",&@$.first_line);
                                      debug ("declaration ::= declaring_list ';' \n");
                                      $$ = $1 ;
                                }
    | stream_declaring_list ';' {
                                      line("Line:%-4d",&@$.first_line);
                                      debug ("declaration ::= stream_declaring_list ';' \n");
                                      $$ = $1 ;
                                }
    ;
declaring_list:
          type_specifier   init_declarator_list  {
             $$ = new declareNode(&@$, *$1, $2);
          }
        ;
init_declarator_list:
      init_declarator                             { $$ = new list<Node*>({$1}); }
    | init_declarator_list ',' init_declarator    { $$->push_back($3); }
    ;
init_declarator:
      declarator                                  { $$ = new declarator(&@$,$1,NULL);      }
    | declarator '=' initializer                  { $$ = new declarator(&@$,$1,$3);        }
    ;
declarator:
      IDENTIFIER                                  { $$ = new idNode(&@$,*$1,NULL);    }
    | declarator '[' constant_expression ']'      {/* $1->arg_list->push_back_back($3);       */}
    | declarator '[' ']'                          {/* $1->isArray = 1;                  */}
    ;  
stream_declaring_list:
      stream_type_specifier IDENTIFIER            {/* $$ = NULL;  */}
    | stream_declaring_list ',' IDENTIFIER        {/* $$ = $1; */}
    ;

/*************************************************************************/
/*                      1.1.3 initializer                                */
/*************************************************************************/
initializer:
      assignment_expression
    | '{' initializer_list '}'                    {/* $$ = $2; */}
    | '{' initializer_list ',' '}'                {/* $$ = $2; */}
    ;
initializer_list:
      initializer                                 {/* $$ = new list<Node*>({$1}); */}
    | initializer_list ',' initializer            {/* $$ = $1->push_back($3); */}
    ;

/*************************************************************************/
/*              1.2 function_definition 函数声明                          */
/*                      1.2.1 parameter_type_list                        */
/*                      1.2.1 function_body                              */
/*************************************************************************/
function_definition:
      type_specifier declarator '(' parameter_type_list ')' compound_statement {/* $$ = new function_definition(&@$,$1,$2,$4,$6); */}
    | type_specifier declarator '(' ')' compound_statement {/* $$ = new function_definition(&@$,$1,$2,NULL,$5); */}
    ;

parameter_type_list:
      parameter_declaration                         {/* $$ = new list<Node*>({$1}); */  }
    | parameter_type_list ',' parameter_declaration {/* $$->push_back($3); */}
    ;

parameter_declaration:
      type_specifier declarator         {/* $$ = new declarator(&@$,$2); $$->type=$1; */}
    ;


/*************************************************************************/
/*              1.3 composite.definition 数据流计算单元声明                */
/*                      1.3.1 composite.head                             */
/*                      1.3.2 composite.body                             */
/*************************************************************************/
composite_definition:
      composite_head composite_body                         {/* $$ = new compositeNode(&@$,$1,$2); */}
    ;
composite_head:
      COMPOSITE IDENTIFIER '(' composite_head_inout ')'     {/* $$ = new compHeadNode(&@$,$2,$4);  */}
    ;
composite_head_inout:
      /*empty*/                                                                           {/* $$ = new ComInOutNode(&@$,NULL,NULL);; */}
    | INPUT composite_head_inout_member_list                                              {/* $$ = new ComInOutNode(&@$,$2);          */}
    | INPUT composite_head_inout_member_list ',' OUTPUT composite_head_inout_member_list  {/* $$ = new ComInOutNode(&@$,$2,$5);       */}
    | OUTPUT composite_head_inout_member_list                                             {/* $$ = new ComInOutNode(&@$,NULL,$2);*/}
    | OUTPUT composite_head_inout_member_list ',' INPUT composite_head_inout_member_list  {/* $$ = new ComInOutNode(&@$,$5,$2);       */}
    ;
composite_head_inout_member_list:
      composite_head_inout_member                                       {/* $$ = new list<Node*>({$1}); */  }                                    
    | composite_head_inout_member_list ',' composite_head_inout_member  {/* $$->push_back($3); */}                    
    ;
composite_head_inout_member:
      stream_type_specifier IDENTIFIER                                  {/* $$ = new inOutdeclNode(&@$,$1,$2); */}                      
    ;
stream_type_specifier:
      STREAM '<' stream_declaration_list '>'                            {/* $$ = $3; */}
    ;    
stream_declaration_list:
      type_specifier IDENTIFIER                                         {/* $$ = new strdclNode(&@$,$1,$2);              */}
    | stream_declaration_list ',' type_specifier IDENTIFIER             { 
                                                                              /*strTypeMember l;
                                                                              l.type = $3;
                                                                              l.identifier = $4;
                                                                              $$->id_list->push_back(l); */
                                                                        }
    ;
/*************************************************************************/
/*                      1.3.2 composite_body                             */
/*************************************************************************/
composite_body:
      '{' composite_body_param_opt statement_list '}'    {/* $$ = new compBodyNode(&@$,$2,$3); */}                     
    ;
composite_body_param_opt:
      /*empty*/                                                         {/* $$ = NULL; */}
    | PARAM parameter_type_list ';'                                     {/* $$ = new paramNode(&@$,$2);       */}
    ;
/*****************************************************************************/
/*        2. operator_add  composite体内的init work window等组件   */
/*             2_1   ADD operator_pipeline                                   */
/*             2_2   ADD operator_splitjoin                                  */
/*             2_3   ADD operator_default_call                               */
/*****************************************************************************/
operator_add:
          ADD operator_pipeline                             {/*  $$ = new addNode(&@$,$2); */}
        | ADD operator_splitjoin                            {/*  $$ = new addNode(&@$,$2); */}
        | ADD operator_layer                                {/*  $$ = new addNode(&@$,NULL); */}
        | ADD operator_default_call                         {/*  $$ = new addNode(&@$,$2); */}
        ;  

operator_pipeline:
          PIPELINE '{'  statement_list '}'
                                                            {/*
                                                                $$ = new pipelineNode(&@$,{
                                                                    compName: 'pipeline',
                                                                    inputs: undefined,
                                                                    body_stmts: $3
                                                                })*/
                                                            }    
        ;
operator_splitjoin:
          SPLITJOIN '{' split_statement  statement_list  join_statement '}'     
                                                            {/*
                                                                $$ = new splitjoinNode(&@$,{
                                                                    compName: 'splitjoin',
                                                                    inputs: undefined,
                                                                    stmt_list: undefined,
                                                                    split: $3,
                                                                    body_stmts: $4,
                                                                    join: $5
                                                                })*/
                                                            }
        | SPLITJOIN '{' statement_list split_statement statement_list join_statement '}'  
                                                            {/*
                                                                $$ = new splitjoinNode(&@$,{
                                                                    compName: 'splitjoin',
                                                                    inputs: undefined,
                                                                    stmt_list: $3,
                                                                    split: $4,
                                                                    body_stmts: $5,
                                                                    join: $6
                                                                })*/
                                                            }
        ;
split_statement:
          SPLIT duplicate_statement                         {/* $$ = new splitNode(&@$,$2);     */}          
        | SPLIT roundrobin_statement                        {/* $$ = new splitNode(&@$,$2);     */}
        ;
roundrobin_statement:
          ROUNDROBIN '(' ')' ';'                            {/* $$ = new roundrobinNode(&@$);   */}
        | ROUNDROBIN '(' argument_expression_list ')' ';'   {/* $$ = new roundrobinNode(&@$,$3);*/}
        ;
duplicate_statement:
          DUPLICATE '('  ')' ';'                            {/* $$ = new duplicateNode(&@$);    */}
        | DUPLICATE '(' exp ')'  ';'                        {/* $$ = new duplicateNode(&@$,$3); */}
        ;
join_statement:
          JOIN roundrobin_statement                         {/* $$ = new joinNode(&@$,$2);      */}
        ;
operator_default_call:
          IDENTIFIER  '(' ')' ';'                           {/* $$ = new compositeCallNode(&@$,$1);    */}
        | IDENTIFIER  '(' argument_expression_list ')' ';'  {/* $$ = new compositeCallNode(&@$,$1,NULL,$3); */}
        ;  
operator_layer:      
          DENSE  '(' argument_expression_list ')' ';'       { /* $$ = new denseLayerNode(&@$,"dense", $3); */}
        | CONV2D '(' argument_expression_list ')' ';'       { /* $$ = new conv2DLayerNode(&@$,"conv2D", $3);  */}
        | MAXPOOLING2D '(' argument_expression_list ')' ';'     { /* $$ = new maxPooling2DLayerNode(&@$,"maxPooling2D", $3);  */}
        | AVERAGEPOOLING2D '(' argument_expression_list ')' ';' { /* $$ = new averagePooling2DLayerNode(&@$,"averagePooling2D", $3);  */}
        | ACTIVATION '(' argument_expression_list ')' ';'       { /* $$ = new activationLayerNode(&@$,"activation", $3);  */}
        ; 
/*************************************************************************/
/*        3. statement 花括号内以';'结尾的结构是statement                    */
/*************************************************************************/    
statement:
      labeled_statement
    | compound_statement
    | expression_statement
    | selection_statement
    | iteration_statement
    | jump_statement
    | declaration
    | operator_add
    ;
labeled_statement:
      CASE constant_expression ':' statement    {/* $$ = new labeled_statement(&@$,$1,$2,$4);*/}
    | DEFAULT ':' statement                     {/* $$ = new labeled_statement(&@$,$1,NULL,$3);*/}
    ;
compound_statement: 
      '{' '}'                                   {/* $$ = new blockNode(&@$,NULL); */} 
    | '{' statement_list '}'                    {/* $$ = new blockNode(&@$,$2); */}
    ;
statement_list:
      statement                {/* $$ = $1 ? new list<Node*>() : new list<Node*>({$1});*/ }
    | statement_list statement {/* if($2) $$->push_back($2);    */}
    ;
expression_statement:
      ';'                       {/* $$ = NULL; */}
    | multi_expression ';'      {/* $$ = $1; */}
    ;
selection_statement:
      IF '(' expression ')' statement %prec IF_WITHOUT_ELSE 
      {/* $$ = new selection_statement(&@$,$1,$3,$5);        */}
    | IF '(' expression ')' statement ELSE statement
      {/* $$ = new selection_statement(&@$,$1,$3,$5,$7);  */}
    | SWITCH '(' expression ')' statement
      {/* $$ = new selection_statement(&@$,$1,$3,$5);        */}
    ;
iteration_statement:
      WHILE '(' expression ')' statement 
      {/* $$ = new whileNode(&@$,$3,$5); */}
    | DO statement WHILE '(' expression ')' ';' 
      {/* $$ = new doNode(&@$,$5,$2);    */}
    | FOR '(' expression_statement expression_statement ')' statement
      {/* $$ = new forNode(&@$,$3,$4,undefined,$6);    */}
    | FOR '(' expression_statement expression_statement expression ')' statement
      {/* $$ = new forNode(&@$,$3,$4,$5,$7); */}
    ;
jump_statement:
      CONTINUE ';'          {/* $$ = new jump_statement(&@$,$1); */}
    | BREAK ';'             {/* $$ = new jump_statement(&@$,$1); */}
    | RETURN ';'            {/* $$ = new jump_statement(&@$,$1); */}
    | RETURN expression ';' {/* $$ = new jump_statement(&@$,$1,$2); */}
    ;    

/*************************************************************************/
/*        4. expression 计算表达式头节点                                    */
/*            4.1 矩阵的常量节点                                            */
/*************************************************************************/
matrix_slice_pair:
        ':'                    {/* $$ = new matrix_slice_pair(&@$,undefined, ':');   */} 
    |   expression             {/* $$ = new matrix_slice_pair(&@$,$1);               */}     
    |   exp ':'                {/* $$ = new matrix_slice_pair(&@$,$1,':');           */}
    |   ':' exp                {/* $$ = new matrix_slice_pair(&@$,undefined,':',$2); */}
    |   exp ':' exp            {/* $$ = new matrix_slice_pair(&@$,$1,':',$3);        */}
    ;
matrix_slice_pair_list:
        matrix_slice_pair                               {/* $$ = new list<Node*>({$1}); */}
    |   matrix_slice_pair_list ',' matrix_slice_pair    {/* $$->push_back($3); */}
    ;
matrix_slice:
      '[' matrix_slice_pair_list ']'                    {/* $$ = $2; */}
    ;
/*************************************************************************/
/*            4.2 expression 其他节点                                     */
/*************************************************************************/
vector_expression:
      '[' multi_expression ']'      {/* $$ = new matrix_constant(&@$, $2); */}
    ;
multi_expression:
      expression                    {/* $$ = new list<Node*>({$1}); */}
    | multi_expression ',' expression    {/* $$->push_back($3); */}
    ;
primary_expression:
      IDENTIFIER                 {/* $$ = new stringNode(&@$,$1);  */}
    | integerConstant            { $$ = new constantNode(&@$,$1); }
    | doubleConstant             {/* $$ = new constantNode(&@$,$1); */}
    | stringConstant             {/* $$ = new constantNode(&@$,$1); */}
    | '(' multi_expression ')'   {/* $$ = new parenNode(&@$,$2);    */}
    | vector_expression 
    ;
operator_arguments:
      '(' ')'               {/* $$ = new list<Node*>(); */}
    | '(' argument_expression_list ')' {/* $$ = $2; */}
    ;
postfix_expression:
      primary_expression     
    | postfix_expression matrix_slice                       {/* $$ = new matrix_section(&@$,$1,$2); */}    
    | postfix_expression operator_arguments                 { /*
                                                                if($$ instanceof callNode){
                                                                    $$ = new compositeCallNode(&@$,$1.name,$1.arg_list,$2)
                                                                }         
                                                                else{
                                                                    $$ = new callNode(&@$,$1,$2)
                                                                }*/
                                                            }
    | MATRIX '.' IDENTIFIER                                 {/* $$ = new lib_binopNode(&@$,$1,$3); */}
    | postfix_expression '.' IDENTIFIER                     {/* $$ = new binopNode(&@$,$1,$2,$3); */}
    | postfix_expression ICR                                { $$ = new unaryNode(&@$,"r++",$1);    }
    | postfix_expression DECR                               { $$ = new unaryNode(&@$,"r--",$1);    }
    | FILEREADER '(' ')' '(' stringConstant ')'             {/* error("暂不支持FILEREADER");      */}
    | postfix_expression operator_arguments operator_selfdefine_body       
                                                            {
                                                               /* $$ = new operatorNode(&@$,$1,$2,$3)*/
                                                            } 
    |  SPLITJOIN '(' argument_expression_list ')'  '{' split_statement statement_list  join_statement '}'  
                                                            {/*
                                                                $$ = new splitjoinNode(&@$,{
                                                                    compName: 'splitjoin',
                                                                    inputs: $3,
                                                                    stmt_list: undefined,
                                                                    split: $6,
                                                                    body_stmts: $7,
                                                                    join: $8
                                                                })*/
                                                            }
    |  SPLITJOIN '(' argument_expression_list ')'  '{' statement_list split_statement statement_list  join_statement '}'
                                                            {/*
                                                                $$ = new splitjoinNode(&@$,{
                                                                    compName: 'splitjoin',
                                                                    inputs: $3,
                                                                    stmt_list: $6,
                                                                    split: $7,
                                                                    body_stmts: $8,
                                                                    join: $9
                                                                })*/
                                                            }
    |   PIPELINE '(' argument_expression_list ')'  '{' statement_list '}'
                                                            {/*
                                                                $$ = new pipelineNode(&@$,{
                                                                    compName: 'pipeline',
                                                                    inputs: $3,
                                                                    body_stmts: $6
                                                                })*/
                                                            }
    |   SEQUENTIAL '(' argument_expression_list ')' '(' argument_expression_list ')' '{' statement_list '}' 
                                                            {/*
                                                                $$ = new sequentialNode(&@$,{
                                                                    compName: 'squential',
                                                                    inputs: $3,
                                                                    arg_list: $6,
                                                                    body_stmts: $9
                                                                })*/
                                                            }                                                        
    ;

argument_expression_list:
      assignment_expression                                 {/* $$ = new list<Node*>({$1}); */  }
    | argument_expression_list ',' assignment_expression    {/* $$->push_back($3); */}
    ;

unary_expression:
      postfix_expression                
    | ICR unary_expression              { $$ = new unaryNode(&@$,"++",$2); }
    | DECR unary_expression             { $$ = new unaryNode(&@$,"--",$2); }
    | unary_operator unary_expression   { $$ = new unaryNode(&@$,*$1,$2); }
    | '(' basic_type_name ')' unary_expression    {/* $$ = new castNode(&@$,$2,$4); */}
    ;

unary_operator:
      '+'  { $$ = new string("+"); }
    | '-'  { $$ = new string("-"); }
    | '~'  { $$ = new string("~"); }
    | '!'  { $$ = new string("!"); }
    ;

exp:
      unary_expression
    | exp '*' exp   { $$ = new binopNode(&@$,$1,"*",$3); }
    | exp '/' exp   { $$ = new binopNode(&@$,$1,"/",$3); }
    | exp '+' exp   { $$ = new binopNode(&@$,$1,"+",$3); }
    | exp '-' exp   { $$ = new binopNode(&@$,$1,"-",$3); }
    | exp '%' exp   { $$ = new binopNode(&@$,$1,"%",$3); }
    | exp '^' exp   { $$ = new binopNode(&@$,$1,"^",$3); }
    | exp '|' exp   { $$ = new binopNode(&@$,$1,"|",$3); }
    | exp '&' exp   { $$ = new binopNode(&@$,$1,"&",$3); }
    | exp '<' exp   { $$ = new binopNode(&@$,$1,"<",$3); }
    | exp '>' exp   { $$ = new binopNode(&@$,$1,">",$3); }
    | exp LE exp        { $$ = new binopNode(&@$,$1,"<=",$3); }
    | exp GE exp        { $$ = new binopNode(&@$,$1,">=",$3); }
    | exp EQ exp        { $$ = new binopNode(&@$,$1,"==",$3); }
    | exp NE exp        { $$ = new binopNode(&@$,$1,"!=",$3); }
    | exp LS exp        { $$ = new binopNode(&@$,$1,"<<",$3); }
    | exp RS exp        { $$ = new binopNode(&@$,$1,">>",$3); }
    | exp OROR exp      { $$ = new binopNode(&@$,$1,"||",$3); }
    | exp ANDAND exp    { $$ = new binopNode(&@$,$1,"&&",$3); }
    ;

conditional_expression:
      exp
    | exp '?' expression ':' expression {/* $$ = new ternaryNode(&@$,$1,$3,$5); */}
    ;

assignment_expression:
      conditional_expression
    | unary_expression assignment_operator assignment_expression    
      {/*
          list<string> operNames({"splitjoinNode","pipelineNode","compositeCallNode","operatorNode","sequentialNode"});
          for(auto name : operNames){
            if(name == $3->ctor){
              if($1->ctor == "parenNode"){
                  ((operNode*)$3)->outputs = ((parenNode*)$1)->exp;
              }else if($1->ctor = "stringNode"){
                  ((operNode*)$3)->outputs = new list<Node*>({$1});
              }else{
                  cout<<"只支持 S = oper()() 或 (S1,S2) = oper()() 两种方式";
              }
            }
          }
          $$ = new binopNode(&@$,$1,$2,$3) ;*/
      }
    ;
assignment_operator:
          '='             { $$ = new string("=")  ; }
        | MULTassign      { $$ = new string("*=") ; }
        | DIVassign       { $$ = new string("/=") ; }
        | MODassign       { $$ = new string("%=") ; }
        | PLUSassign      { $$ = new string("+=") ; }
        | MINUSassign     { $$ = new string("-=") ; }
        | LSassign        { $$ = new string("<<=") ; }
        | RSassign        { $$ = new string(">>=") ; }
        | ANDassign       { $$ = new string("&=") ; }
        | ERassign        { $$ = new string("^=") ; }
        | ORassign        { $$ = new string("|=") ; }
        ;
expression:
      assignment_expression {/* $$ = $1; */}
    ;

constant_expression:
      conditional_expression
    ;
/*************************************************************************/
/*        4.1 postfix_operator COStream 的 operator 表达式                */
/*************************************************************************/
operator_selfdefine_body:
       '{' operator_selfdefine_body_init operator_selfdefine_body_work operator_selfdefine_body_window_list '}'
       {
           //$$ = new operBodyNode(&@$,NULL,$2,$3,$4);
       }
     | '{' statement_list operator_selfdefine_body_init  operator_selfdefine_body_work operator_selfdefine_body_window_list '}'
       {
           //$$ = new operBodyNode(&@$,$2,$3,$4,$5);
       }
     ;    
operator_selfdefine_body_init:
      /*empty*/ { }
    | INIT compound_statement {/* $$ = $2; */}
    ;
operator_selfdefine_body_work:
      WORK compound_statement {/* $$ = $2; */}
    ;
operator_selfdefine_body_window_list:
      /*empty*/  {  }                
    | WINDOW '{' operator_selfdefine_window_list '}'  { $$ = $3; }
    ;
operator_selfdefine_window_list:
      operator_selfdefine_window                                    {/* $$ = new list<Node*>({$1});*/ }
    | operator_selfdefine_window_list operator_selfdefine_window    {/* $$->push_back($2); */}
    ;
operator_selfdefine_window:
      IDENTIFIER window_type ';'                       {/* $$ = new winStmtNode(&@$,$1,$2); */}
    ;
window_type:
      SLIDING '('  ')'                                 {/* winType w; w.type = $1; $$ = w; */}
    | TUMBLING '('  ')'                                {/* winType w; w.type = $1; $$ = w; */}       
    | SLIDING '(' argument_expression_list ')'         {/* winType w; w.type = $1; w.arg_list = $3; $$ = w;*/}
    | TUMBLING '(' argument_expression_list ')'        {/* winType w; w.type = $1; w.arg_list = $3; $$ = w; */} 
    ;     
/*************************************************************************/
/*        5. basic 从词法TOKEN直接归约得到的节点,自底向上接入头部文法结构        */
/*************************************************************************/
type_specifier:
          basic_type_name        
        | CONST basic_type_name  { $$ = new string("const "+*$2); }
        ;
basic_type_name:
          INT        { $$ = new string("int");       }
        | LONG  
        | LONG LONG  { $$ = new string("long long"); }
        | FLOAT 
        | DOUBLE
        | STRING
        | MATRIX
        ;
%%
/* ----语法树结束----*/
void yyerror (const char *msg)
{
    Error(msg,yylloc.first_line,yylloc.first_column);
}
