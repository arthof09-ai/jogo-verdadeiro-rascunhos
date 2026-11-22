# ESTADO-FINAL — Ordem CAIXA-RELATO-B7-CORRECOES-8

Esta ordem faz as correcções D1–D3 da sentença da CAIXA-RELATO-B7-CORRECOES-7, que deu **APROVA COM CORRECÇÕES — 900**.
O trabalho foi feito no PC (Windows 11, Git Bash) a 22/11/2026.

- **Trabalho directo na linha** `fable/integracao-50`, sem ramo lateral e sem fusão.
- **Base:** `5186b01`, a ponta da linha no lançamento (ESTADO-FINAL da CAIXA-RELATO-CORRECOES-9).
- **Commits desta ordem na linha:**
  - `5491fa8` — B1 e B3: os 2 `git rm` e a emenda do número no ESTADO-FINAL-7;
  - o commit deste ficheiro.
- **Território:** só se mexeu nos 2 ficheiros de `provas/ordem-caixa-janela/cobertura-correcoes-6/cliente/`, no
  `ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7-CORRECOES-7.md` e neste ficheiro.

**Privacidade:** este ficheiro e o commit não têm o valor de nenhum PIN nem nomes verdadeiros. Os números abaixo são só
contagens.

## B1 (D1) — os 2 ficheiros com o PIN antigo

**Feito.** Os dois registos de corrida, cometidos pela CAIXA-JANELA-COBERTURA-CORRECOES-6 (`e4072d0`), saíram com
2× `git rm`, sem reescrita:

- `provas/ordem-caixa-janela/cobertura-correcoes-6/cliente/servidor-info.json` (1 linha);
- `provas/ordem-caixa-janela/cobertura-correcoes-6/cliente/servidor.log` (2 linhas).

O resto da pasta (`relato.txt` e as 3 capturas) fica como estava. Como diz a ordem, o lançador da janela já não copia
o info nem o log (`46ebe86`), por isso não há revisão de lançador a fazer.

**A prova** é o verificador `provas/ordem-caixa-relato/ferramentas/verificar-pin-b7-correcoes-7.sh`, corrido com o
Godot 4.7.2 win64_console e a base `5186b01`. Correu antes e depois do `git rm`:

| Verificação | Antes (`5186b01`) | Depois |
|---|---|---|
| PIN antigo — ficheiros na árvore de trabalho (seguidos ou não) | 2 FALHA | **0** ok |
| PIN antigo — ocorrências na árvore de trabalho | 2 FALHA | **0** ok |
| `servidor-info.json` seguidos | 1 FALHA | **0** ok |
| `servidor.log` seguidos fora de `suites/` | 1 FALHA | **0** ok |
| PIN novo de 20 dígitos — ficheiros / ocorrências / seguidos | 0 / 0 / 0 | 0 / 0 / 0 |
| PIN antigo nos ficheiros novos ou mudados desde a base | 0 | 0 |
| Cadeias de 20+ dígitos nos ficheiros novos | 0 | 0 |
| **Total** | 39 ok, **4 FALHAS**, rc 1 | **43/43 ok, 0 falhas, rc 0** |

- **O PIN antigo na árvore toda: 0 ficheiros / 0 ocorrências.** A árvore toda conta-se com os ficheiros seguidos e os
  não seguidos, tirando `.git` e `.godot`.
- As 4 falhas de antes eram o mesmo achado que a -7 registou. Todas as outras verificações deram ok nas duas corridas:
  as recusas com código 2, os 3 arranques vivos e os 4 scripts do Godot sem `--pin`.
- Na corrida de depois, a linha informativa das cadeias de 6+ dígitos nos ficheiros novos dá 5, todas do
  ESTADO-FINAL-7 emendado (números e sha). Não é verificação e nenhuma é um PIN.
- Os logs das duas corridas ficaram na sede, fora do repositório, porque esta ordem não tem território em `provas/`.

## B2 (D2) — o modo sem argumentos no Linux

**Não corrido aqui, de propósito.** Este PC é Windows e não tem Linux nem WSL. Não se simulou nenhuma corrida Linux.

- **A corrida do modo sem argumentos do 4.º lançador** (`provas/ordem-caixa/ferramentas/correr-prova-caixa.sh` sem
  argumentos) **é prova do coordenador**, na sede Linux dele, depois desta entrega.
- **Se essa corrida falhar,** o ponto abre-se e a decisão é do coordenador.

## B3 (D3) — «82 linhas» → «81»

**Feito, no mesmo commit do B1** (`5491fa8`). Na linha da JANELA da tabela das corridas do
`ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7-CORRECOES-7.md`, «82 linhas» passou a «81 linhas». O ficheiro não tem outra
ocorrência de «82 linhas».

- `wc -l provas/ordem-caixa-relato/b7-correcoes-7/cliente-janela/relato.txt` → **81**;
- `wc -l provas/ordem-caixa-janela/cobertura-correcoes-6/cliente/relato.txt` → **81**.

## As listas da retoma

`python retoma-i0004/actualizar-listas.py` correu na raiz do repositório depois do B1 e antes de publicar:

    antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)

O resultado é **0 novos e 0 tirados**, como se esperava, e não mudou nenhum ficheiro.

## Pontos para o coordenador

1. **B2:** falta a corrida Linux do modo sem argumentos do 4.º lançador. É prova tua. Se falhar, o ponto abre-se para
   decidires.
2. **O mesmo «82» noutro sítio, fora do território:** `provas/ordem-caixa-relato/b7-correcoes-7/corridas.log`, linha 11,
   diz `cliente-janela/relato.txt (82 linhas; B6/O2)`. É um registo de corrida da -7 e esta ordem não lhe mexeu. Se o
   quiseres emendado, é para outra ordem.
3. **Referências históricas aos ficheiros apagados:** o ESTADO-FINAL-7, o `verificacao-pin.log` da -7 e o
   `actualizar-listas.log` da COBERTURA-6 continuam a citar os 2 caminhos, como registo. Não citam o valor.
4. **O verificador da -7 tem `bfe4c3c` como base por omissão.** Aqui correu com a base `5186b01`, passada como
   argumento, para que os «ficheiros novos» fossem só os desta ordem. O script não mudou.
5. **A linha final do ficheiro da ordem** (`Estado: NOVA`) está no `ORDEM.md` da sede, fora do repositório, e já
   termina assim. Não lhe mexi.
