# ESTADO-FINAL — Ordem CAIXA-TESTES-CORRECOES-14 (a correcção B1 da sentença da CAIXA-TESTES-CORRECOES-13)

**Ordem:** ORDEM-CAIXA-TESTES-CORRECOES-14, do Comestre CM-000009, 22/11/2026. **Classe:** CORRECÇÃO, só registo.
**Base:** a ponta de `fable/integracao-50` à hora do lançamento, `5c6ecf1`. O trabalho foi feito directamente na linha,
sem ramo lateral.
**Território:** a raiz do repo. Só mudou a l. 62 de `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-10.md`, e entrou este
ficheiro. Não mexi em código.

Este ficheiro não leva nomes verdadeiros nem pedaços deles. O conferidor estrito dá 0 achados nele, nos dois critérios.

## §1 B1 (D1): o pedaço de 12 car. na l. 62 do ESTADO-FINAL-10 (FEITO, PROVADO)

- **Localizado com o conferidor estrito** (`provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`, critério
  alargado), antes de mexer: «linha 62: nome verdadeiro n.º 1 (16 caracteres) — pedaço de 12 caracteres» e «linha 62:
  nome verdadeiro n.º 2 (15 caracteres) — pedaço de 12 caracteres». A linha é mesmo a 62. É a segunda linha da frase
  da privacidade.
- **A sugestão da ordem não chegava a 0.** Neste ficheiro, chamo «palavra B» à última palavra da frase antiga, para
  não a citar. Com a redacção sugerida na ordem, que fica com a palavra B, a l. 62 continuava com 2 achados, agora de
  8 car. Testei frases sozinhas no conferidor e o problema é a própria palavra B, que sozinha dá 7 car. Qualquer
  redacção que fique com ela dá pelo menos 7. Por isso tirei a palavra.
- **A correcção:** a l. 62 passa de «os valores-canário de» + a palavra B a **«os valores-canário das fichas de
  teste.»**. «Fichas de teste» é o nome que a casa já usa para essas fichas (RELATO-CORRECOES-9, B2), por isso o
  sentido mantém-se: são os valores de ensaio, não valores reais. A l. 61 não muda, e o `diff` é só essa linha.
- **Prova** (o conferidor no ficheiro, antes e depois):

  | | Achados na l. 62 | Achados no ficheiro (alargado) | `--velho` | Nomes inteiros |
  |---|---|---|---|---|
  | antes (`5c6ecf1`) | 2 (n.º 1 e n.º 2, 12 car.) | 16 | 16 | 0 |
  | depois | **0** | **14** | **14** | **0** |

  O `diff` da saída do conferidor, antes contra depois, tem só as 2 linhas da l. 62 e o total. Os 14 que ficam (l. 18,
  26, 29, 40, 57, 59 e 71, todos de 4 car.) já lá estavam. São palavras correntes, da mesma classe que a casa já
  aceitou (ESTADO-FINAL-8 §B5 da RELATO).

## §2 Corridas antes de publicar

| Corrida | Resultado |
|---|---|
| `python retoma-i0004/actualizar-listas.py` (na raiz) | antes.txt 37, depois.txt 415, MANIFESTO 459 ficheiros: **0 novos, 0 tirados**. Nenhuma lista mudou |
| Conferidor estrito, ESTADO-FINAL-10 | 16 → **14** (`--velho` 16 → 14); l. 62: 2 → **0**; inteiros 0 → **0** |
| Conferidor estrito, este ESTADO-FINAL | **0**, nos dois critérios |

Não corri a suíte do servidor, porque só mudou o registo.

## §3 Pontos para o coordenador

1. **A sede veio outra vez sem clone**, como na CORRECOES-12 e na -13. Clonei a linha para `repo/` com o mesmo comando
   e deixei o `clone.log` na sede.
2. **A redacção sugerida na ordem não cumpria a prova.** Deixava 8 car., porque a palavra B é, sozinha, um pedaço de
   7 car. dos dois nomes. Usei «das fichas de teste», que dá 0 (§1).
   A primeira redacção deste ESTADO-FINAL citava a palavra e dava 14 achados. Reescrevi-a antes do commit.
3. **A mesma palavra está em muitos outros registos.** Corri o conferidor em todos os `.md` da raiz: 51 ficheiros têm
   achados de 7 car. ou mais, e o motivo deve ser quase sempre a palavra B (por exemplo, ESTADO-FINAL-PROVAS-MAPA-CORR8
   tem 80 e o CORR10-PREP tem 30). Não estão no meu território, por isso não lhes mexi. Fica uma decisão para a casa:
   ou se emendam todos, ou se aceita a palavra B como palavra corrente, tal como os achados de 4 car.
4. Os números do CI não ficam aqui, porque este ficheiro vai no próprio commit.
