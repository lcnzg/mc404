#include "montador.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void erroGramatical(unsigned linha);
void erroLexico(unsigned linha);
int verNome(char* string, unsigned linha);
int verDecimal (char* string, unsigned linha);
int verHexadecimal (char* string, unsigned linha);
int verInstrucao (char* string, unsigned linha);
int verDiretiva(char* string, unsigned linha);
int verNome(char* string, unsigned linha);

/*
 * Argumentos:
 *  entrada: cadeia de caracteres com o conteudo do arquivo de entrada.
 *  tamanho: tamanho da cadeia.
 * Retorna:
 *  1 caso haja erro na montagem;
 *  0 caso não haja erro.
 */
int processarEntrada(char* entrada, unsigned tamanho)
{
    int ignorar = 0; // 1: ignora a leitura de caracteres
    char string[64]; // substring
    int pos=0; // posicao de leitura da substring
    unsigned linha = 1; // linha atual de leitura
    int ordem = 0; // 0: inicio; 1: rotulo; 2: instrucao; 3: diretiva
    int diretiva = 0; // 0: nenhuma; 1: set; 2: org; 3: align; 4: wfill; 5: word
    int argumento = 0; // 0: nenhum; 1: existe 1; 2: existe 2
    int instrucao = 0; // 0: nenhuma; 1: 1 argumento; 2: sem argumento

    string[0] = '\0';

    // Le o vetor de caracteres inteiro
    for(int i=0; i<tamanho-1; i++)
    {

        // Le comentario
        if (entrada[i] == '#')
        {
            ignorar = 1;
            continue;
        }

        // Ignora se for comentario
        if (ignorar && entrada[i] != '\n')
        {
            continue;
        }

        // Verifica os espacos
        if (entrada[i] == ' ' || entrada[i] == '\t' || entrada[i] == '\n')
        {

            // Se os espacos estao no comeco da palavra, ignora
            if ((entrada[i] == ' ' || entrada[i] == '\t') && !pos)
            {
                continue;
            }

            // Le rotulo OK
            if (string[pos-1] == ':')
            {
                string[pos] = '\0';

                // Verificar e enviar token
                if (!verNome(string, linha))
                {
                    return 1;
                }

                // Se nao for o primeiro elemento da linha
                if (ordem != 0)
                {
                    erroGramatical(linha);
                    return 1;
                }

                ordem = 1;

                char *palavra = (char*) malloc((strlen(string)+1)*sizeof(char));
                strcpy(palavra, string);


                Token rotulo;
                rotulo.tipo = DefRotulo;
                rotulo.palavra = palavra;
                rotulo.linha = linha;

                adicionarToken(rotulo);

                pos = 0;
                string[0] = '\0';
            }

            // Entre aspas (argumento de instrucao)
            else if (string[0] == '"')
            {

                // Caso hexadecimal
                if (string[1] == '0' && string[2] == 'x')
                {
                    string[pos-1] = '\0';
                    argumento++;

                    // Verifica se a posicao do numero e valida
                    if (instrucao == 2 || argumento > 1 || ordem != 2)
                    {
                        erroGramatical(linha);
                        return 1;
                    }

                    // Verifica se o numero hexadecimal e valido
                    if (!verHexadecimal((string+1), linha))
                    {
                        return 1;
                    }

                    // Cria token hexadecimal
                    char *palavra = (char*) malloc(strlen(string)*sizeof(char));
                    strcpy(palavra, (string+1));

                    Token hexadecimal;
                    hexadecimal.tipo = Hexadecimal;
                    hexadecimal.palavra = palavra;
                    hexadecimal.linha = linha;

                    adicionarToken(hexadecimal);

                    pos = 0;
                    string[0] = '\0';
                }

                // Caso decimal
                else if (string[1] >= '0' && string[1] <= '9')
                {

                    string[pos-1] = '\0';
                    argumento++;

                    // Verifica se a posicao do numero e valida
                    if (instrucao == 2 || argumento > 1 || ordem != 2)
                    {
                        erroGramatical(linha);
                        return 1;
                    }

                    // Verifica se o numero decimal e valido
                    if (!verDecimal((string+1), linha))
                    {
                        return 1;
                    }

                    // Cria token decimal
                    char *palavra = (char*) malloc(strlen(string)*sizeof(char));
                    strcpy(palavra, (string+1));

                    Token decimal;
                    decimal.tipo = Decimal;
                    decimal.palavra = palavra;
                    decimal.linha = linha;

                    adicionarToken(decimal);

                    pos = 0;
                    string[0] = '\0';
                }

                // Caso nome (endereco)
                else
                {
                    string[pos-1] = '\0';
                    argumento++;

                    if (instrucao == 2 || argumento > 1 || ordem != 2)
                    {
                        erroGramatical(linha);
                        return 1;
                    }

                    // Verifica se o nome e valido
                    if (!verNome((string+1), linha))
                    {
                        return 1;
                    }

                    // Cria token de nome
                    char *palavra = (char*) malloc(strlen(string)*sizeof(char));
                    strcpy(palavra, (string+1));

                    Token endereco;
                    endereco.tipo = Nome;
                    endereco.palavra = palavra;
                    endereco.linha = linha;

                    adicionarToken(endereco);

                    pos = 0;
                    string[0] = '\0';
                }
            }

            // Caso hexadecimal (diretiva)
            else if (string[0] == '0' && string[1] == 'x')
            {
                ordem = 3;
                string[pos] = '\0';
                argumento++;

                // Caso .set
                if (diretiva == 1)
                {
                    if (argumento != 2)
                    {
                        erroGramatical(linha);
                        return 1;
                    }
                }

                // Caso .org
                else if (diretiva == 2)
                {
                    if (argumento != 1)
                    {
                        erroGramatical(linha);
                        return 1;
                    }
                }

                // Caso .align
                else if (diretiva == 3)
                {
                    erroGramatical(linha);
                    return 1;
                }

                // Caso .wfill
                else if (diretiva == 4)
                {
                    if (argumento != 2)
                    {
                        erroGramatical(linha);
                        return 1;
                    }
                }

                // Caso .word
                else if (diretiva == 5)
                {
                    if (argumento != 1)
                    {
                        erroGramatical(linha);
                        return 1;
                    }
                }

                // Se nao for argumento de diretiva
                else
                {
                    erroGramatical(linha);
                    return 1;
                }

                // Verifica se numero hexadecimal e valido
                if (!verHexadecimal(string, linha))
                {
                    return 1;
                }

                // Cria token hexadecimal
                char *palavra = (char*) malloc((strlen(string)+1)*sizeof(char));
                strcpy(palavra, string);

                Token hexadecimal;
                hexadecimal.tipo = Hexadecimal;
                hexadecimal.palavra = palavra;
                hexadecimal.linha = linha;

                adicionarToken(hexadecimal);

                pos = 0;
                string[0] = '\0';
            }

            // Caso decimal
            else if ((string[0] >= '0' && string[0] <= '9') || string[0] == '-')
            {
                ordem = 3;
                string[pos] = '\0';
                argumento++;

                // Caso .set
                if (diretiva == 1)
                {
                    if (argumento != 2)
                    {
                        erroGramatical(linha);
                        return 1;
                    }
                }

                // Caso .org
                else if (diretiva == 2)
                {
                    if (argumento != 1 || string[0] == '-')
                    {
                        erroGramatical(linha);
                        return 1;
                    }
                }

                // Caso .align
                else if (diretiva == 3)
                {
                    if (argumento != 1 || string[0] == '-')
                    {
                        erroGramatical(linha);
                        return 1;
                    }
                }

                // Caso .wfill
                else if (diretiva == 4)
                {
                    if ((argumento != 1  || string[0] == '-') && argumento != 2)
                    {
                        erroGramatical(linha);
                        return 1;
                    }
                }

                // Caso .word
                else if (diretiva == 5)
                {
                    if (argumento != 1)
                    {
                        erroGramatical(linha);
                        return 1;
                    }
                }

                // Se nao for argumento de diretiva
                else
                {
                    erroGramatical(linha);
                    return 1;
                }

                // Verifica se numero decimal e valido
                if (!verDecimal(string, linha))
                {
                    return 1;
                }

                // Cria token decimal
                char *palavra = (char*) malloc((strlen(string)+1)*sizeof(char));
                strcpy(palavra, string);

                Token decimal;
                decimal.tipo = Decimal;
                decimal.palavra = palavra;
                decimal.linha = linha;

                adicionarToken(decimal);

                pos = 0;
                string[0] = '\0';
            }


            // Caso diretiva
            else if (string[0] == '.')
            {
                // Verifica se a posicao da diretiva e valida
                if (ordem != 0 && ordem != 1)
                {
                    erroGramatical(linha);
                    return 1;
                }

                ordem = 3;
                string[pos] = '\0';
                diretiva = verDiretiva(string, linha);

                // Verifica se diretiva e valida
                if (!diretiva)
                {
                    return 1;
                }

                // Cria token de diretiva
                char *palavra = (char*) malloc((strlen(string)+1)*sizeof(char));
                strcpy(palavra, string);

                Token diretiva;
                diretiva.tipo = Diretiva;
                diretiva.palavra = palavra;
                diretiva.linha = linha;

                adicionarToken(diretiva);

                pos = 0;
                string[0] = '\0';
            }

            else if (string[0] != '\0')
            {
                string[pos] = '\0';

                // Caso instrucao
                if ((instrucao = verInstrucao(string, linha)))
                {
                    // Verifica se posicao da instrucao e valida
                    if (ordem != 0 && ordem != 1)
                    {
                        erroGramatical(linha);
                        return 1;
                    }

                    ordem = 2;

                    char *palavra = (char*) malloc((strlen(string)+1)*sizeof(char));
                    strcpy(palavra, string);

                    Token instrucao;
                    instrucao.tipo = Instrucao;
                    instrucao.palavra = palavra;
                    instrucao.linha = linha;

                    adicionarToken(instrucao);

                    pos = 0;
                    string[0] = '\0';
                }

                // Caso nome (SYM/ROT) de diretiva
                else
                {
                    string[pos] = '\0';
                    argumento++;

                    // Caso .set
                    if (diretiva == 1)
                    {
                        if (argumento != 1)
                        {
                            erroGramatical(linha);
                            return 1;
                        }
                    }

                    // Caso .org
                    else if (diretiva == 2)
                    {
                        erroGramatical(linha);
                        return 1;
                    }

                    // Caso .align
                    else if (diretiva == 3)
                    {
                        erroGramatical(linha);
                        return 1;
                    }

                    // Caso .wfill
                    else if (diretiva == 4)
                    {
                        if (argumento != 2)
                        {
                            erroGramatical(linha);
                            return 1;
                        }
                    }

                    // Caso .word
                    else if (diretiva == 5)
                    {
                        if (argumento != 1)
                        {
                            erroGramatical(linha);
                            return 1;
                        }
                    }

                    // Se nao for argumento de diretiva
                    else
                    {
                        erroGramatical(linha);
                        return 1;
                    }

                    // Verifica se o nome e valido
                    if (!verNome(string, linha))
                    {
                        return 1;
                    }

                    // Cria token de nome
                    char *palavra = (char*) malloc((strlen(string)+1)*sizeof(char));
                    strcpy(palavra, string);

                    Token endereco;
                    endereco.tipo = Nome;
                    endereco.palavra = palavra;
                    endereco.linha = linha;

                    adicionarToken(endereco);

                    pos = 0;
                    string[0] = '\0';
                }
            }

            // Muda para proxima linha
            if (entrada[i] == '\n')
            {
                pos = 0;
                string[0] = '\0';
                ignorar = 0;
                ordem = 0;
                diretiva = 0;
                argumento = 0;
                instrucao = 0;
                linha++;
            }

            continue;
        }

        // Le a substring
        string[pos] = entrada[i];
        pos++;
    }

    return 0;
}


