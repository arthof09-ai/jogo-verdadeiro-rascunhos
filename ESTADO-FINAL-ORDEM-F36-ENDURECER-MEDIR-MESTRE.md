# ESTADO-FINAL — Ordem F36 da sentença da CAIXA-EXPANDE-VISTAS (endurecer o `medir_mestre.gd`)

**Coordenador:** CM-000009 (Muse). **Executor:** Claude conta 2, PC do cunhado (opus, esforço médio). **Data:** 23/11/2026.
**Linha:** `fable/integracao-50`, trabalho directo, sem ramos laterais.
**Ponta de partida (`HEAD` antes de começar):** `7c4da45` (F31–F35 da sentença da CAIXA-EXPANDE-VISTAS).
**A linha andou durante a ordem:** entrou a F28 (`5e74098`, `e75b961`; só `provas/` e o ESTADO-FINAL dela, nada em `rascunhos/`). O push foi recusado e rebaseei os meus dois commits, ainda não publicados, sobre `e75b961`. A obra era `32fab45` antes do rebase e é `d1ba45b` depois. Na nova base: as listas da retoma não mudam (0 novos, 0 tirados) e o `medir_mestre` dá o mesmo log (220 ok / 0 falhas). As outras suites correram antes do rebase, com a árvore `rascunhos/` igual byte a byte à de agora.

| commit | o quê |
|---|---|
| `d1ba45b` | a obra: `rascunhos/cliente/testes/medir_mestre.gd` e `provas/ordem-f36-medir-mestre/` |
| (este) | este ESTADO-FINAL e as listas da retoma (`actualizar-listas`: 0 novos, 0 tirados) |
| (a seguir) | a nota do CI da ponta |

**Só a prova mudou.** O jogo (`cenas/mestre/mestre.gd`, `hud/caixa_ordem.gd`) não foi tocado: `git diff 7c4da45 -- rascunhos/cliente/cenas rascunhos/cliente/hud` vazio.

## 1. Os quatro buracos, tapados

A sentença não estava no caminho dado (`~/workspace/conferencias/caixa-expande-vistas/SENTENCA-CAIXA-EXPANDE-VISTAS.md`), nem noutro sítio desta máquina ou do repo (ponto aberto 7.1). Trabalhei pelo texto da ordem. Liguei os buracos aos passos pela ordem em que aparecem: D-A = passo 1, D-B = passo 2, D-C = passo 3, D-G = passo 4.

### D-A — `aberta_livre` na câmara livre (passo 1)
- **Antes:** `aberta_livre` só entrava no `print`. Nos ecrãs baixos o bloco inteiro saltava em silêncio (a caixa está escondida), e a única afirmação passava trivialmente com o texto «sem lugar: sai de cena».
- **Afirmações novas:**
  - `<ecrã> câmara livre: a caixa da ordem à vista (há lugar)` / `sai de cena (sem lugar)`: o resultado esperado por ecrã fica escrito na constante `LIVRE_COM_LUGAR` (só 1920×1080 tem lugar). Assim a medida da vista aberta não pode desaparecer sem a suite reprovar.
  - `<ecrã> câmara livre: vista expandida aberta pelo rato`: `aberta_livre` afirmado (1920×1080).
  - `<ecrã> câmara livre, sem lugar: a compacta no sítio dela tocava num controlo de andar [...]`: nos ecrãs baixos fica afirmado **o porquê** de não haver vista aberta para medir. A compacta, no sítio que o `_posicionar_caixa` lhe dá, toca num controlo de andar e, por desenho, sai de cena. Escondida, a caixa não lê o rato (`_input` pára em `is_visible_in_tree`). Medido: 844×390 tocava em `Subir`; 780×360 em `Manipulo`, `Subir` e `Velocidade`.

### D-B — linhas inteiras à vista e nomes cortados com «…» (passo 2)
- **Antes:** em `_medir_expandida`, as linhas inteiras à vista, o «rola» e os nomes cortados só iam para o `print` da `MEDIDA MESTRE-EXPANDIDA`.
- **Afirmações novas** (por ecrã e número de figuras):
  - `N linhas inteiras à vista sem rolar (esperadas E)`: E = mínimo(figuras, `LINHAS_A_VISTA`), com 9 em 844×390, 8 em 780×360 e todas em 1920×1080.
  - `a lista rola` / `não rola`: rola se, e só se, E < figuras.
  - `N nomes cortados com «…» (esperados E, só os de ensaio)`: em 780×360 (`ECRA_CORTA_NOMES`) cortam-se os nomes das criaturas de ensaio, e só esses, todos a acabar em «…». Nos outros dois ecrãs não se corta nenhum.

