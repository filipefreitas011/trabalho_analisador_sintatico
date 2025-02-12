%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "parser.tab.h"  // Inclui as definições dos tokens e do union

/* Usa a variável output_file definida em parser.y */
extern FILE *output_file;

/* Estrutura para a tabela de símbolos */
typedef struct {
    char id[100];
    char type[10];
} Identifier;

Identifier identifiers[100];
int identifier_count = 0;

/* Procura um identificador na tabela de símbolos */
int find_identifier(char *id) {
    for (int i = 0; i < identifier_count; i++) {
        if (strcmp(identifiers[i].id, id) == 0)
            return i;
    }
    return -1;
}

/* Adiciona um identificador à tabela de símbolos */
void add_identifier(char *id, char *type) {
    int idx = find_identifier(id);
    if (idx == -1) {
        strcpy(identifiers[identifier_count].id, id);
        strcpy(identifiers[identifier_count].type, type);
        identifier_count++;
        fprintf(output_file, "<id, %d> ", identifier_count);
    } else {
        fprintf(output_file, "<id, %d> ", idx + 1);
    }
}
%}

DIGIT       [0-9]+
ID          [a-zA-Z_][a-zA-Z0-9]*
FLOAT       [0-9]+\.[0-9]+
WHITESPACE  [ \t\r\n]+
STRING      \"(\\.|[^\"\\])*\"

%option noyywrap

%%
int       { fprintf(output_file, "<int> ");    return INT; }
float     { fprintf(output_file, "<float> ");  return FLOAT; }
char      { fprintf(output_file, "<char> ");   return CHAR; }
void      { fprintf(output_file, "<void> ");   return VOID; }
public    { fprintf(output_file, "<public> "); return PUBLIC; }
printf    { fprintf(output_file, "<printf> "); return PRINTF; }
scanf     { fprintf(output_file, "<scanf> ");  return SCANF; }
exit      { fprintf(output_file, "<exit> ");   return EXIT; }
static    { fprintf(output_file, "<static> "); return STATIC; }
args      { fprintf(output_file, "<args> ");   return ARGS; }
if        { fprintf(output_file, "<if> ");     return IF; }
else      { fprintf(output_file, "<else> ");   return ELSE; }
for       { fprintf(output_file, "<for> ");    return FOR; }
while     { fprintf(output_file, "<while> ");  return WHILE; }
break     { fprintf(output_file, "<break> ");  return BREAK; }
switch    { fprintf(output_file, "<switch> "); return SWITCH; }
case      { fprintf(output_file, "<case> ");   return CASE; }
default   { fprintf(output_file, "<default> ");return DEFAULT; }
do        { fprintf(output_file, "<do> ");     return DO; }
typedef   { fprintf(output_file, "<typedef> ");return TYPEDEF; }
struct    { fprintf(output_file, "<struct> "); return STRUCT; }
return    { fprintf(output_file, "<return> "); return RETURN; }

"="       { fprintf(output_file, "<= > ");    return ASSIGN; }
"&&"      { fprintf(output_file, "<&&> ");   return ANDAND; }
"||"      { fprintf(output_file, "<||> ");   return OROR; }
"=="      { fprintf(output_file, "<==> ");   return EQEQ; }
"<"       { fprintf(output_file, "<< > ");   return LT; }
"<="      { fprintf(output_file, "<<= > ");  return LE; }
">"       { fprintf(output_file, "<> > ");   return GT; }
">="      { fprintf(output_file, "<>= > ");  return GE; }
"!="      { fprintf(output_file, "<!= > ");  return NE; }
"+"       { fprintf(output_file, "<+> ");    return PLUS; }
"-"       { fprintf(output_file, "<-> ");    return MINUS; }
"*"       { fprintf(output_file, "<*> ");    return MULT; }
"/"       { fprintf(output_file, "</> ");    return DIV; }
"("       { fprintf(output_file, "<(> ");    return LPAREN; }
")"       { fprintf(output_file, "<)> ");    return RPAREN; }
"{"       { fprintf(output_file, "<{> ");    return LBRACE; }
"}"       { fprintf(output_file, "<}> ");    return RBRACE; }
"["       { fprintf(output_file, "<[> ");    return LBRACKET; }
"]"       { fprintf(output_file, "<]> ");    return RBRACKET; }
";"       { fprintf(output_file, "<;> ");    return SEMICOLON; }
","       { fprintf(output_file, "<,> ");    return COMMA; }
"%"       { fprintf(output_file, "<%%> ");   return PERCENT; }
"++"      { fprintf(output_file, "<++> ");   return PLUSPLUS; }
"--"      { fprintf(output_file, "<--> ");   return MINUSMINUS; }
"&"       { fprintf(output_file, "<&> ");    return AMP; }
"|"       { fprintf(output_file, "<|> ");    return PIPE; }
"~"       { fprintf(output_file, "<~> ");    return TILDE; }
"^"       { fprintf(output_file, "<^> ");    return CARET; }
"!"       { fprintf(output_file, "<!> ");    return NOT; }
"+="      { fprintf(output_file, "<+=> ");   return PLUSEQ; }
"-="      { fprintf(output_file, "<-=> ");   return MINUSEQ; }
":"       { fprintf(output_file, "<:> ");    return COLON; }
"?"       { fprintf(output_file, "<?> ");   return QUESTION; }
"#"       { fprintf(output_file, "<#> ");    return HASH; }
"->"      { fprintf(output_file, "<-> > ");  return ARROW; }

{DIGIT}   { 
              yylval.str = strdup(yytext);
              fprintf(output_file, "<num, %s> ", yytext);
              return NUM;
          }
{FLOAT}   { 
              yylval.str = strdup(yytext);
              fprintf(output_file, "<num, %s> ", yytext);
              return NUM;
          }
{ID}      { 
              yylval.str = strdup(yytext);
              add_identifier(yytext, "unknown");
              return ID;
          }
{STRING}  { 
              yylval.str = strdup(yytext);
              fprintf(output_file, "<str, %s> ", yytext);
              return STRING_LITERAL;
          }

"//".*   { /* Ignora comentários de linha única */ }
"/*"([^*]|\*+[^*/])*\*+"/"  { /* Ignora comentários de múltiplas linhas */ }

{WHITESPACE} { /* Ignora espaços em branco */ }

.         { fprintf(output_file, "<invalido, %s> ", yytext); return INVALID; }
%%
