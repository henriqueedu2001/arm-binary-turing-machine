.global _start
_start:
	bl set_header
	bl set_fsm
	bl reset_tape
	bl set_tape
	bl run
	b end

run:
	@ r0: posição do cabeçote (índice i)
	@ r1: estado da FSM (fsm_state), medida como índice
	@ r2: endereço base da fsm
	@ r3: endereço base da fita
	@ r4: tamanho da fita (quantidade de símbolos)
	@ r5: endereço do byte da fita a ser lida pelo cabeçote
	mov r1, #0           @ seta halt = 0 (programa não terminado)
	mov r0, #0xf00c      @ endereço da variável start_pos
	ldr r0, [r0]         @ carrega start_pos em r0
	mov r2, #0xf000      @ endereço da variável fsm_addr
	ldr r2, [r2]         @ carrega fsm_addr em r1
	mov r3, #0xf004      @ endereço da variável tape_addr
	ldr r3, [r3]         @ carrega tape_addr em r2
	mov r4, #0xf008      @ endereço da variável tape_size
	ldr r4, [r4]         @ carrega tape_size em r3
	
	read_loop: 
		@ load em r6 do byte que contenha o i-ésimo símbolo da fita, para leitura do cabeçote
		mov r5, r0           @ r5 = i = posição do cabeçote na fita (i-ésimo símbolo)
		lsr r5, r5, #2       @ remove os dois bits menos significativos de i (ou seja, i <-- (i % 4) >> 2)
		add r5, r5, r3       @ r5 = endereço do byte a ser lido
		ldrb r6, [r5]        @ r6 = byte que contém o i-ésimo símbolo da fita a ser lido pelo cabeçote
		@ isolamento do símbolo dentro do byte carregado em r6
		mov r5, r0           @ r5 = i = posição do cabeçote na fita (i-ésimo símbolo)
		and r5, r5, #0x3     @ r5 = i % 4
		rsb r5, r5, #3       @ r5 = 3 - (i % 4)
		lsl r5, r5, #1       @ r5 = 2 * (3 - (i % 4))
		lsr r6, r6, r5       @ o símbolo de leitura será deslocado para os dois bits menos significativos de r6
		and r6, r6, #0x3     @ máscara para isolar os dois bits do símbolo
		
		@ load da fsm em r7
		mov r7, r1           @ r7 = j = índice do estado q_j da FSM (estado atual)
		lsl r8, r7, #1       @ r8 = 2*j
		add r7, r7, r8       @ r7 = 3*j
		add r7, r2, r7       @ r7 = endereço do primeiro byte do estado q_j
		ldrb r7, [r7]        @ r7 = primeiro byte do estado q_j
		
		@ se x=0
		cmp r6, #0x0         @ verifica se x é o símbolo 0 (representado por 00)
		bne x_not_eq_zero    @ se x != 0, pule esse bloco de instruções
		@ atualização do cabeçote se x = 0
		lsr r8, r7, #1       @ r8 = bit d_0
		and r8, r8, #1       @ remove bits lixo de r8, isolando d_0
		lsl r8, r8, #1       @ r8 = 2*d_0
		sub r8, r8, #1       @ r8 = 2*d_0 - 1; r8 = 1 se d_0 = 1 e r8 = -1 se d_0 = 0
		add r0, r0, r8       @ altera a posição do cabeçote, segundo o estado da FSM
		lsr r10, r7, #3      @ r10 = bit y_0
		@ transição de estado se x = 0
		mov r7, r1           @ r7 = j = índice do estado q_j da FSM (estado atual)
		lsl r8, r7, #1       @ r8 = 2*j
		add r7, r7, r8       @ r7 = 3*j
		add r7, r7, #1       @ r7 = 3*j + 1 (próximo estado se x=0)
		add r7, r2, r7       @ r7 = endereço do primeiro byte do estado q_j
		ldrb r7, [r7]        @ r7 = primeiro byte do estado q_j
		mov r1, r7           @ atualiza próximo estado da FSM
		x_not_eq_zero:
		
		@ se x=1
		cmp r6, #0x1         @ verifica se x é o símbolo 1 (representando por 01 = 0x1)
		bne x_not_eq_one     @ se x != 0, pule esse bloco de instruções
		@ atualização do cabeçote
		and r8, r7, #1       @ r8 = bit d_1
		lsl r8, r8, #1       @ r8 = 2*d_1
		sub r8, r8, #1       @ r8 = 2*d_1 - 1; r8 = 1 se d_1 = 1 e r8 = -1 se d_1 = 0
		add r0, r0, r8       @ altera a posição do cabeçote, segundo o estado da FSM
		lsr r8, r7, #2       @ r8 = bit y_1       
		and r10, r8, #1       @ remove bits lixo de r8, isolando y_1 em r10
		@ transição de estado se x = 1
		mov r7, r1           @ r7 = j = índice do estado q_j da FSM (estado atual)
		lsl r8, r7, #1       @ r8 = 2*j
		add r7, r7, r8       @ r7 = 3*j
		add r7, r7, #2       @ r7 = 3*j + 2 (próximo estado se x=1)
		add r7, r2, r7       @ r7 = endereço do primeiro byte do estado q_j
		ldrb r7, [r7]        @ r7 = primeiro byte do estado q_j
		mov r1, r7           @ atualiza próximo estado da FSM
		x_not_eq_one:
		
		@ se x = blank
		cmp r6, #3           @ verifica se x é o símbolo blank (representando por 11 = 0x3)
		bne x_not_blank      @ se x != blank, pule esse bloco de instruções
		add r0, r0, #1       @ se x = blank, mover cabeçote para direita
		x_not_blank:
		
		@ escrita do símbolo na fita, neste ponto, contido em r10
		mov r8, r10          @ retorna o símbolo para o registrador r8
		cmp r6, #3           @ verifica se x é o símbolo blank (representado por 11 = 0x3)
		beq skip_write       @ se x = blank, pular escrita
		mov r5, r0           @ r5 = i = posição do cabeçote na fita (i-ésimo símbolo)
		lsr r5, r5, #2       @ remove os dois bits menos significativos de i (ou seja, i = (i % 4) >> 2)
		add r5, r5, r3       @ r5 = endereço do byte a ser lido
		ldrb r6, [r5]        @ r6 = byte que contém o i-ésimo símbolo da fita a ser lido pelo cabeçote
		@ isolamento do símbolo dentro do byte carregado em r6
		mov r9, r0           @ r9 = i = posição do cabeçote na fita (i-ésimo símbolo)
		lsr r9, #2           @ r9 = i % 4 = posição do símbolo no byte
		mov r10, #3          @ r10 = 11 = 0x3 (máscara)
		lsl r10, r10, r9     @ desloca a máscara de 2 bits para a posição do símbolo no byte
		orr r6, r6, r10      @ seta os dois bits do símbolo para 11
		eor r6, r6, r10      @ seta os dois bits do símbolo para 00
		lsl r8, r8, r9       @ desloca o símbolo para sua posição correta no byte
		orr r6, r6, r8       @ insere o símbolo no byte da fita
		strb r6, [r5]        @ escreve o símbolo na fita, atualizando o byte correspondente
		skip_write:
		
		cmp r1, #0xff        @ compara fsm_state com halt (0xffff)
		bne read_loop        @ se fsm_state != halt, voltar ao loop
	bx lr                    @ retorno da subrotina

