# Ordem 59: a cobertura na faixa da fronteira do mapa (reserva da Ordem 48). ESTADO FINAL

*Fecho da ordem, 2026-11-15. PCDANASA, Godot 4.7.2 (Compatibility), Node 26 local. A ordem começou na conta 1, cuja
sessão morreu no limite de 5 h (12:37) sem commitar. A sucessão (conta 2, Claude Opus 5.5) continuou a mesma
missão na worktree `C:\Users\txcga\fable-mapa-wt-b`, ramo `fable/fronteira-59` (nascido de `ac2676b`). Tudo o
que aparece como «provado» abaixo foi corrido nesta máquina. Os registos estão em
`C:\Users\txcga\fable-mapa\_tmp\o59\`, fora do repositório. Não toquei em `main`, no clone `fable-mapa\repo`, na
worktree `fable-servidor-wt` nem no clone `fable-ciclo`. O `mesa-mestre.json` não entrou em commit nenhum.*

## O trabalho herdado da sessão morta

A árvore tinha duas coisas por commitar. Revi as duas e aproveitei-as tal como estavam:

- **`servidor/ferramentas/medir-fronteira-cobertura.mjs` (novo).** Corre o servidor de verdade
  (`juizo-terreno.mjs`) em 21 grelhas. Separa a faixa da borda em faixa da FRONTEIRA (todos os lados perto da
  casa estão na fronteira do mapa) e faixa do INTERIOR. Conta os `null` de cada uma e tira o SHA-256 do juízo
  inteiro. Corri-a outra vez sobre `ac2676b` e deu o mesmo ficheiro, byte a byte.
- **`provar_terreno_servidor.gd` (alargada).** Ganhou 6 grelhas que tocam a fronteira só nalguns lados e a
  contagem da faixa da fronteira (`faixaFronteira` no JSON). As 12 grelhas antigas continuam a dar o mesmo resumo
  que davam.

A medição de antes da sessão morta (`_tmp/o59/antes/`, sobre `ac2676b`) ficou nas provas.

## O que mudou (commits)

| commit | o quê |
|---|---|
| `1bbc811` | **Parte 1, a medição de antes.** A ferramenta, a prova alargada e `provas/ordem-59-fronteira/antes-*`. |
| `ba3b115` | **Parte 2, a correcção.** `nucleo/terreno.js`, `folgaFonteCoberturaM` no exportador e no pacote (refeito pela ferramenta), testes `ordem59-fronteira-cobertura.test.mjs`, provas de depois, documentação. |
| `f6d2684` | Listas da retoma e MANIFESTO refeitos pelo gerador (a parte 2 já trazia este ESTADO). Ponta do ramo `fable/fronteira-59`. |
| `06371c1` | **Parte final.** A fusão em `fable/integracao-50` (secção 4). |
| `1f1ede3` | Listas refeitas sobre a fusão. |
| *(este)* | A secção 4 deste ESTADO, na linha, e a seguir as listas outra vez. |

## 1. A medição de antes: a reserva reproduz-se

A medição é a do servidor real da ponta `ac2676b`, em 21 grelhas: as 12 da Ordem 48 e 9 que tocam a fronteira em
1, 2 ou 4 lados (`provas/ordem-59-fronteira/antes-medicao-fronteira.json`).

| | casas `null` |
|---|---|
| faixa da FRONTEIRA (9 grelhas) | **533** |
| faixa do interior | 2 022 |
| fora da faixa | 0 |

A prova cliente↔servidor (`antes-provar-terreno.log`) diz porque é que isto é uma reserva a sério. Nas 533 casas,
o cliente tem **sempre** a cobertura do mapa de referência (0 diferentes). O servidor calava-se onde sabia a
resposta. A faixa da borda da fronteira seguia uma regra diferente da do interior.

## 2. A correcção

### Porque é que a fronteira se pode julgar como o interior

A Ordem 48 calou a faixa da borda por isto: a cobertura de uma casa de dentro pode vir de árvores e rochas que o
cliente planta FORA da zona, e essas mudam com a zona. Li no `campo_floresta.gd` todas as fontes de cobertura
que mudam com a zona:

| fonte | só conta se… | sobrevive fora da zona a mais de |
|---|---|---|
| rocha (≥ 0,5 m) | `Grelha.casa_em(x, z) != FORA` (`continue` senão) | 0,9 × tam + 0,25 → **0,70 m** (tam 0,5) |
| árvore | `Grelha.casa_em != FORA` (senão não entra em `_troncos`) | raio do tronco + 0,75 m |
| estrato | `dar_cobertura` só escreve dentro do mapa | 0,9 × s + 0,25 ≥ 0,925 m |
| tronco tombado | a cobertura dele não passa de x = −19,5 m nem de z = 32,4 m | (longe da fronteira, ±37,5 m) |

Os marcos (menires, laje, charco) não mudam com a zona: já estão no mapa de referência.

Pensemos num lado da zona cuja folga até à fronteira do mapa é de 0,70 m ou menos. Uma fonte para lá desse lado
teria de estar a mais de 0,70 m dele, ou seja, fora do mapa, e aí não conta. Desse lado não vem cobertura
nenhuma. Uma casa cuja faixa só toca lados assim tem a cobertura do mapa de referência, como no interior. Uma
fonte para lá de um lado ABERTO só alcança casas a 1,35 m desse lado. Essas continuam na faixa e continuam `null`.

### O que se mexeu

- **Exportador** (`exportar_terreno.gd`): a constante `FOLGA_FONTE_COBERTURA_M := 0.70`, com a conta escrita
  ao lado. O pacote leva-a no cabeçalho como `folgaFonteCoberturaM`. Refiz o pacote com a ferramenta (~35 s). Só o
  cabeçalho mudou: o campo novo e o SHA do exportador. Escalas, mapa e redes ficaram iguais byte a byte. O
  `conferir-terreno.mjs` diz TERRENO EM DIA.
- **Servidor** (`nucleo/terreno.js`): ao recortar uma grelha, cada lado da zona fica ABERTO ou FECHADO. Fica
  fechado quando a folga até à fronteira é de no máximo `folgaFonteCoberturaM`. A faixa da borda (`longeDaBorda`)
  passa a contar só a distância aos lados abertos. Nada mais mudou: as casas longe de lados abertos têm a
  cobertura do mapa (como o interior) e 2 continua a ser 2. A grelha diz quais são os seus lados fechados
  (`ladosNaFronteira`).
- **Falha fechado.** Se o pacote trouxer uma folga inválida (negativa, texto, null, NaN), não se prepara:
  `terreno: cabecalho.folgaFonteCoberturaM inválida`. Um pacote sem o campo (anterior a esta ordem) não fecha
  lado nenhum e julga como antes, porque calar é o lado seguro.

## 3. Provas da construção

**A grelha da fronteira julgada pelo servidor real** (`depois-medicao-fronteira.json`, `depois-provar-terreno.*`):

| grelha | lados na fronteira | casas da faixa da fronteira | `null` antes → depois | cobertura afirmada diferente do cliente |
|---|---|---|---|---|
| 50 × 50 de 1,5 m | os quatro | 196 | 196 → **0** | **0** |
| 37 × 37 de 2 m | os quatro | 73 | 73 → **0** | **0** |
| 49 × 49 de 1,5 m | este, sul | 95 | 95 → **0** | **0** |
| 50 × 20 de 1,5 m | oeste, este | 36 | 36 → **0** | **0** |
| 20 × 50 de 1,5 m | norte, sul | 36 | 36 → **0** | **0** |
| 49 × 30 de 1,5 m | este | 28 | 28 → **0** | **0** |
| 37 × 20 de 2 m | oeste, este | 18 | 18 → **0** | **0** |
| 35 × 37 de 2 m | norte, sul | 33 | 33 → **0** | **0** |
| 20 × 37 de 2 m (só na medição do servidor) | norte, sul | 18 | 18 → **0** | (não está na prova do cliente) |

Na prova cliente↔servidor de todas as grelhas: **desvio 0 m** em altura e pé (bits do double), 0 juízos e 0
motivos diferentes, 0 coberturas afirmadas diferentes. As **recusas continuam nomeadas**: o Mestre tenta pôr
uma figura em cada casa bloqueada, todas são recusadas, e o motivo é o que o cliente desenha. TUDO PASSOU.

**As grelhas antigas, bit a bit.**
- Comparei o juízo inteiro do servidor (o JSON de `juizo-terreno.mjs`) antes e depois, casa a casa, nas 21
  grelhas. **533 casas mudaram, todas na faixa da fronteira e todas de `null` para a cobertura do mapa de
  referência.** Houve 0 outras diferenças: altura, pé, bloqueio, motivo, cobertura fora da faixa da fronteira,
  figuras, recusas e mover ficaram iguais.
- As 12 grelhas que não tocam a fronteira dão o mesmo SHA-256 do juízo inteiro, antes e depois.
- Comparei com o blob da Ordem 48 (`provas/ordem-48-terreno/medicao-terreno-qualquer-grelha.json`). As 10 grelhas
  antigas que não tocam a fronteira ficam iguais campo a campo, incluindo o detalhe casa a casa das três 25 × 25.
  Nas duas que tocam, só muda `coberturaNaoAfirmada`: 196 → 0 (50 × 50 de 1,5 m) e 73 → 0 (37 × 37 de 2 m).

**Testes novos do servidor** (`testes/ordem59-fronteira-cobertura.test.mjs`, 10 testes):
- o pacote traz a folga;
- a 50 × 50 serve toda a cobertura do mapa, também pela sala (`juizoTerreno`, 0 `null`);
- em 6 grelhas de fronteira, a faixa da fronteira serve o mapa (antes era `null`) e o resto é igual ao juízo de
  um pacote sem a folga;
- 10 grelhas sem fronteira julgam exactamente como antes;
- uma folga inválida não se prepara.

**Suites** (ramo, antes da fusão; sem janela):

| suite | resultado |
|---|---|
| servidor (`node --permission --allow-net … --test`, 365 testes) | 354 passam, 10 saltados (os de rede, como sempre), **1 falha local**: a fixture do Mestre, só por fim de linha (reserva 5) |
| servidor sem `--permission` (o do protocolo) | 364/365; a mesma falha local da fixture |
| `conferir-schemas.py` sobre o tráfego · validador GLB | saída 0 · 31 passam, 0 falham |
| `conferir-terreno.mjs` / `exportar_terreno --conferir` | **TERRENO EM DIA** (o pacote refeito pelo cliente é igual byte a byte ao do ramo) |
| `abrir_scripts` | 73 scripts, 0 falhas |
| `rodar_testes` · `pecas_mestre` · `hud_acoes` | 177/177 · 265/265 · 42/42 |
| `abrir_mestre` · `abrir_clareira` · `canario_privacidade` · `clima_forte` | 67/67 · 22/22 · 10/10 · 119/119 |
| `medir_mestre` · `medir_painel_config` | 0 falhas |
| `provar_assentamento` · `provar_terreno_servidor` · `provar_mestre_no_relevo` | TUDO PASSOU |
| `provar_molde_54` | 0 falhas; o mapa vestido é igual ao construído de raiz (136 linhas) |
| arranque `--quit-after 600` | «pronto» |

(O `provar_pes_bloqueadas` é da Ordem 58 e ainda não existe neste ramo: corre-se na linha fundida, secção 4.)

**CI do ramo.** O run `43746469667` (commit `f6d2684`) deu verdes os 9 jobs, e a sonda de privacidade
(`43746469760`) também. O run do commit da parte 1 (`1bbc811`) falhou só no `retoma-pc`, porque esse commit não
refez as listas da retoma. As listas entraram em `f6d2684`.

## 4. A fusão em `fable/integracao-50`

**A ponta da linha mexeu-se.** O ramo nasceu de `ac2676b`. No fetch antes da fusão, a linha estava em **`b7e352b`**:
tinham entrado as Ordens 57 (relógio), 58 e 60 (recusa no ecrã). Fundi sobre essa ponta nova. O ramo
`fable/integracao-50` está aberto no clone `fable-mapaepo`, em que não toco. Por isso fiz a fusão nesta
worktree, num ramo local `fable/integracao-50-o59` nascido de `origin/fable/integracao-50`, e publiquei com
`git push origin HEAD:refs/heads/fable/integracao-50` (avanço rápido, sem force, com outro fetch logo antes).

**Antes de fundir, conferi que o argumento da fronteira continua a valer na linha.** Entre `ac2676b` e `b7e352b`,
das fontes do terreno só mudou o `campo_floresta.gd` (o relógio). Nenhuma linha acrescentada ou tirada toca em
cobertura, `_na_zona`, `casa_em`, troncos, rochas ou bloqueios. O pacote da linha só diferia no cabeçalho
(o SHA dessa fonte).

**Conflitos (3), todos de ficheiros gerados:**
- `servidor/dados/terreno-floresta.json`: refiz o pacote com o exportador sobre a árvore fundida. Fica com a folga
  da Ordem 59 e o SHA do `campo_floresta.gd` da linha. Escalas, mapa e redes são iguais aos dos dois lados.
- `MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt`: ficaram as da linha na fusão, e o gerador refê-las em
  `1f1ede3` (402 ficheiros no MANIFESTO, `depois.txt` com 353). Uma segunda passagem dá 0 novos e 0 tirados.

**Presenças dos dois lados, provadas na árvore fundida** (`1f1ede3`):
- **Da Ordem 59:** o JSON de `provar_terreno_servidor.gd --json=` é **igual byte a byte** a
  `provas/ordem-59-fronteira/depois-provar-terreno.json` (a faixa da fronteira servida, desvio 0). Os testes
  `ordem59-fronteira-cobertura` passam.
- **Da linha:** o `medir_toque_rasante.gd --json=` é igual byte a byte a `provas/ordem-51-toque/depois.json`. O
  `pecas_mestre` dá 276 e o `hud_acoes` 50 (os números da Ordem 60). O retrato do molde tem 188 linhas (Ordem 57).
  As provas `provar_pes_bloqueadas` (Ordem 58) e `provar_recusa_no_ecra` (Ordem 60) dão TUDO PASSOU.

**Suites na árvore fundida** (sem janela, Godot 4.7.2; Node 26):

| suite | resultado |
|---|---|
| servidor (`--permission --allow-net`) | 365 testes: 354 passam, 10 saltados, 1 falha local da fixture, só por fim de linha (reserva 5; regenerada, `git diff` vazio) |
| protocolo + `conferir-schemas.py` · validador GLB | 364/365 (a mesma fixture) e schemas com saída 0 · 31 passam, 0 falham |
| `conferir-terreno.mjs` / `exportar_terreno --conferir` | TERRENO EM DIA |
| `abrir_scripts` | 83 scripts, 0 falhas |
| `rodar_testes` · `pecas_mestre` · `hud_acoes` | 177/177 · 276/276 · 50/50 |
| `abrir_mestre` · `abrir_clareira` · `canario_privacidade` · `clima_forte` | 67/67 · 22/22 · 10/10 · 119/119 |
| `medir_mestre` · `medir_painel_config` | 0 falhas |
| `provar_assentamento` · `provar_terreno_servidor` · `provar_mestre_no_relevo` · `provar_pes_bloqueadas` · `provar_recusa_no_ecra` | TUDO PASSOU |
| `provar_molde_54` | 0 falhas; retrato com 188 linhas, igual ao construído de raiz |
| `medir_toque_rasante` · `medir_perfil_mestre_52` | saída 0 |
| arranque `--quit-after 600` | «pronto» |

**CI.** Este ESTADO e as listas refeitas são o último commit da ordem. O CI dele corre no push do fecho.

## Reservas, sem rodeios

1. **A folga de 0,70 m é uma conta sobre o código do cliente, não uma medição.** Saiu do menor raio de
   sobrevivência das fontes de cobertura (a rocha de 0,5 m). Está escrita no exportador, que entra nas fontes do
   pacote. Mas nada obriga quem mexer no `campo_floresta.gd` a revê-la. Se alguém plantar uma fonte de cobertura
   FORA do mapa que conte, ou que sobreviva mais perto da zona, o servidor pode afirmar um número errado na
   fronteira. A guarda que existe é indirecta: o SHA do `campo_floresta.gd` obriga a refazer o pacote, e a prova
   cliente↔servidor com as 6 grelhas de fronteira (`provar_terreno_servidor.gd`) mostraria a diferença. A prova
   não corre no CI, porque precisa do Godot com a arena e de ~1 min.
2. **As folgas reais são 0 ou 0,5 m.** As origens caem na rede de 0,5 m e as escalas são 1, 1,5 e 2 m. A
   fronteira «a 0,70 m» nunca se vê no jogo. As grelhas com folga de 1,5 m (48 × 48 de 1,5 m, 36 × 36 de 2 m)
   continuam com a faixa toda calada, porque há mapa lá fora onde pode crescer uma rocha.
3. **A faixa dos lados abertos continua `null` abaixo de 2.** É a parte da reserva da Ordem 48 que não é desta
   ordem: torná-la exacta pede que o servidor saiba o que o cliente planta fora de cada zona. As regras ainda não
   usam a cobertura (ponto 2 da Ordem 44).
4. **A referência das presenças desta prova mudou.** O JSON de `provar_terreno_servidor.gd --json=` já não é igual
   ao blob da Ordem 48: tem `ordem: 59`, as grelhas novas, `faixaFronteira` e o `null` a menos. A referência
   passa a ser `provas/ordem-59-fronteira/depois-provar-terreno.json`.
5. **Local, o teste da fixture do Mestre falha só por fim de linha.** A worktree tem `core.autocrlf=true`, e
   `dados-exemplo/mesa-mestre.json` sai em CRLF. Regenerei-o e o `git diff` dá vazio (conteúdo igual), por isso
   repus a cópia e não o commitei. No CI (Linux, LF) passa.
