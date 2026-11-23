# ESTADO FINAL — ORDEM F25 (limpeza na ponta dos 11 ficheiros) · Claude conta 1, PC · 23/11/2026

A F25 da sentença da CAIXA-EXPANDE-INTERACAO: os 11 registos cometidos que guardavam nomes verdadeiros inteiros passam
à redacção «nome n.º 1» / «nome n.º 2» da DECISÃO O1. Só na ponta; o histórico publicado não foi reescrito (é a F26).

- **Linha:** trabalho directo em `fable/integracao-50`, sem ramo lateral nem fusão.
- **Base:** `94719e0` (o `HEAD` do clone à hora do lançamento). O `fetch` antes do commit trouxe `06e77c4` (a nota do
  CI de `94719e0`, que só mexe em `ESTADO-FINAL-ORDEM-CAIXA-EXPANDE-INTERACAO.md`). Fiz `rebase` sem conflitos:
  a obra assenta em `06e77c4`.
- **Commits:**
  - `081304e`: a limpeza dos 11 ficheiros (69 linhas substituídas; nenhum outro ficheiro);
  - o commit deste ESTADO-FINAL;
  - o commit da nota do CI (§4).
- **Numeração:** a do conferidor estrito e da O1, ou seja a ordem dos nomes verdadeiros nas fichas de teste do
  servidor. O n.º 1 tem 16 caracteres e o n.º 2 tem 15.
- **Biblioteca (GameDev Kit):** não há nela nada para redigir registos de texto. Usei um `str.replace` de Python
  (sem script cometido: a troca é de uma linha e fica descrita no §2).

## 1. Passo 1 — o que lê os 11 ficheiros

**Nenhum código e nenhuma suite lê os 11 registos cometidos.** Conferi com `git grep` sobre a árvore inteira (fora
dos `.md`) pelos caminhos e pelos nomes dos ficheiros:

- **O canário** (`provas/ordem-caixa-janela/ferramentas/teste_nomes_relato.gd`, corrido no CI em
  `.github/workflows/testes.yml:199`) não lê registo nenhum. Lê `nomes_relato.gd` e as fichas de teste do servidor,
  e o caso medido do §4 está congelado no próprio script (`RELATO_VELHO`, desde a NOMES-CORRECOES B2). Não lhe toquei.
- `provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd:26` cita `correcoes-3/mutacoes.log` **num comentário**
  (`##`). Não o lê.
- `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs:3` recebe o registo **por argumento**. Nenhum script
  e nenhum passo do CI o chama sobre estes 11.
- `retoma-i0004/actualizar-listas.py` só trata de `rascunhos/`. Os 11 estão em `provas/`.
- Os `actualizar-listas.log` de `cobertura-correcoes*/` mencionam os nomes dos ficheiros num `diff --stat` antigo.
  São registos, não código.
- **Documentos que os citam** (por caminho, sem ler o conteúdo): `provas/ordem-caixa-janela/README.md:43, 59, 71, 77, 92, 103, 117, 121, 135, 139, 162, 182, 186, 202, 229`, `provas/ordem-caixa-relato/README.md:181` e vários ESTADO-FINAL da raiz.

Como há documentos que os citam, **não apaguei nenhum** e redigi os 11.

## 2. Passo 2 — o que mudou, ficheiro a ficheiro

Regra: todo o nome verdadeiro inteiro, sem distinguir maiúsculas, passa a `nome n.º 1` ou `nome n.º 2`. A forma
toda em minúsculas (o caso «minúsculas» da CORRECOES-3) passa a `nome n.º 1 em minúsculas`. Nenhuma linha
foi acrescentada nem tirada, e os fins de linha ficaram como estavam. As referências de linha
dos documentos continuam certas.

