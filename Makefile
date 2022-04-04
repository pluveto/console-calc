
calc: calc.l calc.y
	bison -d calc.y -v
	flex calc.l
	cc -o calc.out calc.tab.c lex.yy.c -lfl -lm

clean:
	-rm -f *.o *.out*
	-rm *.tab.c *.tab.h *.yy.c *.yy.h
