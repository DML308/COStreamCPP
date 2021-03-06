#ifndef _NODE_H_
#define _NODE_H_
#include "global.h"
#include "nodetype.h"
#include "defines.h"
#include <list>
#include <vector>

class Node
{
    public:
    NodeType type;
    YYLTYPE *loc;
    short pass;
    Node()
    {
        loc=new YYLTYPE();
    }
    virtual ~Node()
    {
        delete loc;
    }
    void setLoc(YYLTYPE loc);
    virtual void print()=0;
    virtual string toString()=0;
};

string listToString(list<Node *>list);

class  primNode: public Node
{
public:
    string name;
    bool isConst;
     primNode(string str,YYLTYPE loc=YYLTYPE()):name(str),isConst(false)
     {
         this->type=primary;
         setLoc(loc);
     }
    ~primNode() {}
    void print(){cout<<"primNodeType:"<< name <<endl;
    string toString();
};

class constantNode:public Node
{
    public:
    string style;
    string sval;
    double  dval;
    long long llval;
    constantNode(string type,string str,YYLTYPE loc=YYLTYPE()):style(type),sval(str)
    {
        setLoc(loc);
        this->type=constant;
    }
    constantNode(string type,long long l,YYLTYPE loc=YYLTYPE()):style(type),llval(l)
    {
        setLoc(loc);
        this->type=constant;
    }
    constantNode(string type,double d,YYLTYPE loc=YYLTYPE()):style(type),dval(d)
    {
        setLoc(loc);
        this->type=constant;
    }
    ~constantNode(){}
    void print(){ cout<<"constant: "<<type<<endl;}
    string toString();
};

/*expNode向前声明*/
class expNode;

class idNode:public Node
{
    public:
    string name;
    string valTyle;
    list<Node *> arg_list;
    Node *init;
    int level;
    int version;
    int isArray;//是否为数组
    int isStream;//是否为stream复杂型
    int isParam;//是否是function 或composite的输入参数
    idNode(string name,YYLTYPE loc=YYLTYPE()):name(name),isArray(0),isStream(0),isParam(0)
    {
        this->type=Id;
        setLoc(loc);
        this->level=Level;
        this->version=current_version[Level];
        this->valTyle="int";
    }