| ficheiro (em `provas/`) | linhas | pares antes → depois | ocorrências antes → depois | linhas mudadas |
|---|---|---|---|---|
| `ordem-caixa-janela/nomes/teste-nomes-relato.log` | 23 | 5 → 0 | 8 → 0 | 4 |
| `ordem-caixa-janela/nomes-correcoes/teste-nomes-relato.log` | 23 | 5 → 0 | 7 → 0 | 4 |
| `ordem-caixa-janela/nomes-correcoes/mutacoes.log` | 19 | 3 → 0 | 3 → 0 | 3 |
| `ordem-caixa-janela/cobertura/teste-nomes-relato.log` | 29 | 5 → 0 | 7 → 0 | 4 |
| `ordem-caixa-janela/cobertura-correcoes/teste-nomes-relato.log` | 33 | 5 → 0 | 7 → 0 | 4 |
| `ordem-caixa-janela/cobertura-correcoes-2/teste-nomes-relato.log` | 35 | 5 → 0 | 7 → 0 | 4 |
| `ordem-caixa-janela/cobertura-correcoes-3/teste-nomes-relato.log` | 35 | 5 → 0 | 7 → 0 | 4 |
| `ordem-caixa-janela/cobertura-correcoes-4/teste-nomes-relato.log` | 36 | 5 → 0 | 7 → 0 | 4 |
| `ordem-caixa-janela/cobertura-correcoes-5/teste-nomes-relato.log` | 36 | 5 → 0 | 7 → 0 | 4 |
| `ordem-caixa-janela/cobertura-correcoes-6/teste-nomes-relato.log` | 36 | 5 → 0 | 7 → 0 | 4 |
| `ordem-caixa-relato/correcoes-3/mutacoes.log` | 182 | 42 → 0 | 121 → 0 | 30 |
| **total** | | **90 → 0** | **188 → 0** | **69** |

A contagem antes bate certo com a sentença (90 pares e 188 ocorrências). Só bate se não se distinguirem maiúsculas:
2 dos 42 pares e 5 das 121 ocorrências de `correcoes-3/mutacoes.log` estão em minúsculas. «Pares em minúsculas» quer dizer pares cujas ocorrências na linha são todas minúsculas: são os das l. 47 e 130. As 5 ocorrências em minúsculas estão nas l. 47, 130, 140, 142 e 144 — as três últimas linhas trazem também a forma com maiúsculas.

**Além dos 90, redigi duas formas que não são nomes inteiros mas ficam quase iguais a eles:**
- **Nomes cortados na origem.** Em `correcoes-3/mutacoes.log`, as linhas 17, 100 e 134 acabam no nome n.º 2 cortado
  pela truncagem da linha (um pedaço de 14 dos 15 caracteres). As linhas 101 e 135 acabam no início do nome n.º 1.
  Os 5 passam a `nome n.º 2 (cortado na origem)` e `nome n.º 1 (cortado na origem)`.
- **O canário mudado.** Em `nomes-correcoes/mutacoes.log:6` estava o nome n.º 2 com a preposição mudada. Passa a
  `«nome n.º 2 com a preposição mudada»`. É a descrição que a O1 usou na NOMES-CORRECOES (com «mudada» no lugar do adjectivo da O1, que partilha quatro letras com um nome e faria disparar o conferidor estrito).

**Igualdades que se mantêm:** os registos de `cobertura-correcoes-4`, `-5` e `-6` eram iguais byte a byte e
continuam a ser (blob `17ccd06ac2e6`). A frase «igual byte a byte» do `README.md:229` continua certa entre eles.
Nenhum documento do repo cita os blobs antigos dos 11. **Uma coisa mudou:** estes 11 registos já não são a saída
crua do Godot. A saída crua do canário traz os nomes inteiros de propósito (§3).

## 3. Passo 3 — o canário continua a disparar

Corri o canário na ponta limpa, com Godot 4.7.2 Windows (`_console.exe`), da mesma forma que o CI:
`godot --headless --path rascunhos/cliente -s <raiz>/provas/ordem-caixa-janela/ferramentas/teste_nomes_relato.gd`.

- **rc=0, 26 de 26 verificações**, sem `SCRIPT ERROR`, `Parse Error` nem `Compile Error`.
- **A saída é a mesma de antes.** Redigi uma cópia da saída nova com a mesma regra, fora do repo. As linhas
  `ok`/`FALHA` e a linha do total ficam iguais às de `cobertura-correcoes-6/teste-nomes-relato.log`.
