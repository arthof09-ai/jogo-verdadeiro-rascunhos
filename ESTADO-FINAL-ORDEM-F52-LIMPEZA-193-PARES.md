# ESTADO FINAL — ORDEM F52 (limpeza dos 193 pares fora do território da F25) · Claude conta 2, PC · 23/11/2026

A F52 da sentença da F25 (§7.3 do `ESTADO-FINAL-ORDEM-F25-LIMPEZA-11-FICHEIROS.md`). Os 193 pares (linha, nome) de
nomes verdadeiros inteiros que sobravam na ponta, em 19 ficheiros de `provas/` que a F25 não tocou, passam à redacção
«nome n.º 1» / «nome n.º 2» da DECISÃO O1, com o mesmo tratamento do §2 da F25. Os 57 pares por desenho ficam como estavam. O histórico publicado não foi reescrito (é a F26).

- **Linha:** trabalho directo em `fable/integracao-50`, sem ramo lateral nem fusão.
- **Base:** `681a9e9` (a nota do CI da F116, o `HEAD` do clone à hora do lançamento). O `fetch` antes do push não
  trouxe nada novo: a obra assenta em `681a9e9`.
- **Commits:**
  - `5a906cf`: a limpeza dos 19 ficheiros (181 linhas substituídas; nenhum outro ficheiro);
  - o commit deste ESTADO-FINAL;
  - o commit da nota do CI (§4).
- **Numeração:** a da O1 e do conferidor (a ordem dos nomes verdadeiros nas fichas de teste do servidor).
- **Biblioteca (GameDev Kit):** não tem nada para redigir registos de texto. Não escrevi ferramenta nova: usei a
  `provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs` da F51, que aplica a redacção do §2 da F25 (§2 abaixo).
- **Fonte da ordem:** a sentença da F25 não está neste PC (`~/workspace` não existe). Usei a lista da ordem, que é a
  do §7.3 da F25 com a correcção F111 dos caminhos das ferramentas.

## 1. Passo 1 — o que lê os 19 ficheiros

Conferi com `git grep` sobre a árvore inteira (fora dos `.md`), pelos caminhos e pelos nomes dos ficheiros
(`ordem-autojogo`, `s1.jsonl`, `s1.repeticao`, `s2.jsonl`, `s3.jsonl`, `resumo.json`, `resumo.md`, `relato.txt`,
`prova_caixa_jogadora`, `prova_caixa_manequim` e os dois READMEs), e pelo sha256 e pelo blob dos 19.
**Nenhum código e nenhum passo do CI lê os registos cometidos.** Por isso não parei em nenhum ficheiro.

- **`.jsonl` e `resumo.*` do autojogo.** `rascunhos/ferramentas/correr-autojogo.sh:61` **escreve** `resumo.md` e
  `resumo.json` numa pasta de saída dada por argumento; não lê os cometidos. `resumo.json:70, 78, 86` cita os
  `.jsonl` pelo nome (é um registo). o `.log` dos lançadores externos da `b7-correcoes-6` (l. 20) e `b7-correcoes-7/corridas.log:14`
  dizem que uma corrida deu «= `s1.jsonl` linha a linha»: são registos, não código (ver §7, ponto 4).
- **Os `relato.txt`.** As provas `prova_caixa_*.gd` (`:75`, `:82`, `:76`, `:69`, `:51` e as outras) **escrevem**
  `relato.txt` na pasta `--saida`. `correr-mutacoes.sh:125` lê o `relato.txt` de uma corrida nova em `$T`, não os
  cometidos. `teste_relato_caixa.gd:29` cita um relato num comentário (`##`). O canário não lê nenhum relato: o caso
  medido está congelado no próprio script (`RELATO_VELHO`).
