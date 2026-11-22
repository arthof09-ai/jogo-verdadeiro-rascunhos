# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES-10 (Claude conta 1, PC) · 22/11/2026

Esta ordem fecha as correcções **B1–B2** da sentença da CAIXA-TESTES-CORRECOES-9. Só mudou registo:
- o `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-8.md`;
- o `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-9.md`;
- este ficheiro.

Nenhuma linha de código mudou. Não toquei em código do jogo, no HUD, nas cores, no protocolo, nos testes nem na prova.

- **Base:** `origin/fable/integracao-50` @ `5e67145` (a ponta à hora do lançamento). A CORRECOES-9 já está lá, em
  `60076d1` + `c8fc879`. Clone novo, `core.autocrlf=false`.
- **Ramo:** `claude1/caixa-testes-correcoes-10`, **não fundido** (a fusão é do coordenador).
- **Commits, por ordem:**
  1. `839b9a0`: as notas no ESTADO-FINAL-8 e no ESTADO-FINAL-9.
  2. Este ficheiro, com as listas da retoma. Corri `actualizar-listas.py` depois do commit 1 e outra vez antes deste
     commit.
- **Conferência:** `~/workspace/conferencias/caixa-testes-correcoes-9/` não está neste PC. Trabalhei pelo texto da
  ordem, que traz os pontos exactos. Conferi cada afirmação no repositório (`testes/fixture-mestre.test.mjs` e
  `dados-exemplo/mesa-mestre.json`, só leitura).

## Ponto a ponto

### B1 (D1): o ESTADO-FINAL-8 aponta para as frases em vigor
**Prova:** no corpo do ESTADO-FINAL-8, os blocos «Corrigido» do §B1 (l. 28–31) e do §B3 (l. 56–62) citavam, fora do
riscado, as frases da CORRECOES-8 como estavam. A CORRECOES-9 substituiu-as noutros sítios (`git show 60076d1`):
- **A frase da fixture:** está riscada no ESTADO-FINAL-7, ponto 2 para o coordenador. Por baixo, a nota «Apertado na
  CAIXA-TESTES-CORRECOES-9 (B3), 22/11/2026».
- **A frase do «recomeçar»:**
  - no ESTADO-FINAL-7, B3, está riscada; por baixo, a nota «Completado na CAIXA-TESTES-CORRECOES-9 (B1),
    22/11/2026»;
  - no comentário de `historicoVida`, o cabeçalho regista «e na CAIXA-TESTES-CORRECOES-9 (B1)».

**Corrigido:** escolhi a primeira via da ordem, a linha datada. Não risquei nada: os blocos ficam como registo do que a
CORRECOES-8 escreveu.
- **A seguir ao «Corrigido» do §B1:** entrou a «Nota da CAIXA-TESTES-CORRECOES-10 (B1), 22/11/2026». Diz que a frase
  citada já não está em vigor. Diz onde está a frase em vigor e porquê: «fora desse cenário não vê nada» só vale para as
  mensagens da jogadora. Aponta para o ESTADO-FINAL-9, B3.
- **A seguir ao «Corrigido, nos dois sítios» do §B3:** entrou a nota com a mesma data. Diz que as duas frases citadas
  já não estão em vigor e cita a parte completada («mais `cartao_fechado` para os cartões abertos e `turno` para a vez
  nova»). Diz onde ficou nos dois sítios. Lembra que a justificação `caido: false`, riscada mais acima, foi corrigida
  na CORRECOES-9 (B2). Aponta para o ESTADO-FINAL-9, B1 e B2.

### B2 (O1): os 5 cenários no ESTADO-FINAL-9
**Prova:** `gerar()` (`testes/fixture-mestre.test.mjs`, l. 80–98) corre 5 funções de cenário:
- `cenarioDesgraca`, `cenarioIA` e `cenarioDados`, que ficam todos em `mestre`: `{ vista: d.vista, snapshot:
  d.snapshotMestre, cartoes: { desgraca: d.cartao, ia, dados } }`;
- `cenarioLobby`, que fica em `lobby`;
- `cenarioAgir`, que fica em `agir`.

A chave `jogadora` guarda `d.jogadora`, as mensagens da heroína no cenário da desgraça. Medido em
`dados-exemplo/mesa-mestre.json`:
- chaves de topo: `origem, canarios, mestre, lobby, agir, jogadora`;
- `mestre`: `vista, snapshot, cartoes`;
- `mestre.cartoes`: `desgraca, ia, dados`.

**Corrigido:** no ESTADO-FINAL-9, B3, a seguir à enumeração, entrou a nota «Precisado na CAIXA-TESTES-CORRECOES-10
(B2), 22/11/2026». Lista os 5 cenários um a um, cada um com a chave onde fica guardado. Diz que o `mestre` conta por 3
(desgraça + `cartoes.ia` + `cartoes.dados`) e que `jogadora` não é um sexto cenário. A frase original não foi
riscada, porque não está errada: só se lia como 4 itens.

**Privacidade:** não houve fuga nem mutação nesta ordem. Nenhum número novo. Os valores citados nos ESTADOS-FINAIS são
os valores-canário de bancada.

## Números das corridas (PC, Node 26.13.0, sobre `5e67145` + `839b9a0`)

| Corrida | Resultado |
|---|---|
| Servidor, `node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"` (em `rascunhos/servidor`) | **421/421**, 0 falhas, 0 cancelados, 0 saltados, 0 todo |
| `node --test --test-isolation=none testes/privacidade.test.mjs` | **11/11** |
| Sonda de privacidade (o `grep` de `.github/workflows/privacidade.yml`, corrido à mão na raiz) | **limpa**: nenhum e-mail pessoal encontrado |
| Prova `node provas/ordem-caixa/ferramentas/prova-servidor.mjs` (da raiz) | **PROVA OK** (não tocada) |
| `actualizar-listas.py` depois do commit 1 e antes do commit 2 | `antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)`; nenhuma lista mudou |

## Pontos para o coordenador

1. **B1–B2 são só registo.** A suite fica 421/421, como a ordem esperava na ponta actual.
2. **O território da ordem diz `provas/ordem-caixa-relato/`, mas os ESTADOS-FINAIS 8 e 9 vivem na raiz.** Não há
   cópias deles em `provas/ordem-caixa-relato/`. As linhas citadas na ordem (§B1 l. 28–30, §B3 l. 56–61) batem com os
   ficheiros da raiz, por isso foi aí que mexi. Não toquei em `provas/ordem-caixa-relato/`.
3. **As listas da retoma não mudaram.** O `actualizar-listas.py` corre e dá 0 novos e 0 tirados, porque os
   ESTADOS-FINAIS da raiz não entram no `MANIFESTO-SHA256.txt` nem no `retoma-i0004/depois.txt`. Por isso o commit 2
   não traz listas. Não é omissão.
4. **A privacidade dá 11/11, não 10/10 como na CORRECOES-9.** Vem da base nova `5e67145`, não desta ordem: não toquei
   em testes.
5. O CI deste ramo não está registado aqui, porque este é o último commit. O precedente é a CORRECOES-8 e a 9.
6. O ficheiro da ordem (o `ORDEM.md` da sede, fora do repo) não foi tocado, como nas ordens anteriores.
