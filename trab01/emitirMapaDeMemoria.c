#include "montador.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Struct para lista de nomes
typedef struct lista
{
    char *string; // guarda o nome do rotulo/def
    int pos; // valor x 2
    struct lista *prox;
} listaNomes;

listaNomes* insereNome(listaNomes *lista, char* nome);
listaNomes* preencheNomes(listaNomes *lista);
listaNomes* procuraNome(listaNomes* inicio, char* string);
void imprimeLista(listaNomes *p);
void erroDeclarado (char* string);
void erroMontagem();

/* Retorna:
 *  1 caso haja erro na montagem;
 *  0 caso não haja erro.
 */
int emitirMapaDeMemoria()
{
    char mapa[2048][5]; // mapa com a saida em hexadecimal. pos par: esq; pos impar: dir
    int preenchido[2048]; // 0: posicao vazia; 1: posicao preenchida
    listaNomes* lista = NULL;
    int pc = 0; // guarda posicao de memoria em leitura

    // Inicializa vetor de controle com 0
    for (int i=0; i<2048; i++)
    {
        preenchido[i] = 0;
    }

    lista = insereNome(lista, "");

    // Preenche lista de nomes
    // Erro se tem nomes repetidos
    if(!(lista = preencheNomes(lista)))
    {
        return 1;
    }

    // Preenche enterecos nomes
    for (int i=0; i<getNumberOfTokens(); i++)
    {

        Token tokenAtual = recuperaToken(i);

        // Preenche a posicao do rotulo
        if(tokenAtual.tipo == DefRotulo)
        {
            int len = strlen(tokenAtual.palavra);
            char* string = malloc(sizeof(char)*len);
            strncpy(string, tokenAtual.palavra, len-1);
            string[len-1] = '\0';

            listaNomes* rot = procuraNome(lista, string);
            rot->pos = pc;

            free(string);
        }

        // Conta instrucao
        else if(tokenAtual.tipo == Instrucao)
        {
            pc++;
        }

        else if(tokenAtual.tipo == Diretiva)
        {

            // Preenche a posicao do simbolo
            if (!strcmp(tokenAtual.palavra, ".set"))
            {
                i++;
                Token tokenAtual = recuperaToken(i);

                listaNomes* sim = procuraNome(lista, tokenAtual.palavra);

                i++;
                tokenAtual = recuperaToken(i);
                sim->pos = strtol(tokenAtual.palavra, NULL, 0)*2;
            }

            // Conta diretiva .org
            else if (!strcmp(tokenAtual.palavra, ".org"))
            {
                i++;
                Token tokenAtual = recuperaToken(i);
                pc=strtol(tokenAtual.palavra, NULL, 0)*2;
            }

            // Conta diretiva .align
            else if (!strcmp(tokenAtual.palavra, ".align"))
            {
                i++;
                Token tokenAtual = recuperaToken(i);
                int mult = strtol(tokenAtual.palavra, NULL, 0);

                // Se esta a direita, pula para prox linha
                if (pc%2)
                    pc++;

                // Pula para linha multipla
                while((pc/2)%mult)
                {
                     pc+=2;
                }
            }

            // Conta diretiva .wfill
            else if (!strcmp(tokenAtual.palavra, ".wfill"))
            {
                i++;
                Token tokenAtual = recuperaToken(i);
                pc+= (strtol(tokenAtual.palavra, NULL, 0))*2;
            }

            // Conta diretiva .word
            else if (!strcmp(tokenAtual.palavra, ".word"))
            {
                pc+=2;
            }
        }
    }

    //Reseta pc
    pc=0;

    // Percorre tokens
    for (int i=0; i<getNumberOfTokens(); i++)
    {
        Token tokenAtual = recuperaToken(i);

        if(tokenAtual.tipo == Instrucao)
        {

            // Erro se posicao invalida
            if (pc>=2048)
            {
                erroMontagem();
                return 1;
            }

            // Erro de sobreescricao
            if (preenchido[pc])
            {
                erroMontagem();
                return 1;
            }

            // Caso instrucao LOAD
            if (!strcmp(tokenAtual.palavra, "LOAD"))
            {
                //01
                mapa[pc][0] = '0';
                mapa[pc][1] = '1';

                i++;
                Token tokenAtual = recuperaToken(i);

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }
                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }

                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }
                preenchido[pc] = 1;
                pc++;
            }

            // Caso instrucao LOAD-
            else if (!strcmp(tokenAtual.palavra, "LOAD-"))
            {
                //02
                mapa[pc][0] = '0';
                mapa[pc][1] = '2';

                i++;
                Token tokenAtual = recuperaToken(i);

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }
                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }

                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }
                preenchido[pc] = 1;
                pc++;

            }

            // Caso instrucao LOAD|
            else if (!strcmp(tokenAtual.palavra, "LOAD|"))
            {
                //03
                mapa[pc][0] = '0';
                mapa[pc][1] = '3';

                i++;
                Token tokenAtual = recuperaToken(i);

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }
                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }
                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }
                preenchido[pc] = 1;
                pc++;
            }

            // Caso instrucao LOADmq
            else if (!strcmp(tokenAtual.palavra, "LOADmq"))
            {
                //0A sem parametro
                mapa[pc][0] = '0';
                mapa[pc][1] = 'A';
                mapa[pc][2] = '0';
                mapa[pc][3] = '0';
                mapa[pc][4] = '0';
                preenchido[pc] = 1;
                pc++;

            }

            // Caso instrucao LOADmq_mx
            else if (!strcmp(tokenAtual.palavra, "LOADmq_mx"))
            {
                //09
                mapa[pc][0] = '0';
                mapa[pc][1] = '9';

                i++;
                Token tokenAtual = recuperaToken(i);

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }
                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }

                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }
                preenchido[pc] = 1;
                pc++;
            }

            // Caso instrucao STOR
            else if (!strcmp(tokenAtual.palavra, "STOR"))
            {
                //21
                mapa[pc][0] = '2';
                mapa[pc][1] = '1';

                i++;
                Token tokenAtual = recuperaToken(i);

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }
                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }

                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }

                preenchido[pc] = 1;
                pc++;
            }

            // Caso instrucao JUMP
            else if (!strcmp(tokenAtual.palavra, "JUMP"))
            {
                //0D ESQ
                //0E DIR

                i++;
                Token tokenAtual = recuperaToken(i);

                int pos = 0;

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }

                    pos = rot->pos;
                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }

                // Hex ou Dec
                else
                {
                    int pos = strtol(tokenAtual.palavra, NULL, 0);
                    sprintf(&mapa[pc][2], "%03X", pos);
                }

                // Posicao a direita
                if (pos%2)
                {
                    mapa[pc][0] = '0';
                    mapa[pc][1] = 'E';
                }

                //Posicao a esquerda
                else
                {
                    mapa[pc][0] = '0';
                    mapa[pc][1] = 'D';
                }

                preenchido[pc] = 1;
                pc++;
            }

            // Caso instrucao JMP+
            else if (!strcmp(tokenAtual.palavra, "JMP+"))
            {
                //0F ESQ
                //10 DIR

                i++;
                Token tokenAtual = recuperaToken(i);

                int pos = 0;

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }

                    pos = rot->pos;
                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }
                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }

                // Posicao a direita
                if (pos%2)
                {
                    mapa[pc][0] = '1';
                    mapa[pc][1] = '0';
                }

                //Posicao a esquerda
                else
                {
                    mapa[pc][0] = '0';
                    mapa[pc][1] = 'F';
                }
                preenchido[pc] = 1;
                pc++;
            }

            // Caso instrucao ADD
            else if (!strcmp(tokenAtual.palavra, "ADD"))
            {
                //05
                mapa[pc][0] = '0';
                mapa[pc][1] = '5';

                i++;
                Token tokenAtual = recuperaToken(i);

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }
                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }

                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }
                preenchido[pc] = 1;
                pc++;
            }

            // Caso instrucao ADD|
            else if (!strcmp(tokenAtual.palavra, "ADD|"))
            {
                //07
                mapa[pc][0] = '0';
                mapa[pc][1] = '7';

                i++;
                Token tokenAtual = recuperaToken(i);

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }
                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }

                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }
                preenchido[pc] = 1;
                pc++;
            }

            // Caso instrucao SUB
            else if (!strcmp(tokenAtual.palavra, "SUB"))
            {
                //06
                mapa[pc][0] = '0';
                mapa[pc][1] = '6';

                i++;
                Token tokenAtual = recuperaToken(i);

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }
                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }
                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }
                preenchido[pc] = 1;
                pc++;
            }

            // Caso instrucao SUB|
            else if (!strcmp(tokenAtual.palavra, "SUB|"))
            {
                //08
                mapa[pc][0] = '0';
                mapa[pc][1] = '8';
                i++;
                Token tokenAtual = recuperaToken(i);

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }

                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }

                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }
                preenchido[pc] = 1;
                pc++;

            }

            // Caso instrucao MUL
            else if (!strcmp(tokenAtual.palavra, "MUL"))
            {
                //0B
                mapa[pc][0] = '0';
                mapa[pc][1] = 'B';

                i++;
                Token tokenAtual = recuperaToken(i);

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }
                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }

                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }

                preenchido[pc] = 1;
                pc++;
            }

            // Caso instrucao DIV
            else if (!strcmp(tokenAtual.palavra, "DIV"))
            {
                //0C
                mapa[pc][0] = '0';
                mapa[pc][1] = 'C';

                i++;
                Token tokenAtual = recuperaToken(i);

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }

                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }

                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }

                preenchido[pc] = 1;
                pc++;
            }

            // Caso instrucao LSH
            else if (!strcmp(tokenAtual.palavra, "LSH"))
            {
                //14 sem parametro
                mapa[pc][0] = '1';
                mapa[pc][1] = '4';
                mapa[pc][2] = '0';
                mapa[pc][3] = '0';
                mapa[pc][4] = '0';

                preenchido[pc] = 1;
                pc++;

            }

            // Caso instrucao RSH
            else if (!strcmp(tokenAtual.palavra, "RSH"))
            {
                //15 sem parametro
                mapa[pc][0] = '1';
                mapa[pc][1] = '5';
                mapa[pc][2] = '0';
                mapa[pc][3] = '0';
                mapa[pc][4] = '0';

                preenchido[pc] = 1;
                pc++;

            }

            // Caso instrucao STORA
            else if (!strcmp(tokenAtual.palavra, "STORA"))
            {
                //12 ESQ
                //13 DIR

                i++;
                Token tokenAtual = recuperaToken(i);
                int pos = 0;

                // Rotulo
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* rot = procuraNome(lista, tokenAtual.palavra);

                    // Erro de rotulo nao declarado
                    if (!rot)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }
                    pos = rot->pos;
                    sprintf(&mapa[pc][2], "%03X", (rot->pos)/2);
                }

                // Hex ou Dec
                else
                {
                    sprintf(&mapa[pc][2], "%03X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }

                // Posicao a direita
                if (pos%2)
                {
                    mapa[pc][0] = '1';
                    mapa[pc][1] = '3';
                }
                //Posicao a esquerda
                else
                {
                    mapa[pc][0] = '1';
                    mapa[pc][1] = '2';
                }

                preenchido[pc] = 1;
                pc++;
            }
        }

        // Caso for uma diretiva
        else if(tokenAtual.tipo == Diretiva)
        {

            // Diretiva .org
            if (!strcmp(tokenAtual.palavra, ".org"))
            {
                i++;
                Token tokenAtual = recuperaToken(i);
                pc=strtol(tokenAtual.palavra, NULL, 0)*2;
            }

            // Diretiva .align
            else if (!strcmp(tokenAtual.palavra, ".align"))
            {
                i++;
                Token tokenAtual = recuperaToken(i);
                int mult = strtol(tokenAtual.palavra, NULL, 0);

                // Se esta a direita, pula para prox linha
                if (pc%2)
                    pc++;

                // Pula para linha multipla
                while((pc/2)%mult)
                {
                    pc+=2;
                }
            }

            // Diretiva .wfill
            else if (!strcmp(tokenAtual.palavra, ".wfill"))
            {

                // Escreve na memoria
                i++;
                Token tokenAtual = recuperaToken(i);

                char string[10];
                int tam = (strtol(tokenAtual.palavra, NULL, 0)*2);

                // Erro se tenta escrever em local incorreto
                if((pc+tam)>=2048 || pc%2)
                {
                    erroMontagem();
                    return 1;
                }

                // Erro de sobreescricao
                for(int j=pc; j<tam+pc; j++)
                {
                    if(preenchido[pc])
                    {
                        erroMontagem();
                        return 1;
                    }
                }

                i++;
                tokenAtual = recuperaToken(i);

                // Se nome
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* nome = procuraNome(lista, tokenAtual.palavra);

                    // Erro de nome nao declarado
                    if (!nome)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }

                    sprintf(string, "%010X", (nome->pos)/2);
                }

                // Se decimal ou hexadecimal
                else
                {
                    sprintf(string, "%010X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }

                // Preenche mapa k linhas
                for (int k=0; k<tam; k++)
                {
                    preenchido[pc+k] = 1;

                    for(int j=0; j<5; j++)
                    {
                        mapa[pc+2*k][j] = string[j];
                        mapa[pc+2*k+1][j] = string[j+5];
                    }
                }
            }

            // Diretiva .word
            else if (!strcmp(tokenAtual.palavra, ".word"))
            {

                // Erro se tenta escrever em local incorreto
                if(pc>=2048 || pc%2)
                {
                    erroMontagem();
                    return 1;
                }

                // Erro de sobreescricao
                if(preenchido[pc] || preenchido[pc+1])
                {
                    erroMontagem();
                    return 1;
                }

                // Escreve na memoria
                i++;
                Token tokenAtual = recuperaToken(i);

                char string[10];

                // Se nome
                if (tokenAtual.tipo == Nome)
                {
                    listaNomes* nome = procuraNome(lista, tokenAtual.palavra);

                    // Erro de nome nao declarado
                    if (!nome)
                    {
                        erroDeclarado(tokenAtual.palavra);
                        return 1;
                    }

                    sprintf(string, "%010X", (nome->pos)/2);
                }

                // Se decimal ou hexadecimal
                else
                {
                    sprintf(string, "%010X", (unsigned) strtol(tokenAtual.palavra, NULL, 0));
                }

                // Preenche mapa
                for(int j=0; j<5; j++)
                {
                    mapa[pc][j] = string[j];
                    mapa[pc+1][j] = string[j+5];
                }

                preenchido[pc] = 1;
                preenchido[pc+1] = 1;
                pc+=2;

            }
        }
    }

    // Impressao mapa
    // FORMATO
    //AAA DD DDD DD DDD
    for (int i=0; i<2048; i++)
    {
        if (preenchido[i])
        {

            // Se posicao par, imprime a posicao em hexadecimal
            if(!(i%2))
            {
                printf("%03X", i/2);
            }

            printf(" %c%c %c%c%c", mapa[i][0], mapa[i][1], mapa[i][2], mapa[i][3], mapa[i][4]);

            // Se posicao impar, quebra a linha
            if(i%2)
            {
                printf("\n");
            }

        }
        // Se posicao impar vazia, complementa com 0
        else if(i%2)
        {
            if(preenchido[i-1])
            printf(" 00 000\n");
        }
    }

    return 0;
}

