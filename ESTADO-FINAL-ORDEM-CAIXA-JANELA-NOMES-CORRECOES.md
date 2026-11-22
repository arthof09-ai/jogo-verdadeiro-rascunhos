# ESTADO FINAL — ORDEM CAIXA-JANELA-NOMES-CORRECOES (Claude conta 1, PC · 22/11/2026)

As correcções B1–B7 da sentença da conferência da CAIXA-JANELA-NOMES.

- **Ramo:** `claude1/caixa-janela-nomes-correcoes`, **não fundido**.
- **Base:** `15eab43`, a ponta de `fable/integracao-50` à hora do lançamento (00:41 −03 = 03:41 UTC). A linha avançou
  durante a ordem: `8870275`/`ae62dd9`/`f049089` (CAIXA-TESTES-CORRECOES-3, 03:45 UTC). Esses commits tocam em
  `rascunhos/servidor/testes/`, nas listas da retoma e num ESTADO-FINAL; este ramo não toca em nenhum deles.
- **Commits:**
  - `1c46007`: as correcções, as corridas e o artefacto do remendo ao CI;
  - o commit deste ESTADO-FINAL, que só acrescenta este ficheiro.
- **A conferência:** não estava neste PC (`~/workspace/conferencias/caixa-janela-nomes/` não existe). Trabalhei pelo
  texto da ordem.
- **Território:** só `provas/ordem-caixa-janela/`. O workflow fica como artefacto (B1). `git diff 15eab43 -- rascunhos/
  .github/` vazio. Nada de HUD nem de cores.

## 1. Ponto a ponto

### B1 — o teste dos nomes entra no CI

**O remendo:** `provas/ordem-caixa-janela/nomes-correcoes/remendo-ci-testes.yml.patch`. Conferi com
`git apply --check` sobre `1c46007` e aplica limpo. Acrescenta um passo:
- nome: «Nomes do relato da caixa-janela — o canário apanha o nome verdadeiro (Ordem CAIXA-JANELA-NOMES, B1 das
  correcções)»;
- **no job `cliente`, logo a seguir ao passo «Relato da caixa»**;
- a mesma forma do passo vizinho: `set -o pipefail`, `timeout 120 "$GODOT" … -s
  "$GITHUB_WORKSPACE/provas/ordem-caixa-janela/ferramentas/teste_nomes_relato.gd" | tee …`, e a guarda contra
  `SCRIPT ERROR|Parse Error|Compile Error`.

**Não o cometi no workflow.** O token deste PC tem os âmbitos `gist`, `read:org` e `repo`, sem `workflow`, e a regra da
casa é que o coordenador aplique o remendo.

**A prova, como pude fazê-la:** tirei o corpo exacto do passo do workflow remendado e corri-o como o runner o corre
(`bash --noprofile --norc -e`, a partir de `rascunhos/cliente`, com `GODOT` = Godot 4.7.2 `_console.exe`):
- **verde:** rc=0, 14 de 14;
- **canário mudado** (na fixture, linha 7: «Lobo de Bancada» → «Lobo da Bancada»): **rc=1**, 13 de 14. O §4 acusa
  «21 achado(s) … 27 brutas». Reposto com `cp`, e o `cmp` confirma que ficou igual.
- Registo: `nomes-correcoes/mutacoes.log`.

**Falta a prova no CI a sério** (o passo vermelho numa corrida do GitHub). Só pode existir depois de o coordenador
aplicar o remendo. Ver §4, ponto 1.

### B2 — o §4 preso ao caso medido

- O relato antigo está **congelado dentro do teste**: `const RELATO_VELHO`, igual byte a byte a
  `provas/ordem-caixa-janela/cliente/relato.txt` (sha256 `6df653c41a29e23a…` nos dois; comparado à máquina).
- O §4 já não lê o ficheiro. Afirma, numa verificação só (o teste continua com 14):
  - `achados.size() == 22`;
  - `achados[0] == "Lobo de Bancada na linha 7"`;
  - **28 ocorrências brutas**.
- **«22 ocorrências» passou a «22 achados (28 brutas)».** Um achado é um par linha × nome. A linha 25, a da ordem
  dinâmica, tem 4 «Lobo de Bancada» e 4 «Bruto de Bancada»: conta 2 achados e 8 ocorrências.
  - Corrigido no teste e no README novo.
  - O ESTADO-FINAL da CAIXA-JANELA-NOMES (§1 e §2) ainda diz «22 ocorrências» / «22 nomes verdadeiros». Não o
    reescrevi, porque é o registo daquela ordem. Fica dito aqui.
- O `cliente/relato.txt` pode agora ser limpo por outra ordem sem partir o teste. Isto cumpre a condição «o §4 migra
  primeiro para a fixture» da decisão sobre o relato antigo.

### B3 — a varredura final de `_fim()` incondicional

**Antes:** `if not _canarios_nomes.is_empty(): …`. Os canários só se juntavam no `_privacidade` (passos 1 e 2). Se a
prova parasse no passo 0 ou 1, onde se escrevem as linhas «bancada:», a varredura final não corria, e uma fuga nessas
linhas passava calada.

