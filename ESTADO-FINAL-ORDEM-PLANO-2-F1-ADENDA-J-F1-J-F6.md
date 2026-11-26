# ESTADO-FINAL — ORDEM-PLANO-2-F1-ADENDA: FECHO J-F1 A J-F6

**Estado: ENTREGUE.** Os seis follow-ups da sentença da F1-ADENDA (APROVADA COM RESSALVAS, 918/1000) estão feitos. Linha
`fable/integracao-50`, directamente na linha, sem fusão, um push por passo. Base medida ao arrancar (26/11/2026,
`git fetch` + `git ls-remote`): **`685924e`**, a ponta do fecho com vídeo da F1.

As provas novas estão em `provas/ordem-plano-2-f1-adenda/j-f/`. Os artefactos que a adenda já tinha não mudaram de lugar.

| Ponto | Feito | Prova | Commit |
|---|---|---|---|
| J-F1 | contador = testes falhados; resumo regenerado sem re-correr: `falhas=7`; corrida focada: `falhas=7` | `suites.sh` (função `falhas`), `suites/resumo.txt`, `j-f/j-f1-corrida-focada-mutacao/` | `58f36e3` |
| J-F2 | primeira linha do resumo com a árvore testada (limpa / por cometer + diff) | as duas corridas focadas | `58f36e3`, `1db055d` |
| J-F3 | diagnóstico re-derivável: reprodução sem `.godot` e ressalva escrita | `j-f/j-f3-reproducao-sem-import/` | `935a61a` |
| J-F4 | sem `.sort()`; resync pós-recomeço também para o espectador | `j-f/j-f4-snapshot-sem-sort/` | `32a1a5b` |
| J-F5 | lobby da sala reaberta: `lobby.figuras.length === 0`, PROVA `[]` | `j-f/j-f5-lobby-sala-reaberta/` | `63fd6e2` |
| J-F6 | uma só grafia da mutação (a comentada) | `mutacao-figuraPublica.diff` | `e33a40b` |

## J-F1 — o contador de falhas

- **Guião.** Em `muta()` do `provas/ordem-plano-2-f1-adenda/suites.sh`, o `grep -cE '  FALHA |^not ok|✖'` passou a ser a
  função `falhas`. Ela lê o `ℹ fail N` do node e, sem ele (Godot), conta as linhas `  FALHA `. É a mesma função que o
  `provas/ordem-plano-2-f1/suites.sh` tem desde o F4 do fecho (`2f7b6f6`). **Por isso o guião da F1 não precisou de mudar:**
  a correcção já lá estava. O contador velho dava 15 para 7 testes: os 7 `✖`, mais o cabeçalho `✖ failing tests:`, mais os 7
  repetidos na lista final. Medido no log novo: o grep velho dá 15 e o `falhas` dá 7.
- **Resumo regenerado, sem re-correr.** Apliquei a função `falhas` ao log já cometido
  `suites/d-aud-12-snapshot-SEM-SUFIXO-NA-FIGURA-PUBLICA.log`, que dá 7. A linha passa a dizer
  `falhas=7 fim=«ℹ pass 0 ℹ fail 7 »`, e uma linha `#` explica a troca. Fiz a mesma correcção no
  `resumo-primeira-corrida-sem-import.txt`. Aí o 7 vem do `fim=` da própria linha, porque o log dessa corrida não sobreviveu
  (ver J-F3).
- **Corrida focada** (`SO_MUTACAO=1`, só o passo da mutação, sem GODOT nem motor):
  `d-aud-12-snapshot-SEM-SUFIXO-NA-FIGURA-PUBLICA exit=1 falhas=7 fim=«ℹ pass 0 ℹ fail 7 » reposto=sim`. Correu duas vezes, com
  o mesmo resultado: sobre `685924e` com o guião por cometer (`j-f1-…`) e sobre o `58f36e3` cometido (`j-f2-…`).

## J-F2 — a árvore exacta no resumo

