#ifndef _NODETYPE_H_
#define _NODETYPE_H_

typedef enum{
/*expression nodes*/
constant=1,Id,Binop,Unary,Cast,Ternary,Initializer,
/*statement nodes*/
Labels,Switch,Case,Default,If,IfElse,While,Do,For,Continue,
Break,Return,Block,Paren,//Paren是啥？
/*type nodes*/
primary,
/*array*/
Array,
/*declaration node*/
Decl,
/*function*/
FuncDcl,Call,
/*SPL node*/
StrDcl,
Compdcl,
Composite,
ComInOut,
InOutdcl,
CompHead,
CompBody,
Param,
ParamDcl,
OperBody,
OperHead,
Operator_,
Window,
WindowStmt,
Sliding,
Tumbling,

/*New for SPL*/
CompositeCall,
Pipeline,
SplitJoin,
Split,
Join,
RoundRobin,
Duplicate,
Add
}NodeType;

#endif