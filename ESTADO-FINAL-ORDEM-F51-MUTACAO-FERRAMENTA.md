# ESTADO FINAL — ORDEM F51 (prova da mutação com artefacto + ferramenta de redacção) · Claude conta 1, PC · 23/11/2026

A F51 da sentença da F25. A F25 deixara dois pontos só em testemunho: a prova da mutação do canário (§3) e a
redacção da saída nova do canário antes de a comparar (§7.5). Os dois passam a ser reproduzíveis no repo.

- **Linha:** trabalho directo em `fable/integracao-50`, sem ramo lateral nem fusão.
- **Base:** o `HEAD` do clone à hora do lançamento era `9fe4ce2` (F50). Antes do commit, a linha andou para `526ef0d`
  (três notas de CI e a F60, só em ESTADO-FINAL da F25, F28 e F36). Avancei por *fast-forward* e voltei a correr as
  duas provas e o canário sobre `526ef0d`: os números são os mesmos. A obra assenta em `526ef0d`.
- **Commits:**
  - `25fb4ea`: a obra (a ferramenta, as provas, o remendo do CI e o README);
  - o commit deste ESTADO-FINAL;
  - o commit da nota do CI (§5).
- **A sentença.** O ficheiro `~/workspace/conferencias/f25-limpeza-11-ficheiros/SENTENCA-F25-LIMPEZA-11-FICHEIROS.md`
  **não existe neste PC** (não há `~/workspace`). Trabalhei com os §§ que a ordem cita, tal como estão no
  `ESTADO-FINAL-ORDEM-F25-LIMPEZA-11-FICHEIROS.md` da ponta: o §2 (a redacção), o §3 (a mutação) e o ponto 5 do §7.
  Batem com o que a ordem descreve. Ver o ponto 1 do §7.
- **Biblioteca (GameDev Kit):** vi as pastas de ferramentas e plugins da BIB (`06_Ferramentas_e_Plugins`,
  `16_Ferramentas_de_Desenvolvimento`, `16 - Ferramentas e Editores`, `10_Ferramentas_e_Plugins`). Só há plugins de
  editor, UI, VFX e gravação de jogo, nada para redigir registos de texto. É o que a F25 já registara. A ferramenta
  nova segue o padrão do `conferir-registo.mjs` da mesma pasta.

## 1. Passo 1 — a mutação, com log cometido

**Como se correu:** `bash provas/ordem-f51-mutacao/correr-mutacao-canario.sh <godot> <pasta-tmp>`. O script faz isto:
1. confere que `nomes_relato.gd` está igual ao commit e que a linha 59 é a condição de `no_relato()`;
2. põe `false and` nessa condição, só na cópia de trabalho (`mutacao.diff`);
3. corre o canário com Godot 4.7.2 Windows (`_console.exe`), da mesma forma que o CI:
   `godot --headless --path rascunhos/cliente -s <raiz>/provas/ordem-caixa-janela/ferramentas/teste_nomes_relato.gd`;
4. repõe o ficheiro com `git checkout` e confere que o `git diff` ficou vazio;
5. redige o log com a ferramenta do §2 e escreve o `resumo.txt`.

**Resultado** (`provas/ordem-f51-mutacao/resumo.txt`):
- **rc=1, 23 de 26 verificações**, sem `SCRIPT ERROR`, `Parse Error` nem `Compile Error`.
- **As 3 FALHA do §3 da F25:**
  - `FALHA 3: «nome n.º 1» na linha 5 → o canário FALHA (0 achado(s), linhas [5])`, a linha 5 suja;
  - `FALHA 3: dentro de JSON também se apanha («nome n.º 2»)`, o nome dentro de JSON;
  - `FALHA 4: o canário apanha no relato antigo 22 achados (…) (0 achado(s), linhas [7,8,…,34]; …)`, o caso medido.
- No log, todas as FALHA saem duas vezes, porque o teste faz `print` e `printerr` (`teste_nomes_relato.gd:41-42`).
- **Reposto:** o `git diff` de `nomes_relato.gd` ficou vazio depois do `git checkout`.