- **As duas ferramentas `.gd`** são código, corrido por `correr-prova-caixa-hud.sh:22`,
  `correr-prova-caixa-manequim.sh:23`, `correr-prova-caixa-relato.sh:59-60`, `correr-mutacoes.sh` e
  `mutacoes.mjs:20-21`. **Os nomes estavam só em dois comentários por ferramenta** (l. 359 e 385 da jogadora, l. 447 e
  473 do manequim; a forma em minúsculas). Nenhuma das substituições textuais de `mutacoes.mjs` procura essas linhas
  (conferi os `de:` todos). O código não muda.
- **Os dois READMEs:** só o README da CAIXA-JANELA é citado (4 `actualizar-listas.log` antigos — cobertura-correções-2/4/5/6 — num `diff --stat`); o README da HUD-JOGADORA não é citado em nenhum ficheiro fora dos `.md`.
- **Hashes:** nenhum ficheiro do repo cita o sha256 (12 caracteres) nem o blob (10) de nenhum dos 19.
- **O CI** (`.github/workflows/testes.yml`) não cita nenhum dos 19.
- `retoma-i0004/actualizar-listas.py` só trata de `rascunhos/`. Os 19 estão em `provas/`.

## 2. Passo 2 — o que mudou, ficheiro a ficheiro

Regra (a do §2 da F25, que a `redigir-nomes.mjs` aplica): todo o nome verdadeiro inteiro, sem distinguir
maiúsculas, passa a `nome n.º 1` ou `nome n.º 2`. A forma toda em minúsculas passa a `nome n.º N em minúsculas`.
Também estavam previstos o corte na origem e o canário mudado, mas nenhum dos 19 os tem como caso próprio; a forma sem a preposição (F97) também não aparece. (Ressalva: o fim da l. 61 do README da CAIXA-JANELA é um corte pela definição da ferramenta — pedaço inicial do nome maior do que o nome público — mas é o nome inteiro partido pela quebra de linha, não truncagem; ver o caso partido abaixo.) **Nenhuma linha foi acrescentada nem tirada**, os fins de linha ficaram como estavam (todos
LF; o `git diff` não tem nenhum CR) e as referências de linha dos documentos continuam certas.

| ficheiro (em `provas/`) | linhas | pares antes → depois | ocorrências antes → depois | linhas mudadas |
|---|---|---|---|---|
| `ordem-autojogo/s1.jsonl` | 109 | 29 → 0 | 56 → 0 | 28 |
| `ordem-autojogo/s1.repeticao.jsonl` | 109 | 29 → 0 | 56 → 0 | 28 |
| `ordem-autojogo/s2.jsonl` | 158 | 42 → 0 | 82 → 0 | 41 |
| `ordem-autojogo/s3.jsonl` | 114 | 30 → 0 | 58 → 0 | 29 |
| `ordem-autojogo/resumo.json` | 93 | 2 → 0 | 2 → 0 | 2 |
| `ordem-autojogo/resumo.md` | 18 | 2 → 0 | 2 → 0 | 2 |
| `ordem-caixa-hud-jogadora/cliente/relato.txt` | 61 | 6 → 0 | 6 → 0 | 5 |
| `ordem-caixa-manequim/cliente/relato.txt` | 71 | 6 → 0 | 6 → 0 | 5 |
| `ordem-caixa-padrao-busto/cliente/relato.txt` | 131 | 6 → 0 | 6 → 0 | 5 |
| `ordem-caixa-relato/cliente-hud/relato.txt` | 63 | 6 → 0 | 6 → 0 | 5 |
| `ordem-caixa-relato/cliente-manequim/relato.txt` | 73 | 6 → 0 | 6 → 0 | 5 |
| `ordem-caixa-relato/correcoes/cliente-hud/relato.txt` | 64 | 6 → 0 | 6 → 0 | 5 |
| `ordem-caixa-relato/correcoes/cliente-manequim/relato.txt` | 74 | 6 → 0 | 6 → 0 | 5 |
| `ordem-caixa-teste-estetica/cliente/relato.txt` | 87 | 6 → 0 | 6 → 0 | 5 |
| `ordem-caixa/cliente/relato.txt` | 40 | 2 → 0 | 2 → 0 | 2 |
| `ordem-caixa-janela/README.md` | 234 | 3 → 0 | 3 → 0 | 4 |
| `ordem-caixa-hud-jogadora/README.md` | 33 | 2 → 0 | 2 → 0 | 1 |
| `ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd` | 560 | 2 → 0 | 2 → 0 | 2 |
| `ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd` | 656 | 2 → 0 | 2 → 0 | 2 |
| **total** | | **193 → 0** | **315 → 0** | **181** |