**Agora:** a varredura corre sempre que se chega a `_fim()`. Sem canários, é FALHA (`not _canarios_nomes.is_empty() and
no_relato.is_empty()`). Os canários existem desde o arranque, por causa da B6.

**Prova por mutação** (em cópias em `tmp/`, nunca no repositório): a fuga reintroduzida (`nome_publico` lê `nome`) e a
prova a parar logo depois do passo 0. Corri as duas versões ao vivo, com o servidor de bancada e o motor VLAB real.

| Versão | Resultado | A fuga |
|---|---|---|
| a da base (`15eab43`) | 2 de 3, rc=1 (só a falha forçada) | 17 linhas com o nome verdadeiro e **nenhuma verificação «fim»**: calada |
| a desta ordem | 2 de 4, rc=1 | `FALHA fim: … (18 achado(s), linhas [7,…,25])`: **apanhada** |

### B4 — o diagnóstico sem nomes

- Há um ajudante novo, `diagnostico(relato, nomes)`, em `nomes_relato.gd`. Devolve «N achado(s), linhas [..]» e usa
  `linhas()`, também novo.
- A prova usa-o nas varreduras do relato: `_privacidade` 1 e 2, e o `fim`. O teste usa-o nos §3 e §4.
- **Também nos textos da caixa:** a varredura de vida/PA/nomes e a de dígitos escreviam o valor achado e o texto da
  caixa no relato. Agora escrevem «N achado(s), textos [índices]».
- O `no_relato()` continua a devolver «<nome> na linha <n>», só para o teste conferir o caso. O comentário diz que o
  diagnóstico que vai para o relato é o `diagnostico()`.
- Na corrida B3 acima, a FALHA «fim» mostra contagem e linhas, sem nenhum nome.

### B5 — o rótulo

«figuras repetidas (as 8 criaturas da prova)» passou a «uma ficha repetida não repete o canário (aqui as 4 fichas + 1
Bruto repetido; na prova viva, 10 figuras de 4 fichas)». O 4 vem de `figuras.size()`, por isso não pode ficar
desactualizado.

### B6 (opcional) — os canários a partir do elenco: **feito**

- Há um ajudante novo, `vista_do_elenco(fichas_json)`. Devolve uma vista do Mestre feita das fichas, só com `id`, `nome`
  e `nomePublico`; nenhum outro campo é copiado.
- A prova lê `servidor/autojogo/fichas-bancada.json` no arranque, e `_canarios_nomes` começa com
  `nomes_verdadeiros(vista_do_elenco(...))`, que dá 2 nomes. Depois o `_privacidade` acrescenta os de cada vista, como
  antes.
- O teste usa o mesmo ajudante. Antes construía a vista à mão e punha-lhe um `vidaActual: 9` que nada usava. Esse campo
  saiu.

### B7 (condição) — a cobertura de vida/PA no relato desta prova

**Por leitura de código, o relato não traz vida, PA nem alma.** Revi as 45 chamadas `_linha`/`_ok` da prova. As fontes
de texto são estas:
- a linha «bancada:»: o passo da IA em JSON (`mover` com destino, `atacar` com `alvoId` e `arma`, `encerrar`) e o estado
  da resposta (`APLICADA`) ou o `motivo`. Os `motivo` da sala são códigos do ROOM_REJECT;
- «a batalha a meio»: fase, rodada, a vez e a ordem, em nomes públicos;
- o passo 1: nomes por `_estado.nome_de` (o nome público), seq e contagens;
- a caixa: nomes públicos;
- as MEDIDAS: geometria;
- os rótulos das verificações e as contagens.

**O que está coberto por verificação automática:**
- os nomes no relato: o canário do relato, agora com os canários do elenco e a varredura incondicional;
- vida, PA e nomes nos **textos da caixa**: os valores da vista do Mestre e qualquer dígito.

**O que falta, antes de fichas reais:**
1. **Nenhuma verificação automática procura vida/PA no relato.** Procurar pelos valores não serve. Os da bancada são
   vida 16/22/30/34 e PA 0/6, e confundem-se com coordenadas, seq e medidas (o mesmo motivo que o ESTADO-FINAL da
   CAIXA-JANELA-NOMES §5.4 dá). O critério que serve é procurar por **chaves**: proibir `vidaActual`, `vidaTotal`,
   `paTotal`, `paLivre` e `alma` em qualquer linha do relato, como a lista `PROIBIDAS` do `teste_relato_caixa.gd`, e
   saber que os rótulos das verificações usam «vida» e «PA» como palavras.
2. **A linha «bancada:» escreve o passo inteiro com `JSON.stringify`.** Se a IA ou o protocolo passarem a pôr um valor
   no passo (um custo de PA, um dano), ele entra no relato sem nenhuma verificação. A varredura por chaves do ponto 1
   cobria também este caso.
3. **Alma não tem canário em lado nenhum.** As fichas de bancada não têm campo de alma. Com fichas reais, o canário da
   caixa e o do ponto 1 têm de o incluir.
