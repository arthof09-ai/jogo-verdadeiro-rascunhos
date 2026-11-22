# ESTADO-FINAL — Ordem CAIXA-RELATO-CORRECOES-4 (as correcções B1–B4 da sentença da CAIXA-RELATO-CORRECOES-3)

**Quem:** Claude, conta 1, no PC (22/11/2026). **Ramo:** `claude1/caixa-relato-correcoes-4`, a partir de `da6683e`
(a ponta de `fable/integracao-50` à hora do lançamento). **Não fundi.**
**Sede:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-caixa-relato-correcoes-4\` (o clone está em `repo\` e a pasta
tmp em `tmp\`).
**Commits:** `b6b9887` (as correcções e as corridas), com o CI verde: 10/10 jobs, retoma-pc incluído, e a sonda de
privacidade verde. A seguir vem o commit deste ESTADO-FINAL.

A conferência não está neste PC. Trabalhei pelo texto da ordem, que traz o ficheiro e a linha de cada defeito.

## 1. Ponto a ponto

### B1 — a contagem do fim diz a verdade também quando a re-varredura falha — FEITO, PROVADO (executado)
- **Defeito:** quando a re-varredura do relato escrito achava um nome, `_fim()` juntava uma linha FALHA e um 2.º
  resumo. O ficheiro ficava com 70 linhas, mas a linha do fim dizia «68 linhas — todas as do ficheiro», e havia dois
  resumos: «43 de 43», que era falso, e depois «43 de 44». Isto estava em `prova_caixa_jogadora.gd:517-521` e no
  manequim em `:613-617`.
- **Correcção** (`_fim()` das duas provas): a verificação do fim passa a FALHA e o resumo é refeito, os dois **no
  sítio**, com `_reescrever(i, t)`, uma função nova que troca a linha `i` do relato e regrava o ficheiro. O
  `_gravar_relato()` saiu do `_linha()`. O ficheiro não ganha linhas, por isso a contagem continua certa, e fica um só
  resumo. A linha nova diz «fim: o relato inteiro (68 linhas — todas as do ficheiro, contando esta e as 2 finais) traz
  nome(s) verdadeiro(s), achados só pela re-varredura do que se escreveu [nome verdadeiro n.º 1 na linha 67]». Na
  consola, a linha reescrita sai marcada «(reescrita da linha N do relato)».
- **Prova** (`correcoes-4/mutacoes.log`, mutação «canário na linha em branco final»):

  | | base `da6683e` | código novo |
  |---|---|---|
  | HUD | 70 linhas, 2 resumos («43 de 43», «43 de 44»), a linha diz 68, rc=1 | **68 linhas, 1 resumo, 42/43**, rc=1 |
  | MANEQUIM (mutação nova) | 80 linhas, 2 resumos («53 de 53», «53 de 54»), a linha diz 78, rc=1 | **78 linhas, 1 resumo, 52/53**, rc=1 |

  As linhas e os resumos contam-se no `relato.txt` com `wc -l` e `grep -c`. O harness escreve-os no registo.

### B2 — as linhas FALHA não ecoam o nome verdadeiro — FEITO, PROVADO (executado)
- **Opção escolhida:** a prova não imprime o nome. Como defesa extra, o harness também filtra.
- **Correcção na prova** (as duas):
  - `_nomes_em` dá «nome verdadeiro n.º K na linha L», com K o n.º em `_canarios_nomes`.
  - A varredura dos textos da caixa dá «canário n.º K (nome|número) no texto n.º J da caixa».
  - Antes, as duas devolviam o nome, e os textos davam também o próprio texto entre «», que trazia o canário. O
    número da vida ou do PA também saía.
  - O `printerr` da FALHA repete a mesma linha, por isso também já não traz o nome.
- **Correcção no harness** (`correr-mutacoes.sh`, cujo registo é cometido):
  - Nas provas vivas, as linhas FALHA e os resumos lêem-se do `relato.txt`.
  - O harness conta os nomes verdadeiros nas linhas FALHA, no relato e na consola. Os nomes são os das fichas da
    corrida em que `nome ≠ nomePublico`.
  - Antes de escrever no registo, troca qualquer nome verdadeiro por «‹nome verdadeiro›». Sem isto, a mutação que põe
    o nome no próprio resumo deixava-o no registo.
- **Prova** (nomes verdadeiros nas linhas FALHA, relato / consola, antes do filtro):

  | mutação | base `da6683e` | código novo |
  |---|---|---|
  | `B1-nome-verdadeiro` (HUD) | 34 / 68 | **0 / 0** (continua 39/43) |
  | `N-B2-canario-minusculas-relato` | 34 / 68 | **0 / 0** (39/43) |
  | `N-B2-canario-minusculas-caixa` | 21 / 42, **36/43** | **0 / 0, 40/43** |
  | `N-B1-canario-na-linha-em-branco` (HUD / MANEQUIM) | 1 / 2 | **0 / 0** |
  | `N-B1-canario-no-resumo` (HUD / MANEQUIM) | 1 / 2 | **0 / 0** |

  Em `minusculas-caixa`, a base dava 36/43 porque a linha FALHA dos textos levava o nome para o relato e as 4
  verificações do relato falhavam em cascata. Sem o eco, só falham as 3 verificações verdadeiras dos textos (40/43). Na
  corrida limpa, os relatos cometidos `correcoes-4/*/relato.txt` não têm nenhum nome verdadeiro (`grep -ci` = 0).

### B3 — o portão do `_fim()` falha em voz alta sem canários — FEITO, PROVADO (executado)
- **Correcção:** com `_canarios_nomes` vazio, `_fim()` regista
  `_ok(false, "fim: a varredura do relato inteiro não tem nenhum nome verdadeiro para procurar (o canário não juntou nenhum) — não pode passar sem verificar")`.
  A re-varredura só corre se a varredura de cima tiver passado.
- **Prova:** usei a mutação «o canário não junta nomes» (`_canarios_nomes.append(...)` → `pass`):

  | | base `da6683e` | código novo |
  |---|---|---|
  | HUD | **42/42, rc=0** (a verificação do fim nem aparece; 67 linhas) | **42/43, rc=1** |
  | MANEQUIM | **52/52, rc=0** (77 linhas) | **52/53, rc=1** |

### B4 — o README dá os números reais das 5 capturas — FEITO
- Em `provas/ordem-caixa-relato/README.md`, na secção CORRECOES (§B5), a frase dizia «no essencial, iguais a estas
  (1,0 % …)». Agora dá os números das 5 capturas: **20,2 % (§1), 3,2 % (§2), 1,4 % (§3), 1,0 % (§4), 13,7 % (§5)**.
  Diz também que só do §2 ao §4 ficam perto e que o 1,0 % é só o §4. A emenda vem marcada «CAIXA-RELATO-CORRECOES-4,
  B4» e cita `correcoes-3/comparacao-caixa-relato-vs-correcoes.log`. Não há outra ocorrência de «no essencial» nesta
  pasta nem nos ESTADO-FINAL da CAIXA-RELATO.

## 2. As corridas (Godot 4.7.2 Windows, `Godot_v4.7.2-stable_win64_console.exe`, motor VLAB real `a91c021c…`, semente 7)

| Corrida | Resultado | Ficheiro |
|---|---|---|
| Teste do relato | **31/31** (no CI também 31/31) | `provas/ordem-caixa-relato/correcoes-4/teste-relato.log` |
| Prova HUD-JOGADORA | **43/43**, 68 linhas varridas = 68 no ficheiro, 1 resumo | `correcoes-4/cliente-hud/relato.txt` |
| Prova MANEQUIM | **53/53**, 78 = 78, 1 resumo | `correcoes-4/cliente-manequim/relato.txt` |
| Mutações `base4` + `novo` | 18 + 18, todas executadas | `correcoes-4/mutacoes.log` |
| CI em `b6b9887` | 10/10 jobs verdes (retoma-pc incluído); sonda de privacidade verde; prova da caixa do servidor PROVA OK | — |

As outras mutações do registo, as das ordens anteriores, dão no código novo os mesmos números que davam na base:
B2-fuga 30/31, B3 ×3 29/31, B5 29/31, B6 29/31, utc 30/31, B3-nome-público 43/43 e 53/53. O teste tem agora 31
verificações porque a B7-CORRECOES-2 lhe juntou casos.

`actualizar-listas` (`python retoma-i0004/actualizar-listas.py`): corri-o depois do commit `b6b9887` e não deu
nenhuma diferença («0 novos, 0 tirados»; `git status` limpo). O ramo não toca em `rascunhos/`, por isso não havia
listas a juntar ao commit. O retoma-pc passou.

## 3. Pontos para o coordenador
1. **A fronteira.** A B1 e a B3 estão em `_fim()`, nas duas provas vivas, que ficam fora de `provas/ordem-caixa-relato/`:
   `provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd` e
   `provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd`. A ordem aponta para essas linhas, e a
   CORRECOES-3 fez o mesmo. Fora disto, só mexi em `provas/ordem-caixa-relato/` (README, `mutacoes.mjs`,
   `correr-mutacoes.sh`, `correcoes-4/`) e neste ficheiro. Não mexi no código do jogo, no HUD, nas cores, no workflow
   nem em `rascunhos/`.
2. **O registo de mutações ainda tem nomes-canário de bancada, em 6 títulos** (3 por modo). São as descrições
   («diz») de `B1-nome-verdadeiro` e `N-B2-canario-minusculas-relato` (o nome verdadeiro n.º 1, inteiro e em minúsculas) e de
   `N-B3-heroina-nome-publico-hud` («Espadachim de Bancada»). Vêm de
   `mutacoes.mjs`, que já está cometido com esse texto. Não os filtrei: no N-B3, «Espadachim de Bancada» só é nome
   verdadeiro dentro da mutação, e filtrá-lo estragava a descrição. São valores-canário de bancada, fictícios. ~~As
   linhas FALHA e os resumos do registo não têm nenhum.~~
   **Emenda (CAIXA-RELATO-CORRECOES-5, B3):** a frase com o risco era falsa como estava escrita. O que se contou foi só
   isto: o `conta_nomes` do harness conta os **nomes inteiros** nas **linhas FALHA**, **antes do filtro**, no
   `relato.txt` e na consola das corridas (os números «nomes verdadeiros nas linhas FALHA: relato N, consola M»).
   Não vê fragmentos de nomes, não olha para os resumos e não olha para o registo que fica escrito. E o registo
   cometido, `correcoes-4/mutacoes.log`, tinha fragmentos: o harness cortava as linhas FALHA aos 400 **bytes** antes de
   filtrar, e o corte partia o nome. Ficaram fragmentos de 14 e de 7 caracteres de dois nomes verdadeiros (linhas
   17/55 e 18/56). Na CORRECOES-5, o `correcoes-4/mutacoes.log` foi regenerado com o filtro antes do corte e voltou a
   ser cometido: o ficheiro que está agora no ramo já não os tem (ver `ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES-5.md`).
3. **Há um modo novo no `correr-mutacoes.sh`: `base4`.** Usa os ficheiros das provas de `da6683e`, a base desta ordem,
   com a tabela de `novo`. O modo `base` continua a ser o `6a87b9e` da CORRECOES-3, para que o `correcoes-3/mutacoes.log`
   se possa reproduzir. As mutações novas são `N4-B3-sem-canarios-hud`, `N4-B3-sem-canarios-manequim` e
   `N4-B1-canario-na-linha-em-branco-manequim`. `SO="id …"` corre só um subconjunto.
4. **A B1 reescreve linhas do relato.** A alternativa era não escrever a contagem antes do fim, mas isso mudava o
   formato da linha que o CI e os relatos antigos usam. A reescrita só acontece no caminho de falha: na corrida verde o
   relato é escrito só com `_linha()`, como antes.
5. **Não mexi no `ORDEM.md` da sede,** como a ordem pede.
