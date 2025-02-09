bison -d parser.y
flex analisador_lexico.l
gcc -o parser parser.tab.c lex.yy.c
./parser < entrada.txt
