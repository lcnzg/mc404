.org 0x0
.section .iv, "a"

_start:

interrupt_vector:
b RESET_HANDLER
b NOT_HANDLED
b SWI_HANDLER
b NOT_HANDLED
b NOT_HANDLED
b NOT_HANDLED
.org 0x18
b IRQ_HANDLER
b NOT_HANDLED

.data
SYS_TIME: .skip 4
USER_TEXT: .word 0x77802000
IRQ_STACK: .skip 512
IRQ_STACK_BEGIN:
SUPERVISOR_STACK: .skip 512
SUPERVISOR_STACK_BEGIN:
CALL_ALARM_QUEUE: .skip 96
CALL_ALARM_N: .word 0
CALL_PROX_QUEUE: .skip 64
CALL_PROX_N: .word 0
SYSCALL_TABLE:
.word read_sonar
.word register_proximity_callback
.word set_motor_speed
.word set_motors_speed
.word get_time
.word set_time
.word set_alarm

.set GPT_BASE,	0x53FA0000
.set GPT_CR,	0x0
.set GPT_PR,	0x4
.set GPT_SR,	0x8
.set GPT_IR,	0xC
.set GPT_OCR1,	0x10

.set TZIC_BASE,		0x0FFFC000
.set TZIC_INTCTRL,	0x0
.set TZIC_INTSEC1,	0x84
.set TZIC_ENSET1,	0x104
.set TZIC_PRIOMASK,	0xC
.set TZIC_PRIORITY9,	0x424

.set GPIO_BASE,		0x53F84000
.set GPIO_DR,		0x0
.set GPIO_GDIR,		0x4

.set USER_STACK_BEGIN, 0x80000000

.set MAX_CALLBACKS, 8
.set MAX_ALARMS, 8

.align 4
.text
RESET_HANDLER:
    @ Zera o contador
    ldr r1, =SYS_TIME
    mov r0, #0
    str r0, [r1]

    msr CPSR_c, #0xD2
    ldr sp, =IRQ_STACK_BEGIN

    msr CPSR_c, #0x1F
    mov sp, #USER_STACK_BEGIN

    msr CPSR_c, #0xD3
    ldr sp, =SUPERVISOR_STACK_BEGIN

    @ configura a tabela de interrupções para apontar para interrupt_vector
    ldr r0, =interrupt_vector

    mcr p15, 0, r0, c12, c0, 0
SET_GPIO:
    @ configura GPIO
    ldr r1, =GPIO_BASE

    mov r0, #0b111110
    mov r2, #255
    orr r0, r0, r2, lsl #18
    mov r2, #63
    orr r0, r0, r2, lsl #26

    str r0, [r1, #GPIO_GDIR]
SET_GPT:
    @ configura GPT
    ldr r1, =GPT_BASE

    mov r0, #0x41
    str r0, [r1, #GPT_CR]

    eor r0, r0, r0
    str r0, [r1, #GPT_PR]

    mov r0, #100
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
    bx r0

IRQ_HANDLER:
    @ armazena contexto na pilha
    stmfd sp!, {r0, r1}
    mrs r0, spsr_all
    mrs r1, cpsr_all
    stmfd sp!, {r0, r1, lr}

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

    @ TODO: callbacks e alarmes

    ldmfd sp!, {r0, r1, lr}
    mrs r1, cpsr_all
    msr spsr_all, r0
    stmfd sp!, {r0, r1}

    sub lr, lr, #4
    movs pc, lr

SWI_HANDLER:
    ldr r2, =SYSCALL_TABLE
    ldr r2, [r2, r7, lsl #2]
    sub r2, r2, #64
    blx r2
    movs pc, lr

NOT_HANDLED:
    b NOT_HANDLED

read_sonar:
    cmp r0, #15
    bhi read_sonar_erro1

    @ TODO: ler sonar

    mov r0, #0
    mov pc, lr
read_sonar_erro1:
    mov r0, #-1
    mov pc, lr

register_proximity_callback:
    ldr r3, =CALL_PROX_N
    ldr r3, [r3]
    cmp r3, #MAX_CALLBACKS
    bhi register_proximity_callback_error1

    cmp r0, #15
    bhi register_proximity_callback_error2

    ldr r3, =CALL_PROX_QUEUE
    add r3, r3, r2, lsl #3
    add r3, r3, r2, lsl #2
    str r0, [r3]
    str r1, [r3, #4]
    str r2, [r3, #8]
    mov r0, #0
    str r0, [r3, #12]

    mov r0, #0
    mov pc, lr
register_proximity_callback_error1:
    mov r0, #-1
    mov pc, lr
register_proximity_callback_error2:
    mov r0, #-2
    mov pc, lr

set_motor_speed:
    cmp r0, #0
    cmpne r0, #1
    bne set_motor_speed_error1 @ identificador inválido
    cmp r1, #63
    bhi set_motor_speed_error2 @ velocidade inválida

    ldr r2, =GPIO_BASE
    ldr r3, [r2, =GPIO_DR]
    @ máscara para escrever a velocidade do motor
    bic r3, r3, #00FC0000
    bic r3, r3, #FF000000

    @ codifica os bits a serem escrevidos
    and r1, r1, #0b111111
    mov r1, r1, lsl 1
    cmp r0, #0
    orreq r3, r3, r1, lsl 18
    orrne r3, r3, r1, lsl 25

    str r3, [r2, =GPIO_DR]

    mov r0, #0
    mov pc, lr
set_motor_speed_error1:
    mov r0, #-1
    mov pc, lr
set_motor_speed_error2:
    mov r0, #-2
    mov pc, lr

set_motors_speed:
    cmp r0, #63
    bhi set_motors_speed_error2 @ velocidade inválida
    cmp r1, #63
    bhi set_motors_speed_error3 @ velocidade inválida

    ldr r2, =GPIO_BASE
    ldr r3, [r2, =GPIO_DR]
    @ máscara para escrever a velocidade do motor
    bic r3, r3, #00FC0000
    bic r3, r3, #FF000000

    @ codifica os bits a serem escrevidos
    and r0, r0, #0b111111
    mov r0, r0, lsl 1
    and r1, r1, #0b111111
    mov r1, r1, lsl 1
    orreq r3, r3, r0, lsl 18
    orrne r3, r3, r1, lsl 25 

    str r3, [r2, =GPIO_DR]
set_motors_speed_error2:
    mov r0, #-2
    mov pc, lr

get_time:
    ldr r0, =SYS_TIME
    ldr r0, [r0]
    mov pc, lr

set_time:
    ldr r1, =SYS_TIME
    str r0, [r1]
    mov pc, lr

set_alarm:
    ldr r2, =CALL_ALARM_N
    ldr r2, [r2]
    cmp r2, #MAX_ALARMS
    bhi set_alarm_error1

    ldr r3, =SYS_TIME
    ldr r3, [r3]
    cmp r3, r1
    blo set_alarm_error2

    ldr r3, =CALL_ALARM_QUEUE
    add r3, r3, r2, lsl #3
    str r0, [r3]
    str r1, [r3, #4]

    ldr r3, =CALL_ALARM_N
    add r2, r2, #1
    str r2, [r3]

    mov r0, #0
    mov pc, lr
set_alarm_error1:
    mov r0, #-1
    mov pc, lr
set_alarm_error2:
    mov r0, #-2
    mov pc, lr
