.org 0x0
.section .iv, "a"

_start:

interrupt_vector:
    b RESET_HANDLER

.org 0x18
    b IRQ_HANDLER

.data
CONTADOR:
    .skip 32 @ Reserva espaco para contador na secao de dados

.org 0x100
.text
RESET_HANDLER:
    @ Zera o contador
    ldr r2, =CONTADOR
    mov r0, #0
    str r0, [r2]

    @ Faz o registrador que aponta para a tabela de interrupções apontar para a tabela interrupt_vector
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0

    SET_GPT:
        @ Constantes para os enderecos do GPT
        .set GPT_BASE,              0x53FA0000
        .set GPT_CR,                0x0
        .set GPT_PR,                0x4
        .set GPT_SR,                0x8
        .set GPT_IR,                0xC
        .set GPT_OCR1,              0x10

        .set TIME_SZ,               100

        @ R1 <= GPT_BASE
        ldr	r1, =GPT_BASE

        @ Deixa o clock_src para periférico
        mov r0, #0x00000041
        str r0, [r1, #GPT_CR]

        @ Zera o prescaler
        mov r0, #0
        str r0, [r1, #GPT_PR]

        @ Coloca TIME_SZ no GPT_OCR1
        mov r0, #TIME_SZ
        str r0, [r1, #GPT_OCR1]

        @ Liga a interrupcao Output Compare 1
        mov r0, #1
        str r0, [r1, #GPT_IR]

    SET_TZIC:
        @ Constantes para os enderecos do TZIC
        .set TZIC_BASE,             0x0FFFC000
        .set TZIC_INTCTRL,          0x0
        .set TZIC_INTSEC1,          0x84
        .set TZIC_ENSET1,           0x104
        .set TZIC_PRIOMASK,         0xC
        .set TZIC_PRIORITY9,        0x424

        @ Liga o controlador de interrupcoes

        @ R1 <= TZIC_BASE
        ldr	r1, =TZIC_BASE

        @ Configura interrupcao 39 do GPT como nao segura
        mov	r0, #(1 << 7)
        str	r0, [r1, #TZIC_INTSEC1]

        @ Habilita interrupcao 39 (GPT)
        @ reg1 bit 7 (gpt)
        mov	r0, #(1 << 7)
        str	r0, [r1, #TZIC_ENSET1]

        @ Configure interrupt39 priority as 1
        @ reg9, byte 3
        ldr r0, [r1, #TZIC_PRIORITY9]
        bic r0, r0, #0xFF000000
        mov r2, #1
        orr r0, r0, r2, lsl #24
        str r0, [r1, #TZIC_PRIORITY9]

        @ Configure PRIOMASK as 0
        eor r0, r0, r0
        str r0, [r1, #TZIC_PRIOMASK]

        @ Habilita o controlador de interrupcoes
        mov	r0, #1
        str	r0, [r1, #TZIC_INTCTRL]

        @ instrucao msr - habilita interrupcoes
        msr CPSR_c, #0x13       @ SUPERVISOR mode, IRQ/FIQ enabled

    SET_GPIO:
        @ Constantes para os enderecos do GPIO
        .set GPIO_BASE              0x53F84000
        .set GPIO_DR,               0x0
        .set GPIO_GDIR,             0x4
        .set GPIO_PSR,              0x8

        @ R1 <= GPIO_BASE
        ldr	r1, =GPIO_BASE

        mov r0, #0b11111111111111000000000000111110 @ configuracao de entrada e saida
        str r0, [r1, #GPIO_GDIR]

@ Laco infinito
laco:
    b laco

IRQ_HANDLER:
    @ R1 <= GPT_BASE
    ldr	r1, =GPT_BASE

    @ Informa que pode limpar OF1
    mov r0, #0x1
    str r0, [r1, #GPT_SR]

    @ CONTADOR++
    ldr r1, =CONTADOR
    ldr r0, [r1]
    add r0, r0, #1
    str r0, [r1]

    sub lr, lr, #4 @ corrige lr
    movs pc, lr
