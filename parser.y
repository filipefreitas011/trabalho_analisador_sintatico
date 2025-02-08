%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// arvore sintática
typedef struct Node {
    char name[50];  // identificador
    char value[50]; // valor
    struct Node *left;
    struct Node *right;
} Node;

// cria nó da árvore sintática
Node* createNode(const char* name, const char* value, Node* left, Node* right) {
    Node* newNode = (Node*)malloc(sizeof(Node));
    strcpy(newNode->name, name);
    if (value) 
        strcpy(newNode->value, value);
    else
        newNode->value[0] = '\0';
    newNode->left = left;
    newNode->right = right;
    return newNode;
}

// imprime a árvore sintática indentada
void printTree(Node* root, int level) {
    if (root == NULL) return;

    for (int i = 0; i < level; i++) printf("  ");

    if (strlen(root->value) > 0)
        printf("%s (%s)\n", root->name, root->value);
    else
        printf("%s\n", root->name);

    printTree(root->left, level + 1);
    printTree(root->right, level + 1);
}

// libera memória da árvore
void freeTree(Node* root) {
    if (root == NULL) return;
    freeTree(root->left);
    freeTree(root->right);
    free(root);
}

void yyerror(const char *s) {
    printf("Erro: %s\n", s);
}

int yylex();
%}

%union {
    char* str;
    struct Node* node;
}

%token <str> ID NUM
%token INT FLOAT CHAR VOID IF ELSE FOR WHILE RETURN
%token ASSIGN PLUS MINUS MULT DIV LPAREN RPAREN LBRACE RBRACE SEMICOLON
%type <node> programa lista_decl declaracao expressao tipo
%left PLUS MINUS  
%left MULT DIV    

%%

// regras
programa:
    lista_decl {
        printf("Árvore Sintática:\n");
        printTree($1, 0);
        freeTree($1);
    }
    ;

lista_decl:
    lista_decl declaracao { $$ = createNode("lista_decl", NULL, $1, $2); }
    | declaracao { $$ = $1; }
    ;

declaracao:
    tipo ID SEMICOLON { $$ = createNode("declaracao", NULL, $1, createNode("ID", $2, NULL, NULL)); }
    | tipo ID ASSIGN expressao SEMICOLON { $$ = createNode("atribuicao", NULL, createNode("ID", $2, NULL, NULL), $4); }
    ;

tipo:
    INT { $$ = createNode("tipo", "int", NULL, NULL); }
    | FLOAT { $$ = createNode("tipo", "float", NULL, NULL); }
    | CHAR { $$ = createNode("tipo", "char", NULL, NULL); }
    ;

expressao:
    expressao PLUS expressao { $$ = createNode("+", NULL, $1, $3); }
    | expressao MINUS expressao { $$ = createNode("-", NULL, $1, $3); }
    | expressao MULT expressao { $$ = createNode("*", NULL, $1, $3); }
    | expressao DIV expressao { $$ = createNode("/", NULL, $1, $3); }
    | NUM { $$ = createNode("NUM", $1, NULL, NULL); }
    | ID { $$ = createNode("ID", $1, NULL, NULL); }
    | LPAREN expressao RPAREN { $$ = $2; }
    ;

%%

int main() {
    yyparse();
    return 0;
}