**O que se cometeu** (em `provas/ordem-f51-mutacao/`):
- `teste-nomes-relato.mutacao.log`: o log da corrida, 39 linhas, sha256 `4560e8ceac8d…`. **É o log redigido**: a saída
  crua do canário traz os nomes verdadeiros inteiros de propósito (10 ocorrências em 7 linhas) e ficou na pasta `tmp/`
  da ordem, fora do repo. Só as 7 linhas com nomes diferem da crua.
- `resumo.txt`: a base, o Godot, a mutação, o rc, a contagem, as 3 FALHA, a reposição, a redacção e o sha256 do log.
- `mutacao.diff`: a linha mudada.

A mutação correu três vezes, duas sobre `9fe4ce2` e uma sobre `526ef0d`, e o log redigido saiu igual byte a byte nas
três. Também é igual byte a byte à corrida da mutação da F25, que ficara crua no `tmp/` da F25, depois de redigida
com a mesma ferramenta. Assim o testemunho da F25 fica conferido contra o artefacto.

## 2. Passo 2 — a ferramenta da redacção do §2

**A ferramenta:** `provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs`, em node, como o `conferir-registo.mjs`.
Lê os nomes verdadeiros das fichas de teste do servidor em todas as corridas, por isso o código não tem nenhum nome.
A numeração é a da O1: a ordem dos nomes verdadeiros nas fichas. Redige as formas do §2 da F25:

| forma | passa a |
|---|---|
| o nome inteiro, sem distinguir maiúsculas | `nome n.º N` |
| a forma toda em minúsculas | `nome n.º N em minúsculas` |
| o canário mudado (a preposição do meio mudada) | `nome n.º N com a preposição mudada` |
| o nome cortado na origem: a linha acaba num pedaço inicial do nome maior do que o nome público | `nome n.º N (cortado na origem)` |

Nenhuma linha é acrescentada nem tirada e os fins de linha ficam como estavam. Se sobrar um nome inteiro, a
ferramenta sai com 3.

**Como se usa** (está no `provas/ordem-caixa-relato/README.md`, na secção da F51):
- `node provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs <saída-crua.log> --saida=<redigido.log>` escreve a
  saída redigida.
- `… <saída-crua.log> --comparar=<registo.log> [--ignorar-cr]` compara byte a byte. Diz só «igual» ou o n.º da 1.ª
  linha diferente, nunca o texto. `--ignorar-cr` serve para o CI: o Godot em Linux escreve LF e os 11 registos são
  CRLF.
- `… --auto-teste` corre 12 verificações com casos montados em memória a partir das fichas: as formas, o nome público
  intacto, o pedaço a meio de uma palavra, os fins de linha e a idempotência. Deu **12 de 12**.

**Prova de que reproduz o §2:** `provas/ordem-f51-mutacao/reproduzir-redaccao-f25.sh <pasta-tmp>` tira do histórico os
11 registos como estavam antes da limpeza (`06e77c4`, o pai de `081304e`) e redige-os. **Os 11 ficam iguais byte a byte
aos 11 limpos da ponta** (`reproducao-f25.log`). As contagens batem com a tabela do §2 da F25:
- 69 linhas redigidas: 4 por registo nos 9 do canário, 3 no `nomes-correcoes/mutacoes.log` e 30 no
  `correcoes-3/mutacoes.log`;
- 188 ocorrências, das quais 5 em minúsculas;
- 5 cortes na origem e 1 canário mudado.

**A saída nova do canário, comparada:** na ponta limpa, o canário deu **rc=0 e 26 de 26**. A saída, redigida, é
**igual byte a byte** a `provas/ordem-caixa-janela/cobertura-correcoes-6/teste-nomes-relato.log`: 3500 bytes, com 4
linhas e 7 ocorrências redigidas. É a comparação que o ponto 5 do §7 da F25 pedia. Com os fins de linha passados a LF,
como no CI, também dá igual com `--ignorar-cr` (3464 bytes). Sem essa opção, difere logo na linha 1, como deve.

