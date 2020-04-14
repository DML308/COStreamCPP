#include "node.h"
#include<string>
using namespace std;
void Node::setLoc(YYLTYPE * loc){
    if(loc){
        this->loc->first_line = loc->first_line;
        this->loc->first_column = loc->first_column;
        this->loc->last_line = loc->last_line;
        this->loc->last_column = loc->last_column;
    }
}
string declarator::toString(){
    string str = identifier->toString();
    if(initializer){
        str += " = " + initializer->toString();
    }
    return str;
}
string declareNode::toString(){
    string str = type + " ";
    for(auto decla : init_declarator_list){
        if(decla){
            str += decla->toString();
        }
    }
    return str;
}
string constantNode::toString(){
    if(type == "string"){
        return source;
    }else if(type == "int"){
        return to_string((int)value);
    }else{
        return to_string(value);
    }
}
string unaryNode::toString(){
    string str ;
    if(op == "r++"){
        str = exp->toString() + "++";
    }else if(op == "r--"){
        str = exp->toString() + "--";
    }else{
        str = op + exp->toString();
    }
    return "("+str+")";
}
string binopNode::toString(){
    return "(" + left->toString() + op + right->toString() + ")";
}
string idNode::toString(){
    string str = name;
    if (isArray){
        if (arg_list.size() == 0) // int sum(int a[])特殊情况,是数组但是无 arg_list
            str += "[]";
        else{
            for (auto i : arg_list){
                str += '[' + i->toString();
                str += "]";
            }
        }
    }

    return str;
}
string selection_statement::toString(){
    string str;
    if(op1 == "if"){
        str = "if(" + exp->toString() + ") " + statement->toString();
        if(else_statement){
            str += " else " + else_statement->toString();
        }
        return str;
    }
    return "selection_statement toString 出错";
}