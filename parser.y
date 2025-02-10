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

/* Função de impressão da árvore sintática */
void printTree(Node* root, int level) {
    if (root == NULL) return;
    /* Se o nó for um nó "transparente" de item de expressão, apenas imprima seu filho esquerdo */
    if (strcmp(root->name, "expr_item") == 0) {
        printTree(root->left, level);
        return;
    }
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

/* Tokens – devem coincidir com os retornados pelo scanner */
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

/* Não-terminais que carregam árvore sintática */
%type <node> program statement_list stmt decl atr if_stmt while_stmt func_def return_stmt bloco expressao tipo lvalue 
%type <node> expr_list non_empty_expr_list param_list param_decl arg_list

%%

program:
    statement_list { 
        printf("Árvore Sintática:\n");
        printTree($1, 0);
        freeTree($1);
    }
    ;

statement_list:
    statement_list stmt { $$ = createNode("statement_list", NULL, $1, $2); }
    | stmt { $$ = $1; }
    ;

stmt:
      decl                { $$ = $1; }
    | atr                 { $$ = $1; }
    | if_stmt             { $$ = $1; }
    | while_stmt          { $$ = $1; }
    | func_def            { $$ = $1; }
    | return_stmt         { $$ = $1; }
    | bloco               { $$ = $1; }
    ;

/* --- Declaração de Variáveis e Vetores --- */
decl:
      tipo ID LBRACKET NUM RBRACKET ASSIGN LBRACE expr_list RBRACE SEMICOLON {
           $$ = createNode("decl-array-init", NULL, 
                        createNode("decl-array", NULL, $1, createNode("ID", $2, NULL, NULL)),
                        $8);
      }
    | tipo ID LBRACKET NUM RBRACKET SEMICOLON {
           $$ = createNode("decl-array", NULL, $1, createNode("ID", $2, NULL, NULL));
      }
    | tipo ID ASSIGN expressao SEMICOLON {
           $$ = createNode("decl-init", NULL, createNode("ID", $2, NULL, NULL), $4);
      }
    | tipo ID SEMICOLON {
           $$ = createNode("decl", NULL, $1, createNode("ID", $2, NULL, NULL));
      }
    ;

/* --- Lado Esquerdo (lvalue) --- */
lvalue:
      ID { $$ = createNode("ID", $1, NULL, NULL); }
    | ID LBRACKET expressao RBRACKET { $$ = createNode("array_access", NULL, createNode("ID", $1, NULL, NULL), $3); }
    ;

atr:
    lvalue ASSIGN expressao SEMICOLON { $$ = createNode("atribuicao", NULL, $1, $3); }
    ;

/* --- Comandos Condicionais e de Repetição --- */
if_stmt:
    IF LPAREN expressao RPAREN stmt %prec LOWER_THAN_ELSE { $$ = createNode("if", NULL, $3, $5); }
    | IF LPAREN expressao RPAREN stmt ELSE stmt { $$ = createNode("if-else", NULL, createNode("if", NULL, $3, $5), $7); }
    ;

while_stmt:
    WHILE LPAREN expressao RPAREN stmt { $$ = createNode("while", NULL, $3, $5); }
    ;

/* --- Comando Return --- */
return_stmt:
    RETURN SEMICOLON { $$ = createNode("return", "void", NULL, NULL); }
    | RETURN expressao SEMICOLON { $$ = createNode("return", NULL, $2, NULL); }
    ;

/* --- Bloco --- */
bloco:
    LBRACE statement_list RBRACE { $$ = $2; }
    ;

/* --- Definição de Função --- */
func_def:
    tipo ID LPAREN param_list RPAREN bloco { 
         $$ = createNode("func_def", NULL, createNode("func_sign", $2, $1, $4), $6); 
    }
    | VOID ID LPAREN param_list RPAREN bloco { 
         $$ = createNode("func_def", NULL, 
                 createNode("func_sign", $2, createNode("tipo", "void", NULL, NULL), $4), $6); 
    }
    ;

/* --- Parâmetros e Argumentos --- */
param_list:
      VOID { $$ = NULL; }
    | /* empty */ { $$ = NULL; }
    | param_decl { $$ = $1; }
    | param_list COMMA param_decl { $$ = createNode("param_list", NULL, $1, $3); }
    ;


param_decl:
    tipo ID { $$ = createNode("param", NULL, $1, createNode("ID", $2, NULL, NULL)); }
    ;

arg_list:
      /* empty */ { $$ = NULL; }
    | expressao { $$ = $1; }
    | arg_list COMMA expressao { $$ = createNode("arg_list", NULL, $1, $3); }
    ;

/* --- Expressões --- */
expressao:
      ID LPAREN arg_list RPAREN { $$ = createNode("call", $1, $3, NULL); }
    | ID LBRACKET expressao RBRACKET { $$ = createNode("array_access", NULL, createNode("ID", $1, NULL, NULL), $3); }
    | expressao PLUS expressao  { $$ = createNode("+", NULL, $1, $3); }
    | expressao MINUS expressao { $$ = createNode("-", NULL, $1, $3); }
    | expressao MULT expressao  { $$ = createNode("*", NULL, $1, $3); }
    | expressao DIV expressao   { $$ = createNode("/", NULL, $1, $3); }
    | expressao LT expressao    { $$ = createNode("<", NULL, $1, $3); }
    | expressao LE expressao    { $$ = createNode("<=", NULL, $1, $3); }
    | expressao GT expressao    { $$ = createNode(">", NULL, $1, $3); }
    | expressao GE expressao    { $$ = createNode(">=", NULL, $1, $3); }
    | expressao EQEQ expressao  { $$ = createNode("==", NULL, $1, $3); }
    | expressao NE expressao    { $$ = createNode("!=", NULL, $1, $3); }
    | expressao SEMICOLON { $$ = $1; }
    | NUM { $$ = createNode("NUM", $1, NULL, NULL); }
    | ID  { $$ = createNode("ID", $1, NULL, NULL); }
    | LPAREN expressao RPAREN { $$ = $2; }
    ;

/* --- Tipos --- */
tipo:
      INT   { $$ = createNode("tipo", "int", NULL, NULL); }
    | FLOAT { $$ = createNode("tipo", "float", NULL, NULL); }
    | CHAR  { $$ = createNode("tipo", "char", NULL, NULL); }
    ;

/* --- Lista de Expressões (para inicializadores) --- */
expr_list:
      non_empty_expr_list { $$ = $1; }
    ;

non_empty_expr_list:
      expressao { $$ = createNode("expr_item", "", $1, NULL); }
    | non_empty_expr_list COMMA expressao { $$ = createNode("expr_list", "", $1, createNode("expr_item", "", $3, NULL)); }
    ;

%%

/* Declaramos a variável yydebug para permitir a ativação do modo de debug */
int yydebug = 0;
/* A variável output_file será utilizada tanto pelo parser quanto pelo scanner */
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
