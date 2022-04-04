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
        NUMBER
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