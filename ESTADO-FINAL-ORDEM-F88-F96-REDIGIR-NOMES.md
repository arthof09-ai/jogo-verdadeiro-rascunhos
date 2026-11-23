# ESTADO-FINAL — Ordem F88–F96 da sentença da F66+F68 (os buracos restantes do redigir-nomes)

**Coordenador:** CM-000009 (Muse). **Executor:** Claude (opus, esforço médio), PC do cunhado. **Data:** 23/11/2026.
**Linha:** `fable/integracao-50`, trabalho directo, sem ramo e sem fusão.

**Partida.** Clonei a linha. O `HEAD` era `457c73d` (`457c73dcef2d3c50990ef04efcd670c51e1f8810`, a nota do CI da
F78+F79+F81+F82), igual à origem. No `push` da obra, a linha não tinha andado.

**A linha andou a seguir à obra.** Logo depois do meu `push` entrou `b571dff`, um commit da rede (F86), filho da
minha obra: os runs das duas pontas começaram às 08:48:10 e às 08:48:27 UTC. É a «Correcção de âmbito … (F86)» e só
mexe no `ESTADO-FINAL-ORDEM-F66-F68-REDIGIR-NOMES.md`:
- troca o âmbito da privacidade de «ficheiros cometidos» por «registos limpos e saídas do relato»;
- **e tira as duas erratas F90 e F92** que a minha obra tinha posto nesse ficheiro (pontos abertos 8 e 9).

Pus este ESTADO-FINAL por cima de `b571dff`, sem desfazer nada.

**Commits:**
1. `69d48ff`: a obra (a ferramenta, o guião da mutação, os dois README, as erratas no ESTADO-FINAL da F66+F68, e o
   `resumo.txt` e o `reproducao-f25.log` novos);
2. (`b571dff`, da rede, F86, não meu);
3. este ESTADO-FINAL;
4. a nota do CI da ponta do commit 3, acrescentada ao §5 (só documento).

**O jogo não mudou, nem a redacção do §2 da F25.** As regras novas só procuram no texto já redigido e só mudam o
código de saída. Os 11 registos limpos continuam a sair iguais byte a byte (§3). Não mexi em nenhum ficheiro do jogo
nem no workflow. Este ficheiro não tem nenhum nome verdadeiro inteiro nem nenhum valor de PIN (§6).

- **A sentença da F66+F68, a da F51 e a FILA não estão neste PC** (não há `~/workspace/`). Trabalhei com o que a ordem
  diz dos itens. **Não encontrei nenhuma decisão lavrada da F71 (F87)**: nem no PC, nem no repo. Por
  isso segui o ramo que a ordem prevê para esse caso. Fechei os 3 buracos J8–J10 e deixei os outros 2 como pontos
  abertos (§7), com casos «AINDA ABERTO» no auto-teste (F95).
- **Biblioteca (GameDev Kit):** o `ESTUDO-BIBLIOTECA.md` não tem nada para redigir ou conferir registos de texto. Segui
  o padrão da própria ferramenta.

## 1. Os itens, um a um, e a linha nova