A contagem antes bate certo com o §7.3 da F25, ficheiro a ficheiro (193 pares). Contei sem distinguir maiúsculas; as
4 ocorrências em minúsculas são as das duas `.gd`. Em todos os 8 `relato.txt` há uma linha com os dois nomes, por isso 6
pares dão 5 linhas.

**Igualdades que se mantêm:** `s1.jsonl` e `s1.repeticao.jsonl` eram iguais byte a byte e continuam a ser. Os quatro
`.jsonl` continuam JSON válido linha a linha e o `resumo.json` continua JSON válido.

**Dois casos tratados à mão (com as funções da própria ferramenta):**
- **O nome partido pela quebra de linha do README da CAIXA-JANELA (l. 61–62).** Além dos 3 pares, o nome n.º 2 está
  inteiro mas partido pela quebra de linha do markdown: as duas primeiras palavras no fim da l. 61, a última no início
  da l. 62. A ferramenta trata o fim da l. 61 como «cortado na origem», o que aqui seria falso: não é truncagem, é o
  nome inteiro. Apliquei a regra 1: a l. 61 acaba em «nome n.º 2, sem fechar a aspa — o » fecha a citação na l. 62, depois de «linha 7» — e a última palavra do nome sai do início da l. 62 (fica «na linha 7»). Por isso este README tem 4 linhas mudadas para 3 pares. Ver §7, ponto 1.
- **Os 8 `relato.txt` de 6 pares.** A ferramenta redige-os, mas sai com 3 e não escreve a saída. A rede da F97 dá
  «1 nome sem a preposição» em todos eles (l. 39, 45, 72, 39, 45, 39, 45 e 53). Fui ver: é um **falso positivo**. A
  linha acaba no **nome público** n.º 1 e a seguinte começa pela etiqueta da linha, que é a última palavra do nome; o
  padrão `\s+` da rede atravessa a quebra de linha. Não é um nome e não se redige. Apliquei a mesma `redigir()` que a
  ferramenta exporta, sem o portão da saída 3, e escrevi o resultado. Ver §7, ponto 2.

## 3. Passo 3 — nada se partiu

No PC, com Godot 4.7.2 Windows, da mesma forma que o CI (`--headless --path rascunhos/cliente -s <raiz>/…`):

- **O canário** (`teste_nomes_relato.gd`): **rc=0, 26 de 26**, sem `SCRIPT ERROR`, `Parse Error` nem `Compile Error`.
- **A saída do canário redigida** (`redigir-nomes.mjs --ignorar-cr --comparar=…/cobertura-correcoes-6/teste-nomes-relato.log`):
  igual byte a byte ao registo limpo (3437 bytes, sem os CR). O auto-teste do `redigir-nomes.mjs` dá 29 de 29.
- **O relato da caixa** (`teste_relato_caixa.gd`): rc=0, 31 de 31.
- A saída crua ficou na pasta `tmp/` da ordem, fora do repo.

As suites do CI estão no §4.

## 4. CI da ponta

**CI da ponta `5a906cf` (a obra): verde.**
- **Testes dos rascunhos**, run `45183219926`: os 10 jobs passaram (`servidor`, `validador-glb`, `motor-real`,
  `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`, `foto-mestre`, `retoma-pc`).
- **Sonda de privacidade**, run `45183219813`: verde.
- **No job `cliente`:** o canário dá 26 de 26. As suites ficam com os números de antes: `rodar_testes` 321/321,
  `caixa_janela` 123/123, a caixa no HUD da jogadora 70/70 e a mutação das células 114/123 (as 9 falhas da B6). O
  passo da F51 dá o auto-teste 29/29 e «igual byte a byte ao redigido (3437 bytes, sem os CR)». O `godot-cliente`
  também dá `rodar_testes` 321/321.
