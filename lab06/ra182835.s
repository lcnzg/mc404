.globl _start

.data

input_buffer:   .skip 32
output_buffer:  .skip 32

.text
.align 4

@ Funcao inicial
_start:
    @ Chama a funcao "read" para ler 4 caracteres da entrada padrao
    ldr r0, =input_buffer
    mov r1, #5             @ 4 caracteres + '\n'
    bl  read
    mov r4, r0             @ copia o retorno para r4.

    @ Chama a funcao "atoi" para converter a string para um numero
    ldr r0, =input_buffer
    mov r1, r4
    bl  atoi

    @ Chama a funcao "encode" para codificar o valor de r0 usando
    @ o codigo de hamming.
    bl  encode
    mov r4, r0             @ copia o retorno para r4.

    @ Chama a funcao "itoa" para converter o valor codificado
    @ para uma sequencia de caracteres '0's e '1's
    ldr r0, =output_buffer
    mov r1, #7
    mov r2, r4
    bl  itoa

    @ Adiciona o caractere '\n' ao final da sequencia (byte 7)
    ldr r0, =output_buffer
    mov r1, #'\n'
    strb r1, [r0, #7]

    @ Chama a funcao write para escrever os 7 caracteres e
    @ o '\n' na saida padrao.
    ldr r0, =output_buffer
    mov r1, #8         @ 7 caracteres + '\n'
    bl  write

    @decode
    @ Chama a funcao "read" para ler 7 caracteres da entrada padrao
    ldr r0, =input_buffer
    mov r1, #8             @ 7 caracteres + '\n'
    bl  read
    mov r4, r0             @ copia o retorno para r4.

    @ Chama a funcao "atoi" para converter a string para um numero
    ldr r0, =input_buffer
    mov r1, r4
    bl  atoi

    @ Chama a funcao "decode" para decodificar o valor de r0 usando
    @ o codigo de hamming.
    bl  decode
    mov r4, r0             @ copia o retorno para r4.
    mov r5, r1             @ copia o erro para r5.

    @ Chama a funcao "itoa" para converter o valor codificado
    @ para uma sequencia de caracteres '0's e '1's
    ldr r0, =output_buffer
    mov r1, #4
    mov r2, r4
    bl  itoa

    @ Adiciona o caractere '\n' ao final da sequencia (byte 5)
    ldr r0, =output_buffer
    mov r1, #'\n'
    strb r1, [r0, #4]

    @ Chama a funcao write para escrever os 4 caracteres e
    @ o '\n' na saida padrao.
    ldr r0, =output_buffer
    mov r1, #5         @ 4 caracteres + '\n'
    bl  write

    @ Chama a funcao "itoa" para converter o bit de erro em r1
    @ para uma sequencia de caracteres '0's e '1's
    ldr r0, =output_buffer
    mov r1, #1
    mov r2, r5
    bl  itoa

    @ Adiciona o caractere '\n' ao final da sequencia (byte 2)
    ldr r0, =output_buffer
    mov r1, #'\n'
    strb r1, [r0, #1]

    @ Chama a funcao write para escrever o caracter de erro e
    @ o '\n' na saida padrao.
    ldr r0, =output_buffer
    mov r1, #2         @ 1 caracter + '\n'
    bl  write

    @ Chama a funcao exit para finalizar processo.
    mov r0, #0
    bl  exit

@ Codifica o valor de entrada usando o codigo de hamming.
@ parametros:
@  r0: valor de entrada (4 bits menos significativos)
@ retorno:
@  r0: valor codificado (7 bits como especificado no enunciado).
encode:
       push {r4-r11, lr}

      @seleciona os digitos desejados
mov r4, r0 @ guarda entrada em r4
and r5, r4, #16 @r5 <- d1 na pos 4
and r6, r4, #4 @r6 <- d2 na pos 3
and r7, r4, #2 @r7 <- d3 na pos 2
and r8, r4, #1 @r8 <- d4 na pos 1

@ move os digitos para pos 1 (mais a direita)
mov r5, r5, lsr #3 @ d1
mov r6, r6, lsr #2 @ d2
mov r7, r7, lsr #1 @d3


@ calcula bits de paridade com xor
@r9 <- p1
eor r9, r5, r6 @ r9 <- d1 xor d2
eor r9, r9, r8 @ r9 <- r9 xor d4

@r10 <- p2
eor r10, r5, r7 @ r9 <- d1 xor d3
eor r10, r10, r8 @ r9 <- r10 xor d4

@r11 <- p3
eor r11, r6, r7 @ r9 <- d2 xor d3
eor r11, r11, r8 @ r9 <- r11 xor d4

@ guarda o resultado na posicao correta
and r4, r4, #0 @zera o registrador 4 para ele guardar o resultado
add r4, r4, r9, lsl #6 @coloca p1 no 7o bit
add r4, r4, r10, lsl #5 @coloca p2 no 6o bit
add r4, r4, r5, lsl #4 @coloca d1 no 5o bit
add r4, r4, r11, lsl #3 @coloca p3 no 4o bit
add r4, r4, r6, lsl #2 @coloca d2 no 3o bit
add r4, r4, r7, lsl #1 @coloca d3 no 2o bit
add r4, r4, r8 @coloca d4 no 1o bit
mov r0, r4


       pop  {r4-r11, lr}
       mov  pc, lr

@ Decodifica o valor de entrada usando o codigo de hamming.
@ parametros:
@  r0: valor de entrada (7 bits menos significativos)
@ retorno:
@  r0: valor decodificado (4 bits como especificado no enunciado).
@  r1: 1 se houve erro e 0 se nao houve.
decode:
       push {r4-r11, lr}

       @ <<<<<< ADICIONE SEU CODIGO AQUI >>>>>>
       mov r4, r0
       and r5, r4, #1 @r1 recebe d4
       and r6, r4, #2
       mov r6, r6, lsr #1 @r6 recebe d3
       and r7, r4, #4
       mov r7, r7, lsr #2 @r7 recebe d2
       and r8, r4, #16
       mov r8, r8, lsr #4 @r8 recebe d1
       and r4, r4, #0 @zera o registrador 4 para ele guardar o resultado
       add r4, r4, r8,  lsl #3 @coloca d1 em sua posicao final
       add r4, r4, r7, lsl #2 @coloca d2 em sua posicao final
       add r4, r4, r6, lsl #1 @coloca d3 em sua posicao final
       add r4, r4, r5 @coloca d4 em sua posicao final
       mov r0, r4 @coloca o resultado em r0
       @verificacao de paridades, o registrador r9 vai ser onde vai ser
       @armazenado o bit de paridade e o resultado do teste desse bit
       mov r1, #0 @zera r1, onde no final tera o resultado do erro
       @teste de p1
       and r9, r4, #64
       mov r9, r9, lsr #6 @r9 recebe p1
       eor r9, r9, r8 @p1 XOR d1
       eor r9, r9, r7 @d2 XOR (d1 XOR p1)
       eor r9, r9, r5 @d4 XOR d2 XOR d1 XOR p1
       cmp r9, #1 @testa se o resultado final eh 1
       moveq r1, #1
       @teste de p2
       and r9, r4, #32
       mov r9, r9, lsr #5  @r9 recebe p2
       eor r9, r9, r8 @p2 XOR d1
       eor r9, r9, r6 @p2 XOR d1 XOR d3
       eor r9, r9, r5 @p2 XOR d1 XOR d3 XOR d4
       cmp r9, #1 @testa se o resultado eh igual a 1
       moveq r1, #1
       @teste de p3
       and r9, r4, #8
       mov r9, r9, lsr #3 @r9 recebe p3
       eor r9, r9, r7 @p3 XOR d2
       eor r9, r9, r6 @p3 XOR d2 XOR d3
       eor r9, r9, r5 @p3 XOR d2 XOR d3 XOR d4
       cmp r9, #1 @testa se o resultado eh igual a 1
       moveq r1, #1

       pop  {r4-r11, lr}
       mov  pc, lr

@ Le uma sequencia de bytes da entrada padrao.
@ parametros:
@  r0: endereco do buffer de memoria que recebera a sequencia de bytes.
@  r1: numero maximo de bytes que pode ser lido (tamanho do buffer).
@ retorno:
@  r0: numero de bytes lidos.
read:
    push {r4,r5, lr}
    mov r4, r0
    mov r5, r1
    mov r0, #0         @ stdin file descriptor = 0
    mov r1, r4         @ endereco do buffer
    mov r2, r5         @ tamanho maximo.
    mov r7, #3         @ read
    svc 0x0
    pop {r4, r5, lr}
    mov pc, lr

@ Escreve uma sequencia de bytes na saida padrao.
@ parametros:
@  r0: endereco do buffer de memoria que contem a sequencia de bytes.
@  r1: numero de bytes a serem escritos
write:
    push {r4,r5, lr}
    mov r4, r0
    mov r5, r1
    mov r0, #1         @ stdout file descriptor = 1
    mov r1, r4         @ endereco do buffer
    mov r2, r5         @ tamanho do buffer.
    mov r7, #4         @ write
    svc 0x0
    pop {r4, r5, lr}
    mov pc, lr

@ Finaliza a execucao de um processo.
@  r0: codigo de finalizacao (Zero para finalizacao correta)
exit:
    mov r7, #1         @ syscall number for exit
    svc 0x0

@ Converte uma sequencia de caracteres '0' e '1' em um numero binario
@ parametros:
@  r0: endereco do buffer de memoria que armazena a sequencia de caracteres.
@  r1: numero de caracteres a ser considerado na conversao
@ retorno:
@  r0: numero binario
atoi:
    push {r4, r5, lr}
    mov r4, r0         @ r4 == endereco do buffer de caracteres
    mov r5, r1         @ r5 == numero de caracteres a ser considerado
    mov r0, #0         @ number = 0
    mov r1, #0         @ loop indice
atoi_loop:
    cmp r1, r5         @ se indice == tamanho maximo
    beq atoi_end       @ finaliza conversao
    mov r0, r0, lsl #1
    ldrb r2, [r4, r1]
    cmp r2, #'0'       @ identifica bit
    orrne r0, r0, #1
    add r1, r1, #1     @ indice++
    b atoi_loop
atoi_end:
    pop {r4, r5, lr}
    mov pc, lr

@ Converte um numero binario em uma sequencia de caracteres '0' e '1'
@ parametros:
@  r0: endereco do buffer de memoria que recebera a sequencia de caracteres.
@  r1: numero de caracteres a ser considerado na conversao
@  r2: numero binario
itoa:
    push {r4, r5, lr}
    mov r4, r0
itoa_loop:
    sub r1, r1, #1         @ decremento do indice
    cmp r1, #0          @ verifica se ainda ha bits a serem lidos
    blt itoa_end
    and r3, r2, #1
    cmp r3, #0
    moveq r3, #'0'      @ identifica o bit
    movne r3, #'1'
    mov r2, r2, lsr #1  @ prepara o proximo bit
    strb r3, [r4, r1]   @ escreve caractere na memoria
    b itoa_loop
itoa_end:
    pop {r4, r5, lr}
    mov pc, lr