| item | o que estava | a linha nova |
|---|---|---|
| **F88** «Limite» do README | «a rede não apanha o nome sem a preposição» | a rede apanha-o como corte **quando a 1.ª parte do nome chega sozinha ao mínimo do corte** (mais caracteres do que o nome público, e pelo menos 4). Com as fichas de agora, a 1.ª parte dos dois nomes é o próprio nome público, e por isso passa. Provei-o com fichas fictícias em `tmp/`: com a 1.ª parte maior do que o público, a rede deu 1 corte; com a 1.ª parte igual ao público, deu 0 |
| **F90** a frase dos 2 nomes | «com menos de 2 nomes verdadeiros, falha com 1» | **«Com 1 nome verdadeiro, falha com 1; com 0, sai com 2 antes do auto-teste»**, no README da ferramenta, no cabeçalho da ferramenta e em errata no §2 do ESTADO-FINAL da F66+F68 (essa errata saiu depois em `b571dff`, ponto aberto 8). Provei-o com fichas fictícias: com 0 nomes, rc=2 («nada a redigir»); com 1 nome, rc=1 («0 de 1») |
| **F91** o contador do diff | `grep -c '^-[^-]'` e `'^+[^+]'` | `^-` menos `^--- ` e `^+` menos `^\+\+\+ `, **e** tem de dar «1 1» no `git diff --numstat` (§2) |
| **F92** o relato do `sort -u` | «o `uniq` só junta as repetidas seguidas» | **neste corpus a troca é preventiva**: as duas cópias de uma FALHA saem seguidas, e o `uniq` também dá 3. Medi-o no log cometido: 6 linhas FALHA, 3 com o `uniq` e 3 com o `sort -u`. Está no README da F51, no comentário do guião e em errata no §2 do ESTADO-FINAL da F66+F68 (essa errata saiu depois em `b571dff`, ponto aberto 8) |
| **F93** a contagem dupla em `suspeitos()` | o nome inteiro contava como inteiro **e** como variante (antiga: 1 inteiro + 1 variante) | as duas coisas da ordem. **Excluí** o nome tal e qual e as 5 variantes da lista com um espaço só (nova: 1 inteiro + 0 variantes). **Escrevi** na função exportada «só chamar sobre o texto JÁ redigido». Também um corte que começa dentro de uma variante deixou de contar como corte, e duas preposições do mesmo nome já não contam a mesma ocorrência duas vezes |
| **F94** J8 — corte colado a uma letra | o pedaço do nome seguido logo de outra letra passava (rc=0) | conta como corte quando o pedaço tem **pelo menos 2 palavras inteiras do nome e acaba a meio de uma palavra do nome** (ponto aberto 3) |
| **F94** J9 — pontuação a seguir à palavra substituída | «X du, Y», «X d. Y» passavam (rc=0) | conta como variante: depois da palavra do meio pode vir pontuação (`\p{P}+`), com ou sem espaço |
| **F94** J10 — variante partida por quebra de linha | «…X» no fim de uma linha e «de Y…» ou «du Y…» na seguinte passavam (rc=0) | a variante procura-se no texto todo, e o espaço à volta da palavra do meio pode ser uma quebra de linha (LF ou CRLF). Conta como variante, na linha onde começa. Se o pedaço do fim da linha chegar ao mínimo, redige-se como corte na origem, como antes |
| **F95** casos «ainda abertos» | — | duas verificações **«F95 AINDA ABERTO»**: o nome sem a preposição, e um pedaço que começa a meio do nome («de Y» e só «Y»). Os dois casos passam enquanto o buraco está aberto. Quem o fechar tem de os virar para afirmarem a saída 3 |
| **F96** a dependência das fichas | não estava escrita | está escrita no README e no código, verificação a verificação (§2) |

**A linha de resumo da ferramenta (no stderr) não mudou de forma.** J9 e J10 contam como «variante(s) de preposição
fora da lista», e J8 conta como «corte(s) a meio da linha». Por isso o `reproducao-f25.log` só mudou na linha da base
(`56a7fd1` → `457c73d`).

**A prova de ponta a ponta, pela linha de comandos.** Montei três saídas cruas em `tmp/`, fora do repo: a saída do
canário (36 linhas, CRLF) mais um caso por buraco. Corri as duas ferramentas só com `--saida`:

| caso | ferramenta antiga (`457c73d`) | ferramenta nova |
|---|---|---|
| J8, corte colado a uma letra | **rc=0**, escreveu o redigido | **rc=3**, «1 corte(s) a meio da linha (linhas 37)», não escreveu |
| J9, «du,» | **rc=0**, escreveu o redigido | **rc=3**, «1 variante(s) … (linhas 37)», não escreveu |
| J10, partido por quebra de linha | **rc=0**, escreveu o redigido | **rc=3**, «1 variante(s) … (linhas 37)», não escreveu |

## 2. O auto-teste e o guião

**O auto-teste: de 16 para 22 verificações, 22/22.** As 16 de antes continuam iguais. Juntei frases à 15.ª (a rede
calada): o nome público seguido de uma palavra que começa pela letra da preposição, e a preposição colada a outra
letra. São as frases que o J8 não pode apanhar. As 6 novas:

