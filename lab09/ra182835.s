@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
@ Codigo de usuário que ajusta a direção do robô para evitar colisões.
@ São utilizados os sonares frontais (3 e 4) do robô para detectar obstáculos
@ e controlar seus motores para redirecionar o robô de modo que ele os evite.
@ Após desviar, o robô segue uma trajetória retilínea.
@
@ 2 syscalls serao utilizadas para controlar o robo:
@   write_motors  (syscall de numero 124)
@                 Parametros:
@                       r0 : velocidade para o motor 0  (valor de 6 bits)
@                       r1 : velocidade para o motor 1  (valor de 6 bits)
@
@  read_sonar (syscall de numero 125)
@                 Parametros:
@                       r0 : identificador do sonar   (valor de 4 bits)
@                 Retorno:
@                       r0 : distancia capturada pelo sonar consultado (valor de 12 bits)
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


.text
.align 4
.globl _start

_start:                         @ main

        mov r0, #0              @ Carrega em r0 a velocidade do motor 0.
                                @ Lembre-se: apenas os 6 bits menos significativos
                                @ serao utilizados.
        mov r1, #0              @ Carrega em r1 a velocidade do motor 1.
        mov r7, #124            @ Identifica a syscall 124 (write_motors).
        svc 0x0                 @ Faz a chamada da syscall.

        ldr r6, =1200           @ r6 <- 1200 (Limiar para rotacionar o robo)
        ldr r8, =900            @ r8 <- 900 (limiar de sentido)

loop:
        mov r0, #3              @ Define em r0 o identificador do sonar a ser consultado. (esq)
        mov r7, #125            @ Identifica a syscall 125 (read_sonar).
        svc 0x0
        mov r5, r0              @ Armazena o retorno da syscall.

        mov r0, #4              @ Define em r0 o sonar. (dir)
        mov r7, #125
        svc 0x0

        mov r1, #0              @ Se preciso, virar para esquerda
        cmp r5, r0              @ Compara o retorno (em r0) com r5.
        bge min                 @ Se r5 > r0: Salta pra min
        mov r0, r5              @ Senao: r0 <- r5
        mov r1, #1              @ Se preciso, virar para direita

min:
        cmp r0, r6              @ Compara r0 com r6
        blt vira                @ Se r0 menor que o limiar: vira

                                @ Senao define uma velocidade igual para os 2 motores
        mov r0, #36
        mov r1, #36
        mov r7, #124
        svc 0x0

        b loop                  @ Refaz toda a logica

vira:
        cmp r1, #1              @ Compara se deve virar para direita
        cmpeq r8, r0            @ Compara com o limiar de sentido
        blt viraEsq             @ Vira para a esquerda se a dist a direita for menor que o limiar
        b viraDir               @ Vira para a direita se a dist a esquerda for menor que o limiar

viraDir:                        @ Vira para direita

        mov r0, #0              @ Para roda da direita
        mov r1, #10              @ Movimenta roda da esquerda
        mov r7, #124
        svc 0x0

        b loop

viraEsq:                        @ Vira para esquerda

        mov r0, #10              @ Movimenta roda da direita
        mov r1, #0              @ Para roda da esquerda
        mov r7, #124
        svc 0x0

        b loop

end:                            @ Parar o robo
        mov r0, #0
        mov r1, #0
        mov r7, #124
        svc 0x0

        mov r7, #1              @ syscall exit
        svc 0x0
