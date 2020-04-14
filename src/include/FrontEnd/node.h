#ifndef _NODE_H_
#define _NODE_H_
#include "global.h"
#include "defines.h"
#include <list>
#include <vector>

class SymbolTable;

class Node{
  public:
    string ctor;
    YYLTYPE *loc;
    Node(){
        loc = new YYLTYPE();
    }
    Node(YYLTYPE * loc){
        this->loc = new YYLTYPE();
        this->setLoc(loc);
    }
    virtual ~Node(){
        delete loc;
    }
    void setLoc(YYLTYPE * loc);
    virtual string toString(){ return "该 Node 的 toString 还未实现:" + this->ctor; }
    virtual Node * getCopy(){ return NULL; };
};

string listToString(list<Node *> list);
/********************************************************/
/*        4. expression 计算表达式头节点                   */
/********************************************************/
class expNode : public Node{
  public:
    virtual double getValue() { return 0; };
    expNode(YYLTYPE * loc): Node(loc){ }
};
class unaryNode: public expNode{
  public:
    string op;// 默认在左边, - + ~ ! -- ++, 若有在右边的, 标记为 r++, r--
    Node* exp;
    unaryNode(YYLTYPE*loc, string op, Node*exp):expNode(loc){
      this->ctor = "unaryNode";
      this->op = op;
      this->exp = exp;
    }
    string toString();
};
class binopNode: public expNode{
  public:
    Node* left;
    string op;
    Node* right;
    binopNode(YYLTYPE*loc, Node*left,string op,Node*right): expNode(loc){
      this->ctor = "binopNode";
      this->left = left;
      this->op = op;
      this->right = right;
    }
    string toString();
};
class parenNode: public expNode{
  public:
  list<Node*>exp;
  parenNode(YYLTYPE *loc, list<Node*>*exp):expNode(loc){
    this->ctor == "parenNode";
    if(exp) this->exp = *exp;
  }
  string toSring();
};
class stringNode: public expNode {
  public:
    string name;
    stringNode(YYLTYPE * loc, string name): expNode(loc){
      this->name = name;
    }
    double getValue();
};
class constantNode: public expNode {
  public:
    double value;
    string type;
    string source;
    constantNode(YYLTYPE * loc, long long value): expNode(loc){
      this->ctor = "constantNode";
      this->value = value;
      type="int";
    };
    constantNode(YYLTYPE * loc, double value): expNode(loc){
      this->ctor = "constantNode";
      this->value = value;
      type="double";
    };
    constantNode(YYLTYPE * loc, string source): expNode(loc){
      this->ctor = "constantNode";
      this->source = source;
      type="string";
    };
    string toString();
};

/********************************************************/
/*              1.1 declaration                         */
/********************************************************/
class idNode: public Node{
  public:
    string name;
    list<Node *> arg_list;
    int isArray;
    idNode(YYLTYPE * loc, string name, list<Node*>* arg_list): Node(loc){
      this->ctor = "idNode";
      this->name = name;
      if(arg_list) this->arg_list = *arg_list;
      if(this->arg_list.size()) this->isArray = 1;
    };
    string toString();
};
class initializer_list: public Node{
  public:
    list<Node *>rawData;
    initializer_list(YYLTYPE * loc, Node* first): Node(loc){
      this->rawData.push_back(first);
    };
};
class declarator : public Node{
  public:
    idNode * identifier;
    Node * initializer;
    declarator(YYLTYPE * loc, Node * identifier, Node * initializer): Node(loc){
      this->ctor = "declarator";
      this->identifier = (idNode*)identifier;
      this->initializer = initializer;
    }
    string toString();
};
class declareNode : public Node{
  public:
    string type;
    list<Node *> init_declarator_list;
    declareNode(YYLTYPE * loc, string type, list<Node *> * init_declarator_list): Node(loc){
        this->ctor = "declareNode";
        this->type = type;
        if(init_declarator_list){ this->init_declarator_list = *init_declarator_list; }
    }
    ~declareNode() {}
    string toString();
};
/********************************************************/
/*              1.2 function.definition 函数声明          */
/********************************************************/
class function_definition : public Node{
  public:
    string name;
    string type;
    list<Node *> param_list;
    Node * funcBody;
    function_definition(YYLTYPE * loc,string type, Node * decl, list<Node*> * param_list, Node * compound): Node(loc){
      this->ctor = "function_definition";
      this->name = ((declarator *)decl)->identifier->name;
      if(param_list) this->param_list = *param_list;
      this->funcBody = compound;
    }
};
/********************************************************/
/*        2. composite                                  */
/********************************************************/
class ComInOutNode :public Node{
  public:
    list<Node*> input_list;
    list<Node*> output_list;
    ComInOutNode(YYLTYPE *loc, list<Node*>*input_list, list<Node*>*output_list):Node(loc) {
        this->ctor = "ComInOutNode";
        if(input_list) this->input_list = * input_list;
        if(output_list) this->output_list = * output_list;
    }
};
class compHeadNode :public Node{
  public:
    string compName;
    ComInOutNode * inout;
    compHeadNode(YYLTYPE *loc, string compName, Node*inout):Node(loc) {
        this->ctor = "compHeadNode";
        this->compName = compName;
        this->inout = (ComInOutNode*)inout;
    }
};
typedef struct strTypeMemberStruct{
  string type;
  string identifier;
}strTypeMember;