| n.º | caso | o que afirma |
|---|---|---|
| 17 | **J8** | o pedaço do nome n.º 2 até à 1.ª letra da 3.ª palavra, colado a outra letra, não se redige. A rede conta 1 corte, na linha 2 → saída 3 |
| 18 | **J9** | o nome n.º 1 com «du,», «d.» e «du;» (este sem espaço): 1 variante por caso → saída 3 |
| 19 | **J10** | o nome n.º 1 partido antes da preposição (LF e CRLF) e a variante «du» partida depois dela: 1 variante, na linha onde começa → saída 3 |
| 20 | **F93** | o nome n.º 1 inteiro num texto cru conta só como inteiro; com 2 espaços, conta só como 1 variante |
| 21 | **F95 AINDA ABERTO** | o nome n.º 1 sem a preposição não dá suspeito |
| 22 | **F95 AINDA ABERTO** | um pedaço que começa a meio do nome n.º 1 não dá suspeito |

**Os casos têm dentes.** Fiz 6 cópias mutadas da ferramenta, em `tmp/`. Uma cópia desfaz uma só regra nova, e todas
fazem o auto-teste falhar (rc=1, 21 de 22):

| mutação | falha |
|---|---|
| sem a pontuação do J9 | a 18.ª |
| sem a quebra de linha do J10 | a 19.ª |
| sem o corte colado do J8 | a 17.ª |
| J8 largo de mais (sem as 2 palavras inteiras) | a 15.ª (a rede calada) |
| sem a exclusão do nome tal e qual (F93) | a 20.ª |
| sem o desconto do corte dentro de uma variante (F93) | a 18.ª («X d. Y» também contava como corte) |

**As dependências das fichas (F96), provadas.** Corri o auto-teste com fichas fictícias em `tmp/`:
- **com a mesma forma das verdadeiras** («X prep Y», com o público = X): 22 de 22;
- **com o nome n.º 1 sem preposição:** falham a 13.ª, a 15.ª e da 18.ª à 22.ª;
- **com o nome n.º 2 sem preposição:** falham a 5.ª e a 15.ª;
- **com o nome n.º 2 de 2 palavras:** falham a 5.ª, a 15.ª e a 17.ª.

A ordem falava dos «casos 13/14». Com isto vi que a 14.ª não depende do nome n.º 1: precisa de o nome n.º 2 ser maior
do que o mínimo do corte. Escrevi a dependência verdadeira, verificação a verificação.

**O guião da mutação** (`provas/ordem-f51-mutacao/correr-mutacao-canario.sh`). Pus o contador à prova contra diffs
falsos, em `tmp/diffs/`:

| diff | contador antigo | contador novo |
|---|---|---|
| o verdadeiro | sim | sim |
| uma linha a mais posta | NÃO | NÃO |
| outra mutação na mesma linha | NÃO | NÃO |
| vazio | NÃO | NÃO |
| **uma linha a mais tirada, só com «-»** | **sim** (errado) | NÃO |
| **uma linha a mais posta, só com «+»** | **sim** (errado) | NÃO |

**O caso que a fórmula da ordem não vê:** uma linha tirada cujo texto começa por «-- ». No diff fica «--- …», igual a
um cabeçalho, e a fórmula desconta-a. Montei-o num repo de rascunho em `tmp/`: a fórmula deu 1/1, mas o `numstat` deu
«1 2» → NÃO. Por isso o guião exige as duas.

**A corrida nova do guião** (sobre `457c73d`, com a ferramenta nova): rc=1, 23 de 26, as 3 FALHA, 0 erros de script,
ficheiro reposto, «1 linha(s) tirada(s), 1 posta(s) (git diff --numstat: 1 1) — exactamente uma linha mudada: sim»,
«esperado: sim» e rc=0 do guião.
- **O log da mutação saiu igual byte a byte** ao da F51 e da F66: o mesmo sha256 `4560e8ce…2747653`, e o ficheiro não
  mudou no commit. O `mutacao.diff` também não mudou.
