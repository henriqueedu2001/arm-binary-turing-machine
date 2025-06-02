# arm-binary-turing-machine
Esse repositório contém o assembler para uma máquina de turing binária (BTM), para assembly arm. A especificação técnica da modelagem da BTM está contida no relatório `Turing_Machine.pdf`.

O assembler permite que você especifique uma fita binária, com os símbolos $0$, $1$ e $\square$ (blank), além de uma FSM descrita numa linguagem própria desse projeto.

# Sintaxe da Fita
Os símbolos $\square$, 0 e 1 são representados pelos caracteres b, 0 e 1, respectivamente, no arquivo `tape.in`. Por exemplo, a fita F tal que

$F = (\square, \square, 0, 1, 0, 0, 1, 1)$

é representada no arquivo como:

```
bb010011
```

O programa filtra espaços, quebras de linha e caracteres diferentes de 'b', '0' e '1', portanto, é possível escrever uma mesma fita de diversas formas. A versão atual não dá suporte para comentários, portanto, escreva exclusivamente a fita com os caracteres válidos, possivelmente com espaços e quebras de linha para melhor organização.

# Sintaxe da FSM
Cada estado $q_i$ da FSM, junto de suas transições, é representado pela sintaxe:

`qi: y0=<y0> y1=<y1> d0=<d0> d1=<d1> q0*=<q0*> q1*=<q1*>`

Em que:
- `y0`: símbolo a ser escrito caso o cabeçote leia $x=0$
- `y1`: símbolo a ser escrito caso o cabeçote leia $x=1$  
- `d0`: próximo movimento do cabeçote após ler o símbolo $x=0$
- `d1`: próximo movimento do cabeçote após ler o símbolo $x=1$ 
- `q0*`: próximo estado da BTM após o cabeçote ler o símbolo $x=0$
- `q1*`: próximo estado da BTM após o cabeçote ler o símbolo $x=1$

Essas variáveis podem assumir os seguintes valores:
- `x0`, `x1`, `y0` e `y1`: ou 0 ou 1
- `q0*`e `q1*`: q0, q1, q2, ..., q254, qh, sendo qh = estado de HALT.

Para escrever a FSM completa, basta escreva um estado abaixo do outro:

```
q0: y0=<y0> y1=<y1> d0=<d0> d1=<d1> q0*=<q0*> q1*=<q1*>
q1: y0=<y0> y1=<y1> d0=<d0> d1=<d1> q0*=<q0*> q1*=<q1*>
q2: y0=<y0> y1=<y1> d0=<d0> d1=<d1> q0*=<q0*> q1*=<q1*>
q3: y0=<y0> y1=<y1> d0=<d0> d1=<d1> q0*=<q0*> q1*=<q1*>
q5: y0=<y0> y1=<y1> d0=<d0> d1=<d1> q0*=<q0*> q1*=<q1*>
...
q254: y0=<y0> y1=<y1> d0=<d0> d1=<d1> q0*=<q0*> q1*=<q1*>
```

Escreva os estados necessariamente na sequência $q_0$, $q_1$, $q_2$, $\cdots$, $q_{254}$. Não escreva qualquer lógica para o estado $q_h$ de HALT; ou seja, sua FSM **nunca** deve terminar com

`qh: y0=<y0> y1=<y1> d0=<d0> d1=<d1> q0*=<q0*> q1*=<q1*>`

ou

`q255 y0=<y0> y1=<y1> d0=<d0> d1=<d1> q0*=<q0*> q1*=<q1*>`

A sintaxe deve ser exatamente essa; qualquer variação, com adição de espaços ou quebras de linha, pode comprometer a correta decodificação da FSM. Portanto, calma calabreso.

## Exemplo de FSM
Para fins de ilustração, considere a FSM descrita abaixo:

<img src='imgs/fsm_example.png' style='background-color: white;'><img/>

```
q0: y0=1 y1=0 d0=1 d1=1 q0*=q0 q1*=q1
q1: y0=1 y1=0 d0=1 d1=1 q0*=q0 q1*=qh
```

Nessa FSM, temos três estados $q_0$, $q_1$ e $q_h$. A BTM começa com estado interno $q_0$.

No estado $q_0$, caso o cabeçote leia $x=0$, ele continua em $q_0$, pois q0*=q0, escreve $y=1$ na fita, pois y0=1, e move-se para direita na fita, pois d0=1. Caso o cabeçote leia $x=1$, ele transita para $q_1$, pois q1*=q1, escreve $y=0$ na fita, pois y1=1, e move-se para direita na fita, pois d1=1. 

No estado $q_1$, caso o cabeçote leia $x=0$, ele transita para $q_0$, pois q0*=q0, escreve $y=1$ na fita, pois y0=1, e move-se para direita na fita, pois d0=1. Caso o cabeçote leia $x=1$, ele transita para $q_h$ (HALT), pois q1*=qh, escreve $y=0$ na fita, pois y1=1, e move-se para direita na fita, pois d1=1; nesse caso, a máquina entrou em HALT e interrompe a execução em seguida.


# Como usar o assembler?
Clone esse repositório para seu diretório local. Nos arquivos `files/fsm.in` e `files/tape.in` escreva a FSM e a fita, nas notações e convenções adotadas aqui. Então, execute o script `assembler.py`.

```bash
python3 assembler.py
```

O arquivo de saída é `files/btm.s`, um arquivo em assembly arm, pronto para execução.