// Imprime erro gramatical
void erroGramatical(unsigned linha)
{
    fprintf(stderr, "ERRO GRAMATICAL: palavra na linha %d!", linha);
}

// Imprime erro lexico
void erroLexico(unsigned linha)
{
    fprintf(stderr, "ERRO LEXICO: palavra inválida na linha %d!", linha);
}

/*
 * Argumentos:
 *  string: cadeia de caracteres com o possivel nome.
 * Retorna:
 *  1 caso nome seja valido;
 *  0 caso nome seja invalido.
 */
int verNome(char* string, unsigned linha)
{
    // Se o primeiro caracter for numero, o rotulo e invalido
    if (string[0] >= '0' && string[0] <= '9')
    {
        erroLexico(linha);
        return 0;
    }

    // Verifica se e alfanumerico ou inderscore
    for(int i=0; i<strlen(string)-1; i++)
    {
        if (!((string[i] >= 'A' && string[i] <= 'z') || (string[i] >= '0' && string[i] <= '9') || string[i] == '_'))
        {
            erroLexico(linha);
            return 0;
        }

    }

    return 1;
}

/*
 * Argumentos:
 *  string: cadeia de caracteres com a possivel diretiva.
 * nao verifica argumentos
 * Retorna:
 *  >0 caso diretiva seja valida, cada numero corresponde a uma diretiva;
 *  0 caso diretiva seja invalida.
 */
