# ESTADO-FINAL — Ordem CAIXA-RELATO-CORRECOES-12 (a O1 da sentença da CAIXA-RELATO-CORRECOES-11)

**Quem:** Claude, no PC (22/11/2026). **Linha:** `fable/integracao-50`, trabalho directo, sem ramo lateral nem fusão.
**Base:** `ec79c90` (a ponta à hora do lançamento: o ESTADO-FINAL da Ordem CAIXA-ESTADOS-FINAIS-NOMES, §5). A ordem
cita `4c32d69`, mas a linha tinha andado mais um commit: o `ec79c90` só mexe no
`ESTADO-FINAL-ORDEM-CAIXA-ESTADOS-FINAIS-NOMES.md`.
**Sede:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-caixa-relato-correcoes-12\`. Chegou sem clone (só
`ORDEM.md`, os `.b64`, o `.cmd` de arranque e o log vazio). Clonei a linha em `repo\`, como nas ordens anteriores, e
pus a pasta tmp em `tmp\`.
**Território:** só o ficheiro novo `provas/ordem-caixa-relato/correcoes-11/teste-relato.log` e este ESTADO-FINAL.

Este ficheiro não leva nomes verdadeiros, nem pedaços deles, nem o valor de nenhum PIN. O conferidor estrito dá 0
achados nele (§2).

## 1. O ponto

### B1 (O1) — o teste do relato na ponta actual, com a saída cometida — FEITO (com a reserva do §3.1)
- **Corrida fresca, na ponta `ec79c90`.** Não copiei nada do `tmp\` da sede da CORRECOES-11. Usei o Godot 4.7.2 do PC
  (`Godot_v4.7.2-stable_win64_console.exe`, `--version` → `4.7.2.stable.official.ed1daf0bf`), em modo headless:
  1. `--headless --path rascunhos/cliente --import` → rc=0. O `git status` ficou limpo depois disto.
  2. `--headless --path rascunhos/cliente -s <repo>/provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd`,
     com stdout e stderr para `tmp\teste-relato.log` → **rc=0**.
- **O resultado:** a última linha é «teste do relato da caixa: 31 de 31 verificações passaram.» Há 31 linhas `ok`, e
  nenhuma linha com `FALHA`, `ERROR` ou `WARNING`.
- **A saída cometida:** `provas/ordem-caixa-relato/correcoes-11/teste-relato.log` é a cópia, sem alterações, do
  `tmp\teste-relato.log` (46 linhas e mais o fim de linha; o conferidor conta 47). Tal como o da CORRECOES-10, guarda
  também a linha do cabeçalho do Godot.
- **Comparado com o precedente** (`correcoes-10/teste-relato.log`): com as horas `HH:MM:SS.mmm` normalizadas, só a
  linha 9 difere, e é a da hora local, que muda por natureza. Tudo o resto é igual linha a linha.

## 2. A prova (os números das corridas)

| Corrida | Resultado |
|---|---|
| `--import` do cliente (Godot 4.7.2 headless) | rc=0 |
| teste do relato (`teste_relato_caixa.gd`), na ponta `ec79c90` | **31 de 31**, rc=0 |
| conferidor estrito no log novo, critério alargado | **4 achados, 0 inteiros** (linhas 14, 37, 39, 39; pedaços de 6, 5, 4, 4) |
| conferidor estrito no log novo, critério antigo (`--velho`) | **2 achados, 0 inteiros** (linha 39, pedaços de 4 e 4) |
| conferidor no precedente (`correcoes-10/teste-relato.log`), alargado / antigo | **4 / 2 achados, 0 inteiros** (as mesmas linhas e os mesmos comprimentos) |
| conferidor estrito neste ESTADO-FINAL, alargado / antigo | 0 / 0 achados |
| `retoma-i0004/actualizar-listas.py`, antes do commit | «MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)», sem mudanças nas listas |
| `retoma-i0004/actualizar-listas.py`, depois do commit | o mesmo, 0 novos, 0 tirados, sem mudanças |

O CI da ponta fica registado no commit seguinte a este (§4).

## 3. Pontos para o coordenador

1. **A barreira «0 achados nos dois critérios» não se pode cumprir tal como está escrita, porque o precedente que a
   justifica não tem 0 achados.** O `correcoes-10/teste-relato.log` que está na linha dá 4 achados (alargado) e 2
   (antigo), com 0 inteiros. O próprio relatório da corrida da CORRECOES-10 já o dizia: «4 achados de palavras
   correntes», e o de `correcoes-8` dava o mesmo. O «0 achados» do ESTADO-FINAL-10 (§2) refere-se ao `absolutizar.sh`,
   aos harnesses, às saídas `.txt` e ao próprio ESTADO-FINAL, e não ao `teste-relato.log`.
   O log fresco dá exactamente os números do precedente: as mesmas linhas, os mesmos comprimentos e **0 inteiros**. Os
   achados caem todos dentro de palavras correntes do português que o próprio `teste_relato_caixa.gd` escreve (não
   as cito aqui, para não pôr pedaços dos nomes num ficheiro). Não vêm de nenhum dado de ficha.
   Para chegar a 0 achados, ou se edita o log, o que falsifica a prova, ou se muda o texto do teste, o que fica fora
   do território. **Cometi o log tal como saiu**, por ter o mesmo padrão do precedente aceite. Se a sentença quiser 0
   achados à letra, isso pede uma ordem que mude as frases do teste. Para tirar este log, basta reverter um commit.
2. **A previsão do `actualizar-listas` nas regras da casa («1 novo») não bate com o script.** O script só olha para
   `rascunhos/` (é o `git diff` contra `9cbaca8` com `-- rascunhos`), e o log fica em `provas/`. Por isso o resultado
   certo é 0/0, como a própria secção B1 da ordem diz.
3. **A base andou um commit além do que a ordem cita** (`4c32d69` → `ec79c90`, só um ESTADO-FINAL de outra ordem). A
   prova foi corrida em `ec79c90`.
4. A sede chegou sem clone, e clonei a linha em `repo\`. O `ORDEM.md` da sede já termina com `<b>Estado: NOVA</b>`, e
   não mexi nele. Nenhum valor de PIN foi escrito.

## 4. CI

(preenchido no commit seguinte)