**No CI: o passo novo está no remendo, por aplicar.** O passo para o job `cliente` está em
`provas/ordem-f51-mutacao/remendo-ci-testes.yml.patch`:
- um `actions/setup-node@v4` com o node 22, porque o job `cliente` não tinha node;
- o auto-teste;
- a comparação da saída do canário com o registo da COBERTURA-CORRECOES-6, logo a seguir ao passo do canário.

Cometi primeiro a obra com o workflow mudado, mas o `push` foi **recusado**: «refusing to allow an OAuth App to create
or update workflow `.github/workflows/testes.yml` without `workflow` scope». O token deste PC (o do `gh`) só tem
`gist`, `read:org` e `repo`. Refiz o commit, que ainda não estava publicado, sem o workflow e com o remendo. É o
caminho das ordens anteriores: o executor entrega o remendo e o coordenador aplica-o (`91fcfc5` da NOMES-CORRECOES e
`67c9169` da CAIXA-JANELA-CI).

O remendo aplica-se limpo na ponta (`git apply --check`). Os seus dois comandos, corridos cá contra a saída LF do
canário, deram rc=0. **Até alguém o aplicar, a ferramenta não corre no CI.** Ver o ponto 2 do §7.

## 3. Passo 3 — nada se partiu

- **O canário na ponta limpa:** 26 de 26, cá (rc=0) e no CI (§5).
- A obra não muda nenhum ficheiro que as suites leiam. Só acrescenta ferramentas e registos em `provas/` e uma secção
  no README. O workflow não mudou. Os números das suites vêm do CI da ponta (§5).

## 4. Privacidade re-derivada

- **Nomes verdadeiros inteiros: 0.** Contei, sem distinguir maiúsculas, nos 10 ficheiros que a obra acrescenta ou muda
  e neste ESTADO-FINAL. O log da mutação tem 0, porque é o redigido.
- **Critério estrito** (`conferir-registo.mjs`, pedaços de 4 ou mais letras). Este ESTADO-FINAL dá 0 achados nos dois
  critérios (alargado e `--velho`). Também dão 0: os dois scripts, o `README.md` da prova, o `mutacao.diff`, o
  `reproducao-f25.log` e o remendo. Os achados que sobram não são nomes inteiros: nenhum é nome verdadeiro inteiro. Seis deles são prefixos do nome verdadeiro (5 no log da mutação e 1 no resumo.txt) e coincidem com o nome público ou as suas primeiras letras, sem revelar mais do que o público.
  - `redigir-nomes.mjs`: 2 achados, os dois na linha do caminho por omissão das fichas, o mesmo do `conferir-registo.mjs`;
  - `provas/ordem-caixa-relato/README.md`: 32 → 34 achados. Os 2 novos estão nesse mesmo caminho;
  - `resumo.txt`: 1 achado, o adjectivo das ocorrências não filtradas, que vem citado da saída do canário na 3.ª FALHA;
  - `teste-nomes-relato.mutacao.log`: 17 achados. É saída do jogo, a que a decisão de âmbito da CORRECOES-7 não aplica
    o critério estrito, e é a mesma classe de achados dos 11 da F25 (§5 da F25). Tem mais 1 do que o registo da
    COBERTURA-CORRECOES-6 (16), porque as FALHA saem em duplicado.
  - Reescrevi as palavras correntes que se evitavam sem perder sentido (o pronome distributivo de quatro letras,
    o particípio de «aplicar» e o de «trocar»).
- **PIN: 0.** Esta ordem não arrancou o servidor, por isso não houve PIN nem `--pin=`. Não há nenhum valor de PIN em
  nenhum ficheiro.
- **As saídas cruas** (com os nomes inteiros, de propósito) ficaram em `tmp/` da ordem, fora do repo: a mutação, o
  canário limpo e os 11 registos tirados do histórico.
- **Listas da retoma:** corri `python retoma-i0004/actualizar-listas.py` depois da obra e deu «0 novos, 0 tirados».
  Nenhum ficheiro de `rascunhos/` mudou e nenhum SHA das listas mudou, por isso não houve nada a sincronizar.

## 5. CI da ponta

