# ESTADO-FINAL — Ordem F66+F68 da sentença da F51 (a rede de segurança e o auto-teste do redigir-nomes)

**Coordenador:** CM-000009. **Executor:** Claude (opus, esforço médio), PC do cunhado. **Data:** 23/11/2026.
**Linha:** `fable/integracao-50`, trabalho directo, sem ramo e sem fusão.

**Partida.** Clonei a linha e o `HEAD` era `56a7fd1` (`56a7fd11ffcbc808b4ba7b55193b41d72ca20969`, a nota do CI da F64),
igual à origem. No `push` da obra a linha não tinha andado.

**Commits:**
1. `1c8dcdb`: a obra (a ferramenta, o guião da mutação, os dois README, o `resumo.txt` e o `reproducao-f25.log` novos);
2. este ESTADO-FINAL;
3. a nota do CI da ponta do commit 2, acrescentada ao §5 (só documento).

**A redacção do §2 da F25 não mudou.** As regras novas só procuram no texto já redigido e só mudam o código de saída. Os
11 registos limpos continuam a sair iguais byte a byte (§3). Não mexi em nenhum ficheiro do jogo nem no workflow. Não há
nenhum nome verdadeiro inteiro nem valor de PIN neste ficheiro (§6).

- **A sentença da F51 não está neste PC** (não há `~/workspace/conferencias/`). Trabalhei com o que a ordem diz dos
  buracos, que bate com o «Limite» que a F65 escreveu no README da ferramenta (ponto aberto 1).
- **Biblioteca (GameDev Kit):** a F51 e a F64 já viram as pastas de ferramentas da BIB, e o `ESTUDO-BIBLIOTECA.md` não tem
  nada para redigir ou conferir registos de texto. Segui o padrão da própria ferramenta.

## 1. F66 — a rede de segurança (a saída 3)
`provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs`, função nova `suspeitos()`. Corre sobre o texto redigido,
antes de escrever a saída e antes de comparar. A saída 3 passa a sair quando sobra qualquer uma de três coisas, e diz
só contagens e n.ºs de linha, nunca o texto:

| o que sobra | antes | agora |
|---|---|---|
| um nome inteiro | saída 3 | saída 3 (igual) |
| **buraco 1:** a variante de preposição fora da lista de 5 — o nome com a palavra da preposição substituída por outra palavra qualquer, ou com mais de um espaço à volta dela | rc=0, em silêncio | **saída 3**, «N variante(s) de preposição fora da lista (linhas …)» |
| **buraco 2:** o corte a meio da linha — um pedaço inicial do nome com a medida do corte na origem (maior do que o nome público, sem acabar em espaço, a começar numa fronteira de palavra), seguido de um carácter que não é letra | rc=0, em silêncio | **saída 3**, «N corte(s) a meio da linha (linhas …)» |

- A linha de resumo da ferramenta (no stderr) acaba agora em «sobram 0 nome(s) inteiro(s), 0 variante(s) de
  preposição fora da lista, 0 corte(s) a meio da linha». É só a cauda dessa linha que muda no `resumo.txt` e no
  `reproducao-f25.log`.
- **O corpus actual dá 0 casos, como a ordem diz:** nos 11 registos da F25, na saída nova do canário e na saída da
  mutação, as duas contagens novas dão 0.
- **Prova de ponta a ponta, pela linha de comandos.** Montei três saídas cruas em `tmp/`, fora do repo: a saída do
  canário mais uma linha com a variante do nome n.º 1 (a preposição substituída por «du»), mais uma linha com o corte
  mínimo do nome n.º 2 a meio da linha, e as duas juntas.

  | caso | ferramenta antiga (`56a7fd1`), só `--saida` | ferramenta nova |
  |---|---|---|
  | variante fora da lista | **rc=0** | **rc=3**, «1 variante(s) … (linhas 37)» |
  | corte a meio da linha | **rc=0** | **rc=3**, «1 corte(s) … (linhas 37)» |
  | as duas | — | **rc=3**, linhas 37 e 38 |

  Com rc=3, a ferramenta não escreve o redigido. Com `--comparar`, a antiga dava rc=1, mas só porque a linha a mais
  mudava a comparação.