### D-C — a expandida com 8 figuras (passo 3)
- `FIGURAS_EXPANDIDA := [8, 12, 16]` (era `[12, 16]`). O caso de 8 passa por todas as medidas da expandida nos 3 ecrãs, incluindo as do D-B e do D-G. A última (16) continua a ser a que fica no ecrã para a câmara livre.
- Medido com 8: 8 linhas inteiras sem rolar nos 3 ecrãs; 4 nomes cortados em 780×360, 0 nos outros; a caixa dentro do tabuleiro e acima do fundo.

### D-G — o fecho pelo rato separado do fecho pelo clique (passo 4)
- **Antes:** `aberta_depois` lia-se depois do `_rato(p)` e **antes** do `_clique(p)`. O fecho medido era só o do rato.
- **Afirmações novas:**
  - `fecho pelo rato — com o rato na folha a caixa volta à compacta`: `aberta_depois_rato`, lido antes do clique (é a afirmação antiga, com nome próprio).
  - `depois do clique do rato na folha a caixa continua compacta`: `aberta_depois_clique`, lido **depois** do `_clique`, como a ordem pede.
  - O fecho **pelo clique**, medido à parte (`_medir_fecho_por_clique`):
    - `vista expandida aberta pelo toque (sem o rato a mexer)`: a caixa abre como quando um toque a abre, sem o rato a mexer.
    - `fecho pelo clique — o clique na folha fecha a caixa`: o clique cai na folha, no mesmo ponto. Lê-se logo a seguir ao clique e antes do próprio toque, que também fecharia a caixa e taparia um clique que não fechasse.
    - `o gesto que fecha fica na caixa — não reabre nem chega à folha`: a regra D1 da CAIXA-EXPANDE-INTERACAO.
- Porquê assim: com o rato a sério, no jogo, **só o mexer do rato** abre e fecha a caixa (`caixa_ordem.gd`, `_input`: o `InputEventMouseMotion` chama `definir_sobre`). O clique que fecha é o que o motor imita a partir de um toque (`DEVICE_ID_EMULATION`). Medi esse. Ver o ponto aberto 7.2.

## 2. Os números, antes e depois

| suite | `7c4da45` (antes) | `d1ba45b` (depois) |
|---|---|---|
| `medir_mestre` | 130 ok / 0 falhas | **220 ok / 0 falhas** (código 0, 5 s; o CI dá-lhe 120 s) |

As 90 afirmações a mais vêm de duas fontes:
- **A expandida, +84.** Passou de 7 para 14 afirmações por caso: +3 do D-B, +1 do clique do rato e +3 do fecho pelo clique. Os casos passaram de 6 para 9 (12/16 → 8/12/16, × 3 ecrãs). Antes eram 7 × 6 = 42, agora são 14 × 9 = 126.
- **A câmara livre, +6.** São 3 de com/sem lugar (uma por ecrã), 1 de `aberta_livre` e 2 do porquê nos ecrãs baixos.

As medidas de antes repetem-se iguais, com uma excepção: 844×390 com 16 figuras dá a aberta com 883 u de altura (era 884), porque o estado anterior é outro (o caso de 12 acaba agora fechado pelo toque). É o 883/884 já registado na F15; a altura não é afirmada ao u.

**A prova de que as guardas novas disparam** (`provas/ordem-f36-medir-mestre/ferramentas/mutacoes-medir-mestre.sh`): quatro mutações do jogo, uma por vez, repostas no fim (`git diff` vazio).

| mutação | resultado | falhas das guardas novas |
|---|---|---|
| M1: a caixa nunca sai de cena na câmara livre | 217 ok, 5 falhas | 2 (D-A: «sai de cena (sem lugar)» em 844×390 e 780×360) |
| M2: sem o tecto da largura | 202 ok, 18 falhas | 3 (D-B: os «…» em 780×360, com 8, 12 e 16) |
| M3: o clique imitado de um toque fora não fecha | 202 ok, 18 falhas | 9 (D-G: «fecho pelo clique», nos 9 casos) |
| M4: o rato a sério não abre a caixa | 190 ok, 30 falhas | 1 (D-A: «câmara livre: vista expandida aberta pelo rato») |

Na primeira versão do D-G, o M3 não reprovava o «fecho pelo clique»: o toque que vem a seguir ao clique fechava a caixa na mesma. Por isso a leitura passou para logo depois do clique, e o M3 acima é dessa versão.

