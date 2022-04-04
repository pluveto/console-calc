---
authors:
- Pluveto
date: '2022-04-04T11:25:04.177053+08:00'
draft: false
slug: flex-and-bison-of-actual-combat-a-simple-calculator
title: Flex & Bison 实战：一个简单计算器
toc: true
---
## 概述

本文以一个计算器的实现为例介绍 Flex & Bison 的使用。

## 词法分析

Flex 可帮助我们生成词法分析器。

代码：

*calc.l*

```c
%%
"+"         { printf("PLUS\n"); }
"-"         { printf("MINUS\n"); }
"*"         { printf("TIMES\n"); }
"/"         { printf("DIVIDE\n"); }
"|"         { printf("ABS\n"); }
[0-9]+      { printf("NUMBER %s\n", yytext); }
\n          { printf("NEWLINE\n"); }
[ \t]       {}
.           { printf("Mystery character %s\n", yytext); }
%%
```

说明：

**yytext**：指向本次匹配的输入串

`l` 文件的结构是这样的：

```
声明部分
%%
翻译规则
%%
辅助性C语言例程
```



生成词法分析器：

```
flex calc.l
```

编译：

```
cc lex.yy.c -lfl
```

运行：

```
./a.out
```

效果：

![image-20220404113139987](https://cdn.jsdelivr.net/gh/pluveto/0images@master/2022/04/upgit_20220404_1649043102.png)



## 最简单的语法分析

上面生成的 Token 都是直接输出到控制台。为了与语法分析器交互，需要换一种方式。

*calc.l* 19:

```c
%{
    #include<stdlib.h>
    void yyerror(char*);
    #include "calc.tab.h"  
%}

%%
[0-9]+      {yylval=atoi(yytext); return NUMBER;}
[-+*/\n]   {return *yytext;}
[ \t]       ;

.    	    yyerror("Error");

%%
int yywrap(void)
{
  return 1;
}

```

*calc.y* 31:

```c
%token NUMBER
%left '+' '-' '*' '/'

%{
    #include <stdio.h>
    #include <math.h>
    void yyerror(char *s);
    int yylex();    
%}

%%
    
    prog: 
        | prog expr '\n' { printf("= %d\n", $2); };
    expr:
        NUMBER {{ printf("read number %d\n", $$); }};
        | expr '+' expr {{ $$ = $1 + $3; }}
        | expr '-' expr {{ $$ = $1 - $3; }}
        | expr '*' expr {{ $$ = $1 * $3; }}
        | expr '/' expr {{ $$ = $1 / $3; }}
        ;
%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main() {
    yyparse();
    return 0;
}
```

可以看到，我们用 `%token` 可以声明词符。然后在 lex 文件中使用 `#include "calc.tab.h"  ` 可以引入这些声明。

编译：

*Makefile* 8:

```makefile
clean:
	rm -f *.o *.out
	rm *.tab.c *.tab.h *.yy.c *.yy.h

calc: calc.l calc.y
	bison -d calc.y
	flex calc.l
	cc -o $@ calc.tab.c lex.yy.c -lfl
```

```
make calc
```

运行：

```
./calc                                                root@hw-ecs-hk
1*2+3*4
read number 1
read number 2
read number 3
read number 4
= 20
```

我们发现算符是无结合顺序的。下面增加优先级

## 实现加减乘除的优先级

第一种方法最简单，使用 `%left` 指令：

```c
%left '+' '-'
%left '*' '/'
```

![image-20220404212628074](https://cdn.jsdelivr.net/gh/pluveto/0images@master/2022/04/upgit_20220404_1649084528.png)

第二种方法，可以在修改规则实现优先级。

*calc.y* 33:

```clike
%token NUMBER
%left '+' '-' '*' '/'

%{
    #include <stdio.h>
    #include <math.h>
    void yyerror(char *s);
    int yylex();    
%}

%%
    
    prog: 
        | prog expr '\n' { printf("= %d\n", $2); };
    expr:
        expr '+' term { $$ = $1 + $3; }
        | expr '-' term { $$ = $1 - $3; }
        | term
    term:
        NUMBER {{ printf("read number %d\n", $$); }};
        | term '*' term { $$ = $1 * $3; }
        | term '/' term { $$ = $1 / $3; }        
        ;
%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main() {
    yyparse();
    return 0;
}
```

## 实现括号指定运算顺序

下面实现计算 `(1+2)*3` 这样带括号的表达式：

*calc.l* 19:

```c
%{
    #include<stdlib.h>
    void yyerror(char*);
    #include "calc.tab.h"  
%}

%%
[0-9]+      {yylval=atoi(yytext); return NUMBER;}
[-+*/()\n]   {return *yytext;}
[ \t]       ;

.    	    yyerror("Error");

%%
int yywrap(void)
{
  return 1;
}

```

*calc.y* 37:

```c
%token NUMBER
%left '+' '-' '*' '/'

%{
    #include <stdio.h>
    #include <math.h>
    void yyerror(char *s);
    int yylex();    
%}

%%
    
    prog: 
        | prog expr '\n' { printf("= %d\n", $2); };
    expr:
        expr '+' term { $$ = $1 + $3; }
        | expr '-' term { $$ = $1 - $3; }
        | term
    term:
        | term '*' factor { $$ = $1 * $3; }
        | term '/' factor { $$ = $1 / $3; }        
        | factor
        ;
    factor:
        NUMBER {{ printf("read number %d\n", $$); }};
        | '(' expr ')' { $$ = $2; }
        ;
%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main() {
    yyparse();
    return 0;
}
```

效果：

![image-20220404213809951](https://cdn.jsdelivr.net/gh/pluveto/0images@master/2022/04/upgit_20220404_1649084533.png)

## 实现绝对值和负数

将 `|` 添加到 token 富豪中。

*calc.y* 39:

```c
%token NUMBER
%left '+' '-' '*' '/'

%{
    #include <stdio.h>
    #include <math.h>
    void yyerror(char *s);
    int yylex();    
%}

%%
    
    prog: 
        | prog expr '\n' { printf("= %d\n", $2); };
    expr:
        expr '+' term { $$ = $1 + $3; }
        | expr '-' term { $$ = $1 - $3; }
        | term
    term:
        term '*' factor { $$ = $1 * $3; }
        | term '/' factor { $$ = $1 / $3; }        
        | factor
        ;
    factor:
        NUMBER {{ printf("read number %d\n", $$); }};
        | '-' factor { $$ = -$2; }        
        | '(' expr ')' { $$ = $2; }
        | '|' expr '|' { $$ = $2>0?$2:-$2; }
        ;
%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main() {
    yyparse();
    return 0;
}
```

## 实现乘方

需要引入 math 库，因此：

*Makefile* 5:

```makefile

calc: calc.l calc.y
	bison -d calc.y
	flex calc.l
	cc -o $@ calc.tab.c lex.yy.c -lfl -lm

clean:
	-rm -f *.o *.out
	-rm *.tab.c *.tab.h *.yy.c *.yy.h

```

*calc.y* 40:

```c
%token NUMBER
%left '+' '-' '*' '/'

%{
    #include <stdio.h>
    #include <math.h>
    void yyerror(char *s);
    int yylex();    
%}

%%
    
    prog: 
        | prog expr '\n' { printf("= %d\n", $2); };
    expr:
        expr '+' term { $$ = $1 + $3; }
        | expr '-' term { $$ = $1 - $3; }
        | term
    term:
        | term '*' '*' factor { $$ = pow($1, $4); }
        | term '*' factor { $$ = $1 * $3; }
        | term '/' factor { $$ = $1 / $3; }        
        | factor
        ;
    factor:
        NUMBER {{ printf("read number %d\n", $$); }};
        | '-' factor { $$ = -$2; }        
        | '(' expr ')' { $$ = $2; }
        | '|' expr '|' { $$ = $2>0?$2:-$2; }
        ;
%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main() {
    yyparse();
    return 0;
}
```

效果：

![image-20220404215856400](https://cdn.jsdelivr.net/gh/pluveto/0images@master/2022/04/upgit_20220404_1649084538.png)

## 支持小数

这里需要注意的是，Flex 的规则表达式和常用的 Perl 格式不一样。参阅 [Flex Regular Expressions (aau.dk)](https://people.cs.aau.dk/~marius/sw/flex/Flex-Regular-Expressions.html)

*calc.l* 22:

```c
%{
    #define YYSTYPE double

    #include<stdlib.h>
    void yyerror(char*);
    #include "calc.tab.h"

%}

%%
-?([0-9]+|[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?)        {yylval = atof(yytext); return NUMBER;}
[-+*/()|\n]   {return *yytext;}
[ \t]       ;

.    	    yyerror("Error");

%%
int yywrap(void)
{
  return 1;
}

```

正则表达式太长了怎么办？可以用别名：

*calc.l* 24:

```c
%{
    #define YYSTYPE double

    #include<stdlib.h>
    void yyerror(char*);
    #include "calc.tab.h"

%}

number        -?([0-9]+|[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?)

%%
{number}      {yylval = atof(yytext); return NUMBER;}
[-+*/()\|\n]  {return *yytext;}
[ \t]       ;

.    	    yyerror("Error");

%%
int yywrap(void)
{
  return 1;
}

```

*calc.y* 41:

```c
%token NUMBER
%left '+' '-' '*' '/'

%{
    #define YYSTYPE double
    #include <stdio.h>
    #include <math.h>
    void yyerror(char *s);
    int yylex();    
%}

%%
    
    prog: 
        | prog expr '\n' { printf("= %lf\n", $2); };
    expr:
        expr '+' term { $$ = $1 + $3; }
        | expr '-' term { $$ = $1 - $3; }
        | term
    term:
        term '*' '*' factor { $$ = pow($1, $4); }
        | term '*' factor { $$ = $1 * $3; }
        | term '/' factor { $$ = $1 / $3; }        
        | factor
        ;
    factor:
        NUMBER {{ printf("read number %lf\n", $$); }};
        | '-' factor { $$ = -$2; }        
        | '(' expr ')' { $$ = $2; }
        | '|' expr '|' { $$ = $2>0?$2:-$2; }
        ;
%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main() {
    yyparse();
    return 0;
}
```

*Makefile* 10:

```makefile

calc: calc.l calc.y
	bison -d calc.y -v
	flex calc.l
	cc -o calc.out calc.tab.c lex.yy.c -lfl -lm

clean:
	-rm -f *.o *.out*
	-rm *.tab.c *.tab.h *.yy.c *.yy.h

```

效果

![image-20220404224949402](https://cdn.jsdelivr.net/gh/pluveto/0images@master/2022/04/upgit_20220404_1649084542.png)

## 测试

测试发现，上面的代码有问题。`-1-1` 报错。解决方法：修改 number 的 token 定义：

*calc.l* 10:

```plaintext
number        ([0-9]+|[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?)
```

至此，一个简单的计算器完成了。

你可以在[这里](https://github.com/pluveto/console-calc)找到源码。