set_header:
	@ HEADER começa em 0xf000
	@ 0xf000: fsm_addr
	@ 0xf004: tape_addr
	@ 0xf008: tape_size (quantidade de símbolos)
	@ 0xf00c: start_pos
	@ INICIALIZAÇÃO DO HEADER
	mov r0, #0xf000      @ endereço base do header
	@ registro de fsm_addr
	mov r1, #0xf100      @ fsm_addr: ponteiro para o início da FSM
	str r1, [r0]         @ registra o fsm_addr no header
	@ registro de tape_addr
    mov r1, #0xf200      @ tape_addr: ponteiro para o início da fita
    add r0, r0, #4       @ avança a posição de escrita para os próximos 4 bytes
	str r1, [r0]         @ registra o tape_addr no header
	@registro de tape_size
	mov r1, #16          @ tape_size: tamanho da fita
    add r0, r0, #4       @ avança a posição de escrita para os próximos 4 bytes
	str r1, [r0]         @ registra o tape_addr no header
	@ registro de start_pos
	mov r1, #0           @ start_pos: posição do cabeçote na fita
	add r0, r0, #4       @ avança a posição de escrita para os próximos 4 bytes
	str r1, [r0]         @ registra o tape_addr no header
	
	bx lr                @ retorno da subrotina
	
