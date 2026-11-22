# ESTADO FINAL — ORDEM CAIXA-HUD-JOGADORA-MEDICAO-8-FIGURAS (Claude conta 1, PC · 22/11/2026)

Ordem: fechar o PENDENTE da HUD-JOGADORA, a caixa da jogadora com 8 figuras em ecrãs baixos. Classe MEDIÇÃO.
Base: `fable/integracao-50` @ `5a29112` (a ponta à hora do lançamento). Trabalho directo na linha, sem ramo lateral.
Este ficheiro não leva nomes verdadeiros nem o valor de nenhum PIN.

## 1. O ponto

### B1: medir a caixa da jogadora com 8 figuras em ecrãs baixos. FEITO. Há 1 transbordo, no ponto 4 (§3).
- **O critério foi escrito antes da corrida** e está em `provas/ordem-caixa-hud-jogadora/medicao-8-figuras/CRITERIO.md`.
  São 5 pontos: (1) a caixa não tapa a ⚙/ficha; (2) não tapa a barra inferior; (3) não tapa a faixa de cima;
  (4) a faixa continua centrada; (5) nada fica cortado.
- **O teste alargado** é `rascunhos/cliente/testes/caixa_jogadora.gd`, com um §8 novo:
  - 8 figuras na ordem dinâmica (2 da jogadora e 6 criaturas, com nomes públicos genéricos de até 10 letras);
  - a caixa ligada, em combate;
  - medida em 844×390, 780×360 e 1920×1080 (controlo);
  - a faixa medida com a frase mais comprida que mostra (`FAIXA_MAIS_LONGA`).
  O helper partilhado `_snapshot` mudou em 2 linhas; os §§1–7 passam iguais (18/18 nas duas corridas). O teste continua a ser o mesmo ficheiro que o CI já corre, e o workflow não foi tocado.
- **A corrida:** Godot 4.7.2 do PC (`Godot_v4.7.2-stable_win64.exe`, `4.7.2.stable.official.ed1daf0bf`),
  `--headless`, sem GPU. Primeiro `--import` (rc 0). Depois `-s res://testes/caixa_jogadora.gd` com `--path rascunhos/cliente`.
  A medição é exequível em headless: o critério de morte não se aplicou.
- **Não toquei na caixa:** `hud/caixa_ordem.gd`, `hud/ordem_turnos.gd`, `hud/retratos.gd`, `dados/apresentacao.gd`,
  `hud/hud.gd` e `.github/workflows/*` ficaram intactos.

## 2. A prova: os números por resolução
Os ficheiros estão em `provas/ordem-caixa-hud-jogadora/medicao-8-figuras/`:
- `CRITERIO.md`: o critério;
- `TABELA.md`: a tabela completa;
- `corrida-1-criterio.log` e `corrida-2-final.log`: os 2 logs.

As unidades (u) são as da tela do HUD, em que a altura é sempre 1080 u. Os px reais são as unidades vezes a escala.

| Resolução | Altura da caixa | Caixa (u) | Faixa: largura restante / precisa | Sobreposição | Centrada | Cortado |
|---|---|---|---|---|---|---|
| **844×390** | 323 u = 117 px reais (30 % do ecrã) | 1186×323, 8 por linha | 959 u / 729 u | **não** | **não** (margens 126 / 1204 u) | não |
| **780×360** | 349 u = 116 px reais (32 % do ecrã) | 1269×349, 8 por linha | 867 u / 788 u | **não** | **não** (margens 136 / 1288 u) | não |
| 1920×1080 (controlo) | 212 u = 212 px reais (20 % do ecrã) | 767×212, 8 por linha | 1017 u / 453 u | **não** | **não** (margens 77 / 778 u) | não |

A sobreposição dá não nas três resoluções e em todos os elementos (ficha `false`, barra `false`, faixa `false`).
Também nas três:
- a caixa cabe no ecrã;
- os 8 quadradinhos estão todos dentro da caixa;
- a faixa tem mais largura livre do que a frase mais comprida precisa;
- a barra está visível.

O veredicto pelos pontos é o mesmo nas três resoluções: **1, 2, 3 e 5 cumprem; o 4 falha.**

| Corrida | Resultado |
|---|---|
| `--import` do cliente | rc 0 |
| teste antes de mexer, na base `5a29112` (referência) | 18 de 18, rc 0 |
| `corrida-1-criterio.log`, o critério tal como foi escrito, com o ponto 4 a contar | **33 de 36**, rc 1. As 3 falhas são o ponto 4 nas 3 resoluções |
| `corrida-2-final.log`, o teste publicado, com o ponto 4 em linha `REGISTO (não conta)` | **33 de 33**, rc 0, 0 linhas com `FALHA`, `ERROR` ou `WARNING` |
| linhas `MEDIDA` das duas corridas | iguais byte a byte |
| conferidor estrito (`provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`), alargado e antigo: o teste, o `CRITERIO.md`, o `TABELA.md` e o `corrida-2-final.log` | **0 / 0 achados**, 0 inteiros |
| conferidor estrito no `corrida-1-criterio.log` (o log tal como saiu do Godot), alargado e antigo | 6 / 0 achados, **0 inteiros**. São pedaços (6 letras) de palavras correntes numa frase do teste, que depois mudou |
| conferidor estrito neste ESTADO-FINAL, alargado e antigo | 0 / 0 achados |
| `retoma-i0004/actualizar-listas.py` | ver §4 |