// Cria uma lista com simbolos e defRotulos
listaNomes* preencheNomes(listaNomes *lista)
{

    int tam = getNumberOfTokens();
    int len = 0;
    int i;
    Token tokenAtual;

    for (i=0; i<tam; i++)
    {

        tokenAtual = recuperaToken(i);

        // Insere Simbolo
        if (tokenAtual.tipo == Diretiva)
        {
            if (!strcmp(tokenAtual.palavra, ".set"))
            {
                i++;
                tokenAtual = recuperaToken(i);
                lista = insereNome(lista, tokenAtual.palavra);
            }
        }

        // Insere DefRotulo
        if (tokenAtual.tipo == DefRotulo)
        {
            len = strlen(tokenAtual.palavra);
            char* string = malloc(sizeof(char)*(len));
            strncpy(string, tokenAtual.palavra, len-1);
            string[len-1] = '\0';

            lista = insereNome(lista, string);
        }
    }

    return lista;
}

// Insere um elemento no fim da lista
listaNomes* insereNome(listaNomes *lista, char* nome)
{

    listaNomes *novo=malloc(sizeof(listaNomes));
    novo->prox = NULL;
    novo->string = nome;

    if(!lista)
    {
        lista = novo;
        return lista;
    }

    // Erro: dois nomes iguais
    if(!strcmp(lista->string, nome))
    {
        erroMontagem();
        return NULL;
    }

    if(!lista->prox)
    {
        lista->prox=novo;
    }

    else
    {
        listaNomes *aux = lista->prox;

        while(aux->prox)
        {
            aux = aux->prox;

        }

        aux->prox = novo;
    }
    return lista;
}

// Procura um nome na lista
// Retorna o elemento encontrado da lista
listaNomes* procuraNome(listaNomes* inicio, char* string)
{

    if(!inicio)
        return NULL;

    listaNomes* aux = inicio;

    do
    {
        if(!strcmp(aux->string, string))
            return aux;

        aux = aux->prox;
    }
    while(aux);

    return NULL;
}

// Funcao de teste, para imprimir lista
void imprimeLista(listaNomes *p)
{
    printf("\n");
    while(p)
    {
        printf("String:%s Pos:%d",p->string, p->pos);
        printf("\n");
        p=p->prox;
    }
    return;
}


int procuraToken(char* string)
{

    int tam = getNumberOfTokens();
    int i;

    for (i=0; i<tam; i++)
    {

        recuperaToken(i);
    }

    return i;
}

// Imprime erro caso rotulo/simbolo nao foi declarado
void erroDeclarado (char* string)
{
    fprintf(stderr, "USADO MAS NÃO DEFINIDO: %s!", string);
}

// Imprime erro de montagem
void erroMontagem ()
{
    fprintf(stderr, "Impossível montar o código!");
}