- O `retoma-pc` está verde, o que confirma que as listas da retoma batem certo.

**CI da ponta `697f90c` (a obra mais este ESTADO-FINAL): verde.** Testes, run `45183545241`: 10/10 jobs. Sonda, run
`45183545355`: verde. No job `cliente`, os mesmos números: 26/26, 321/321, 123/123, 70/70, mutação 114/123,
auto-teste 29/29, igual byte a byte.

**Logs do CI:** 0 pares de nomes verdadeiros inteiros nos logs dos jobs `cliente` (das duas pontas) e
`godot-cliente` (de `5a906cf`).

Este commit só acrescenta texto a este ficheiro.

## 5. Privacidade re-derivada

- **Os 19 ficheiros:** 0 pares e 0 ocorrências de nomes verdadeiros inteiros, sem distinguir maiúsculas. A rede da
  `redigir-nomes.mjs` dá 0 inteiros, 0 variantes de preposição fora da lista e 0 cortes a meio da linha em todos. A
  única coisa que acusa é o falso positivo dos 8 relatos (§2).
- **Os dois critérios do conferidor** (`conferir-registo.mjs`, alargado e `--velho`): os achados do nome inteiro
  passam de 193 a 0 nos dois. Ficheiro a ficheiro, nos dois critérios: autojogo 29, 29, 42, 30, 2, 2 → 0; os 8
  relatos 6 → 0; `ordem-caixa/cliente/relato.txt` 2 → 0; READMEs 3 e 2 → 0; ferramentas 2 e 2 → 0.
- **O critério estrito** (todos os achados, pedaços de 4 ou mais letras) baixou em quase todos, como na F25. Não
  precisa de ir a zero:

  | ficheiro (em `provas/`) | alargado antes → depois | `--velho` antes → depois |
  |---|---|---|
  | `ordem-autojogo/s1.jsonl` e `s1.repeticao.jsonl` (por ficheiro) | 116 → 104 | 116 → 104 |
  | `ordem-autojogo/s2.jsonl` | 166 → 146 | 166 → 146 |
  | `ordem-autojogo/s3.jsonl` | 120 → 108 | 120 → 108 |
  | `ordem-autojogo/resumo.json` | 12 → 8 | 12 → 8 |
  | `ordem-autojogo/resumo.md` | 6 → 2 | 6 → 2 |
  | `ordem-caixa-hud-jogadora`, `relato/cliente-hud`, `relato/correcoes/cliente-hud` (por ficheiro) | 48 → 46 | 48 → 46 |
  | `ordem-caixa-manequim`, `relato/cliente-manequim`, `relato/correcoes/cliente-manequim`, `teste-estetica` (por ficheiro) | 46 → 44 | 46 → 44 |
  | `ordem-caixa-padrao-busto/cliente/relato.txt` | 67 → 65 | 67 → 65 |
  | `ordem-caixa/cliente/relato.txt` | 18 → 18 | 18 → 18 |
  | `ordem-caixa-janela/README.md` | 42 → 39 | 42 → 39 |
  | `ordem-caixa-hud-jogadora/README.md` | 11 → 11 | 11 → 11 |
  | `prova_caixa_jogadora.gd` | 64 → 60 | 62 → 58 |
  | `prova_caixa_manequim.gd` | 63 → 59 | 61 → 57 |

  **O que sobra não são nomes nem inícios de nomes.** O maior pedaço que sobra tem 11 caracteres: a preposição mais a
  palavra das fichas, que é palavra corrente nestes registos (as etiquetas das linhas, os ids das armas, «criaturas
  de …»). O resto são pedaços dessa palavra e os nomes públicos. A rede de cortes dá 0: não sobra nenhum início de
  nome maior do que o nome público.
