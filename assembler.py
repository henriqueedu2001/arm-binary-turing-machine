tape_path = 'tape.in'
fsm_path = 'fsm.in'    

def main():
    tape = 'bb00100101100100'
    get_tape_instructions(tape)
    return


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
    return instructions


def convert_tape_to_hex(raw_tape: str) -> str:
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
        '1010': 'A',
        '1011': 'B',
        '1100': 'C',
        '1101': 'D',
        '1110': 'E',
        '1111': 'F'
    }
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