4. Os canários de nome só cobrem `nome` ≠ `nomePublico`. Outros campos privados de uma ficha real (descrição,
   anotações do Mestre) não têm canário.

Não implementei nada disto: a ordem pede que se diga, e a fronteira de privacidade das provas mantém-se, porque nada de
vida, PA ou alma entra nos ficheiros desta ordem.

## 2. Corridas (PC, Godot 4.7.2 Windows `C:\Users\txcga\RPG_Local\ferramentas\Godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe`; Node 26.13; motor VLAB real sha256 `a91c021c…3261`, baixado do sítio público; semente 7)

| Corrida | Resultado | Registo |
|---|---|---|
| Teste dos nomes do relato | **14/14** | `provas/ordem-caixa-janela/nomes-correcoes/teste-nomes-relato.log` |
| Prova viva da caixa-janela | **38/38**, rc=0; 0 «Lobo/Bruto de Bancada» no relato | `nomes-correcoes/cliente/relato.txt` |
| Teste do relato da caixa (passo «Relato da caixa») | **28/28** | `nomes-correcoes/suites/teste_relato_caixa.log` |
| Servidor, `node --test --test-isolation=none` | **418/418**, 0 falhas | `nomes-correcoes/suites/servidor-node-test.log` |
| `prova-servidor.mjs` (passo «Prova da caixa») | **PROVA OK** | `nomes-correcoes/suites/prova-servidor.log` |
| rodar_testes · abrir_scripts | 290/290 · 107 scripts, 0 falhas | `nomes-correcoes/suites/` |
| caixa_jogadora · hud_acoes · canario_privacidade | 18/18 · 50/50 · 10/10 | `nomes-correcoes/suites/` |
| `actualizar-listas` (retoma) | 0 novos, 0 tirados, sem diferenças: o ramo não toca em `rascunhos/`, por isso não havia listas para juntar | — |

- **Capturas da prova viva** (sha256, 16 primeiros): `0086b0edbd6a8051`, `b46e4b57b68effbb` e `79f7c54d69c4c0db`. Vi a
  de 780×360: «Lobo», «Bruto», «Arqueira …», «Espadachi…», partida em 9 + 1.
- **Os servidores correram sem `--permission`**, como nas ordens anteriores. Com essa opção, o Node 26 deste PC recusa
  a rede.
- **O clone era fresco.** A 1.ª tentativa da prova viva falhou com `Could not find type "AplicadorPerfil"`, porque os
  `class_name` não estavam registados. Fiz `--import` e repeti. A saída da tentativa falhada foi apagada.

## 3. CI

| Workflow | Commit | Corrida | Resultado |
|---|---|---|---|
| «Testes dos rascunhos» | `1c46007` | 44985512359 | **verde, 10/10 jobs**: cliente, godot-cliente, servidor, protocolo, motor-real, ponta-a-ponta, foto-mestre, provas-mapa, validador-glb, **retoma-pc** |
| «Sonda de privacidade» | `1c46007` | 44985512364 | **verde** |

O passo novo da B1 **ainda não está** nesta corrida: o remendo é do coordenador.

## 4. Pontos para o coordenador

1. **Aplicar o remendo da B1** (`provas/ordem-caixa-janela/nomes-correcoes/remendo-ci-testes.yml.patch`, com
   `git apply`). Depois falta ver o passo vermelho numa corrida do CI a sério: um push de ensaio com o canário mudado,
   por exemplo a mesma mudança da linha 7 da fixture, e depois repor. Só o fiz localmente, com o corpo exacto do passo.
2. **O job do passo.** A ordem diz «job `godot-cliente`, a seguir ao passo «Relato da caixa»», mas esse passo está no
   job **`cliente`** (`testes.yml:157-162`). O `godot-cliente` só tem import e `rodar_testes`, com `timeout-minutes: 5`.
   Segui a âncora («a seguir ao Relato da caixa») e pus o passo no `cliente`, onde o passo irmão já corre ficheiros de
   `$GITHUB_WORKSPACE/provas/`. Se o crítico queria mesmo o `godot-cliente`, o passo passa para lá sem mudar nada.
   Funciona com o Godot 4.7.2 fixo desse job, mas soma uns segundos aos 5 minutos.
3. **A base avançou durante a ordem** (`f049089`, a CAIXA-TESTES-CORRECOES-3). Não há sobreposição de ficheiros. As
   listas da retoma desse ramo não mudam com este, porque este ramo não toca em `rascunhos/`.
4. **A B7 deixa 4 faltas para antes das fichas reais** (§1 B7). A mais barata e a que fecha mais é a varredura do relato
   por chaves (vida/PA/alma).
5. O ESTADO-FINAL da CAIXA-JANELA-NOMES ainda diz «22 ocorrências». Não o reescrevi, porque é registo; a correcção está
   aqui e no README.
6. O `ORDEM.md` da sede não foi mexido. Como na ordem anterior, a linha «Estado: NOVA» está no último ponto da lista e
   não numa linha só sua.