int verDiretiva(char* string, unsigned linha)
{
    if (!strcmp(".set", string))
        return 1;

    if (!strcmp(".org", string))
        return 2;

    if (!strcmp(".align", string))
        return 3;

    if (!strcmp(".wfill", string))
        return 4;

    if (!strcmp(".word", string))
        return 5;

    return 0;
}

/*
 * Argumentos:
 *  string: cadeia de caracteres com a possivel instrucao.
 * nao verifica enderecos/rotulos
 * Retorna:
 *  1 caso instrucao seja valido;
 * 2 caso seja valida mas nao requer argumento
 *  0 caso instrucao seja invalido.
 */
int verInstrucao (char* string, unsigned linha)
{
    if (!strcmp("LOAD", string))
        return 1;

    if (!strcmp("LOAD-", string))
        return 1;

    if (!strcmp("LOAD|", string))
        return 1;

    if (!strcmp("LOADmq", string))
        return 2;

    if (!strcmp("LOADmq_mx", string))
        return 1;

    if (!strcmp("STOR", string))
        return 1;

    if (!strcmp("JUMP", string))
        return 1;

    if (!strcmp("JMP+", string))
        return 1;

    if (!strcmp("ADD", string))
        return 1;

    if (!strcmp("ADD|", string))
        return 1;

    if (!strcmp("SUB", string))
        return 1;

    if (!strcmp("SUB|", string))
        return 1;

    if (!strcmp("MUL", string))
        return 1;

    if (!strcmp("DIV", string))
        return 1;

    if (!strcmp("LSH", string))
        return 2;

    if (!strcmp("RSH", string))
        return 2;

    if (!strcmp("STORA", string))
        return 1;

    return 0;
}

