symbol_bits_map = {
    'b': '11',
    '0': '00',
    '1': '01'
}

bits_hex_digit_map = {
    '0000': '0',
    '0001': '1',
    '0010': '2',
    '0011': '3',
    '0100': '4',
    '0101': '5',
    '0110': '6',
    '0111': '7',
    '1000': '8',
    '1001': '9',
    '1010': 'a',
    '1011': 'b',
    '1100': 'c',
    '1101': 'd',
    '1110': 'e',
    '1111': 'f'
}

tape_path = 'files/tape.in'
fsm_path = 'files/fsm.in'    
core_path = 'src/core.s'
btm_code_path = 'files/btm.s'

def main():
    # carregando os arquivos
    tape = load(tape_path)
    fsm_spec = load(fsm_path)
    core = load(core_path)
    # decodificando
    fsm_instructions = get_fsm_instructions(fsm_spec)
    tape_instructions = get_tape_instructions(tape)
    
    # escrita do assembly
    assembly_code = assembly(core, fsm_instructions, tape_instructions)
    with open(btm_code_path, 'w') as file:
        file.write(assembly_code)
    
    return


def assembly(core: str, fsm_instructions: str, tape_instructions) -> str:
    final_code = ''
    final_code += core + '\n\n'
    final_code += fsm_instructions + '\n'
    final_code += tape_instructions + '\n'
    final_code += 'end:'
    return final_code


def load(file_path: str) -> str:
    core = ''
    with open(file_path, 'r') as file:
        core = file.read()
    return core


def get_fsm_instructions(fsm_spec: str) -> str:
    """Para uma dada FSM, gera as instruções para programá-la na memória

    Args:
        fsm_spec (str): a especificação da FSM

    Returns:
        str: as instruções da FSM
    """
    instructions = ''
    instructions += 'set_fsm:\n'
    instructions += '\tmov r0 #0xf000\n'
    instructions += '\tldr r0, [r0]\n'
    fsm_states = get_little_endian_fsm_states(fsm_spec)
    for i in range(len(fsm_states)//8):
        byte = fsm_states[8*i: 8*i + 8]
        high_byte, low_byte = byte[0:4], byte[4:8]
        instructions += f'\tmov r1, #0x{high_byte}  @ carrega o high byte da FSM (i = {i})\n'
        instructions += f'\tmov r2, #0x{low_byte}  @ carrega o low byte da FSM (i = {i})\n'
        instructions += f'\tlsl r1, r1, #16  @ desloca a parte alta de r1\n'
        instructions += f'\torr r1, r1, r2   @ concatena high byte + low byte (i = {i})\n'
        instructions += f'\tstr r1, [r0]     @ store do estado da FSM (i = {i})\n'
        instructions += f'\tadd r0, r0, #4   @ atualiza a próxima posição de escrita\n'
    
    instructions += f'\tbx lr            @ retorno da subrotina\n'
    return instructions


def get_little_endian_fsm_states(fsm_spec: str) -> str:
    fsm_states = fsm_spec.split(sep='\n')
    fsm_states = [decode_state(fsm_state) for fsm_state in fsm_states]
    fsm_states = ''.join(fsm_states)
    padding = '0' * (8 - len(fsm_states) % 8)
    fsm_states = fsm_states + padding
    
    little_endian_tape = ''
    for i in range(len(fsm_states)//8):
        new_byte = fsm_states[8*i + 6: 8*i + 8] + fsm_states[8*i + 4: 8*i + 6] + fsm_states[8*i + 2: 8*i + 4] + fsm_states[8*i:8*i + 2]
        little_endian_tape += new_byte
    
    return little_endian_tape


def decode_state(fsm_state_line: str) -> str:
    tokens = fsm_state_line.split(sep=' ')
    x0 = tokens[1][-1]
    x1 = tokens[2][-1]
    y0 = tokens[3][-1]
    y1 = tokens[4][-1]
    xy_block = f'{x0}{x1}{y0}{y1}'
    xy_block = bits_hex_digit_map[xy_block]
    xy_block = f'0{xy_block}'
    q0_next = get_state_index_hex(tokens[5][4:])
    q1_next = get_state_index_hex(tokens[6][4:])
    decoded_state = f'{xy_block}{q0_next}{q1_next}'
    
    return decoded_state


def get_state_index_hex(fsm_state: str) -> str:
    index = fsm_state[1:]
    if index == 'h':
        return 'ff'
    
    index = int(index)
    index = hex(index)[2:]
    if len(index) == 1: index = f'0{index}'
    
    return index


def get_tape_instructions(raw_tape: str) -> str:
    """Para uma dada fita de entrada, gera as instruções de assembly ARM necessárias para
    escrevê-la na memória.

    Args:
        raw_tape (str): o texto bruto da fita

    Returns:
        str: as instruções em assembly arm
    """
    instructions = ''
    instructions += 'set_tape:\n'
    instructions += '\tmov r0, #0xf004   @ endereço de tape_addr do header\n'
    instructions += '\tldr r0, [r0]      @ carrega tape_addr em r0\n'    
    hex_tape = convert_tape_to_hex(raw_tape)
    for i in range(len(hex_tape)//8):
        byte = hex_tape[8*i:8*i + 8]
        low_byte, high_byte = byte[4:8], byte[0:4]
        instructions += f'\tmov r1, #0x{high_byte}   @ high byte (i = {i})\n'
        instructions += f'\tmov r2, #0x{low_byte}   @ low byte (i = {i})\n'
        instructions += f'\tlsl r1, r1, #16   @ shift do high byte para a parte alta de r1\n'
        instructions += f'\torr r1, r1, r2    @ concatenação high byte + low byte em r1\n'
        instructions += f'\tstr r1, [r0]      @ store do byte (i = {i})\n'
        instructions += '\tadd r0, r0, #4    @ próxima posição de escrita\n'
    instructions += f'\tbx lr             @ retorno da subrotina\n'
    return instructions


def convert_tape_to_hex(raw_tape: str) -> str:
    symbols = [symbol for symbol in raw_tape  if symbol in ['b', '0', '1']] # filtering
    symbols = [symbol_bits_map.get(symbol) for symbol in symbols] # converting 
    for _ in range(16 - len(symbols) % 16): symbols.append('11') # padding
    
    hex_tape = ''
    for i in range(len(symbols)//2):
        new_bits = symbols[2*i] + symbols[2*i + 1]
        hex_digits = bits_hex_digit_map[new_bits]
        hex_tape += hex_digits
    
    little_endian_tape = ''
    for i in range(len(hex_tape)//8):
        little_endian_tape += little_endian(hex_tape[8*i:8*i + 8])
    
    return little_endian_tape


def little_endian(byte: str) -> str:
    return byte[6:8] + byte[4:6] + byte[2:4] + byte[0:2]

main()