class strdclNode : public Node{
  public:
    list<strTypeMember>id_list;
  strdclNode(YYLTYPE *loc, string type, string identifier): Node(loc){
    this->ctor = "strdclNode";
    strTypeMember s;
    s.type = type;
    s.identifier = identifier;
    this->id_list.push_back(s);
  }
};
class inOutdeclNode :public Node{
  public:
    strdclNode * strType;
    string id;
    inOutdeclNode(YYLTYPE *loc, Node * strType, string id):Node(loc) {
        this->ctor = "inOutdeclNode";
        this->strType = (strdclNode *)strType;
        this->id = id;
    }
};
class paramNode: public Node{
  public:
    list<Node *> param_list;
    paramNode(YYLTYPE *loc, list<Node*>*param_list):Node(loc){
      this->ctor = "paramNode";
      if(param_list) this->param_list = *param_list;
    }
};
class compBodyNode: public Node{
  public:
    list<Node*> stmt_list;
    paramNode* param;
    compBodyNode(YYLTYPE *loc, Node* param, list<Node*> * stmt_list):Node(loc){
      this->ctor  = "compBodyNode";
      this->param = (paramNode*)param;
      if(stmt_list) this->stmt_list = *stmt_list;
    }
};
class compositeNode : public Node{
  public:
    string compName;
    ComInOutNode *inout;
    compBodyNode *body;
    compositeNode(YYLTYPE *loc, Node * head, Node * body): Node(loc){
      this->ctor = "compositeNode";
      this->compName = ((compHeadNode*)head)->compName;
      this->inout = ((compHeadNode*)head)->inout;
      this->body = (compBodyNode*)body;
    }
};
/********************************************************/
/*        3. statement 花括号内以';'结尾的结构是statement   */
/********************************************************/
class blockNode: public Node{
  public:
  list<Node*>stmt_list;
  blockNode(YYLTYPE *loc,list<Node*> *stmt_list):Node(loc){
    this->ctor = "blockNode";
    if(stmt_list) this->stmt_list = *stmt_list;
  }
  string toString();
};
class jump_statement: public Node{
  public:
  string op1;
  Node* op2;
  jump_statement(YYLTYPE *loc,string op1, Node* op2 = NULL):Node(loc){
    this->ctor = "jump_statement";
    this->op1 = op1;
    this->op2 = op2;
  }
  string toString();
};
class labeled_statement: public Node{
  public:
  string op1;
  Node* condition;
  Node* statement;
  labeled_statement(YYLTYPE *loc,string op1,Node* condition,Node* statement):Node(loc){
    this->ctor = "labeled_statement";
    this->op1 = op1;
    this->condition = condition;
    this->statement = statement;
  }
  string toString();
};
class selection_statement: public Node{
  public:
  string op1;
  Node* exp; 
  Node* statement;
  Node* else_statement;
  selection_statement(YYLTYPE *loc,string op1, Node* exp, Node*statement, Node* else_statement):Node(loc){
    this->ctor = "selection_statement";
    this->op1 = op1; // "if" | "switch"
    this->exp = exp;
    this->statement = statement;
    this->else_statement = else_statement;
  }
  string toString();
};
class whileNode: public Node{
  public:

  whileNode(YYLTYPE *loc):Node(loc){
    this->ctor = "whileNode";
  }
  string toString();
};
class doNode: public Node{
  public:

  doNode(YYLTYPE *loc):Node(loc){
    this->ctor = "doNode";
  }
  string toString();
};
class forNode: public Node{
  public:

  forNode(YYLTYPE *loc):Node(loc){
    this->ctor = "forNode";
  }
  string toString();
};

/********************************************************/
/* operNode in expression's right                       */
/********************************************************/
typedef struct winTypeT{
  string type;
  list<Node*>*arg_list;
}winType;
/********************************************************/
/* 矩阵相关 node                       */
/********************************************************/

/********************************************************/
/* 神经网络相关 node                                      */
/********************************************************/
#endif