**CI da ponta `25fb4ea`** (a obra): **verde**.
- **Testes dos rascunhos**, run `45114122290`: os 10 jobs passaram (`servidor`, `validador-glb`, `motor-real`,
  `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`, `foto-mestre`, `retoma-pc`).
- **Sonda de privacidade**, run `45114122360`: verde.
- **Os números, no job `cliente`:**
  - o canário deu «26 de 26 verificações passaram»;
  - `rodar_testes` 321/321 (e 321/321 no `godot-cliente`);
  - `caixa_janela` 123/123;
  - `caixa_jogadora` 70/70;
  - a mutação das células deu «114 de 123», com as 9 falhas do assert B6, e o ficheiro ficou reposto.
- O `retoma-pc` está verde, o que confirma que as listas da retoma batem certo.
- **O remendo, contra a saída real do CI.** Tirei do log deste run a saída crua do canário em Linux (36 linhas, LF),
  só para `tmp/`. Passei-a pelos dois comandos do remendo: auto-teste 12/12, e o redigido ficou **igual byte a byte**
  ao registo da COBERTURA-CORRECOES-6 com `--ignorar-cr` (3464 bytes). O passo, aplicado, passa.

**CI da ponta `360d4df`** (a obra mais este ESTADO-FINAL): **verde**. Testes dos rascunhos, run `45114494823`, com os
10 jobs a passar, e Sonda de privacidade, run `45114494730`. Os números do job `cliente` são os mesmos: canário 26/26,
`rodar_testes` 321/321 (também no `godot-cliente`), `caixa_janela` 123/123, `caixa_jogadora` 70/70 e mutação das
células «114 de 123». O commit desta nota só acrescenta este parágrafo a este ficheiro.

## 6. Ficheiros

- `provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs`: a ferramenta.
- `provas/ordem-caixa-relato/README.md`: a secção da F51, com o uso.
- `provas/ordem-f51-mutacao/`: `README.md`, `correr-mutacao-canario.sh`, `teste-nomes-relato.mutacao.log`,
  `resumo.txt`, `mutacao.diff`, `reproduzir-redaccao-f25.sh`, `reproducao-f25.log` e `remendo-ci-testes.yml.patch`.

## 7. Pontos abertos para o coordenador

1. **A sentença da F25 não está neste PC.** Não há `~/workspace/conferencias/`. Os §§ que segui (§2, §3 e o ponto 5 do
   §7) são os do ESTADO-FINAL da F25 e batem com a ordem. Se a sentença numerar ou disser de outra forma, é preciso
   conferir.
2. **O remendo do CI está por aplicar.** A ordem pede que a ferramenta corra no CI, mas o token deste PC não tem a
   permissão `workflow`. Até o coordenador aplicar `provas/ordem-f51-mutacao/remendo-ci-testes.yml.patch` (ou dar um
   token com essa permissão), a ferramenta só corre à mão. O CI desta ponta ficou verde **sem** o passo novo. Também
   não procurei pôr a ferramenta num glob de testes de `rascunhos/`: seria uma suite do jogo a chamar uma prova, e isso
   não está na ordem.
3. **O CI imprime a saída crua do canário.** O passo do canário (`testes.yml:199`) faz `tee` da saída crua. Por isso,
   os logs do job `cliente`, que são públicos num repo público, mostram os nomes inteiros por desenho do canário. É
   assim desde que o canário entrou no CI (`91fcfc5`) e está fora desta ordem. Se se quiser fechar, o mesmo passo pode
   escrever a crua só no ficheiro e mostrar a versão redigida pela ferramenta. Isso é uma decisão do coordenador.
4. **O critério do «cortado na origem».** O §2 da F25 descreve os cortes, mas não diz a regra. A que usei é esta: um
   pedaço inicial do nome no fim da linha, numa fronteira de palavra, maior do que o nome público e sem acabar em
   espaço. Reproduz os 5 cortes da F25 e mais nada nos 11. Se aparecer um corte noutro sítio que não o fim da linha,
   esta regra não o apanha (a ferramenta continua a sair com 3 só para nomes inteiros).
