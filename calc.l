%{
    #define YYSTYPE double

    #include<stdlib.h>
    void yyerror(char*);
    #include "calc.tab.h"

%}

number        ([0-9]+|[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?)

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