- **Este ESTADO-FINAL:** 0 nomes inteiros e 0 achados nos dois critérios do conferidor.
- **PIN:** esta ordem não arrancou o servidor, por isso não houve PIN. Não há nenhum valor de PIN em nenhum ficheiro.
- **Listas da retoma:** `python retoma-i0004/actualizar-listas.py` depois da obra: «0 novos, 0 tirados». Nenhum
  ficheiro de `rascunhos/` mudou, por isso nenhum SHA das listas mudou e não houve nada a sincronizar.

## 6. Os 57 por desenho e a árvore inteira

Não toquei em nenhum dos ficheiros por desenho. Contagem na ponta nova, na árvore inteira, sem distinguir maiúsculas:
**57 pares em 3 ficheiros**, todos por desenho: as fichas (`rascunhos/servidor/autojogo/`, 2), o
canário (`teste_nomes_relato.gd`, **33**) e o `relato.txt` da CAIXA-JANELA (22). O ficheiro do cenário, na mesma pasta, tem 0.
Antes da obra a árvore tinha 250 = 193 + 57. **O canário tem 33 pares, não 34** como diz o §7.3 da F25 (ver §7,
ponto 3).

## 7. Pontos abertos para o coordenador

1. **O nome partido pela quebra de linha no README da CAIXA-JANELA (l. 61–62).** Tratei-o como nome inteiro
   («nome n.º 2», e a última palavra sai da l. 62), e não como «cortado na origem», que é o que a ferramenta faria.
   Não está na lista dos 193, porque a contagem por linha não o vê. Se o coordenador preferir a forma da ferramenta,
   é uma linha a mudar.
2. **A rede da F97 dá um falso positivo nos 8 relatos.** O padrão do nome sem a preposição (`1.ª parte \s+ última
   parte`) atravessa a quebra de linha. Um relato onde uma linha acaba no nome público e a seguinte começa pela
   etiqueta (a última palavra do nome) faz a ferramenta sair com 3 e não escrever a saída. Não mudei a ferramenta,
   porque está fora do território desta ordem. Se a rede deve barrar a quebra de linha nesse padrão (como a F114 fez
   no padrão das variantes), é outra ordem.
3. **O canário tem 33 pares, não 34.** O §7.3 da F25 diz 34; na ponta `681a9e9` contei 33 (40 ocorrências). Não lhe
   toquei, porque é por desenho. A causa é a F97, commit `879bac2`: redigiu os nomes em 4 mensagens de diagnóstico do canário e a l. 112 perdeu o seu único par (−1 par, −5 ocorrências: 34→33, 45→40).
4. **Os 19 já não são saída crua.** o `.log` dos lançadores externos da `b7-correcoes-6` (l. 20) e `b7-correcoes-7/corridas.log:14` dizem que uma corrida deu igual a `s1.jsonl` linha a linha. São comparações **manuais, registadas em logs** — nenhum código nem passo do CI as faz (ver §1). Quem repetir essa comparação tem de aplicar primeiro a mesma redacção à saída nova (como no ponto 5 do §7 da F25). O mesmo vale para os `resumo.json`/`resumo.md` — uma corrida nova reescreve-os também (`correr-autojogo.sh:61`) — e para os `relato.txt`, que as provas reescrevem em todas as corridas (a comparação manual de um relato está registada em `provas/ordem-caixa-relato/b7-correcoes-7/lancador-caixa.log:7, 17`, um `diff` contra o `relato.txt` cometido da `ordem-caixa`).
5. **O histórico.** Os 19 ficheiros com os nomes inteiros continuam nos commits publicados até `681a9e9` (é a F26).

## Nota do CI (fusão C-FUS-1..5) — ponta `56477a6`

Testes **45204033141** + Sonda **45204032981**: **10/10 jobs verdes e a Sonda verde** na ponta da fusão. O commit da fusão só muda este ESTADO-FINAL (C-FUS-1 a C-FUS-5, correcções documentais da conferência da F52, 960, unânime); os 19 ficheiros da obra não foram tocados. Nomes inteiros nos logs: 0.