## 2. F68 — o auto-teste e o guião
**O auto-teste: de 12 para 16 verificações, 16/16.**
- **A guarda dos 2 nomes.** Com menos de 2 nomes verdadeiros nas fichas, o auto-teste falha com 1 e diz que os outros
  casos não correram. Antes rebentava com um `TypeError` ao montar o 2.º caso. Provei-o com umas fichas de 1 nome só,
  em `tmp/`: a antiga dava `TypeError` e a nova dá «0 de 1» e rc=1. O próprio auto-teste também o verifica (caso 16).
- **Os casos novos:**

  | n.º | caso | o que afirma |
  |---|---|---|
  | 13 | **a variante do nome n.º 1** (a preposição substituída por «du», fora da lista) | a redacção deixa-a igual (o §2 não muda) e a rede conta 1 variante, na linha 1 → saída 3 |
  | 14 | **o corte mínimo do nome n.º 2** (o pedaço mais curto que a regra do §2 aceita) | a meio da linha, a redacção deixa-o e a rede conta 1 corte, na linha 2 → saída 3; no fim da linha, redige-se como «nome n.º 2 (cortado na origem)» |
  | 15 | a rede calada | não dispara no que a redacção deixa limpo: o nome público, o pedaço a meio de palavra e as formas já redigidas |
  | 16 | a guarda | com 1 só nome verdadeiro, o auto-teste sai com 1 sem rebentar |

- **Os casos têm dentes.** Corri 5 cópias mutadas da ferramenta, em `tmp/`, e todas fazem o auto-teste falhar (rc=1):

  | mutação | resultado |
  |---|---|
  | a rede não conta variantes | 15 de 16 |
  | a rede não conta cortes | 15 de 16 |
  | a saída 3 volta a ver só os nomes inteiros | 14 de 16 |
  | sem a guarda dos 2 nomes | 15 de 16 |
  | o corte a meio deixa de exigir a fronteira depois do pedaço | 15 de 16 |

**O guião da mutação** (`provas/ordem-f51-mutacao/correr-mutacao-canario.sh`):
- **`LC_ALL=C sort -u` em vez de `uniq`** na contagem das FALHA distintas. O `uniq` só junta as repetidas seguidas.
  Pus `LC_ALL=C` para a ordem das linhas sair igual em qualquer máquina. Com ele, as 3 FALHA saem ordenadas no
  `resumo.txt`, e por isso mudam de ordem em relação ao resumo da F51.
- **Afirma que o `mutacao.diff` tem exactamente uma linha mudada.** Tem de ter uma «-» igual à linha 59 tal como estava
  e uma «+» igual à mutação. Se não, o `resumo.txt` diz «NÃO» e o guião sai com 1. Pus o troço à prova contra diffs
  falsos:

  | diff | resultado |
  |---|---|
  | o verdadeiro | sim |
  | uma linha a mais posta | NÃO |
  | outra mutação na mesma linha | NÃO |
  | vazio | NÃO |

**A corrida nova do guião** (sobre `56a7fd1`): rc=1, 23 de 26, as 3 FALHA, 0 erros de script, ficheiro reposto,
«exactamente uma linha mudada: sim», «esperado: sim» e rc=0 do guião.
- **O log da mutação saiu igual byte a byte** ao da F51: o mesmo sha256 `4560e8ce…2747653`, e o ficheiro não mudou no
  commit. O `mutacao.diff` também não mudou.
- O `resumo.txt` mudou na data, na base, na linha nova do diff, na ordem das FALHA e na cauda da redacção.

## 3. Antes e depois