A primeira linha do `resumo.txt` passa a ser
`# commit: <HEAD> · árvore testada: <tree> (limpa: a árvore do commit)`. Se a cópia de trabalho não for igual ao commit, a
linha diz `(NÃO é a do commit, <tree do HEAD>: …)`. Nesse caso seguem-se linhas `# por cometer: <git status --porcelain>` e o
guião guarda `arvore-por-cometer.diff` (`git diff --binary` do HEAD para a árvore testada). A árvore mede-se com um índice
temporário: `git add -A` e depois `git write-tree`, o que respeita o `.gitignore` e não toca no índice real. Mede-se antes da
mutação.

- Árvore por cometer (`j-f1-corrida-focada-mutacao/resumo.txt`): `árvore testada: c3a93e6…`, com
  `por cometer: M …/suites.sh`. **Conferi que é reproduzível:** num worktree limpo do `685924e`, `git apply` do diff guardado
  seguido de `git add -A && git write-tree` dá **`c3a93e637d069196b1cdc543951cead44050e3fb`**, a mesma árvore.
- Árvore limpa (`j-f2-corrida-focada-arvore-limpa/resumo.txt`): `commit: 58f36e3… · árvore testada: 08c9c64… (limpa)`. É igual
  a `git rev-parse 58f36e3^{tree}`.
- Os dois resumos antigos da adenda não tinham a árvore medida. Acrescentei-a à mão, com a marca «não medida»: pelo
  ESTADO-FINAL da adenda, a árvore era `4fd5c6c` mais o teste ainda por cometer, que entrou no `15bc45e` (filho directo do
  `4fd5c6c`, só com esse ficheiro).

## J-F3 — a prova do diagnóstico da corrida descartada

**Ressalva escrita: os logs brutos da primeira corrida não sobreviveram.** Só ficou o resumo. O guião apaga `$L/*.log` no
arranque, e a segunda corrida usou o mesmo `$L`. Isto é inferido do guião e do ESTADO-FINAL da adenda («repetiu-se tudo»), não
foi visto. A sede da adenda já não existe neste PC, e procurei os logs neste PC sem os encontrar.

Para o diagnóstico ser re-derivável do pacote, **reproduzi-o**. Fiz um worktree do `15bc45e` (a árvore da adenda), que não tem
`.godot` porque o git a ignora, e corri o `abrir_scripts` com o Godot 4.7.2 `--headless`:

| Passo | exit | scriptErrors |
|---|---|---|
| sem `--import` | 1 | **26**, o mesmo número do resumo da primeira corrida |
| `--import` | 0 | 0 |
| com import | 0 | 0, como no `resumo.txt` que conta |

Excerto (`abrir_scripts-sem-import.log:4-5`): `SCRIPT ERROR: Parse Error: Could not find type "AplicadorPerfil" in the current
scope. at: … (res://arte/cenas/clareira_prova.gd:57)`. Logo a seguir vem `ColorScript`. Os dois são `class_name` declarados
(`arte/perfis/aplicar_perfil.gd:1` e `arte/ambiente/color_script.gd:2`). Os três logs e o `LEIA.txt` com os comandos estão em
`j-f/j-f3-reproducao-sem-import/`. **Limite:** só reproduzi o `abrir_scripts`, não as 13 suites. É uma reprodução, não o log
original. Pus também no cabeçalho do `suites.sh` o aviso de correr o `--import` primeiro num clone novo.

## J-F4 — sem `.sort()`; o espectador no resync pós-recomeço

- **Sem ordenação.** Ao medir a ordem real das figuras, vi que ela **não é estável entre caminhos**. A sala reaberta do journal
  dá Heroína, Lobo, Orc, Orc. Os outros caminhos dão Heroína, Orc, Orc, Lobo. Comparar a lista pela ordem faria falhar a sala
  reaberta sem defeito nenhum. Por isso o teste confere **cada nome na casa da sua figura** (2,2 Heroína Teste · 2,6 Orc 1 ·
  5,6 Orc 2 · 9,9 Lobo 1) e afirma que o snapshot tem 4 figuras. A linha PROVA passa a ser `nome@x,y`, pela ordem do snapshot.