## 3. As outras suites (local, Godot 4.7.2 `--headless`, em `d1ba45b`)
`provas/ordem-f36-medir-mestre/suites/resumo-alheios.txt`, 0 erros de script:
- `rodar_testes` 321/321;
- `caixa_janela` 123/123, com a mutação das células a dar 114/123 (as 9 falhas da B6);
- `caixa_jogadora` 70/70;
- `abrir_mestre` 67/67;
- `pecas_mestre` 286/286;
- `hud_acoes` 50/50;
- `abrir_clareira` 22/22;
- `canario_privacidade` 10/10;
- `teste_relato_caixa` 31/31;
- `teste_nomes_relato` 26/26;
- `medir_painel_config` 0 falhas;
- `abrir_scripts`: 108 scripts, 0 falhas.

## 4. O CI da ponta
*(A preencher no commit da nota do CI.)*

## 5. Listas da retoma
Corri o `actualizar-listas.py` depois do commit 1. Deu 0 novos e 0 tirados. Só muda o SHA de `rascunhos/cliente/testes/medir_mestre.gd` no `retoma-i0004/depois.txt` e no `MANIFESTO-SHA256.txt` (`606db648…` → `42e34a07…`), que vão neste commit.

## 6. Privacidade, re-derivada
Usei o conferidor `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs` nos dois critérios (alargado e `--velho`).

| ficheiro | alargado / antigo | nomes inteiros |
|---|---|---|
| este ESTADO-FINAL | **0 / 0** | 0 |
| as linhas que acrescentei a `medir_mestre.gd` (o `+` do diff contra `7c4da45`) | **0 / 0** | 0 |
| `provas/ordem-f36-medir-mestre/README.md`, `ferramentas/mutacoes-medir-mestre.sh`, `mutacoes/resumo.txt`, `suites/resumo-alheios.txt` | **0 / 0** | 0 |
| `suite/medir_mestre.log`, `suite/medir_mestre.antes.log`, `mutacoes/M1…M4.log` | 6 / 6 por log | **0** |

- **Os logs do Mestre:** os 6 achados estão todos nas 3 linhas `[floresta] …` que o próprio jogo imprime ao carregar o cenário (2 por linha). É o padrão já aceite na CAIXA-EXPANDE-VISTAS, e o log da base `7c4da45` dá o mesmo 6 / 6. As linhas que a suite escreve dão 0.
- **As minhas linhas** tinham uma palavra corrente que partilha um pedaço de 4 letras com os nomes: 2 achados no `.gd` e 4 no guião. Troquei-a. Ficaram 0 / 0, e a suite e as mutações voltaram a correr depois da troca; os números acima são dessa corrida.
- **Os logs inteiros das outras suites não se cometem,** porque o do `teste_nomes_relato` imprime nomes verdadeiros de propósito. Fica só a linha final de todos.
- **As criaturas de ensaio** («Vigia de ensaio N», «Sombra comprida de ensaio N») têm nomes inventados para a medida.
- **PIN:** esta ordem não arrancou o servidor nem a prova viva, por isso não houve PIN. Não há nenhum valor de PIN em nenhum ficheiro.

## 7. Pontos abertos para o coordenador
1. **A sentença não foi encontrada.** O caminho `~/workspace/conferencias/caixa-expande-vistas/SENTENCA-CAIXA-EXPANDE-VISTAS.md` não existe nesta máquina (nem `~/workspace`), e não há cópia no repo. Liguei D-A/D-B/D-C/D-G aos passos 1–4 pela ordem. Se a sentença os define de outra maneira, a obra pode não bater letra a letra: falta conferir.
2. **«Fecho pelo clique» com o rato a sério não existe no jogo.** Um clique do rato fora da caixa, sem o rato se mexer antes, não a fecha: só o movimento fecha. Na prática o rato mexe-se sempre até ao sítio do clique, por isso não vi defeito. Medi o fecho pelo clique no único caminho que o jogo tem: o clique imitado de um toque (regra D1). Fica para decidir se um clique do rato a sério fora da caixa também a deve fechar. Seria uma mudança do jogo, fora desta ordem.
3. **Os números afirmados no D-B são os medidos na ponta.** São eles: 9 linhas em 844×390, 8 em 780×360 e todas em 1920×1080; em 780×360 cortam-se só os nomes de ensaio. Não vêm de uma especificação. Se a letra, a altura da linha ou os nomes de ensaio mudarem, as tabelas `LINHAS_A_VISTA` e `ECRA_CORTA_NOMES` mudam com eles, e a suite reprova até alguém as actualizar. Isso é o que se quer.
4. **Câmara livre nos ecrãs baixos:** continua sem lugar, por desenho. Agora está afirmado, com o porquê. Se o desenho mudar e a caixa passar a caber, `LIVRE_COM_LUGAR` reprova e obriga a medir a vista aberta lá.
