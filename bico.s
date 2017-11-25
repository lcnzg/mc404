.global set_motor_speed
.global set_motors_speed
.global read_sonar
.global read_sonars
.global register_proximity_callback
.global add_alarm
.global get_time
.global set_time

.text
.align 4

@ set_motor_speed
@ Parametros:
@ r0: ponteiro para struct "motor_cfg_t" (2 bytes)
@ Retorno:
@ -
set_motor_speed:
    push {r7, lr}

    @ Parametros da syscall 18
    ldrb r1, [r0, #1] @ carrega byte 2 da struct no r1
    ldrb r0, [r0] @ carrega byte 1 da struct no r0

    mov r7, #18
    svc 0x0 @ chama a syscall 18

    pop {r7, pc}

@ set_motors_speed
@ Parametros:
@ r0: ponteiro para struct "motor_cfg_t" (2 bytes)
@ r1: ponteiro para outra struct "motor_cfg_t" (2 bytes)
@ Retorno:
@ -
set_motors_speed:
    push {r7, lr}

    ldrb r7, [r0] @ carrega byte 1 da struct 1 no r4

    cmp r7, #1 @ inverte ponteiros se struct 1 for do motor 1
        moveq r7, r0
        moveq r0, r1
        moveq r1, r7

    @ Agora r0 se refere ao motor0 e r1 ao motor1

    @ Parametros da syscall 19
    ldrb r1, [r1, #1] @ carrega byte 2 da struct no r1
    ldrb r0, [r0, #1] @ carrega byte 2 da struct no r1

    mov r7, #19
    svc 0x0 @ chama a syscall 19

    pop {r7, pc}

@ read_sonar
@ Parametros:
@ r0: identificador do sonar (0 a 15)
@ Retorno:
@ r0: distancia / -1: sonar invalido
read_sonar:
    push {r7, lr}

    mov r7, #16
    svc 0x0 @ chama a syscall 16

    pop {r7, pc}

@ read_sonars
@ Parametros:
@ r0: identificador do sonar inicial (0 a 15)
@ r1: identificador do sonar final (0 a 15)
@ r2: ponteiro para vetor de distancias
@ Retorno:
@ -
read_sonars:
    push {r4-r8, lr}

    @ guarda parametros
    mov r4, r0 @ r4 <- r0
    mov r5, r1 @ r5 <- r1
    mov r6, r2 @ r6 <- r2

    mov r7, #16 @ parametro para syscall
    mov r8, #0 @ contador

    read_sonars_loop:
        mov r0, r4
        svc 0x0 @ chama a syscall 16

        str r0, [r6, r8, lsl #2] @ guarda retorno no vetor

        cmp r4, r5 @ se r4 < r5, repete
        add r4, r4, #1
        add r8, r8, #1
        blo read_sonars_loop

    pop {r4-r8, pc}

@ register_proximity_callback
@ Parametros:
@ r0: identificador do sonar (0 a 15)
@ r1: limiar de distancia
@ r2: ponteiro funcao caso alarme
@ Retorno:
@ -
register_proximity_callback:
    push {r7, lr}

    mov r7, #17
    svc 0x0 @ chama a syscall 17

    pop {r7, pc}

@ add_alarm
@ Parametros:
@ r0: ponteiro funcao caso alarme
@ r1: tempo do sistema
@ Retorno:
@ -
add_alarm:
    push {r7, lr}

    mov r7, #22
    svc 0x0 @ chama a syscall 22

    pop {r7, pc}

@ get_time
@ Parametros:
@ r0: ponteiro para variavel que recebera o tempo do sistema
@ Retorno:
@ -
get_time:
    push {r7, lr}

    mov r4, r0 @ guarda parametro

    mov r7, #20
    svc 0x0 @ chama a syscall 20

    str r0, [r4] @ guarda o retorno no endereco do parametro

    pop {r7, pc}

@ set_time
@ Parametros:
@ r0: tempo do sistema
@ Retorno:
@ -
set_time:
    push {r7, lr}

    mov r7, #21
    svc 0x0 @ chama a syscall 21

    pop {r7, pc}
