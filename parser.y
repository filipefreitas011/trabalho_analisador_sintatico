%code requires {
    /* Declaração antecipada para que o header conheça o tipo Node */
    typedef struct Node Node;
}
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Definição completa da árvore sintática */
typedef struct Node {
    char name[50];
    char value[50];
    struct Node *left;
    struct Node *right;
} Node;

/* Cria um nó da árvore sintática */
Node* createNode(const char* name, const char* value, Node* left, Node* right) {
    Node* newNode = (Node*)malloc(sizeof(Node));
    if (!newNode) {
        fprintf(stderr, "Erro: falha na alocação de memória.\n");
        exit(1);
    }
    strcpy(newNode->name, name);
    if (value)
        strcpy(newNode->value, value);
    else
        newNode->value[0] = '\0';
    newNode->left = left;
    newNode->right = right;
    return newNode;
}

/* Imprime a árvore sintática (com indentação) */
void printTree(Node* root, int level) {
    if (root == NULL) return;
    for (int i = 0; i < level; i++) 
        printf("  ");
    if (strlen(root->value) > 0)
        printf("%s (%s)\n", root->name, root->value);
    else
        printf("%s\n", root->name);
    printTree(root->left, level + 1);
    printTree(root->right, level + 1);
}

/* Libera a memória da árvore */
void freeTree(Node* root) {
    if (root == NULL) return;
    freeTree(root->left);
    freeTree(root->right);
    free(root);
}

/* Função chamada em caso de erro sintático */
void yyerror(const char *s) {
    printf("Erro: %s\n", s);
}

int yylex();
%}

%union {
    char* str;
    Node* node;
}

/* Tokens – estes devem coincidir com os retornados pelo scanner */
%token <str> ID NUM STRING_LITERAL
%token INT FLOAT CHAR VOID PUBLIC PRINTF SCANF EXIT STATIC ARGS IF ELSE FOR WHILE BREAK SWITCH CASE DEFAULT DO TYPEDEF STRUCT RETURN
%token ASSIGN PLUS MINUS MULT DIV LPAREN RPAREN LBRACE RBRACE SEMICOLON
%token ANDAND OROR EQEQ LT LE GT GE NE
%token LBRACKET RBRACKET COMMA PERCENT PLUSPLUS MINUSMINUS AMP PIPE TILDE CARET NOT PLUSEQ MINUSEQ COLON QUESTION HASH ARROW
%token INVALID

/* Diretivas para resolver o “dangling else” */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

/* Precedência para operadores relacionais e aritméticos */
%left LT LE GT GE EQEQ NE
%left PLUS MINUS
%left MULT DIV

%type <node> programa lista_stmt stmt decl atr if_stmt bloco expressao tipo

%%

programa:
    lista_stmt {
        printf("Árvore Sintática:\n");
        printTree($1, 0);
        freeTree($1);
    }
    ;

lista_stmt:
    lista_stmt stmt { $$ = createNode("lista_stmt", NULL, $1, $2); }
    | stmt { $$ = $1; }
    ;

stmt:
      decl                { $$ = $1; }
    | atr                 { $$ = $1; }
    | if_stmt             { $$ = $1; }
    | bloco               { $$ = $1; }
    ;

/* Declaração com ou sem inicialização */
decl:
      tipo ID SEMICOLON {
           $$ = createNode("decl", NULL, $1, createNode("ID", $2, NULL, NULL));
      }
    | tipo ID ASSIGN expressao SEMICOLON {
           $$ = createNode("decl-init", NULL, createNode("ID", $2, NULL, NULL), $4);
      }
    ;

/* Atribuição */
atr:
    ID ASSIGN expressao SEMICOLON {
         $$ = createNode("atribuicao", NULL, createNode("ID", $1, NULL, NULL), $3);
    }
    ;

/* Comando if com ou sem else – a primeira produção tem precedência menor que ELSE */
if_stmt:
    IF LPAREN expressao RPAREN stmt %prec LOWER_THAN_ELSE {
         $$ = createNode("if", NULL, $3, $5);
    }
    | IF LPAREN expressao RPAREN stmt ELSE stmt {
         $$ = createNode("if-else", NULL, createNode("if", NULL, $3, $5), $7);
    }
    ;

/* Bloco composto por lista de sentenças */
bloco:
    LBRACE lista_stmt RBRACE { $$ = $2; }
    ;

/* Expressões aritméticas e relacionais */
expressao:
      expressao PLUS expressao  { $$ = createNode("+", NULL, $1, $3); }
    | expressao MINUS expressao { $$ = createNode("-", NULL, $1, $3); }
    | expressao MULT expressao  { $$ = createNode("*", NULL, $1, $3); }
    | expressao DIV expressao   { $$ = createNode("/", NULL, $1, $3); }
    | expressao LT expressao    { $$ = createNode("<", NULL, $1, $3); }
    | expressao LE expressao    { $$ = createNode("<=", NULL, $1, $3); }
    | expressao GT expressao    { $$ = createNode(">", NULL, $1, $3); }
    | expressao GE expressao    { $$ = createNode(">=", NULL, $1, $3); }
    | expressao EQEQ expressao  { $$ = createNode("==", NULL, $1, $3); }
    | expressao NE expressao    { $$ = createNode("!=", NULL, $1, $3); }
    | NUM                     { $$ = createNode("NUM", $1, NULL, NULL); }
    | ID                      { $$ = createNode("ID", $1, NULL, NULL); }
    | LPAREN expressao RPAREN { $$ = $2; }
    ;

tipo:
      INT   { $$ = createNode("tipo", "int", NULL, NULL); }
    | FLOAT { $$ = createNode("tipo", "float", NULL, NULL); }
    | CHAR  { $$ = createNode("tipo", "char", NULL, NULL); }
    ;

%%

/* Declaramos a variável yydebug para permitir a ativação do modo de debug */
int yydebug = 0;

/* A variável output_file será utilizada pelo scanner também */
FILE *output_file;

int main() {
    output_file = fopen("output.lex", "w");
    if (!output_file) {
        fprintf(stderr, "Erro ao abrir o arquivo output.lex.\n");
        exit(1);
    }
    yydebug = 1;  /* Ativa o modo de debug do parser */
    yyparse();
    fclose(output_file);
    return 0;
}