- **Os nomes continuam lá de propósito.** A saída crua continua a imprimir 5 pares (7 ocorrências) de nomes
  verdadeiros inteiros, como o desenho manda. **Essa saída ficou fora do repo, na pasta `tmp/` da ordem, e não foi
  cometida.**
- **A mutação prova que dispara.** Pus `false and` na condição de `no_relato()` em `nomes_relato.gd:59`, só na cópia
  de trabalho. O canário deu **rc=1 e 23 de 26**, com 3 FALHA: as duas do §3 (a linha 5 suja e o nome dentro de
  JSON) e a do §4 (os 22 achados do caso medido). Reposto com `git checkout`, e o `git status` voltou aos 11
  ficheiros da obra.

As outras suites (servidor, protocolo, `rodar_testes`, `caixa_janela`, `caixa_jogadora`, provas do mapa, retoma-pc)
não lêem estes registos. O CI do §4 confirma-as.

## 4. CI da ponta

**CI da ponta `dd16afe`** (a obra mais este ESTADO-FINAL): **verde**.
- **Testes dos rascunhos**, run `45105083910`: os 10 jobs passaram (`servidor`, `validador-glb`, `motor-real`,
  `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`, `foto-mestre`, `retoma-pc`).
- **Sonda de privacidade**, run `45105083935`: verde.
- **No job `cliente`**, o passo do canário deu «26 de 26 verificações passaram», o mesmo que cá. As suites
  continuam com os números de antes: `rodar_testes` 321/321, `caixa_janela` 123/123 e `caixa_jogadora` 58/58.
- O `retoma-pc` está verde, o que confirma que as listas da retoma batem certo.

Este commit só acrescenta texto a este ficheiro.

**CI da ponta `9fe4ce2` (F50, emendas da conferência), já na linha** (Testes 45112901995 + Sonda 45112902028): **10/10 jobs verdes e a Sonda verde** — a condição da fusão da F25 está cumprida.

## 5. Privacidade re-derivada

- **Os 11 ficheiros:** 0 pares e 0 ocorrências de nomes verdadeiros inteiros, sem distinguir maiúsculas.
- **Pelo critério estrito** (`conferir-registo.mjs`, pedaços de 4 ou mais letras), os achados baixaram em todos:

  | ficheiro | antes → depois |
  |---|---|
  | `nomes/teste-nomes-relato.log` | 14 → 6 |
  | `nomes-correcoes/teste-nomes-relato.log` | 15 → 8 |
  | `nomes-correcoes/mutacoes.log` | 6 → 1 |
  | `cobertura/teste-nomes-relato.log` | 19 → 12 |
  | `cobertura-correcoes/teste-nomes-relato.log` | 21 → 14 |
  | `cobertura-correcoes-2` a `-6` (por ficheiro) | 23 → 16 |
  | `correcoes-3/mutacoes.log` | 64 → 4 |

  **Os achados que sobram não são nomes nem pedaços de nomes.** Separei-os um a um, fora do repo. São palavras
  correntes que partilham letras com os nomes: a palavra que dá nome às fichas de teste (sozinha, com a preposição,
  ou no fim de outra palavra), uma palavra de quatro letras que quer dizer «cada», e o início do adjectivo que os registos usam para as ocorrências não filtradas. Também
  aparecem os dois nomes públicos das criaturas, que o canário mostra de propósito. O maior pedaço que sobra tem 12
  caracteres, e todos estão nessas palavras. Não sobra nenhum nome inteiro, nem nenhum início de nome que passe do
  nome público. Ver o ponto 4 do §7.
- **Este ESTADO-FINAL:** 0 nomes inteiros e 0 achados nos dois critérios do conferidor (alargado e `--velho`).
- **PIN:** esta ordem não arrancou o servidor, por isso não houve PIN. Não há nenhum valor de PIN em nenhum
  ficheiro.