/*
 * Argumentos:
 *  string: cadeia de caracteres com a possivel numero hexadecimal.
 * Retorna:
 *  1 caso hexadecimal seja valido;
 *  0 caso hexadecimal seja invalido.
 */
int verHexadecimal (char* string, unsigned linha)
{
    // Verifica se comeca com 0x
    if (!(string[0] == '0' && string[1] == 'x'))
    {
        erroLexico(linha);
        return 0;
    }

    // Verifica se esta entre 0 a 9 e A/a e F/f com 12 caracteres
    for(int i=2; i<12; i++)
    {
        if (!((string[i] >= 'A' && string[i] <= 'F') || (string[i] >= 'a' && string[i] <= 'f') || (string[i] >= '0' && string[i] <= '9')))
        {
            erroLexico(linha);
            return 0;
        }
    }

    return 1;
}

/*
 * Argumentos:
 *  string: cadeia de caracteres com a possivel numero decimal.
 * Retorna:
 *  1 caso decimal seja valido;
 *  0 caso decimal seja invalido.
 */
int verDecimal (char* string, unsigned linha)
{
    // Verifica se o primeiro digito e negativo ou numero
    if (!(((string[0] >= '0') && (string[0] <= '9')) || string[0] == '-'))
        {
            erroLexico(linha);
            return 0;
        }

    // Verifica se e numero
    for(int i=1; string[i] != '\0' ; i++)
    {

        if (!((string[i] >= '0') && (string[i] <= '9')))
        {
            erroLexico(linha);
            return 0;
        }
    }

    return 1;
}