| prova | antes (`56a7fd1`) | depois (`1c8dcdb`) |
|---|---|---|
| auto-teste do `redigir-nomes` | 12/12 | **16/16** |
| os 11 registos limpos (`reproduzir-redaccao-f25.sh`) | 11 de 11 iguais byte a byte | **11 de 11 iguais byte a byte**, e todos com 0 variantes e 0 cortes |
| contagens da redacção nos 11 | 69 linhas, 188 ocorrências | iguais |
| a saída nova do canário, redigida, contra a COBERTURA-CORRECOES-6 (PC, CRLF, sem `--ignorar-cr`) | igual | **igual byte a byte** (3500 bytes), 0 / 0 / 0 |
| saída 3 com a variante fora da lista | rc=0 | **rc=3** |
| saída 3 com o corte a meio da linha | rc=0 | **rc=3** |
| auto-teste com 1 só nome | `TypeError` | **rc=1**, sem rebentar |
| guião da mutação | rc=1, 23 de 26, 3 FALHA (`uniq`) | igual, com `sort -u` e «diff de uma linha: sim» |

O `reproducao-f25.log` foi regenerado. Em relação ao da F51 só mudam a linha da base (`526ef0d` → `56a7fd1`) e a cauda
das 11 linhas «redigido:».

**As suites neste PC, sobre a obra** (Godot 4.7.2 Windows, os comandos do CI, depois de um `--import` no clone novo):

| suite | resultado | rc | `SCRIPT ERROR` / `Parse Error` / `Compile Error` |
|---|---|---|---|
| o canário (`teste_nomes_relato.gd`) | **26 de 26** | 0 | 0 |
| `rodar_testes` | **321 de 321** | 0 | 0 |
| `caixa_janela` | **123 de 123** | 0 | 0 |
| `caixa_jogadora` | **70 de 70** | 0 | 0 |
| mutação das células (`mutacao-celulas.sh`) | **114 de 123**, 9 falhas, todas do assert B6, «MUTACAO APANHADA» | 0 | 0 |

As saídas cruas ficaram em `tmp/suites/`, fora do repo, porque o canário imprime nomes inteiros de propósito. A obra não
mexe em nenhum ficheiro que as suites do Godot leiam.

## 4. O passo da F51 no CI
O passo «A saída do canário, redigida (§2 da F25), é igual byte a byte ao registo limpo» está no job `cliente` desde
`74f5fa9` (F65). Esta ordem não lhe mexe: o passo já chama `--auto-teste` e a comparação, e por isso corre a ferramenta
nova sem mudar o workflow. Um rc=3 da rede nova põe o passo vermelho. O token deste PC continua sem a permissão
`workflow`, e não foi preciso.

## 5. CI
**CI da ponta `1c8dcdb` (a obra): verde.**
- **Testes dos rascunhos**, run `45133218989`: passaram os 10 jobs (`servidor`, `validador-glb`, `motor-real`,
  `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`, `foto-mestre` e `retoma-pc`).
- **Sonda de privacidade**, run `45133218993`: verde.
- **O passo novo da F51 correu, com a ferramenta nova:**
  - «auto-teste do redigir-nomes: 16 de 16 verificações passaram.», com os 4 casos F66/F68 «ok»;
  - a saída do canário em Linux, redigida, deu «sobram 0 nome(s) inteiro(s), 0 variante(s) de preposição fora da
    lista, 0 corte(s) a meio da linha» e ficou «igual byte a byte ao redigido (3464 bytes, sem os CR)».
- **Os números do log do run:**
  - o canário deu «26 de 26»;
  - `rodar_testes` 321/321, também no `godot-cliente`;
  - `caixa_janela` 123/123;
  - `caixa_jogadora` 70/70;
  - a mutação das células deu «114 de 123» e «MUTACAO APANHADA: 9 falhas, todas do assert B6».
- No `retoma-pc` sai uma linha «PC DIFERENTE DO 9cbaca8». Já saía igual no run `45131224957` da F64, e o job passa.