- O `resumo.txt` mudou na data, na base e na linha do diff (que agora traz o `numstat`).
- Depois da corrida, só troquei palavras nos comentários do guião (§6). A lógica é a que correu.

## 3. Antes e depois

| prova | antes (`457c73d`) | depois (`69d48ff`) |
|---|---|---|
| auto-teste do `redigir-nomes` | 16/16 | **22/22** |
| os 11 registos limpos (`reproduzir-redaccao-f25.sh`) | 11 de 11 iguais byte a byte | **11 de 11 iguais byte a byte**. A saída do guião é igual à de antes, linha a linha, com as mesmas contagens e 0 / 0 / 0 nos 11 |
| contagens da redacção nos 11 | 69 linhas, 188 ocorrências | iguais |
| a saída nova do canário deste PC, redigida, contra a COBERTURA-CORRECOES-6 (CRLF, sem `--ignorar-cr`) | igual | **igual byte a byte** (3500 bytes), 0 / 0 / 0 |
| J8, J9 e J10 pela linha de comandos | rc=0 | **rc=3** |
| o nome inteiro em `suspeitos()` | 1 inteiro + 1 variante | **1 inteiro + 0 variantes** |
| fichas com 0 / 1 nome verdadeiro | rc=2 / rc=1 | igual (agora está bem escrito) |
| guião da mutação | 23 de 26, «uma linha: sim» | igual, também com o `numstat` «1 1» |

**As suites neste PC, sobre a obra** (Godot 4.7.2 Windows, com os comandos do CI, depois de um `--import` no clone
novo):

| suite | resultado | rc | `SCRIPT ERROR` / `Parse Error` / `Compile Error` |
|---|---|---|---|
| o canário (`teste_nomes_relato.gd`) | **26 de 26** | 0 | 0 |
| `rodar_testes` | **321 de 321** | 0 | 0 |
| `caixa_janela` | **123 de 123** | 0 | 0 |
| `caixa_jogadora` | **70 de 70** | 0 | 0 |
| mutação das células (`mutacao-celulas.sh`) | **114 de 123**, 9 falhas, todas do assert B6, «MUTACAO APANHADA» | 0 | 0 |

- O meu guião das suites chamou primeiro a mutação das células dentro de `rascunhos/cliente`, e ela parou porque o
  guião corre na raiz do repo. Voltei a corrê-la na raiz, como o CI faz.
- As saídas cruas ficaram em `tmp/suites/`, fora do repo, porque o canário imprime nomes inteiros de propósito.

## 4. O passo da F51 no CI
O passo está no job `cliente` desde `74f5fa9` (F65) e não lhe mexi. Já chama `--auto-teste` e a comparação, por isso
corre a ferramenta nova sem mudar o workflow.

## 5. CI
**CI da ponta `69d48ff` (a obra): verde.**
- **Testes dos rascunhos**, run `45141558696`: passaram os 10 jobs (`servidor`, `validador-glb`, `motor-real`,
  `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`, `foto-mestre` e `retoma-pc`).
- **Sonda de privacidade**, run `45141558584`: verde.
- **O passo da F51 correu, com a ferramenta nova:**
  - «auto-teste do redigir-nomes: 22 de 22 verificações passaram.»;
  - a saída do canário em Linux, redigida, deu «sobram 0 nome(s) inteiro(s), 0 variante(s) de preposição fora da
    lista, 0 corte(s) a meio da linha» e ficou «igual byte a byte ao redigido (3464 bytes, sem os CR)».
- **Os números do log do run:**
  - o canário deu «26 de 26»;
  - `rodar_testes` 321/321, também no `godot-cliente`;
  - `caixa_janela` 123/123;
  - `caixa_jogadora` 70/70;
  - a mutação das células deu «MUTACAO APANHADA: 9 falhas, todas do assert B6».
- No `retoma-pc` sai a linha «PC DIFERENTE DO 9cbaca8», como nos runs das ordens anteriores, e o job passa.

A ponta `b571dff` (da rede, F86) teve o seu próprio CI. Não o conto aqui, porque não é obra desta ordem.

