.org 0x0
.section .iv, "a"

_start:

interrupt_vector:
b RESET_HANDLER
b NOT_HANDLED
.org 0x08
b SWI_HANDLER @ interrupcoes de software
b NOT_HANDLED
b NOT_HANDLED
b NOT_HANDLED
.org 0x18
b IRQ_HANDLER @ interrupcao IRQ
b NOT_HANDLED

.data
SYS_TIME:             .skip 4
USER_TEXT:            .word 0x77812000
IRQ_HANDLER_DEPTH     .word 0
IRQ_STACK:            .skip 4096
IRQ_STACK_BEGIN:
SUPERVISOR_STACK:     .skip 1024
SUPERVISOR_STACK_BEGIN:

@ fila de alarmes
@ estrutura (9 bytes cada):
@ . apontador de subrotina [0:31]
@ . tempo do alarme [32:63]
@ . FLAG: alarme já chamado [64:71], só o lsb é usado
CALL_ALARM_QUEUE:     .skip 72
CALL_ALARM_N:         .word 0
@ fila de callbacks de proximidade
@ estrutura (12 bytes cada):
@ . FLAG: callback já [0:0]
@ . identificador do sonar [4 bytes]
@ . apontador de subrotina [4 bytes]
@ . proximidade do alarme [4 bytes]
CALL_PROX_QUEUE:      .skip 96
CALL_PROX_N:          .word 0

SYSCALL_TABLE:
.word read_sonar
.word register_proximity_callback
.word set_motor_speed
.word set_motors_speed
.word get_time
.word set_time
.word set_alarm

@ Constantes para os enderecos do GPT
.set GPT_BASE,        0x53FA0000
.set GPT_CR,          0x0
.set GPT_PR,          0x4
.set GPT_SR,          0x8
.set GPT_IR,          0xC
.set GPT_OCR1,        0x10

@ Constantes para os enderecos do TZIC
.set TZIC_BASE,       0x0FFFC000
.set TZIC_INTCTRL,    0x0
.set TZIC_INTSEC1,    0x84
.set TZIC_ENSET1,     0x104
.set TZIC_PRIOMASK,   0xC
.set TZIC_PRIORITY9,  0x424

@ Constantes para os enderecos do GPIO
.set GPIO_BASE,       0x53F84000
.set GPIO_DR,         0x0
.set GPIO_GDIR,       0x4
.set GPIO_PSR,        0x8

.set TIME_SZ,         200

.set USER_STACK_BEGIN,  0x80000000

.set MAX_CALLBACKS,   8
.set MAX_ALARMS,      8

.align 4
.text
RESET_HANDLER:
    @ Zera o contador
    ldr r1, =SYS_TIME
    mov r0, #0
    str r0, [r1]

    ldr r1, =IRQ_HANDLER_DEPTH
    mov r0, #0
    str r0, [r1]

    msr CPSR_c, #0xD2
    ldr sp, =IRQ_STACK_BEGIN

    msr CPSR_c, #0xDF
    mov sp, #USER_STACK_BEGIN

    msr CPSR_c, #0xD3
    ldr sp, =SUPERVISOR_STACK_BEGIN

    @ configura a tabela de interrupções para apontar para interrupt_vector
    ldr r0, =interrupt_vector

    mcr p15, 0, r0, c12, c0, 0

