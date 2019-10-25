%{
    //#define DEBUG
    #include "defines.h"//
    #include "node.h"
    #include <list>
    #include "token.h"
    #include <vector>
    int yycolumn=1;
    #define YY_USER_ACTION yylloc.first_line=yylloc.last_line=yylineno;\
        yylloc.first_column=yycolumn;\
        yylloc.last_column=yycolumn+yyleng-1;\
        yycolumn+=yyleng;
%}

/*标识符*/
identifier ([a-zA-Z_][0-9a-zA-Z_]*)
/*指数部分*/
exponent_part ([eE][-+]?[0-9]+)
/*小数部分*/
fractional_constant ([0-9]*"."[0-9]+)|([0-9]+".")
/*浮点数*/
floating_constant ((({fractional_constant}{exponent_part}?)|([0-9]+{exponent_part_part})))

/*10进制数字，例如123456*/
decimal_constant ([1-9][0-9]*)
/*8进制数字*/
octal_constant ("0"[0-7]*)
/*16进制数字*/
hex_constant ("0"[xX][0-9a-fA-F]+)

/*字符串*/
string_constant ('[^\n]*'|\"[^\n]*\")

/*空白字符*/
any_white ([ \t])

/*多行注释*/
Annotations "/*"([^\*]|(\*)*[^\*/])*(\*)*"*/"
/*单行注释*/
Annotation \/\/[^\n]*\n

%option noyywrap
%option yylineno
%%

"\n"                                        {yycolumn=1;}
{any_white}                                  
{Annotation}                                {debug("单行注释\n");yycolumn=1;}
{Annotations}                               {debug("多行注释\n");yycolumn=1;}
{decimal_constant}|{hex_constant}|{octal_constant}  {
                                                        yylval.num=stoll(yytext,0,0);
                                                        return integerConstant;
                                                    }
{float_constant}                            {
                                            yylval.doubleNum=strtod(yytext,0);
                                            return doubleConstant;
                                            }
{string_constant}                           {
                                            string str=string(yytext);
                                            yylval.str=new string(str.substr(l,str.size()-2));
                                            return stringConstant;
                                            }

string      {return STRING;}
int         {return INT;}
double      {return DOUBLE;}
float       {return FLOAT;}
long        {return LONG;}
const       {return CONST;}
define      {return DEFINE;}

while       {return WHILE;}
for         {return FOR;}
break       {return BREAK;}
continue    {return CONTINUE;}
switch      {return SWITCH;}
case        {return CASE;}
default     {return DEFAULT;}
if          {return IF;}
else        {return ELSE;}
do          {return DO;}
return      {return RETURN;}

composite   {return COMPOSITE;}
input       {return INPUT;}
output      {return OUTPUT;}
stream      {return STREAM;}
FileReader  {return FILEREADER;}
FileWriter  {return FILEWRITER;}
add         {return ADD;}

param       {return PARAM;}
init        {return INIT;}
work        {return WORK;}
window      {return WINDOW;}
tumbling    {return TUMBLING;}
sliding     {return SLIDING;}

splitjoin   {return SPLITJOIN;}
pipeline    {return PIPELINE;}
split       {return SPLIT;}
join        {return JOIN;}
duplicate   {return DUPLICATE;}
roundrobin  {return ROUNDROBIN;}

matrix      {return MATRIX;}

{identifier} {yylval.str=new string(yytext); 
              return IDENTIFIER;}

"("         {return *yytext;}
")"         {return *yytext;}
"["         {return *yytext;}
"]"         {return *yytext;}
"{"         {return *yytext;}
"}"         {return *yytext;}
"\""        {return *yytext;}
"'"         {return *yytext;}
","         {return *yytext;}
"#"         {return *yytext;}

"."         {return '.';}
"&"         {return '&';}
"|"         {return '|';}
"^"         {return '^';}
"+"         {return '+';}
"-"         {return '-';}
"*"         {return '*';}
"/"         {return '/';}
"%"         {return '%';}
"<"         {return '<';}
">"         {return '>';}
"~"         {return '~';}
"!"         {return '!';}
"?"         {return '?';}
":"         {return ':';}
";"         {return ';';}
"="         {return '=';}

"##"        {return POUNDPOUND;}
"++"        {return ICR;}
"--"        {return DECR;}
"<<"        {return LS;}
">>"        {return RS;}
"<="        {return LE;}
">="        {return GE;}
"=="        {return EQ;}
"!="        {return NE;}
"&&"        {return ANDAND;}
"||"        {return OROR;}
"*="        {return MULTassign;}
"/="        {return DIVassign;}
"+="        {return PLUSassign;}
"-="        {return MINUSassign;}
"<<="       {return LSassign;}
">>="       {return RSassign;}
"&="        {return ANDassign;}
"^="        {return ERassign;}
"|="        {return ORassign;}

. {Error(string("不支持的字符：")+string(yytext),yylineno,yycolumn);
}

%%