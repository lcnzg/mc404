# v = (gx)^1/2

LOAD MQ,M(x) # transfere x para MQ
MUL M(g) # multiplica MQ (x) pelo g e salva em MQ
LOAD MQ # transfere o menos significativo da multiplicacao do MQ para o AC
STOR M(y) # salva gx (y) em 0x101
RSH # divide AC por 2
STOR M(k) # salva k em 0x102

# repetir 10x
laco:
LOAD M(y) # carrega o y em AC
DIV M(k) # divide ac por k e salva em mq
LOAD MQ # passa de mq para ac
ADD M(k) # soma AC com k
RSH # divide AC por 2
STOR M(k) # salva k em 0x102
LOAD M(cont) # carrega contador
SUB M(um) # decrementa 1 do contador
STOR M(cont) # salva novo contador
# fim do trecho a ser repetido

JUMP+ M(laco)
LOAD M(k) # salva resultado em AC
JUMP M(0x400) # pula para posicao 0x400 inexistente (termina execucao)

# VARIAVEIS
.align 1
.org 0x100
g:
    .word 10
y:
  .word 0
k:
  .word 0
cont:
  .word 9
um:
  .word 1

.org 0x105
x:
  .word 0
