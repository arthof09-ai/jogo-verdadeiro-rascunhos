# ESTADO-FINAL — ORDEM-PLANO-2-F1-ADENDA (CM-000009) — D-AUD-12: o sufixo também no snapshot

**Estado: ENTREGUE.** Linha `fable/integracao-50`, directamente na linha. Base medida ao arrancar (26/11/2026, `git ls-remote`):
`4fd5c6c`, a ponta da retoma da F1.

**Pré-condição.** A F1 está PARCIAL (falta a batalha de bancada com vídeo), mas a parte que esta adenda corrige, o D-AUD-12, foi
entregue no `4739849` (23/11). A adenda não toca na bancada.

## 1. O que se mediu primeiro: a causa já estava fechada no código

A sentença da INVESTIGA (E9) diz que a F1 «omite `figuraPublica` (`projecao.js:133-143`)». Na ponta, isso **já não se
verifica**. As linhas citadas são as de **antes** da F1. Desde o `4739849`, `figuraPublica` compõe o nome com
`nomePublicoDaFigura(fig, ficha)`, que chama `comOrdinal(nomePublicoDe(ficha), fig)`. Hoje é `projecao.js:148-158`. O mesmo vale
para `figuraDoMestre` (`:164-178`). O `nomePublicoDe(ficha)` não precisou de mudar de assinatura: o sufixo compõe-se em
`figuraPublica`, que é uma das duas vias que a ordem admitia.

O que faltava era o **caso de regressão** dos snapshots novos. O teste da F1 (`d-aud-12-ordinal.test.mjs`) só cobria o
snapshot do recomeço.

Decisões da ordem, aplicadas:
- **`projecao.js` não muda.** O sufixo já nasce em `figuraPublica`.
- **`CAMPOS_PERMITIDOS` não muda.** O ordinal não é um campo separado nos eventos: vai dentro do `nomePublico`. O teste da F1
  confirma que as figuras do snapshot da Party têm só as 7 chaves de sempre.
- **`conferir-estado.js` fica fora do âmbito** (E10) e não é tocado. A linha que a F1 lá pôs, `seHouver(f, 'ordinal', …)`,
  fica como está, porque esta adenda não a revê.
- O formato é o da F1 («Orc 1», «Orc 2»). Se o Mestre escolher outro (C-4), a mudança é de uma linha em `comOrdinal`.

## 2. Caso de regressão: `rascunhos/servidor/testes/d-aud-12-snapshot-novo.test.mjs` (7 casos)

A mesa tem dois orcs da mesma ficha e um lobo. Em cada caminho que dá um snapshot novo, os nomes das figuras do
`ROOM_SNAPSHOT` têm de ser `Heroína Teste`, `Lobo 1`, `Orc 1`, `Orc 2`. Os casos são estes:

| Caminho | Quem | Antes (mutação) | Depois (ponta) |
|---|---|---|---|
| entrada a meio da batalha | espectador | «Orc»/«Orc» | «Orc 1»/«Orc 2» |
| **reentrada** (sai e volta) | jogadora, espectador | «Orc»/«Orc» | «Orc 1»/«Orc 2» |
| **resync** com um `lastSeq` que não se serve | jogadora, espectador | «Orc»/«Orc» | «Orc 1»/«Orc 2» |
| **resync** com o `lastSeq` de antes do corte do recomeço | jogadora | «Orc»/«Orc» | «Orc 1»/«Orc 2» |
| **recomeço** (o snapshot que vai a todos) | jogadora, espectador | «Orc»/«Orc» | «Orc 1»/«Orc 2» |
| sala **reaberta do journal**, com o Mestre já dentro | jogadora | «Orc»/«Orc» | «Orc 1»/«Orc 2» |
| sala **reaberta do journal**, com a jogadora à espera até o Mestre voltar | jogadora | «Orc»/«Orc» | «Orc 1»/«Orc 2» |