reset_tape:
	@ carrega os valores de tape_addr e tape_size 
	mov r0, #0xf004      @ carrega o endereço da variável tape_addr do header
	ldr r0, [r0]         @ carrega tape_addr em r0
	mov r1, #0xf008      @ carrega o endereço da variável tape_size do header
	ldr r1, [r1]         @ carrega tape_size em r1
	@ itera sobre a fita deixando-a em branco            
	lsr r1, #2               @ n iterações, n = tape_size/4 (4 símbolos/byte)
	mov r2, #0xff            @ set do byte para 0xff (4 símbolos blank)
	inner_loop:
		sub r1, r1, #1       @ i = i - 1
		strb r2, [r0]        @ seta o byte da fita para ff
		add r0, r0, #1       @ avançar 1 byte (4 símbolos) para frente na fita
		cmp r1, #0           @ compara o índice i do loop com 0
		bne inner_loop       @ caso i != 0, repita o loop
	bx lr                @ retorno da subrotina

set_tape:
	@ Exemplo para a fita bb00100101100100 = 0xf0411410
	@ Para a leitura correta, devemos armazenar 0x101441f0
	mov r0, #0xf004          @ endereço de tape_addr do header
	ldr r0, [r0]             @ carrega tape_addr em r0
	mov r1, #0x1014          @ primeira parte da fita
	mov r2, #0x41f0          @ segunda parte da fita
	lsl r1, r1, #16          @ desloca a primeira parte da fita para a porção mais significativa
	orr r1, r1, r2           @ junta as duas partes da fita em r1
	str r1, [r0]             @ store da fita
	bx lr                    @ retorno da subrotina

set_fsm:
	@ Exemplo para a FSM de detecção de 11
	@ q0 transita para q1 se x=1 e para q0 se x=0
	@ q1 transita para qhalt se x = 1 e para q0 de x=0
	@ o cabeçote sempre inverte o bit lido
	@ FSM: 0700010700ff representada na memória como 070100070000ff00
	@ FSM: 0b00 010b 00ff representada na memória como 0b01 000b 0000 ff00
	mov r0, #0xf000          @ ponteiro fsm_addr para o endereço base da FSM
	ldr r0, [r0]             @ r0 = fsm_addr = endereço base da FSM
	@ escrita da primeira parte da FSM
	mov r1, #0x0b01          @ carrega a parte alta em r1
	mov r2, #0x000b          @ carrega a parte baixa em r2
	lsl r1, r1, #16          @ desloca a parte alta de r1
	orr r1, r1, r2           @ r1 = 0x07010007
	str r1, [r0]             @ store da primeira parte da FSM
	@ escrita da segunda parte da FSM
	add r0, r0, #4           @ atualização da próxima posição de escrita
	mov r1, #0x0000          @ carrega a parte alta em r1
	mov r2, #0xff00          @ carrega a parte baixa em re
	lsl r1, r1, #16          @ desloca a parte alta de r1
	orr r1, r1, r2           @ r1 = 0x0000ff00
	str r1, [r0]             @  store da segunda parte da FSM
	bx lr                    @ retorno da subrotina

end:
	
	