- **Listas da retoma:** corri `python retoma-i0004/actualizar-listas.py` depois da obra: «0 novos, 0 tirados». O
  `antes.txt`, o `depois.txt` e o `MANIFESTO-SHA256.txt` ficaram iguais, porque nenhum ficheiro de `rascunhos/`
  mudou.

## 6. Histórico

**Não reescrevi o histórico.** Os 11 ficheiros com os nomes inteiros continuam nos commits publicados até `06e77c4`.
Apagá-los dali seria reescrever a história de um repo público, e isso depende da palavra do Mestre (F26).

## 7. Pontos abertos para o coordenador

1. **«Pedaços» e a O1.** A ordem pede pedaços, mas também pede o mesmo tratamento da DECISÃO O1, e a O1 usou a
   redacção «n.º». Segui a O1. Cortar o nome em pedaços literais (por exemplo, o início do nome) faria disparar o
   conferidor estrito, por isso não o fiz. Se o coordenador quiser pedaços literais, é outra ordem.
2. **A heroína do cenário N-B3** (`correcoes-3/mutacoes.log`, l. 55–68 e 149 em diante). Neste cenário, a heroína
   entra de propósito com nome diferente do nome público. Nas fichas de teste, porém, o nome dela é público por
   inteiro. Por isso não conta como nome verdadeiro, nem para a sentença (fora dos 90), nem para o conferidor.
   Deixei-o como estava. Se o coordenador o quiser tratar como verdadeiro no contexto do cenário, são mais 10 linhas (22 ocorrências)
   neste ficheiro.
3. **Fora dos 11 ainda há nomes verdadeiros inteiros na ponta.** Contei-os na árvore inteira, só por números, sem
   distinguir maiúsculas: **251 pares em 22 ficheiros** (a lista itemizada abaixo nomeia 23 ficheiros, incluindo `rascunhos/servidor/autojogo/cenario-bancada.json`, com 0 pares; 22 é o número de ficheiros com pares). Destes, três são por desenho: as fichas
   (`rascunhos/servidor/autojogo/`, 2), o canário (`teste_nomes_relato.gd`, 34, com o `RELATO_VELHO` congelado) e
   o `relato.txt` da CAIXA-JANELA (22, o caso medido). Os outros: `provas/ordem-autojogo/` (`s1.jsonl` 29,
   `s1.repeticao.jsonl` 29, `s2.jsonl` 42, `s3.jsonl` 30, `resumo.json` 2, `resumo.md` 2), oito `relato.txt` de
   provas da caixa (6 por ficheiro) — `ordem-caixa-hud-jogadora/cliente/relato.txt`, `ordem-caixa-manequim/cliente/relato.txt`, `ordem-caixa-padrao-busto/cliente/relato.txt`, `ordem-caixa-relato/cliente-hud/relato.txt`, `ordem-caixa-relato/cliente-manequim/relato.txt`, `ordem-caixa-relato/correcoes/cliente-hud/relato.txt`, `ordem-caixa-relato/correcoes/cliente-manequim/relato.txt` e `ordem-caixa-teste-estetica/cliente/relato.txt` — `provas/ordem-caixa/cliente/relato.txt` (2), `provas/ordem-caixa-janela/README.md` (3),
   `provas/ordem-caixa-hud-jogadora/README.md` (2) e as ferramentas `prova_caixa_jogadora.gd` e
   `prova_caixa_manequim.gd` (2 por ficheiro). Os 90 eram mesmo um piso. Não lhes toquei, porque estão fora do território
   desta ordem.
4. **O critério estrito** continua a achar palavras correntes nos 11 ficheiros (§5). Para chegar a zero por esse
   critério, seria preciso redigir também essas palavras e os nomes públicos, o que estragaria os registos. A
   ordem pede «nunca um nome inteiro», e esse critério está cumprido.
5. **Os 11 já não são saída crua.** Quem voltar a correr o canário e comparar byte a byte com estes registos vai
   achar diferenças nas linhas redigidas (4 por registo do canário). Para comparar, aplica-se primeiro a mesma redacção à saída
   nova (§3).