## 6. Privacidade re-derivada
**Âmbito: os ficheiros que esta ordem cometeu** (os 7 da obra e este ESTADO-FINAL). A ordem pedia o âmbito escrito
como «ficheiros cometidos». Mas a rede (F86) corrigiu-o em `b571dff`: no repo inteiro, «ficheiros cometidos» é
falso à letra, e o âmbito certo é «registos limpos e saídas do relato». Por isso escrevo o âmbito restrito, que é
verdadeiro à letra. Os logs do CI ficam fora do repo e fora desta conta (ponto aberto 10).

**Medi o repo inteiro, para saber onde estão os nomes** (com o `sobram()`, só contagens e caminhos, nada escrito no
repo). Dos 2008 ficheiros cometidos na ponta `b571dff`, 22 trazem nomes inteiros, num total de 390 ocorrências.
- Os dois que `b571dff` cita: o ficheiro de teste do canário (45) e as fichas (2).
- 10 `relato.txt` de provas antigas: o da `ordem-caixa-janela` (28, o «relato antigo» que o canário usa de
  propósito), um com 2 e oito com 6.
- 6 ficheiros da `provas/ordem-autojogo` e mais 4 de outras provas: 2 README e 2 ferramentas `prova_caixa_*.gd`.

Nenhum destes é desta ordem. Ver o ponto aberto 11.

Usei o conferidor `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`, nos dois critérios (alargado e
`--velho`). A coluna dos nomes inteiros é a contagem do `sobram()` da ferramenta, que procura o nome inteiro sem
distinguir maiúsculas. A coluna do PIN conta os números de 20 algarismos, que é a forma do PIN.

| ficheiro | alargado / antigo, na ponta `457c73d` | alargado / antigo, depois | nomes inteiros | PIN |
|---|---|---|---|---|
| `ESTADO-FINAL-ORDEM-F66-F68-REDIGIR-NOMES.md` | 3 / 2 | **3 / 2** na obra (`69d48ff`); 4 / 4 depois de `b571dff`, que não é meu | 0 | 0 |
| `provas/ordem-caixa-relato/README.md` | 34 / 30 | **34 / 30** | 0 | 0 |
| `ferramentas/redigir-nomes.mjs` | 2 / 2 | **2 / 2** | 0 | 0 |
| `provas/ordem-f51-mutacao/README.md` | 0 / 0 | **0 / 0** | 0 | 0 |
| `correr-mutacao-canario.sh` | 0 / 0 | **0 / 0** | 0 | 0 |
| `reproducao-f25.log` | 0 / 0 | **0 / 0** | 0 | 0 |
| `resumo.txt` | 1 / 1 | **1 / 1** | 0 | 0 |
| este ESTADO-FINAL | — | **0 / 0** | 0 | 0 |

- **A obra não acrescenta nenhum achado.** Os que lá estão são os de antes, em palavras correntes e no texto antigo.
- No 1.º rascunho, o conferidor apanhou 16 linhas minhas nos ficheiros da obra e 6 neste ESTADO-FINAL. Nenhuma
  trazia um nome. Eram palavras correntes que partilham 4 ou mais letras seguidas com um nome. Para as encontrar sem imprimir pedaços dos nomes, tapei com «#» o que o
  conferidor apanhava. Troquei-as todas antes do commit, por formas equivalentes.
- **Os casos novos montam-se em memória** a partir das fichas, como os de antes. Nenhum nome vai para o código.
- **As saídas cruas e os casos de ponta a ponta** com nomes ficaram em `tmp/`, fora do repo.
- **As fichas fictícias** de `tmp/fichas/` só têm nomes inventados.
- **Nomes verdadeiros inteiros: 0** nos 7 ficheiros da obra e neste ESTADO-FINAL.
- **PIN: 0.** Esta ordem não arrancou o servidor, por isso não houve PIN nem `--pin=`.
- **O ponto aberto do log do CI continua (F85, ponto aberto 10).** Os logs do job `cliente` trazem nomes verdadeiros
  inteiros, porque o canário os imprime de propósito, e os logs dos runs públicos são legíveis por qualquer pessoa.
  Esta ordem não muda isso. A ferramenta não imprime nenhum nome, e os casos que juntei não acrescentam nenhum ao log.
  Fechar a impressão dos nomes no CI é decisão da F71.