    idNode(string *name,YYLTYPE loc=YYLTYPE())
    {
        new (this) idNode(*name,loc);
    } 
    ~idNode(){}
    void print(){}
    string toString();
};

class initNode:public Node
{
    public:
    list<Node *> value;
    initNode(Node *node,YYLTYPE loc=YYLTYPE())
    {
        value.push_back(node);
        this.type=Initializer;
        setLoc(loc);
    }
    ~initNode(){}
    void print(){}
    string toString();
};

class  functionNode:public Node
{
    public:
    functionNode(){}
    ~ functionNode(){}
};

class expNode:public Node
{
    public:
    expNode(){}
    ~expNode(){}
    void print(){}
    string toString(){};
};

class arrayNode:public Node
{
    public:
    list<Node *>arg_list;
    arrayNode(expNode *exp,YYLTYPE loc=YYLTYPE())
    {
        //exp为NULL,也要push？？
        arg_list.push_back(exp);
        setLoc(loc);
    }
    ~arrayNode(){}
    void print(){}
    string toString(){return string("arrayNode");}
};

class declareNode: public Node
{
    public:
    primNode *prim;
    list<idNode *> id_list;
    declareNode(primNode *prim,idNode *id,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Decl;
        this->prim=prim;
        if(id)
        this->id_list.push_back(id);
    }
    ~declareNode(){}
    void print(){}
    string toString();
};

class unaryNode:public Node
{
    public:
    expNode *exp;
    string op;
    unaryNode(string op,expNode *exp,YYLTYPE loc=YYLTYPE())
    {
        setLoc(loc);
        this->exp=exp;
        this->op=op;
    }
    ~unaryNode(){}
    void print(){}
    string toString();
};

class binopNode:public Node
{
    public:
    expNode *left;
    expNode *right;
    string op;
    binopNode(expNode *left,string op,expNode *right,YYLTYPE loc=YYLTYPE())
    {
        this->type=Binop;
        setLoc(loc);
        this->left=left;
        this->right=right;
        this->op=op;
    }
    ~binopNode(){}
    void print(){}
    string toString();
};

class ternaryNode:public Node
{
    public:
    expNode *first;
    expNode *second;
    expNode *third;
    ternaryNode(expNode *first,expNode *second,expNode *third,YYLTYPE loc=YYLTYPE())
    {
        setLoc(loc);
        this->type=Ternary;
        this->first=first;
        this->second=second;
        this->third=third;
    }
    ~ternaryNode(){}
    void print(){}
    string toString();
};
class parenNode:public Node
{
    public:
    expNode *exp;
    parenNode(expNode *exp,YYLTYPE loc=YYLTYPE())
    {
        setLoc(loc);
        this->type=Paren;
        this->exp=exp;
    }
    ~parenNode(){}
    void print(){}
    string toString();
};

class  castNode:public Node
{
    public:
    primNode *prim;
    expNode *exp;
    castNode(primNode *prim,expNode *exp,YYLTYPE loc=YYLTYPE())
    {
        setLoc(loc);
        this->type=Cast;
        this->prim=prim;
        this->exp=exp;
    }
    ~castNode(){}
    void print(){}
    string toString();
};

//switch()  case：
class  caseNode:public Node
{
    public:
    expNode *exp;
    Node *stmt;
    caseNode(expNode *exp,Node *stmt,YYLTYPE loc=YYLTYPE())
    {
        setLoc(loc);
        this->type=Case;
        this->exp=exp;
        this->stmt=stmt;
    }
    ~caseNode(){}
    void print(){}
    string toString();
};

class defaultNode:public Node
{
    public:
    Node *stmt;
    defaultNode(Node *stmt,YYLTYPE loc=YYLTYPE())
    {
         setLoc(loc);
         this->type=Default;
         this->stmt=stmt;
    }
    ~defaultNode(){}
    void print(){}
    string toString();
};

class continueNode:public Node
{
    public:
    continueNode(YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Continue;
    }
    ~continueNode(){}
    void print(){}
    string toString(){ return "continue;";}
};

class breakNode:public Node
{
    public:
    breakNode(YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Break;   
    }
    ~breakNode(){}
    void print(){}
    string toString(){return "break;";}
};

class returnNode:public Node
{
    public:
    expNode *exp:
    returnNode(expNode *exp,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Return;
        this->exp=exp;
    }
    ~returnNode(){}
    void print(){}
    string toString();
};

class ifNode:public Node
{
    public:
    expNode *exp;
    Node *stmt;
    ifNode(expNode *exp,Node *stmt,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=If;
        this->exp=exp;
        this->stmt=stmt;
    }
    ~ifNode(){}
    void print(){}
    string toString();
};

class ifElseNode: public Node
{
    public:
    expNode *exp;
    Node *stmt1;
    Node *stmt2;
    ifElseNode(expNode *exp,Node *stmt1,Node *stmt2,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=IfElse;
        thid->exp=exp;
        this->stmt1=stmt1;
        this->stmt2=stmt2;
    }
    ~ifElseNode(){}
    void print(){}
    string toString();
};

class switchNode:public Node
{
    public:
    expNode *exp;
    Node *stat;
    switchNode(expNode *exp,Node *stat,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Switch;
        this->exp=exp;
        this->stat=stat;
    }
    ~switchNode(){}
    void print(){}
    string toString();
};

class whileNode:public Node
{
    public:
    expNode *exp;
    Node *stmt;
    whileNode(expNode *exp,Node *stmt,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=While;
        this->exp=exp;
        this->stmt=stmt;
    }
    ~whileNode(){}
    void print(){}
    string toString();
};

class doNode:public Node
{
    public:
    expNode *exp;
    Node *stmt;
    doNode(Node *stmt,expNode *exp,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Do;
        this->exp=exp;
        this->stmt=stmt;
    }
    ~doNode(){}
    void print(){}
    string toString();
};

class forNode:public Node
{
    public:
    Node *init;
    /*init 可以是declaration*/
    expNode *cond;
    Node *stmt;
    forNode(Node *init,expNode *cond,expNode *next,Node *stmt,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=For;
        this->init=init;
        this->cond=cond;
        this->next=next;
        this->stmt=stmt;
    }
    void print(){}
    string toString();
};

class blockNode:public Node
{
    public:
    list<Node *> stmt_list;
    YYLTYPE right;
    blockNode(list<Node *> *stmt_list,YYLTYPE left=YYLTYPE(),YYLTYPE right=YYLTYPE())
    {
        this->setLoc(left);
        this->right;
        this->type=Block;
        if(stmt_list)
        this->stmt_list=*stmt_list;
    }
    ~blockNode(){}
    void print(){}
    string toString();
};

class compositeNode;
class pipelineNode: public Node
{
    public:
    list<Node *> *outputs;
    list<Node *> *inputs;
    list<Node *> *body_stmts;
    compositeNode *replace_composite;
    pipelineNode(list<Node *> *outputs,list<Node *> *inputs,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Pipeline;
        this->outputs=outputs;
        this->inputs=inputs;
        this->body_stmts=body_stmts;
        this->replace_composite=NULL;
    }
    ~pipelineNode(){}
    void print(){}
    string toString()
    {
        return "pipelineNode";
    }
};

class roundrobinNode:public Node
{
    public:
    list<Node *> *arg_list;
    roundrobinNode(list<Node *> *arg_list,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=RoundRobin;
        this->arg_list=arg_list;
    }
    ~roundrobinNode(){}
    void print(){}
    string toString(){};
};

class duplicateNode:public Node
{
    public:
    expNode *exp;
    duplicateNode(expNode *exp,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Duplicate;
        this->exp=exp;
    }
    ~duplicateNode(){}
    void print(){}
    string toString(){}
};

class splitNode:public Node
{
    public:
    Node *dup_round;
    splitNode(Node *dup_round,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Split;
        this->dup_round=dup_round;  
    }
    ~splitNode(){}
    void print(){}
    string toString(){}
};

class joinNode:public Node
{
    public:
    roundrobinNode  *rdb;
    joinNode(roundrobinNode *rdb,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=join;
        this->rdb=rdb;
    }
    ~joinNode(){}
    void print(){}
    string toString(){}
};

class splitjoinNode:public Node
{
    public:
    list<Node *> *outputs;
    list<Node *> *inputs;
    splitNode *split;
    joinNode *join;
    list<Node *> *stmt_list;
    list<Node *> *body_stmts;
    compositeNode *replace_composite;
    splitjoinNode(list<Node *> *inputs,
                  list<Node *> *outputs,
                  splitNode *split,
                  list<Node *> *stmt_list,
                  list<Node *> *body_stmts,
                  joinNode *join,
                  YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=SplitJoin;
        this->inputs=inputs;
        this->outputs=outputs;
        this->split=split;
        this->join=join;
        this->stmt_list=stmt_list;
        this->body_stmts=body_stmts;
        this->replace_composite=NULL;
    }
    ~splitjoinNode(){}
    void print(){}
    string toString(){return "splitjoinNode";}
};

class addNode:public Node
{
    public:
    Node *content;
    addNode(Node *content,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Add;
        this->content=content;
    }
    ~addNode(){}
    void print(){}
    string toString(){}
};

class slidingNode:public Node
{
    public:
    list<Node *> *arg_list;
    slidingNode(list<Node *> *arg_list,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Sliding;
        this->arg_list=arg_list;
    }
    ~slidingNode(){}
    void print(){}
    string toString(){}
};

class tumblingNode:public Node
{
    public:
    list<Node *> *arg_list;
    tumblingNode(list<Node *> *arg_list,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Tumbling;
        this->arg_list=arg_list;
    }
    ~tumblingNode(){}
    void print(){}
    string toString(){}
};

class strdclNode:public Node
{
    public:
    list<idNode *> id_list;
    strdclNode(idNode *id,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=StrDcl;
        if(id)
            id_list.push_back(id);
    }
    ~strdclNode(){}
    void print(){}
    string toString(){}
}

class winStmtNode:public Node
{
    public:
    Node *winType;
    string winName;
    winStmtNode(string winName,Node *winType,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=WindowStmt;
        this->winName=winName;
        this->winType=winType;
    }
    ~winStmtNode(){}
    void print(){}
    string toString(){}

};

class windowNode:public Node
{
    public:
    list<Node *> *win_list;
    windowNode(list<Node *> *win_list)
    {
        this->type=Window;
        this->win_list=win_list;
    }
    ~windowNode(){}
    void print(){}
    string toString(){}
};

class paramNode;
class operBodyNode:public Node
{
    public:
    paramNode *param;
    list<Node *> stmt_list;
    Node *init;
    Node *work;
    windowNode *win;
    operBodyNode(list<Node *> *stmt_list,Node  *init,Node *work,windowNode *win)
    {
        this->type=operBody;
        if(stmt_list){this->stmt_list=*stmt_list;}
        this->init=init;
        this->work=work;
        this->win=win;
    }
    ~operBodyNode(){}
    void print(){}
    string toString(){return "operBodyNode";}
;}

class callNode:public Node
{
    public:
    string name;
    list<Node *> arg_list;
    callNode(string name,list<Node *> *arg_list,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=Call;
        this->name=name;
        if(arg_list)
            this->arg_list=*arg_list;
    }
    callNode(string *name,list<Node *> *arg_list,YYLTYPE loc=YYLTYPE())
    {
        new (this) callNode(*name,arg_list,loc);
    }
    ~callNode(){}
    void print(){}
    string toString(){};
};

class inOutdeclNode:public Node
{
    public:
    Node *strType;
    idNode *id;
    inOutdeclNode(Node *strType,idNode *id,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=InOutdcl;
        this->strType=strType;
    }
    ~inOutdeclNode(){}
    void print(){}
    string toString(){}
};

class ComInOutNode:public Node
{
    public:
    list<Node *> *input_List;
    list<Node *> *output_List;
    ComInOutNode(list<Node *> *input_list,list<Node *> *output_list,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=ComInOut;
        this->input_List= input_list;
        this->output_List=output_list;
    }
    ~ComInOutNode(){}
    void print(){}
    string toString(){}
};

class paramDeclNode:public Node
{
    public:
    primNode *prim;
    idNode *id;
    paramDeclNode(idNode *id,arrayNode *adcl,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=ParamDcl;
        this->prim=prim;
        this->id=id;
    }
    ~paramDeclNode(){}
    void print(){}
    string toString(){}
};
class paramNode : public Node
{
    public:
    list<Node *> *param_list;
    paramNode(list<Node *> *param_list)
    {
        this->type=Param;
        this->param_list=param_list;
    }
    ~paramNode(){}
    void print(){}
    string toString(){}
};

class funcBodyNode: public Node
{
    public:
    list<Node *> *stmt_list;
    funcBodyNode(list<Node *> *stmt_list)
    {
        this->stmt_list=stmt_list;
    }
    ~funcBodyNode(){}
    void print(){}
    string toString();
}

class compBodyNode:public Node
{
    public:
    paramNode *param;
    list<Node *> *stmt_List;
    compBodyNode(paramNode *param,list<Node *> *stmt_list)
    {
        this->type=CompBody;
        this->param=param;
        this->stmt_list=stmt_list;
    }
    compBodyNode(compBodyNode &body)
    {
        this->type=CompBody;
        this->param=body.param;
        this->stmt_List=new list<Node *>();
        *(this->stmt_List)=*(body.stmt_List);
    }
    ~compBodyNode(){}
    void print(){}
    string toString(){}
};

class funcDclNode:public Node
{
    public:
    primNode *prim;
    string name;
    list<Node *> param_list;
    funcBodyNode *funcBody;
    funcDclNode(primNode *prim,string *name,list<Node *> *param_list,funcBodyNode *funcBody)
    {
        this->type=FuncDcl;
        this->prim=prim;
        this->name=*name;
        if(param_list)
            this->param_list=*param_list;
        this->funcBody=funcBody;    
    }
    ~funcDclNode(){}
    void print(){}
    string toString(){}
};

class compositeCallNode:public Node
{
    public:
    string compName;
    list<Node *> *stream_list;
    list<Node *> *inputs;
    list<Node *> *outputs;
    compositeCallNode *actual_composite;
    compositeCallNode(list<Node *> *outputs,string compName,list<Node *> *stream_List,list<Node *> *inputs,compositeNode *actual_composite,YYLTYPE loc=YYLTYPE())
    {
        this->setLoc(loc);
        this->type=CompositeCall;
        this->compName=compName;
        this->inputs=inputs;
        this->actual_composite=actual_composite;
    }
    ~compositeCallNode(){}
    void print(){}
    string toString(){}
};

class compHeadNode:public Node
{
    public:
    string compName;
    ComInOutNode *inout;
    compHeadNode(string compName,ComInOutNode *inout)
    {
        this->type=CompHead;
        this->compName=compName;
        this->inout=inout;
    }
    ~compHeadNode(){}
    void print(){}
    string toString(){}
};

class compositeNode:public Node
{
    public:
    compHeadNode *head;
    compBodyNode *body;
    string compName;
    compositeNode(compHeadNode *head,compBodyNode *body)
    {
        this->type=Composite;
        this->head=head;
        this->body=body;
        this->compName=head->compName;
    }
    ~compositeNode(){}
    void print(){}
    string toString(){}
};

class operatorNode:public Node
{
    public:
    string operName;
    list<Node *> *inputs;
    list<Node *> *outputs;
    operBodyNode *operBody;
    operatorNode(list<Node *> *outputs,string operName,list<Node *> *inputs,operBodyNode *operBody)
    {
        this->type=Operator_;
        this->outputs=outputs;
        this->operName=operName;
        this->inputs=inputs;
        this->operBody=operBody;
    }
    ~operatorNode(){}
    void print(){}
    string toString();
};
#endif 