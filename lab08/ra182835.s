.global ajudaORobinson

.data

saida:
.skip 4

aviso:
  .asciz "Não existe um caminho!\n"

.text
.align 4

ajudaORobinson: @ void
  stmfd sp!, {lr}

  bl inicializaVisitados  @ funcao que zera matriz de visitados

  bl posicaoYRobinson     @ r0: recebe pos y
  mov r1, r0              @ r1: recebe pos y
  bl posicaoXRobinson     @ r0: recebe pos x

  bl buscaDFS @ inicia a busca em profundidade

  @ Caso nao achou caminho, imprime aviso
  cmp r0, #0
  ldreq r0, =aviso
  moveq r1, #23
  bleq write

  ldmfd sp!, {pc} @ fim funcao ajudaORobinson

@ Funcao recursiva para encontrar um caminho
@ parametros:
@  r0: posicao x
@  r1: posicao y
@ retorno:
@  r0: 1 se encontrou caminho, 0 se nao
buscaDFS:
  stmfd sp!, {r6-r9, lr}

  @ Salva entrada
  mov r6, r0        @ r6: pos x
  mov r7, r1        @ r7: pos y

  @ Chama funcao foiVisitado
  mov r0, r6
  mov r1, r7
  bl foiVisitado

  cmp r0, #1        @ Caso ja foiVisitado (retorna 0)
  beq buscaDFS_ret0

  @ Chama funcao daParaPassar
  mov r0, r6
  mov r1, r7
  bl daParaPassar

  cmp r0, #0        @ Caso nao daParaPassar (retorna 0)
  beq buscaDFS_ret0

  @ Chama funcoes que verificam a posicao de destino
  mov r8, #0        @ Zera variaveis auxiliares
  mov r9, #0
  bl posicaoXLocal  @ Recebe pos x final
  cmp r0, r6
  moveq r8, #1      @ Se chegou no x final, r8 = 1
  bl posicaoYLocal  @ Recebe pos y final
  cmp r0, r7
  moveq r9, #1      @ Se chegou no y final, r9 = 1

  @ Caso encontrou caminho (imprime e retorna 1)
  cmpeq r8, r9
  beq buscaDFS_imprime

  @ Chama funcao visitaCelula (marca visita em progresso)
  mov r0, r6
  mov r1, r7
  bl visitaCelula

  @ Visita recursivamente os vizinhos de x, y
  @
  @ -> (x++, y)
  add r0, r6, #1
  mov r1, r7
  bl buscaDFS
  cmp r0, #1 @ Se retorna 1, imprime a posicao atual
  beq buscaDFS_imprime
  @
  @ /^ (x++, y--)
  add r0, r6, #1
  sub r1, r7, #1
  bl buscaDFS
  cmp r0, #1
  beq buscaDFS_imprime
  @
  @ ^ (x, y--)
  mov r0, r6
  sub r1, r7, #1
  bl buscaDFS
  cmp r0, #1
  beq buscaDFS_imprime
  @
  @ ^\ (x--, y--)
  sub r0, r6, #1
  sub r1, r7, #1
  bl buscaDFS
  cmp r0, #1
  beq buscaDFS_imprime
  @
  @ <- (x, y--)
  mov r0, r6
  sub r1, r7, #1
  bl buscaDFS
  cmp r0, #1
  beq buscaDFS_imprime
  @
  @ |/  (x--, y++)
  sub r0, r6, #1
  add r1, r7, #1
  bl buscaDFS
  cmp r0, #1
  beq buscaDFS_imprime
  @
  @ \/ (x, y++)
  mov r0, r6
  add r1, r7, #1
  bl buscaDFS
  cmp r0, #1
  beq buscaDFS_imprime
  @
  @ \| (x++, y++)
  add r0, r6, #1
  add r1, r7, #1
  bl buscaDFS
  cmp r0, #1
  beq buscaDFS_imprime
  @ @ @

  @ Imprimir coordenadas x y (r6 r7)
  buscaDFS_imprime:
    ldr r0, =saida

    add r6, r6, #'0'  @ converte posicoes para char
    add r7, r7, #'0'

    str r6, [r0]      @ coloca x no buffer

    mov r8, #' '      @ coloca espaco no buffer
    str r8, [r0, #1]

    str r7, [r0, #2]  @ coloca y no buffer

    mov r8, #'\n'     @ coloca '\n' no buffer
    str r8, [r0, #3]

    mov r1, #4        @ escreve na saida padrao
    bl write

    b buscaDFS_ret1   @ retorna 1

  buscaDFS_ret0:
    moveq r0, #0            @ retorno 0
    ldmfd sp!, {r6-r9, pc}  @ fim funcao buscaDFS

  buscaDFS_ret1:
    moveq r0, #1            @ retorno 1
    ldmfd sp!, {r6-r9, pc}  @ fim funcao buscaDFS

@ Escreve uma sequencia de bytes na saida padrao.
@ parametros:
@  r0: endereco do buffer de memoria que contem a sequencia de bytes.
@  r1: numero de bytes a serem escritos
write:
			push {r5, r7, lr}
			mov r4, r0
			mov r5, r1
			mov r0, #1         @ stdout file descriptor = 1
			mov r1, r4         @ endereco do buffer
			mov r2, r5         @ tamanho do buffer.
			mov r7, #4         @ write
			svc 0x0
			pop {r5, r7, lr}
			mov pc, lr
