#ifdef _GLOBAL_HH
#define _GLOBAL_HH_
#include<stdio.h>
#include "defines.h"
#define INT_MIN -2147483648
#define MAX_INF 214783647

#define MAX_SCOPE_DEPTH 100 //最大嵌套深度
extern string infile_name;
extern string output_path;
extern string origin_path;
extern string temp_name;
extern FILE *infp;
extern FILE *outfp;

extern float VersionNumber;
extern const char *const CompiledDate;
extern int Level;
extern int current_version[MAX_SCOPE_DEPTH];
extern int WarningLevel;

void Error(string msg,int line,int column=0;);
void Warning(string msg,int line,int column=0);

#endif

 