- **Antes** (`provas/ordem-plano-2-f1-adenda/regressao-snapshot-ANTES.log`): é a mutação que repõe o estado da reprodução
  `l28`. Em `figuraPublica`, o `nomePublicoDaFigura(fig, …)` passa a `nomePublicoDe(fichas[fig.fichaId])`
  (`mutacao-figuraPublica.diff`). Resultado: **0 de 7**, com «Orc»/«Orc» em todos os snapshots. A mesma mutação também correu
  dentro do `suites.sh` pelo padrão B3: `pass 0 fail 7`, o ficheiro foi reposto e o `git diff` ficou vazio.
- **Depois** (`regressao-snapshot-DEPOIS.log`): **7 de 7**.

Uma nota sobre a sala reaberta. Até o Mestre voltar, a jogadora está na sala de espera (ordem 22, 17-2) e o snapshot dela
é só o lobby, com 0 figuras. Isto é desenho do jogo, não é falha. A batalha chega-lhe num snapshot novo quando o Mestre
entra, e é esse que o teste confere.

No cliente, `estado.gd:133-138` limpa as figuras e copia as do snapshot tal como vêm. O que o servidor manda é o que a
jogadora vê.

## 3. Suites

Correram neste PC com Godot 4.7.2 `--headless` e Node v26.13.0, sobre `4fd5c6c` mais o teste novo. O guião é
`provas/ordem-plano-2-f1-adenda/suites.sh`: são as suites da F1 mais a mutação acima. Os logs e o `resumo.txt` estão em `suites/`.

| Suite | Resultado |
|---|---|
| servidor (`testes/*.test.mjs`) | **453/453** (446 da F1 + 7 novos) |
| motor real | 6/6 |
| prova da caixa | PROVA OK |
| `abrir_scripts` · `medir_painel_config` · `medir_mestre` · `aparelhos_f2` | exit 0 |
| `rodar_testes` | 333 de 333 |
| `abrir_clareira` | 22 de 22 |
| `abrir_mestre` | 67 de 67 |
| `pecas_mestre` | 336 de 336 |
| `hud_acoes` | 70 de 70 |
| `caixa_jogadora` | 70 de 70 |
| `camera_segue` | 19 de 19 |
| `caixa_janela` | 123 de 123 |
| **canário de privacidade** | **10 de 10** |
| `teste_relato_caixa` · `teste_nomes_relato` | 31 de 31 · 26 de 26 |
| validar-mensagens (`pecas_mestre`, `abrir_mestre`) | exit 0 · exit 0 |
| Sonda dos caminhos do PC | na cópia limpa: 0 novas, exit 0. Na árvore de trabalho deu exit 1 só por `.godot/editor/project_metadata.cfg`, que o git ignora e que o `--import` criou. |

Todas as suites deram 0 `SCRIPT ERROR / Parse Error / Compile Error`.

**A primeira corrida não conta.** Foi feita num clone novo, sem a cache `.godot`, e os `class_name` não se resolviam: deu
scriptErrors e timeouts nas suites do Godot. Isto era do ambiente, não do código. Ficou registada em
`suites/resumo-primeira-corrida-sem-import.txt`. A seguir correu-se uma vez `Godot --headless --import` e repetiu-se tudo: o
resultado é a tabela acima. Para quem correr o guião num clone novo: fazer o `--import` primeiro.

**Privacidade:** só fichas e nomes fictícios (Heroína Teste, Visita, Orc, Lobo). Não há e-mails nas provas, e os caminhos do PC
saem como `<sede>`.

## 4. Commits

| Commit | O quê |
|---|---|
| `15bc45e` | o teste novo `d-aud-12-snapshot-novo.test.mjs` |
| `dee1a39` | listas da retoma sincronizadas (1 novo, 0 tirados) |
| (este) | provas e este ESTADO-FINAL |
| (a seguir) | nota do CI |

## 5. Nota do CI

Fica no commit seguinte, com os números das corridas.