**CI da ponta `3a4244b` (a obra mais este ESTADO-FINAL): verde.**
- Testes dos rascunhos, run `45133611443`: passaram os 10 jobs.
- Sonda de privacidade, run `45133611472`: verde.
- O passo da F51 correu outra vez: o auto-teste deu 16 de 16, e a saída do canário redigida ficou igual byte a byte
  (3464 bytes, sem os CR).
- Os números são os mesmos: canário 26/26, `rodar_testes` 321/321 (também no `godot-cliente`), `caixa_janela`
  123/123, `caixa_jogadora` 70/70 e mutação das células «114 de 123», «MUTACAO APANHADA».
- O commit desta nota só acrescenta este parágrafo a este ficheiro.

## 6. Privacidade re-derivada
Conferidor: `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`, nos dois critérios (alargado e `--velho`). A
coluna dos nomes inteiros é a contagem do `sobram()` da ferramenta, que procura o nome inteiro sem distinguir maiúsculas.

| ficheiro | alargado / antigo, na ponta `56a7fd1` | alargado / antigo, depois | nomes inteiros |
|---|---|---|---|
| `ferramentas/redigir-nomes.mjs` | 2 / 2 | **2 / 2** | 0 |
| `provas/ordem-caixa-relato/README.md` | 34 / 30 | **34 / 30** | 0 |
| `provas/ordem-f51-mutacao/README.md` | 0 / 0 | **0 / 0** | 0 |
| `correr-mutacao-canario.sh` | 0 / 0 | **0 / 0** | 0 |
| `reproducao-f25.log` | 0 / 0 | **0 / 0** | 0 |
| `resumo.txt` | 1 / 1 | **1 / 1** | 0 |
| este ESTADO-FINAL | — | **0 / 0** | 0 |

- **A obra não acrescenta nenhum achado.** Os que lá estão são os de antes, em palavras correntes e no texto antigo.
- No 1.º rascunho, o meu comentário da regra nova trazia uma palavra corrente que partilha 4 letras com um apelido. O
  conferidor apanhou-a, e troquei-a por «substituída» antes do commit.
- **Os casos novos montam-se em memória** a partir das fichas, como os 12 de antes, e nenhum nome vai para o código.
- **As saídas cruas e os casos de ponta a ponta** com nomes ficaram em `tmp/`, fora do repo.
- **Nomes verdadeiros inteiros: 0** em todos os ficheiros da obra e neste ESTADO-FINAL.
- **PIN: 0.** Esta ordem não arrancou o servidor, por isso não houve PIN nem `--pin=`. Não há nenhum número de 20
  algarismos (a forma do PIN) nos ficheiros mudados.
- **As listas da retoma:** `python retoma-i0004/actualizar-listas.py` deu «0 novos, 0 tirados» e não mudou nenhum
  ficheiro. As listas só cobrem `rascunhos/`, e nenhum ficheiro de `rascunhos/` mudou. Não houve nenhum SHA a
  sincronizar.

## 7. Pontos abertos para o coordenador
1. **A sentença da F51 não está neste PC.** Se ela definir os buracos de outra maneira (por exemplo, outra medida para
   o «corte a meio da linha»), é preciso conferir.
2. **Escolhi a saída 3, e não um aviso.** A ordem deixa as duas. A saída 3 põe o passo do CI vermelho, que é o que a
   rede quer. Um falso positivo, como o nome público seguido da preposição a meio de uma frase, também fica vermelho:
   falha alto, não em silêncio.
3. **A variante «fora da lista» é a substituição por uma palavra.** O nome sem a preposição («X Y» em vez de «X de Y»)
   não é apanhado. Acrescentá-lo é uma decisão da sentença. Ficou escrito como «Limite» no README da ferramenta.
4. **O corte a meio só cobre pedaços do início do nome**, com a mesma medida do corte na origem. Um pedaço que comece a
   meio do nome (por exemplo, só o apelido) não é apanhado, tal como no §2.
5. **A palavra «du» no caso 13 é escolha minha.** É uma preposição de outra língua, fora da lista de 5.