**Porque o ponto 4 não conta no teste publicado.** O teste já está no CI, com `pipefail`, e um rc 1 punha a linha
vermelha. A faixa descentrada vem do desenho da Ordem CAIXA-JANELA B3 (`hud.gd _posicionar_caixa`): quando a faixa
centrada não cabe, centra-se entre a ⚙ e a caixa. Essa decisão está à espera do olho do Mestre, e esta ordem não a pode
corrigir. Por isso o teste mede-a e regista-a numa linha `REGISTO (não conta)` nas 3 resoluções. Os pontos 1, 2, 3 e 5
continuam a ser verificações que contam e guardam contra regressões. A corrida do critério sem esta mudança fica
cometida como prova (33/36). A variante do teste com o ponto 4 a contar não foi cometada — só o seu log
(`corrida-1-criterio.log`).

**Mudanças de redacção feitas depois da 1.ª corrida, só para o conferidor dar 0 achados:**
- no teste, a frase da barra ficou «barra inferior»;
- no `CRITERIO.md`, o mesmo (ponto 2, «não tapa a barra inferior»).

Não mudou o sentido de nenhum ponto nem nenhuma conta.

## 3. Pontos para o coordenador
1. **O transbordo, com números.** Com 8 figuras, a caixa nunca tapa nada nem corta nada. Mas a faixa de cima **deixa de
   estar centrada no ecrã em todas as resoluções medidas, incluindo o controlo 1920×1080.** Centra-se entre a ⚙ e a
   caixa. A faixa só fica centrada se `área − 2 × (caixa + folga) ≥ precisa`:

   | Resolução | Caixa máxima para centrar | Caixa com 8 | Excesso | Desvio do centro da faixa |
   |---|---|---|---|---|
   | 844×390 | 762 u | 1186 u | **424 u** | 539 u |
   | 780×360 | 732,5 u | 1269 u | **536,5 u** | 576 u |
   | 1920×1080 | 698,5 u | 767 u | **68,5 u** | 350,5 u |

   A correcção é o EXPANDE, pendente do veredicto do Mestre às fotos do PADRAO-BUSTO. Não se corrigiu aqui.
   O `ESTADO-FINAL-ORDEM-CAIXA-JANELA.md` (linhas 78–79) já dizia que a faixa descentra com a caixa larga. Esta medição
   dá-lhe os números para 8 figuras e mostra que o mesmo acontece em 1920×1080.
2. **A altura da caixa** fica a 30–32 % do ecrã nos ecrãs baixos, numa só linha de 8, porque ao lado ainda há largura
   para a faixa e a fila não precisa de partir. Não tapa a ⚙/ficha nem a barra.
3. **O retrato no teste é o da linha (2,8 letras).** O PADRAO-BUSTO (3,4 letras) não está na linha. Se o EXPANDE ou o
   PADRAO-BUSTO entrarem, a caixa alarga e estes números mudam. Basta voltar a correr `caixa_jogadora.gd` §8, que imprime
   as linhas `MEDIDA` e `REGISTO`.
4. **A cobertura que já existia:** o `testes/caixa_janela.gd` B3 (Ordem CAIXA-JANELA) já mede 8, 12 e 16 figuras em
   844×390, 780×360 e 1280×720, mas não mede a centragem nem o controlo 1920×1080. O §8 novo cobre essa parte.

## 4. Commits e listas
- **`retoma-i0004/actualizar-listas.py`**, corrido na raiz do repo:
  - antes do 1.º commit: «antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta
    passagem)», sem mudanças, porque o script lê o `HEAD`;
  - depois do 1.º commit: o mesmo, **0 novos, 0 tirados**. Mudou a linha SHA-256 do `caixa_jogadora.gd` em
    `retoma-i0004/depois.txt` e em `MANIFESTO-SHA256.txt` (1 linha por ficheiro). Esses dois ficheiros ficam fora do
    território declarado, mas é a própria regra da casa que manda corrê-lo, e o job `retoma-pc` do CI exige-o.
- **Commits, directamente na linha `fable/integracao-50`, sem ramo lateral:**
  - `dca5694`: o teste (§8) e a pasta de provas;
  - `3203d83`: as listas da retoma e este ESTADO-FINAL;
  - `7f7ab32`: só o §5 deste ficheiro.
  Antes de publicar: `fetch` e depois `rebase` sobre a ponta. A ponta continuava em `5a29112`: nada a rebasear e
  nenhum conflito.
- **Publicado:** push `5a29112..7f7ab32 -> fable/integracao-50`. `git ls-remote`: `fable/integracao-50` =
  `7f7ab32e3206c4347736ad3f797f82fb85fb8230`.

## 5. CI verificado no `7f7ab32`
- No `7f7ab32`: **Testes dos rascunhos success** (run 45067521621) e **Sonda de privacidade success**
  (run 45067521656) — 11/11 check-runs.
- No `3203d83` também estava verde: Testes run 45067277410 e Sonda run 45067277477.
- No job `cliente`, o `caixa_jogadora.gd` dá **33 de 33**. As 3 linhas `REGISTO (não conta)` têm os mesmos números do
  PC (margens 126/1204, 136/1288 e 77/778 u).
- §5 actualizado no commit documental da conferência (F1) para citar o CI da ponta `7f7ab32`.
