LOAD M(tamvet) # carrega tamanho vetores
SUB M(um) # diminui 1 do tamanho pois jump funciona quando n >= 0

laco:
STOR M(tamvet) # salva tamanho reduzido
LOAD M(vet1) # carrega posicao vetor 1
STA M(pos2) # muda endereco da pos2
ADD M(um) # soma 1 na posicao do vetor 1
STOR M(vet1) # guarda prox posicao vetor 1
LOAD M(vet2) # carrega posicao vetor 2
STA M(pos1) # muda endereco da pos1
ADD M(um) # soma 1 na posicao do vetor 2
STOR M(vet2) # guarda prox posicao vetor 2

pos1:
LOAD MQ,M(0) # carrega em mq o endereco alterado pelo stor (vetor 2)

pos2:
MUL M(0) # multiplica mq pelo endereco alterado pelo stor (vetor 1)

LOAD MQ # transfere de mq para ac
ADD M(soma) # soma total com multiplicacao realizada
STOR M(soma) # guarda a nova soma
LOAD M(tamvet) # carrega tamanho restante do vetor
SUB M(um) # decrementa 1 do tamanho

JUMP+ M(laco) # pula para posicao laco enquanto tamanho >= 0
LOAD M(soma) # carrega soma em AC
JUMP M(0x400) # pula para posicao 0x400 inexistente (termina execucao)

# VARIAVEIS
.align 1
.org 0x0fe
soma:
  .word 0 # soma
um:
  .word 1 # constante 1

.org 0x3fd
vet1:
  .word 0 # endereco vetor 1
vet2:
  .word 0 # endereco vetor 2
tamvet:
  .word 0 # tamanho vetores / contador