SET_GPIO:
    @ configura GPIO
    ldr r1, =GPIO_BASE

    @ configuracao de entrada e saída (corrigido)
    mov r0, #0b111110
    orr r0, r0, 0xFF, lsl #18
    orr r0, r0, 0x3F, lsl #26
    str r0, [r1, #GPIO_GDIR]

SET_GPT:
    @ configura GPT
    ldr r1, =GPT_BASE

    mov r0, #0x41
    str r0, [r1, #GPT_CR]

    eor r0, r0, r0
    str r0, [r1, #GPT_PR]

    @ Coloca TIME_SZ no GPT_OCR1
    mov r0, #TIME_SZ
    str r0, [r1, #GPT_OCR1]

    mov r0, #1
    str r0, [r1, #GPT_IR]

SET_TZIC:
    @ configura TZIC
    ldr	r1, =TZIC_BASE

    @ Configura interrupcao 39 do GPT como nao segura
    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_INTSEC1]

    @ Habilita interrupcao 39 (GPT)
    @ reg1 bit 7 (gpt)
    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_ENSET1]

    @ Configurar interrupt39 priority como 1
    @ reg9, byte 3
    ldr r0, [r1, #TZIC_PRIORITY9]
    bic r0, r0, #0xFF000000 @ copia a parte menos significativa
    mov r2, #1
    orr r0, r0, r2, lsl #24
    str r0, [r1, #TZIC_PRIORITY9]

    @ Configure PRIOMASK como 0
    eor r0, r0, r0
    str r0, [r1, #TZIC_PRIOMASK]

    @ Habilita o controlador de interrupcoes
    mov	r0, #1
    str	r0, [r1, #TZIC_INTCTRL]

    @ transfere código para o usuário
    ldr r0, =USER_TEXT
    ldr r0, [r0]
    msr CPSR_c, #0x10
    mov pc, r0

IRQ_HANDLER:
    @ salva o contexto
    push {r0-r3}
    mrs r0, spsr_all
    mrs r1, cpsr_all
    push {r0, r1, lr}

    ldr r1, =IRQ_HANDLER_DEPTH
    ldr r0, [r1]
    add r0, r0, #1
    str r0, [r1]

    @ permite o tratamento de interrupcões
    msr CPSR_c, #0x12

    @ desarma a interrupcao do gpt
    ldr r1, =GPT_BASE
    mov r0, #1
    str r0, [r1, #GPT_SR]

    ldr r1, =SYS_TIME
    ldr r0, [r1]
    add r0, r0, #1
    str r0, [r1]

    @ evita tratamentos do callback múltiplos
    ldr r0, =IRQ_HANDLER_DEPTH
    ldr r0, [r0]
    cmp r0, #1
    bhi IRQ_HANDLER_END

    ldr r2, =CALL_ALARM_QUEUE
    ldr r3, =CALL_ALARM_N
    ldr r3, [r3]
    add r3, r3, r2

    @ executa alarme e callback de proximidade em modo privilegiado
    @ TODO: será possível mudar isso?
    @ não podemos simplesmente trocar para o modo usuario
    @ por que temos que voltar no movs pc, lr
IRQ_HANDLER_ALARM_LOOP:
    cmp r2, r3
    bhs IRQ_HANDLER_PROXIMITY

    @ verifica o tempo do alarme, salta se o tempo tiver passado
    ldr r0, [r2, #4]
    ldr r1, =SYS_TIME
    ldr r1, [r1]
    cmp r0, r1
    addls r2, r2, #9
    bls IRQ_HANDLER_ALARM @ não passou o tempo
    ldrb r0, [r2, #8]
    cmp r0, #1
    addeq r2, r2, #9
    beq IRQ_HANDLER_ALARM @ já processado

    mov r0, #1
    strb r0, [r2, #8]
    ldr r0, [r2]
    push {r0-r3}
    blx r0
    pop {r0-r3}

    add r2, r2, #9
    b IRQ_HANDLER_ALARM_LOOP
IRQ_HANDLER_ALARM_END:
    ldr r2, =CALL_PROX_QUEUE
    ldr r3, =CALL_PROX_N
    ldr r3, [r3]
    add r3, r3, r2
IRQ_HANDLER_PROXIMITY_LOOP:
    cmp r2, r3
    bhs IRQ_HANDLER_END

    ldr r0, [r2]
    bl read_sonar
    ldr r1, [r2, #4]
    cmp r0, r1
    addhs r2, r2, #12
    bhs IRQ_HANDLER_PROXIMITY_LOOP @ distância acima do limiar

    ldr r0, [r2, #8]
    push {r0-r3}
    blx r0
    pop {r0-r3}

    add r2, r2, #12
    b IRQ_HANDLER_PROXIMITY_LOOP
IRQ_HANDLER_END:
    ldr r1, =IRQ_HANDLER_DEPTH
    ldr r0, [r1]
    sub r0, r0, #1
    str r0, [r1]

    ldmfd sp!, {r0, r1, lr}
    msr cpsr_all, r0
    msr spsr_all, r1
    stmfd sp!, {r0-r3}

    sub lr, lr, #4
    movs pc, lr

SWI_HANDLER:
    @ calcula offset em r2 e salta para syscall
    ldr r2, =SYSCALL_TABLE
    ldr r2, [r2, r7, lsl #2]
    sub r2, r2, #64
    blx r2
    movs pc, lr

NOT_HANDLED:
    b NOT_HANDLED

@ read_sonar (codigo: 16)
@ Parametros:
@ r0: identificador do sonar (0 a 15)
@ Retorno:
@ r0: distancia / -1: sonar invalido
read_sonar:
    push {lr}
    cmp r0, #15
    bhi read_sonar_erro1 @ sonar invalido

    @ Ler sonar
    ldr r1, =GPIO_BASE
    ldr r2, [r1, #GPIO_DR] @ r2 <- GPIO_DR (Data register)

    @ SONAR_MUX <- SONAR_ID
    @ TRIGGER <- 0
    bic r2, r2, #0b111110 @ SONAR_MUX = 0 e TRIGGER = 0
    orr r2, r2, r0, lsl #2 @ GPIO_DR <- SONAR_MUX <- SONAR_ID
    str r2, [r1, #GPIO_DR] @ r2 -> GPIO_DR (Data register)

    @ Delay 15ms
    mov r0, #15
    bl delay

    @ TRIGGER <- 1
    ldr r2, [r1, #GPIO_DR] @ r2 <- GPIO_DR (Data register)
    orr r2, r2, #0b10 @ TRIGGER = 1
    str r2, [r1, #GPIO_DR] @ r2 -> GPIO_DR (Data register)

    @ Delay 15ms
    mov r0, #15
    bl delay

    @ TRIGGER <- 0
    ldr r2, [r1, #GPIO_DR] @ r2 <- GPIO_DR (Data register)
    bic r2, r2, #0b10 @ TRIGGER = 0
    str r2, [r1, #GPIO_DR] @ r2 -> GPIO_DR (Data register)

    @ FLAG 1?
    read_sonar_loop:
        ldr r2, [r1, #GPIO_DR] @ r2 <- GPIO_DR (Data register)
        and r2, r2, #0b1 @ r2 <- FLAG

        cmp r2, #1
        beq read_sonar_loop1

        @ N: Delay 10ms / volta
        mov r0, #10
        bl delay

        b read_sonar_loop

    read_sonar_loop1:
        @ Y: r0 <- SONAR_DATA
        ldr r2, [r1, #GPIO_DR] @ r2 <- GPIO_DR (Data register)
        mov r0, r2, lsr #6

        and r0, r0, #0b111111111111 @ r0 <- distancia

    pop {pc} @ retorna r0 (distancia)

    @ sonar invalido
    read_sonar_erro1:
        mov r0, #-1
        pop {pc} @ retorna r0 (distancia)

@ delay (read_sonar auxiliar)
@ Parametros:
@ r0: tempo em ms aproximado
@ Retorno:
@ -
delay:
    @ multiplicacao por 10
    mov r0, r0, lsl #1
    add r0, r0, r0, lsl #2

    @ loop com 2 instrucoes, 2 x 10 instrucoes no loop
    delay_loop:
    subs r0, r0, #1
    bhs delay_loop

    mov pc, lr

@ register_proximity_callback (codigo: 17)
@ Parametros:
@ r0: identificador do sonar (0 a 15)
@ r1: limiar de distancia
@ r2: ponteiro funcao caso alarme
@ Retorno:
@ r0: -1 se callbacks maior que MAX_CALLBACKS
@     -2 se sonar invalido
@     0 se não
register_proximity_callback:
    ldr r3, =CALL_PROX_N
    ldr r3, [r3]
    cmp r3, #MAX_CALLBACKS
    bhi register_proximity_callback_error1 @ > que MAX_CALLBACKS

    cmp r0, #15
    bhi register_proximity_callback_error2 @ sonar invalido

    ldr r3, =CALL_PROX_QUEUE
    add r3, r3, r2, lsl #3
    add r3, r3, r2, lsl #2
    str r0, [r3]
    str r1, [r3, #4]
    str r2, [r3, #8]
    mov r0, #0
    str r0, [r3, #12]

    @ ok, retorna
    mov r0, #0
    mov pc, lr

    @ > que MAX_CALLBACKS
    register_proximity_callback_error1:
        mov r0, #-1
        mov pc, lr

    @ sonar invalido
    register_proximity_callback_error2:
        mov r0, #-2
        mov pc, lr

@ set_motor_speed (codigo: 18)
@ Parametros:
@ r0: identificador do motor (0 ou 1)
@ r1: velocidade
@ Retorno:
@ r0: -1 se motor invalido
@     -2 se velocidade invalida
@     0 caso ok
set_motor_speed:
    cmp r0, #0
    cmpne r0, #1
    bne set_motor_speed_error1 @ motor inválido
    cmp r1, #63
    bhi set_motor_speed_error2 @ velocidade inválida

    ldr r2, =GPIO_BASE
    ldr r3, [r2, #GPIO_DR]

    @ máscara para escrever a velocidade do motor
    bic r3, r3, #0x00FC0000
    bic r3, r3, #0xFF000000

    @ codifica os bits a serem escritos
    and r1, r1, #0b111111
    mov r1, r1, lsl #1
    cmp r0, #0
    orreq r3, r3, r1, lsl #18
    orrne r3, r3, r1, lsl #25

    str r3, [r2, #GPIO_DR]

    @ ok, retorna
    mov r0, #0
    mov pc, lr

    @ motor inválido
    set_motor_speed_error1:
      mov r0, #-1
      mov pc, lr

    @ velocidade inválida
    set_motor_speed_error2:
      mov r0, #-2
      mov pc, lr

@ set_motors_speed (codigo: 19)
@ Parametros:
@ r0: velocidade para motor 0
@ r1: velocidade para motor 1
@ Retorno:
@ r0: -1 se velocidade do motor 0 invalida
@     -2 se velocidade do motor 1 invalida
@     0 caso ok
set_motors_speed:
    cmp r0, #63
    bhi set_motors_speed_error1 @ velocidade motor 0 inválida
    cmp r1, #63
    bhi set_motors_speed_error2 @ velocidade motor 1 inválida

    ldr r2, =GPIO_BASE
    ldr r3, [r2, #GPIO_DR]

    @ máscara para escrever a velocidade do motor
    bic r3, r3, #0x00FC0000
    bic r3, r3, #0xFF000000

    @ codifica os bits a serem escritos
    and r0, r0, #0b111111
    mov r0, r0, lsl #1
    and r1, r1, #0b111111
    mov r1, r1, lsl #1
    orreq r3, r3, r0, lsl #18
    orrne r3, r3, r1, lsl #25
    str r3, [r2, #GPIO_DR]

    @ ok, retorna
    mov r0, #0
    mov pc, lr

    @ velocidade motor 0 inválida
    set_motors_speed_error1:
        mov r0, #-1
        mov pc, lr

    @ velocidade motor 1 inválida
    set_motors_speed_error2:
        mov r0, #-2
        mov pc, lr

@ get_time (codigo: 20)
@ Parametros:
@ -
@ Retorno:
@ r0: tempo do sistema
get_time:
    ldr r0, =SYS_TIME
    ldr r0, [r0]
    mov pc, lr

@ set_time (codigo: 21)
@ Parametros:
@ r0: tempo do sistema
@ Retorno:
@ -
set_time:
    ldr r1, =SYS_TIME
    str r0, [r1]
    mov pc, lr

@ set_alarm (codigo: 22)
@ Parametros:
@ r0: ponteiro funcao caso alarme
@ r1: tempo do sistema
@ Retorno:
@ r0: -1 se qtd alarmes ativos maior que MAX_ALARMS
@     -2 se tempo menor que tempo atual sistema
@     0 caso ok
set_alarm:
    ldr r2, =CALL_ALARM_N
    ldr r2, [r2]
    cmp r2, #MAX_ALARMS
    bhi set_alarm_error1 @ alames ativos > que MAX_ALARMS

    ldr r3, =SYS_TIME
    ldr r3, [r3]
    cmp r3, r1
    blo set_alarm_error2 @ tempo < que SYS_TIME

    ldr r3, =CALL_ALARM_QUEUE
    add r3, r3, r2, lsl #3
    str r0, [r3]
    str r1, [r3, #4]
    eor r1, r1, r1
    strb r1, [r3, #8]

    ldr r3, =CALL_ALARM_N
    add r2, r2, #1
    str r2, [r3]

    @ ok, retorna
    mov r0, #0
    mov pc, lr

    @ alames ativos > que MAX_ALARMS
    set_alarm_error1:
        mov r0, #-1
        mov pc, lr

    @ tempo < que SYS_TIME
    set_alarm_error2:
        mov r0, #-2
        mov pc, lr