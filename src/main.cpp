#include <iostream>
#include "node.h"
#include <list>
#include "token.h"
#include "0.handle_options.h"
#include "global.h"


extern FILE *yyin;                               // flex uses yyin as input file's pointer
extern int yyparse();                            // parser.cc provides yyparse()
string PhaseName = "undefined";                  //阶段名

//===----------------------------------------------------------------------===//
// Main
//===----------------------------------------------------------------------===//
int main(int argc, char *argv[])
{
    //===----------------------------------------------------------------------===//
    // 编译前端 begin
    //===----------------------------------------------------------------------===//

    // (0) 对命令行输入预处理
    if (handle_options(argc, argv) == false)
        return 0;

    // (1) 做第一遍扫描(当输入文件存在时)(函数和 composite 变量名存入符号表 S)
    if (infile_name.size() == 0)
    {
        infp = stdin;
        infile_name = "stdin";
    }
    else
    {
        infp = changeTabToSpace();
        infp = recordFunctionAndCompositeName();
        //设置输出文件路径
        setOutputPath();
    }
    
    // (2) 文法建立和语法树生成
    PhaseName = "Parsing";
    yyin = infp;
    yyparse();

    // (3) 语义检查
    PhaseName = "SemCheck";
    /* 找到Main composite */
    // (4) 打印抽象语法树
    PhaseName = "PrintAstTree";
    // (5)语法树到平面图 SSG 是 StaticStreamGraph 对象
    PhaseName = "AST2FlatSSG";
    // (6) 对静态数据流图各节点进行工作量估计
    //===----------------------------------------------------------------------===//
    // 编译前端 end
    //===----------------------------------------------------------------------===//
    //===----------------------------------------------------------------------===//
    // 编译后端 begin
    //===----------------------------------------------------------------------===//
    // (1) 对静态数据流图进行初态和稳态调度
    // (2) 用XML文本的形式描述SDF图
    // (3) 对节点进行调度划分
    // (5) 打印理论加速比
    // (6) 阶段赋值
    // (7) 输入为SDF图，输出为目标代码
    //===----------------------------------------------------------------------===//
    // 编译后端 end
    //===----------------------------------------------------------------------===//
    // (last) 全局垃圾回收
    PhaseName = "Recycling";
    return 0;
}