- **O espectador.** O caso «RESYNC depois do recomeço» corre agora para a jogadora e para o espectador, cada um com o seu
  `lastSeq` de antes do corte.
- **Resultados** (`j-f/j-f4-snapshot-sem-sort/`, no `32a1a5b`): DEPOIS **7 de 7, 11 linhas PROVA** (eram 10, entrou
  `resync-pos-recomeco-espectador`). ANTES, com a mutação da adenda, 0 de 7. Servidor **453/453**: o caso novo está dentro de
  um teste que já existia, por isso o número não mudou.
- **O que o `.sort()` deixava passar, medido.** Fiz uma mutação ad hoc em `comOrdinal`, que troca «Orc 1»/«Orc 2» entre os dois
  orcs, e corri os dois testes. O teste velho (`6622b3e`) dá **7 de 7 verde**. O teste novo dá **0 de 7**
  (`troca-teste-velho.log`, `troca-teste-novo.log`).

## J-F5 — o lobby da sala reaberta

No caso da sala reaberta com a jogadora à espera, entraram `registar('sala-reaberta-lobby-heroina', lobby)` e
`assert.equal(lobby.figuras.length, 0)`, mais o `Array.isArray`. O DEPOIS (`j-f/j-f5-lobby-sala-reaberta/`, no `63fd6e2`) traz
`PROVA sala-reaberta-lobby-heroina: []`. Dá 7 de 7 e 12 linhas PROVA: as 11 do J-F4 mais esta. O servidor fica em 453/453. A
afirmação «com 0 figuras» do ESTADO-FINAL da adenda passa assim a ser medida.

## J-F6 — uma só grafia da mutação

**A grafia escolhida é a linha com o comentário:**
`    nomePublico: nomePublicoDe(fichas[fig.fichaId]), // MUTACAO (PLANO-2-F1-ADENDA): o snapshot sem o número`.
Regenerei o `mutacao-figuraPublica.diff`: apliquei esta linha ao `projecao.js` (blob `34732f5`, igual desde o `4fd5c6c`) e tirei
o `git diff`. Por isso o blob novo é `4d92936`. Conferi com `git apply --check`. Agora o `mutacao-figuraPublica.diff`, o
`suites.sh` e o `suites/d-aud-12-snapshot-SEM-SUFIXO-NA-FIGURA-PUBLICA.log` mostram a mesma linha byte a byte. Escolhi esta
grafia para não editar o log de uma corrida. O `regressao-snapshot-ANTES.log` da adenda fica como foi corrido, com a linha sem
o comentário. É o registo de uma corrida e o comentário não muda o comportamento. Os ANTES novos do J-F4 já usam a grafia
comentada.

## Commits

| Commit | O quê |
|---|---|
| `58f36e3` | J-F1 + J-F2: o guião, os dois resumos regenerados e a corrida focada (árvore por cometer) |
| `1db055d` | J-F2: a corrida focada sobre a árvore limpa |
| `935a61a` | J-F3: a reprodução sem `.godot` e a ressalva |
| `32a1a5b` | J-F4: o teste e as provas |
| `63fd6e2` | J-F5: o teste e as provas |
| `e33a40b` | J-F6: o diff regenerado |
| `d0c88c2` | listas da retoma sincronizadas (0 novos, 0 tirados; `d-aud-12-snapshot-novo.test.mjs` `90267348…` → `9c2d44e7…`) |
| (este) | este ESTADO-FINAL |
| (a seguir) | nota do CI |

Ambiente: Node v26.13.0, Python 3.12.10, Godot 4.7.2 `--headless`. Privacidade: só fichas fictícias, os caminhos do PC saem
como `<sede>`, e a sonda dos caminhos está limpa (0 novas). Um incidente sem consequência: no J-F4, o `sed` da redacção deu erro
depois do push. Conferi a seguir que os logs enviados não tinham nenhum caminho do PC (grep e sonda, 0).

## Nota do CI

(no commit seguinte)
