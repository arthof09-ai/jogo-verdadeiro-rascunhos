# ESTADO-FINAL — ORDEM-CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES-2 (22/11/2026)

**Executor:** conta 2.
**Ramo:** `claude2/caixa-testes-guiao-fragil-correcoes-2`, sobre `fable/integracao-50` @ `5e67145` (a ponta à hora do
lançamento; já contém a CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES, `b700bf4` + `fe4a84d`, como antepassados directos).
**Não fundido** — a fusão é do coordenador.
**Commits:** um só, que cobre C1–C4, as listas da retoma e este ESTADO-FINAL.

**Território mexido:** `rascunhos/servidor/testes/privacidade.test.mjs` (só o comentário «Limite»: −3/+4 linhas),
`ESTADO-FINAL-ORDEM-CAIXA-TESTES-GUIAO-FRAGIL.md`, `ESTADO-FINAL-ORDEM-CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES.md`,
`retoma-i0004/depois.txt`, `MANIFESTO-SHA256.txt` e este ficheiro. Nenhuma linha de lógica, nenhuma asserção, nenhum
número, nada de código do jogo, nada de HUD, nada de cores.

Regra da ordem cumprida: as frases da sentença vão **por extenso**, palavra a palavra, sem abreviar.

## C1 (J-D1) — a cláusula condicional da B1

- `ESTADO-FINAL-ORDEM-CAIXA-TESTES-GUIAO-FRAGIL.md`, ponto 4: o «não calada» nu («A conclusão prática mantém-se: em
  geral a sanidade falha alto, não calada.») ficou riscado. A seguir vem, com a marca `[GUIAO-FRAGIL-CORRECOES-2 C1]`,
  a frase da sentença por extenso:
  «A sanidade compara contra uma ordem posterior: falha alto em geral, e só passaria calada se essa ordem posterior coincidisse de novo com a do snapshot.»
  No topo do ficheiro há uma nota nova, «Corrigido de novo pela Ordem CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES-2».
- Espelho em `ESTADO-FINAL-ORDEM-CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES.md`, secção B1: a mesma frase por extenso, com a
  mesma marca, logo depois de «A conclusão prática não muda: em geral, a sanidade falha alto.»

*Prova:* `git diff` destes dois ficheiros. Não toca o `.mjs` nem nenhum hash de lista (estes ficheiros estão fora de
`rascunhos/`).

## C2 (J-D2) — sai «e a M5» do parentético

`privacidade.test.mjs`, comentário «Limite» antes da guarda `a ordem reconstruída do journal = a da sala`
(agora L223–226). O parentético antigo, «(o controlo B3 e a M5 mordem nos instantes intermédios)», passa à forma
preferida da ordem:
`// (o controlo B3 morde nos instantes intermédios; a M5 morde na guarda final)`

## C3 (J-D3) — «escapa» e «não eliminado» no mesmo comentário

Na mesma edição, o «escapava» passa a «escapa» e entra o «não eliminado». O texto da sentença fica por extenso,
partido só pela quebra de linha do comentário:
```
// Um desvio num instante intermédio que reconvirja até ao fim escapa a esta guarda; fica mitigado pelas mutações
// M1/M2/M5 da CAIXA-TESTES-GUIAO-FRAGIL, não eliminado.
```
A primeira linha do comentário ganhou a marca `CORRECOES-2, C2+C3`.

*Prova C2+C3:* `git diff` do `.mjs`. As únicas linhas mudadas começam por `//`, e nenhuma linha de código muda. O hash
mudou de `92f2ee27…` para `9296539b8556ac93b6ab1a665489c7787b77fbc53760f61b00daa93012139e18`, re-sincronizado nas listas
(ver a tabela das corridas).

## C4 (J-D4 + J-R1) — ponto 5 numa só linha; o cabeçalho sem o `3e096ee` como antepassado

Em `ESTADO-FINAL-ORDEM-CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES.md`:
- **Cabeçalho:** «já contém a CAIXA-TESTES-GUIAO-FRAGIL, `3e096ee`» ficou riscado. A seguir, com a marca
  `[GUIAO-FRAGIL-CORRECOES-2 C4]`: «já contém a CAIXA-TESTES-GUIAO-FRAGIL (forma rebaseda sobre a linha; `3e096ee` é a
  ponta original antes do rebase, não um antepassado)».
  *Prova:* no clone, `git merge-base --is-ancestor 3e096ee HEAD` responde «Not a valid object name 3e096ee», porque o
  objecto nem sequer está no remoto. A forma rebaseda (`db4d805`, `5be70df`) é antepassada da base, tal como
  `1b907bc` (`--is-ancestor` → 0).
- **Ponto 5:** a versão partida em duas linhas ficou riscada. A seguir, com a marca, vem numa só linha: «O ficheiro da
  ordem (`ORDEM.md`, a cópia na sede `ordem-caixa-testes-guiao-fragil-correcoes\`) não foi tocado; a sua última linha
  é `- O ficheiro da ordem termina com a linha exacta: <b>Estado: NOVA</b>`.» O nome `ORDEM.md` é o nome real da
  cópia. Conferi que esse ficheiro da sede termina mesmo com essa linha.
- No topo do ficheiro há uma nota nova, «Corrigido pela Ordem CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES-2».

## Corridas (PC, Node v26.13.0, sobre a árvore com C2+C3)

| Corrida | Resultado |
|---|---|
| Suite do servidor (`node --test testes/`) | **421/421** (pass 421, fail 0): sem mudança de total |
| `privacidade.test.mjs` sozinho | **11/11** |
| Sonda de privacidade (o mesmo `grep` do workflow `privacidade.yml`) | limpa |
| `python retoma-i0004/actualizar-listas.py` | antes.txt 37, depois.txt 415, MANIFESTO 459 (0 novos, 0 tirados). Só mudou a linha de `privacidade.test.mjs` em `depois.txt` e no MANIFESTO |

## Pontos para o coordenador

1. **Um só commit.** O `actualizar-listas` lê o `HEAD`. Fiz um commit temporário com as edições, corri o script e
   desfiz o commit com `reset --soft`. Depois fiz um único commit com tudo: C1–C4, as listas e este ficheiro. As listas
   batem com a árvore desse commit.
2. **A conferência não está neste PC** (`~/workspace/conferencias/…` não existe). Fui pelo texto da ordem, que traz as
   frases da sentença por extenso.
3. **As linhas da ordem batem com a ponta:** o comentário estava em L223–225 (agora L223–226), o ponto 4 em L125–129,
   B1 em L14–18, o cabeçalho em L4–5 e o ponto 5 em L78–79.
4. **O CI** do commit não fica registado aqui, porque este ficheiro vai no mesmo commit. O resultado vai na resposta
   da corrida.
5. **O ficheiro da ordem desta corrida** (`ORDEM.md` da sede) não foi tocado. A sua última linha é `- O ficheiro da ordem termina com a linha exacta: <b>Estado: NOVA</b>`.