- **As listas da retoma:** `python retoma-i0004/actualizar-listas.py` deu «0 novos, 0 tirados» e não mudou nenhum
  ficheiro. As listas só cobrem `rascunhos/`, e nenhum ficheiro de `rascunhos/` mudou. Não houve nenhum SHA a
  sincronizar.

## 7. Pontos abertos para o coordenador
1. **As sentenças e a FILA não estão neste PC.** Não encontrei nenhuma decisão lavrada da F71 (F87), por isso segui o
   ramo da ordem: fechei J8–J10 e deixei abertos os 2 que vêm a seguir. Se a sentença definir J8–J10 de outra maneira,
   é preciso conferir.
2. **O nome sem a preposição e o pedaço que começa a meio do nome continuam abertos.** A decisão é da F71 (F87). As
   verificações 21 e 22 do auto-teste marcam-nos como «AINDA ABERTO».
3. **A medida do J8 é escolha minha**: pelo menos 2 palavras inteiras do nome, e o corte a meio de uma palavra do nome.
   - **Porquê:** nos dois nomes, o nome público é a 1.ª palavra e a palavra seguinte é a preposição. Sem esta medida,
     «público + palavra começada por d» (como em «… diz») disparava a rede.
   - **O que fica de fora:** um corte colado com só uma palavra inteira, como «X d» + letra ou «X de» + letra.
   - **Um falso positivo possível:** outra pessoa com o mesmo nome e preposição e um apelido com a mesma 1.ª letra.
     Esse caso fica vermelho: falha alto, não em silêncio.
4. **O J9 só cobre a pontuação depois da palavra do meio**, como a ordem pede. A pontuação antes dela, como em
   «X, du Y», não é apanhada.
5. **O J10 pode, em teoria, ligar 3 linhas.** Basta uma linha que acabe no nome público, uma linha com uma só palavra e
   uma linha que comece pelo apelido. O corpus não tem nenhum caso destes (0 variantes nos 11 registos e no canário).
6. **A fórmula do F91 sozinha não chega** quando a linha tirada começa por «-- ». Por isso juntei o `numstat`. A ordem
   deixava escolher entre os dois, e eu usei os dois.
7. **A F93 tem um efeito num texto cru.** Uma das 5 variantes da lista não dá suspeito, porque a função conta com o
   texto redigido. Escrevi-o na função e no README. A ferramenta só a chama depois de redigir.
8. **`b571dff` tirou as erratas F90 e F92 do ESTADO-FINAL da F66+F68.** Esse commit da rede (F86) é filho da
   minha obra, mas o ficheiro que deixou não tem as duas erratas que a obra lá pôs. Parece ter sido escrito a partir de
   uma cópia anterior a `69d48ff`, mas não sei se foi de propósito, por isso não as voltei a pôr. As duas frases
   correctas continuam noutros sítios: no README da ferramenta (F90), no README da F51 e no comentário do guião (F92), e
   neste ESTADO-FINAL (§1). **Decisão do coordenador:** voltar a pôr as erratas, ou deixar como está.
9. **No ESTADO-FINAL da F66+F68 ficam, portanto, as frases antigas**: «com menos de 2 nomes verdadeiros … falha com 1»
   e o `sort -u` sem a palavra «preventiva».
10. **O ponto aberto do log do CI continua (F85).** Contei o log do run `45141558696` com o `sobram()`: traz 7 nomes
    verdadeiros inteiros, da saída crua do canário que o job `cliente` imprime, como nas ordens anteriores. O que a
    ferramenta imprime só tem contagens. Não guardei o log no repo.
11. **O âmbito da privacidade ainda não está fechado.** Nem «ficheiros cometidos» (a ordem) nem «registos limpos e
    saídas do relato» (a correcção de `b571dff`) é verdadeiro à letra para o repo inteiro: há 10 `relato.txt` com
    nomes inteiros (§6). É preciso decidir se esses relatos contam como «saídas do relato» e se se redigem, e isso não
    cabe nesta ordem.
