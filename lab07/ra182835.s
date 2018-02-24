.globl _start

.data

input_buffer:   .skip 32
output_buffer:  .skip 36

@ Linhas
vetor1: .skip 3072
vetor2: .skip 3072

.text
.align 4

@ Funcao inicial
_start:
		@ Chama a funcao "read" para ler 3 caracteres (n) da entrada padrao
		ldr r0, =input_buffer
		mov r1, #4             @ 3 caracteres + '\n'
		bl  read
		mov r4, r0             @ copia o retorno para r4.

		@ Chama a funcao "atoiHex" para converter a string hexadecimal para um numero
		ldr r0, =input_buffer
		mov r1, r4
		bl  atoiHex

		@ Guarda n convertido em r11
		mov r11, r0

		@ Calcula o triangulo de pascal
		tPascal:

			mov r10, #0     @ zera indice de linha atual
			mov r5, #0      @ zera indice do elemento do vetor
			ldr r6, =vetor1 @ r6 recebe o endereco da linha anterior
			ldr r7, =vetor2 @ r7 recebe o endereco da linha atual

			tPascal_loop:

				cmp r10, r11               @ se indice == tamanho maximo
				beq tPascal_fim            @ finaliza o triangulo

				@ Calcula o vetor
				@ BASE esq.
				cmp r5, #0                 @ se estiver no indice 0
				moveq r8, #1               @ primeiro elemento e 1 (linhaAtual)
				streq r8, [r7, r5, lsl #2] @ linhaAtual[i] = r8

				@ BASE dir.
				cmp r5, r10                @ se estiver no ultimo indice
				mov r9, #1								 @ r9 = 1
				streq r9, [r7, r5, lsl #2] @ ultimo elemento e 1 (linhaAtual)
				bleq imprime_linha         @ imprime a linha

				@ ELEMENTO interno
				cmp r5, #0
				ldrne r8, [r6, r5, lsl #2] @ r8 = linhaAnterior[i]
				subne r5, #1               @ (i-1)
				ldrne r9, [r6, r5, lsl #2] @ r9 = linhaAnterior[i-1]
				addne r8, r8, r9           @ r8 += linhaAnterior[i-1] (r9)
				addne r5, #1               @ (i)
				strne r8, [r7, r5, lsl #2] @ linhaAtual[i] = r8

				add r5, #1     @ aumenta indice do elemento na linha

				b tPascal_loop @ volta para calcular os demais elementos da linha

		@ Imprime o vetor
		imprime_linha:
			mov r5, #0 @ zera indice do elemento da linha
			b imprime_loop

		imprime_loop:
				cmp r5, r10        		  @ se indice elemento == tamanho maximo
				beq imprime_fim       	@ finaliza impressa linha

				@ Move o elemento do vetor para o r4
				ldr r4, [r7, r5, lsl #2]

				@ Chama a funcao "itoaHex" para converter o elemento inteiro
				@ de r4 para uma string hexadecimal
				ldr r0, =output_buffer
				mov r1, #8
				mov r2, r4
				bl  itoaHex

				@ Adiciona o caractere ' ' ao final da sequencia
				ldr r0, =output_buffer
				mov r1, #' '
				strb r1, [r0, #8]

				@ Chama a funcao write para escrever os 8 caracteres e ' ' na saida padrao.
				ldr r0, =output_buffer
				mov r1, #9        		 @ 8 caracteres + ' '
				bl  write

				add r5, #1             @ aumenta indice do elemento na linha

		b imprime_loop

				imprime_fim:
					@ Imprime ultimo elemento (1)
					mov r4, #1

					@ Chama a funcao "itoaHex" para converter o 1
					@ em uma string hexadecimal
					ldr r0, =output_buffer
					mov r1, #8
					mov r2, r4
					bl  itoaHex

					@ Adiciona o caractere '\n' no fim do buffer
					ldr r0, =output_buffer
					mov r1, #'\n'
					strb r1, [r0, #8]

	 				@ Chama a funcao write para escrever o hexa e o '\n' na saida padrao.
 					ldr r0, =output_buffer
 					mov r1, #9         @ '\n'
 					bl  write

	 				add r10, #1 @ aumenta linha atual
					mov r5, #0  @ zera indice de elemento

					@ inverte referencias para linhas
					mov r8, r6
					mov r6, r7
					mov r7, r8

					b tPascal_loop @ calcula a proxima linha

	 	tPascal_fim:
 		@ Chama a funcao exit para finalizar processo.
	 	mov r0, #0
	 	bl  exit

@ Le uma sequencia de bytes da entrada padrao.
@ parametros:
@  r0: endereco do buffer de memoria que recebera a sequencia de bytes.
@  r1: numero maximo de bytes que pode ser lido (tamanho do buffer).
@ retorno:
@  r0: numero de bytes lidos.
read:
			push {r4, r5, r7, lr}
			mov r4, r0
			mov r5, r1
			mov r0, #0         @ stdin file descriptor = 0
			mov r1, r4         @ endereco do buffer
			mov r2, r5         @ tamanho maximo.
			mov r7, #3         @ read
			svc 0x0
			pop {r4, r5, r7, lr}
			mov pc, lr

@ Escreve uma sequencia de bytes na saida padrao.
@ parametros:
@  r0: endereco do buffer de memoria que contem a sequencia de bytes.
@  r1: numero de bytes a serem escritos
write:
			push {r4, r5, r7, lr}
			mov r4, r0
			mov r5, r1
			mov r0, #1         @ stdout file descriptor = 1
			mov r1, r4         @ endereco do buffer
			mov r2, r5         @ tamanho do buffer.
			mov r7, #4         @ write
			svc 0x0
			pop {r4, r5, r7, lr}
			mov pc, lr

@ Finaliza a execucao de um processo.
@  r0: codigo de finalizacao (Zero para finalizacao correta)
exit:
			mov r7, #1         @ syscall number for exit
			svc 0x0

@ Converte um numero binario em uma sequencia de caracteres hexadecimais
@ parametros:
@  r0: endereco do buffer de memoria que recebera a sequencia de caracteres.
@  r1: numero de caracteres a ser considerado na conversao
@  r2: numero binario
itoaHex:
		push {r4, r5, lr}

		itoaHex_loop:
			sub r1, r1, #1      @ indice-- (inicio: n total caracteres)
			cmp r1, #0          @ verifica se ainda ha bits a serem lidos
			blt itoaHex_end

			and r3, r2, #0b1111 @ separa 4 bits

			@ Converte para char em hex
			cmp r3, #9
			addls r4, r3, #'0'
			addhi r4, r3, #'7' @ '7' = 'A' - '10'

			mov r2, r2, lsr #4  @ prepara o proximo bit
			strb r4, [r0, r1]   @ escreve caractere na memoria

			b itoaHex_loop

		itoaHex_end:
			pop {r4, r5, lr}
			mov pc, lr

@ Converte uma sequencia de caracteres hexadecimais em um numero binario
@ parametros:
@  r0: endereco do buffer de memoria que armazena a sequencia de caracteres.
@  r1: numero de caracteres a ser considerado na conversao
@ retorno:
@  r0: numero binario
atoiHex:
		push {r4, r5, r6, r7, lr}
		mov r4, r0         @ r4 == endereco do buffer de caracteres
		mov r5, r1         @ r5 == numero de caracteres a ser considerado
		mov r0, #0         @ number = 0
		mov r1, #0         @ loop indice
		mov r7, #16        @ base 16

		atoiHex_loop:
			cmp r1, r5            @ se indice == tamanho maximo
			beq atoiHex_end       @ finaliza conversao

			ldrb r2, [r4, r1]  @ carrega 1 byte em r2

			@ Calcula potencia da base
			mov r3, #1        @ 16^0
			sub r6, r5, r1    @ expoente
			sub r6, r6, #1
			pot:
				cmp r6, #0      @ caso expoente for 0
				beq pot_fim

				mul r3, r7, r3

				sub r6, r6, #1
				b pot

			pot_fim:

			@ Se >= 'A', -'A' + 10
			cmp r2, #'A'
			subhs r2, r2, #'A'
			addhs r2, r2, #10

			@ Se < 'A', -'0'
			sublo r2, r2, #'0'

			@ Multiplica byte pela base
			mul r3, r2, r3

			@ Adiciona no numero binario
			add r0, r0, r3

			add r1, r1, #1 @ Aumenta indice

			b atoiHex_loop

		atoiHex_end:
			pop {r4, r5, r6, r7, lr}
			mov pc, lr
