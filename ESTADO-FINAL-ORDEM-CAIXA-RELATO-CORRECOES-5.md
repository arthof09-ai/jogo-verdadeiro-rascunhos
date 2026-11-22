# ESTADO-FINAL — Ordem CAIXA-RELATO-CORRECOES-5 (as correcções B1–B3 da sentença da CAIXA-RELATO-CORRECOES-4)

**Quem:** Claude, conta 2, no PC (22/11/2026). **Ramo:** `claude2/caixa-relato-correcoes-5`, a partir de `7ce6df3`
(a ponta de `fable/integracao-50` à hora do lançamento). **Não fundi.**
**Sede:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-caixa-relato-correcoes-5\` (o clone está em `repo\`; a pasta
tmp, com o registo antigo e as saídas das mutações, em `tmp\`).
**Commits:** `7a12c01` (as correcções, o registo regenerado e as corridas), com o CI verde: 10/10 jobs, retoma-pc
incluído, e a sonda de privacidade verde. A seguir vem o commit deste ESTADO-FINAL.

A conferência não está neste PC (`~/workspace/conferencias/` não existe aqui). Trabalhei pelo texto da ordem, que
traz o ficheiro e as linhas dos defeitos. Confirmei os defeitos todos no registo cometido antes de mexer.

Este ficheiro não cita os nomes verdadeiros nem os fragmentos: diz só a linha, o n.º do nome e quantos caracteres.

## 1. Ponto a ponto

### B1 — filtrar antes de cortar; registo regenerado e cometido de novo — FEITO, PROVADO (executado)
- **Defeito, confirmado:** em `correr-mutacoes.sh:93` (base), as linhas FALHA passavam por `cut -c1-400` **antes** do
  `filtrar` (`:95`). O `cut` conta bytes, e os primeiros 400 bytes acabavam a meio do 10.º achado. O `sed` procura o
  nome inteiro e já não casava. O registo cometido tinha um fragmento de 14 dos 15 caracteres de um nome nas linhas
  17 e 55, e um de 7 dos 16 caracteres do outro nome nas linhas 18 e 56. Tinha também um `�` nessas linhas, porque o
  corte partia um carácter UTF-8 a meio.
- **Correcção** (`provas/ordem-caixa-relato/ferramentas/correr-mutacoes.sh`):
  - O bloco que vai para o registo passa **inteiro** pelo `filtrar` e só depois pelo `cortar 400`:
    `{ …erros; …FALHA (sem cortar); …resumos } | filtrar "$filtro" | cortar 400`.
  - `filtrar` e `cortar` são agora em node. O filtro trata o nome como texto literal (antes, um `.` ou um `/` no nome
    estragava o `sed`). Ignora maiúsculas e minúsculas também fora do ASCII (`giu`). Troca primeiro os nomes mais
    compridos.
  - O `cortar` conta pontos de código, não bytes, e não deixa `�`.
  - Os nomes do filtro são os da corrida (fichas com a mutação) mais os das fichas cometidas.
  - O mecanismo deixa de depender de onde o nome cai: o corte só vê texto que já foi filtrado. O pior que pode ficar
    cortado é o marcador `‹nome verdadeiro›`.
- **Prova das funções**, isoladas, numa linha sintética de 457 caracteres com 190 `á` à frente e três nomes (um
  deles a cavalo do corte, outro em maiúsculas, outro em minúsculas): os 3 foram trocados e não ficou nenhum `�`.
  `a.b` como nome não apanha `axb`.
- **Registo regenerado:** `provas/ordem-caixa-relato/correcoes-4/mutacoes.log`. Voltou a ser cometido no mesmo
  sítio, porque é a mesma experiência com o mesmo código das provas; o antigo fica só no histórico e em
  `tmp\mutacoes-correcoes-4-antigo.log`. Foram 18 mutações `base4` (ficheiros de `da6683e`) e 18 `novo`, todas
  executadas. Os resultados coincidem um a um com os do registo antigo (ver §2).
- **Conferido linha a linha** com o conferidor novo `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`.
  - **Critério:** acha o nome inteiro, ou qualquer pedaço de **4 ou mais** letras seguidas de uma palavra de um nome
    verdadeiro (nome ≠ nomePublico), sem distinguir maiúsculas. Exclui só as ocorrências dentro de um nome que nas
    fichas é público por inteiro (nome = nomePublico). Diz a linha, o n.º do nome e o comprimento do maior pedaço
    contíguo; não repete o texto.

  | registo | achados | linhas |
  |---|---|---|
  | antigo (`7ce6df3`) | **18** | 12, 50, 132, 170 (nome inteiro); 17, 55 (14 de 15); 18, 56 (7 de 16); 6, 7 (cabeçalho escrito à mão: uma palavra corrente do português que é pedaço de um nome) |
  | **regenerado** | **0** | — (248 linhas) |

  - **Conferência independente, por grep:** procurei sem distinguir maiúsculas todos os pedaços de 4 letras das
    palavras dos dois nomes (não os cito aqui). Só aparecem as linhas 76 e 192, com o nome público por inteiro
    «Espadachim de Bancada» (ver B2).
  - Há 0 caracteres `�`. A linha mais comprida tem 400 caracteres.
  - O marcador `‹nome verdadeiro›` aparece 28 vezes.
  - Escrevi o cabeçalho do registo sem duas palavras correntes do português que o critério estrito acusa, para
    a regra continuar sem excepções.

### B2 — o `diz` passa pelo filtro — FEITO, PROVADO (executado)
- **Correcção:** o título (`node mutacoes.mjs diz …`) e a linha «NÃO APLICOU» passam pelo `filtrar`. Os nomes do
  filtro são os das **fichas cometidas** (lidos uma vez, com os ficheiros limpos, antes do ciclo). Não uso os da
  corrida: na mutação da heroína, a mutação faz do nome público um «verdadeiro», e esse não se toca.
- **Prova:** no registo regenerado, os 4 títulos que traziam um nome verdadeiro (`B1-nome-verdadeiro` e
  `N-B2-canario-minusculas-relato`, nos dois modos; agora nas linhas 17/137 e 55/175) dizem «‹nome verdadeiro›».
  Os títulos de `N-B3-heroina-nome-publico-hud` (linhas 76/192) ficam com «Espadachim de Bancada», que é o nome
  público nas fichas. O conferidor dá 0 em todo o ficheiro.
- O `mutacoes.mjs` não mudou: os textos-fonte dos títulos continuam lá. Ver §3.2.

### B3 — o ESTADO-FINAL da CORRECOES-4 §3.2 diz o âmbito real — FEITO
- Em `ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES-4.md` §3, ponto 2, a frase «As linhas FALHA e os resumos do registo
  não têm nenhum» leva **um risco por cima**. Logo depois, uma emenda com a marca «CAIXA-RELATO-CORRECOES-5, B3», que diz o que
  conta o `conta_nomes`:
  - só **nomes inteiros**, só em **linhas FALHA**, **antes do filtro**, no `relato.txt` e na consola;
  - não vê fragmentos, não olha para os resumos e não olha para o registo escrito;
  - o registo antigo tinha fragmentos (linhas 17/55 e 18/56, sem os citar), e foi regenerado nesta ordem.
- O cabeçalho do registo regenerado diz o mesmo âmbito, e diz que o registo é conferido pelo `conferir-registo.mjs`.

## 2. As corridas (Godot 4.7.2 Windows, `Godot_v4.7.2-stable_win64_console.exe`, motor VLAB real `a91c021c…3261`, semente 7)

| Corrida | Resultado | Ficheiro |
|---|---|---|
| Teste do relato | **31/31** (no CI também 31/31) | `provas/ordem-caixa-relato/correcoes-5/teste-relato.log` |
| Prova HUD-JOGADORA | **43/43**, rc=0; 68 linhas varridas = 68 no ficheiro, 1 resumo; 0 nomes verdadeiros | `correcoes-5/cliente-hud/relato.txt` |
| Prova MANEQUIM | **53/53**, rc=0; 78 = 78, 1 resumo; 0 nomes verdadeiros | `correcoes-5/cliente-manequim/relato.txt` |
| Mutações `base4` + `novo` | 18 + 18, todas executadas; `conferir-registo.mjs` → **0 achados** | `correcoes-4/mutacoes.log` (regenerado) |
| CI em `7a12c01` | **10/10 jobs verdes** (servidor, cliente, motor-real, foto-mestre, godot-cliente, protocolo, ponta-a-ponta, provas-mapa, validador-glb, **retoma-pc**); sonda de privacidade verde; prova da caixa do servidor PROVA OK | — |

Resultados das mutações regeneradas, `base4` → `novo` (iguais, um a um, aos do registo antigo):

| mutação | base4 | novo |
|---|---|---|
| `B1-nome-verdadeiro` (HUD) | 39/43 | 39/43 |
| `B2-fuga-linhas-hora` | 30/31 | 30/31 |
| `B3-caixaMestre` / `B3-master` / `B3-PA` / `B6-estado-de-actor` / `B5-bias-zero` | 29/31 | 29/31 |
| `N-B2-canario-minusculas-relato` | 39/43 | 39/43 |
| `N-B2-canario-minusculas-caixa` | 36/43 | 40/43 |
| `N-B3-heroina-nome-publico` (HUD / MANEQUIM) | 43/43, 53/53 | 43/43, 53/53 |
| `N-B6-utc-e-sem-fuso` | 30/31 | 30/31 |
| `N-B1-canario-na-linha-em-branco` (HUD) | 43/43 + 43/44 (2 resumos, 70 linhas) | 42/43 |
| `N-B1-canario-no-resumo` (HUD / MANEQUIM) | 42/43, 52/53 | 42/43, 52/53 |
| `N4-B3-sem-canarios` (HUD / MANEQUIM) | 42/42, 52/52, rc=0 | 42/43, 52/53, rc=1 |
| `N4-B1-canario-na-linha-em-branco-manequim` | 53/53 + 53/54 (80 linhas) | 52/53 |

`actualizar-listas` (`python retoma-i0004/actualizar-listas.py`): corri-o depois do commit `7a12c01` e outra vez
antes do commit deste ficheiro. Deu «0 novos, 0 tirados», e o `git status` ficou limpo. O ramo não toca em
`rascunhos/`, por isso não havia listas a sincronizar. O retoma-pc passou.

## 3. Pontos para o coordenador
1. **O registo foi regenerado no mesmo sítio** (`correcoes-4/mutacoes.log`), em vez de ir para um ficheiro novo em
   `correcoes-5/`. Li o «voltar a cometer o `mutacoes.log`» como querendo que, na ponta do ramo, o ficheiro com os
   fragmentos deixasse de existir. **O registo antigo continua no histórico do git** (`7ce6df3` e anteriores). Tirá-lo
   de lá era reescrever história e não é trabalho meu. São valores-canário fictícios.
2. **Os textos-fonte dos nomes-canário ficam onde estavam.** O `mutacoes.mjs` traz os títulos com o nome verdadeiro
   inteiro (linhas 37 e 49), e o ESTADO-FINAL da CORRECOES-4, §3.2, cita-os pelo nome. A ordem pediu só o registo, e
   não lhes toquei. A emenda B3 que escrevi nesse §3.2 não cita nomes nem fragmentos. Se quiseres que nem a fonte os
   tenha, é uma ordem pequena: trocar os dois `diz` por «o nome verdadeiro n.º K».
3. **O critério do conferidor é estrito.** Acusa palavras correntes do português (um pronome indefinido, um particípio, um substantivo), porque são
   pedaços de 4 ou mais letras de uma palavra dos nomes. No registo regenerado não há nenhuma, por isso não precisei
   de excepções. Nos relatos das provas, o conferidor acusaria os nomes públicos curtos, que lá estão por direito.
   Foi feito para o registo, não para os relatos.
4. **Fronteira:** mexi só em `provas/ordem-caixa-relato/` (`correr-mutacoes.sh`, `conferir-registo.mjs` novo,
   README, `correcoes-4/mutacoes.log`, `correcoes-5/`), no ESTADO-FINAL da CORRECOES-4 (B3) e neste ficheiro. Não
   mexi nas provas vivas, no código do jogo, no HUD, nas cores, no workflow nem em `rascunhos/`. O `base4` e o `base`
   ficam como estavam.
5. **Não mexi no `ORDEM.md` da sede.**
