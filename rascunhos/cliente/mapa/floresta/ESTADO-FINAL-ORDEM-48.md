# Ordem 48: o terreno do servidor para qualquer tamanho de grelha. ESTADO FINAL

*Fecho da ordem, 2026-11-15, conta 2, Opus 5.5, uma sessão. PCDANASA: Godot 4.7.2, Node 26 local. Ramo
`fable/servidor-grelhas-48`, tirado de `8cd941d` (ponta da Ordem 45). As três partes estão feitas,
commitadas e empurradas, sem força. Trabalho de código e de testes: nenhuma cena, material ou coisa que se
veja foi tocada. O que está «provado» abaixo foi corrido nesta máquina.*

## O que mudou (commits)

| commit | o quê |
|---|---|
| `427499b` | **Parte A.** O pacote passa a ser o mapa inteiro (`terreno/2`) e o servidor recorta dele a grelha viva. Fim da queda silenciosa: o que não cabe falha com nome. Testes novos e adaptados; a prova cliente↔servidor e a do Mestre passam a usar o recorte. |
| `b0448d6` | **Parte B.** A `exportar_terreno()` antiga da `grelha_floresta.gd` foi apagada; pacote reexportado (só muda o SHA da fonte). |
| `b9332c9` | **Parte C.** `servidor/ferramentas/conferir-terreno.mjs`, a conferência completa num comando, e o README do terreno (`servidor/dados/README.md`). |
| `b0da90e` | As provas (`provas/ordem-48-terreno/`): a medição em 12 grelhas e a sonda das 42 zonas (ferramenta nova `sondar_zonas_terreno.gd`). |
| `8d43087` | Listas da retoma e MANIFESTO refeitos (`actualizar-listas.py`: 278 em `depois.txt`, 4 novos no MANIFESTO). |
| *(este)* | Este ESTADO FINAL e as listas outra vez (o ESTADO vive em `rascunhos/`). |

## Parte A: qualquer tamanho servido, sem queda silenciosa

### O que encontrei: o mapa muda com a zona

A ordem propunha exportar o mapa de 50 × 50 uma vez e recortar. Antes de o fazer, medi uma coisa que o
recorte simples não aguentaria: **o mapa da arena muda com o tamanho da grelha.** Desde a Ordem 42, o mapa é
construído para a zona jogável e não planta nada dentro dela: nem árvores, nem rochas, nem estrato, e o tronco
tombado é cortado antes dela. Pior: o que a zona tira muda a forma como o gerador gasta a semente, e as coisas
plantadas longe também mudam de sítio (medido: as casas 4, 32, 232, 755 e 2000 do mapa, perto da orla, mudam
entre zonas).

Mesmo assim, o que **bloqueia** uma casa **dentro** da zona não depende da zona:

- os marcos (menires, santuário, lanternas) têm semente própria;
- a água funda e a escarpa são do relevo;
- o que a zona tira só sobrevive a mais do que o raio dele da borda, e daí não chega a nenhuma casa de dentro.
  Com casas de 1 m e de 2 m, a casa do mapa debaixo de uma casa do jogo passa no máximo 0,5 m para fora da borda
  (as origens caem na rede de 0,5 m). As árvores sobrevivem a mais de 0,95 m da borda; as rochas e o tronco,
  ainda mais longe.

A **sonda** (`sondar_zonas_terreno.gd`) constrói o mapa de verdade para 42 zonas: de 1 × 1 a 70 × 70, nas três
escalas, quadradas e não, com lados pares e ímpares, e maiores do que o mapa. Compara cada casa do jogo com o
mapa de referência: **43 010 casas, 0 com bloqueio diferente, 0 com motivo diferente.**

A **cobertura** é outra conversa. Uma árvore logo fora da zona dá meia cobertura à casa vizinha de dentro, e
essa árvore muda com a zona. Na sonda, 79 das 4 799 casas da faixa da borda têm no cliente uma cobertura mais
alta do que a do mapa de referência. Longe da borda: 0 diferenças.

### O desenho: uma só fonte, três partes

O exportador (`cenas/arena/ferramentas/exportar_terreno.gd`) abre a arena do jogo 10 vezes, sem janela (~40 s),
e escreve o pacote `servidor/dados/terreno-floresta.json` (658 kB). Tem três partes:

- **`escalas`.** Para 1, 1,5 e 2 m, a origem no mapa da grelha de 1, 2, 3… casas de lado: a regra da arena
  (`Assentamento.origem_no_mapa`) tabelada até à maior grelha que cabe no mapa de 75 m (75, 50 e 37 casas). O
  servidor não reescreve a regra: lê a tabela. O `rodar_testes` confere a tabela contra a regra, lado a lado.
- **`redes`.** As 9 maiores grelhas que cabem no mapa, uma por escala e «fase» da origem: 50 × 50 de 1,5 m;
  75/74 × 75/74 de 1 m; 37/36 × 37/36 de 2 m. Cada uma leva a `alturaM` e o `peM` de cada casa, medidos com
  `arena.centro_casa` e `arena.pe_figura`, e escritos em base64 dos doubles (os bits exactos, sem passar por texto
  decimal). Leva também a casa do mapa debaixo de cada coluna e de cada linha. Toda a grelha que cabe é um recorte
  exacto de uma rede: os mesmos centros, logo os mesmos bits.
- **`mapa`.** O bloqueio, o motivo e a cobertura das 50 × 50 casas, tirados do mapa construído para uma zona de
  referência de 56 × 56 casas de 1,5 m: 84 m, 4,5 m além do mapa a toda a volta. Nada do que a zona tira chega
  lá. O exportador confere essa folga antes de escrever.

O servidor (`nucleo/terreno.js`) acha a rede onde a grelha viva encaixa e recorta-a. O bloqueio e o motivo de cada
casa do jogo são os da casa do mapa debaixo do centro.

A cobertura funciona assim:

- **Longe da borda** (o centro da casa do mapa a mais de 1,35 m da borda da zona), é a do mapa.
- **Na faixa da borda**, o servidor só afirma a cobertura total (2): no mapa, a cobertura só sobe com o que se
  planta. Abaixo disso devolve `null`. Nunca dá um número errado.

O limite de 1,35 m é o maior alcance para dentro de uma cobertura vinda de fora: rocha 1,35 m, árvore 1,30 m,
tronco 1,15 m. A conta está escrita no exportador, e a sonda confirma-a (o maior alcance observado foi 0,75 m).

### Fim da queda silenciosa

Já não há caminho para «tudo se pisa» com o terreno ligado:

- **Criar** uma sala cuja grelha não cabe no mapa falha: `criarSala: TERRENO_GRELHA_FORA_DO_MAPA: a grelha 51x51 de 1.5 m não cabe no mapa da floresta (50 x 50 casas de 1.5 m); nesta escala cabem até 50x50`.
- **Mudar de escala** para uma em que a grelha deixe de caber é recusado ao Mestre, com o mesmo nome, e a sala
  fica na escala em que estava. Exemplo: 40 × 40 cabe com 1,5 m e com 1 m, mas não com 2 m (80 m).
- **Restaurar**, com terreno, uma sala gravada numa grelha que não cabe também não abre.
- `para()` nunca devolve `null`: lança o erro nomeado. `TERRENO_ESCALA_SEM_TABELA` cobre uma escala que o pacote
  não tenha.
- Ao preparar o pacote, cada par de lados que a tabela promete tem de encaixar numa rede. Um pacote incoerente não
  se prepara.

### Medições

**A prova da ordem: 25 × 25 com o servidor de verdade.** É `provar_terreno_servidor.gd`. O núcleo `sala.js` com o
pacote, chamado por `juizo-terreno.mjs`, é comparado com a arena do jogo aberta com o mesmo snapshot, casa a casa.
A altura e o pé comparam-se pelos bits do double, como na Ordem 44. Nos casos «auto», o Mestre tenta pôr uma
figura em **cada** casa que o servidor julga bloqueada.

| grelha | desvio da altura | desvio do pé | bloqueadas no servidor | juízo / motivo diferente | recusas, todas com o motivo do cliente | mover (bloqueadas no cliente) |
|---|---|---|---|---|---|---|
| **25 × 25 de 1,5 m** | **0 m** (625 casas) | **0 m** | 10 (água ×2, escarpa ×8) | 0 / 0 | 10 | 51 (0) |
| **25 × 25 de 1 m** | **0 m** | **0 m** | 0 | 0 / 0 | 0 | 91 (0) |
| **25 × 25 de 2 m** | **0 m** | **0 m** | 41 (água, menir, tronco, escarpa, lanterna, santuário) | 0 / 0 | 41 | 21 (0) |

Os outros 9 casos também passam: 30 × 30 de 1,5 e 2 m, 20 × 20 de 1,5 m, 21 × 17 de 1 m, 33 × 27 de 2 m,
44 × 20 de 1,5 m, 50 × 50 de 1,5 e 1 m, e 37 × 37 de 2 m. Em todos:

- o desvio da altura e do pé é 0 m;
- há 0 bloqueios e 0 motivos diferentes, e 0 coberturas afirmadas diferentes;
- todas as recusas trazem o motivo que o cliente desenha (88 na 50 × 50 de 1,5 m, 133 na 50 × 50 de 1 m);
- as figuras desenhadas estão no `peM` do servidor, com desvio 0 m;
- os marcos que bloqueiam batem.

O detalhe está em `provas/ordem-48-terreno/medicao-terreno-qualquer-grelha.json`, casa a casa (com os bits) nas
três 25 × 25.

**Regressão contra o pacote da Ordem 44.** Comparei o pacote antigo (`8cd941d`, 6 grelhas feitas uma a uma) com o
recorte novo das mesmas 6 grelhas, bit a bit:

- alturas: 0 diferenças;
- pé: 0 diferenças;
- bloqueio e motivos: 0 diferenças;
- cobertura fora da faixa da borda: 0 diferenças.

**Regressão na zona livre.** A grelha de sempre, 20 × 20 de 1,5 m, com e sem terreno, dá as mesmas opções de mover
e o mesmo hash de estado, também depois de o Mestre passar a escala a 2 m e a 1 m. Há dois testes, o da Ordem 44
e um novo da Ordem 48. A 20 × 20 tem 0 casas bloqueadas, de 1,5 m e de 1 m.

**O ecrã do Mestre.** `provar_mestre_no_relevo.gd` lia o pacote antigo. Agora pergunta ao servidor de verdade e
compara pelos bits: Mestre − servidor dá 0 m no centro e no pé, nas grelhas 20 × 20 e 30 × 30, e as casas
bloqueadas são 43 no Mestre, 43 no jogador e 43 no servidor.

## Parte B: a `exportar_terreno()` antiga

**Apagada, em vez de delegar.** As razões:

- ninguém a chamava (o `git grep` só a encontra na definição e em documentos históricos);
- dava números que não são os do jogo: alturas ao centímetro, a casa do mapa em vez da casa do jogo, e sem o pé
  da Ordem 44;
- delegar obrigaria a grelha do mapa, um `RefCounted`, a depender de uma ferramenta que abre a arena do jogo.

No sítio dela ficou uma nota a dizer onde está o terreno do servidor.

**A guarda apanhou a mudança.** Com a fonte mudada e o pacote por refazer, o `rodar_testes` ficou vermelho com o
nome da fonte: «… em dia com as fontes do cliente: mapa/floresta/grelha_floresta.gd» (176/177, saída 1).
Reexportado, só o cabeçalho do pacote muda (o SHA); os dados são os mesmos, e o `rodar_testes` voltou a 177/177.

**As fontes com SHA passam de 5 a 6.** São o relevo, a grelha do mapa, o campo, as formas, o assentamento e o
próprio exportador. O exportador decide a forma do pacote, a zona de referência e a faixa da borda: mudá-lo sem
reexportar tem de dar vermelho.

## Parte C: a conferência completa como script local

Corre-se com um comando:

```
node rascunhos/servidor/ferramentas/conferir-terreno.mjs [--godot=…]
```

Faz duas conferências:

1. **As fontes**, só com Node: o SHA de cada uma contra o cabeçalho do pacote. A lista das fontes é lida do
   exportador, para não haver duas.
2. **O pacote**, com o Godot: refaz o pacote inteiro (`exportar_terreno.gd -- --conferir`) e compara-o byte a byte.
   O `--conferir` diz que fontes mudaram e que partes do pacote diferem.

Está documentado em `rascunhos/servidor/dados/README.md`, o README do terreno, novo. Corri-o nesta máquina:

| situação | saída |
|---|---|
| árvore limpa | **`TERRENO EM DIA`**, saída 0 (37 s) |
| `RAIO_PEGADA_FRAC` 0,28 → 0,29 no `assentamento.gd`, sem reexportar | **`TERRENO_DESACTUALIZADO`**: «a fonte cenas/arena/assentamento.gd mudou desde a exportação», «a parte «redes» do pacote difere do que o cliente gera hoje»; saída 1 |
| uma linha de comentário no `relevo_floresta.gd` | **`TERRENO_DESACTUALIZADO`**: «a fonte mapa/floresta/relevo_floresta.gd mudou desde a exportação»; saída 1 |
| Godot inexistente (`--godot=` errado) | `GODOT_FALHOU` (ENOENT); saída 1 (sem Godot nenhum: `GODOT_NAO_ENCONTRADO`) |

As mudanças de teste foram desfeitas com `git checkout`. Não toquei nos workflows: o CI continua a apanhar um
pacote velho pela guarda das fontes no `rodar_testes`.

## Provas corridas no fecho

**Cliente, sem janela (Godot 4.7.2), na ponta `b0da90e`:**

| suite | resultado |
|---|---|
| `abrir_scripts` | 68 scripts, 0 falhas (67 + a sonda nova) |
| `rodar_testes` | **177/177** (176 da Ordem 45: as 3 da guarda do terreno passam a 4) |
| `pecas_mestre` | 236/236 |
| `clima_forte` | 119/119 |
| `hud_acoes` | 32/32 |
| `abrir_clareira` | 22/22 |
| `abrir_mestre` | 57/57 |
| `canario_privacidade` | 10/10 |
| `medir_mestre`, `medir_painel_config` | 0 falhas |

Nenhuma suite teve SCRIPT ERROR. Também correram:

- o arranque `--quit-after 600`: «pronto», 0 erros;
- `provar_terreno_servidor`: TUDO PASSOU (12 grelhas);
- `provar_mestre_no_relevo`: TUDO PASSOU;
- `sondar_zonas_terreno`: 42 zonas, nenhuma contradiz;
- o conferir: EM DIA.

**Servidor (como o CI, com `--permission`):** 355 testes, **345 passam, 0 falham**, 10 saltados (os
condicionais que já existiam). Os 345 são os 338 da Ordem 44 mais 7: os 8 testes novos da Ordem 48, menos 1 da
Ordem 44 que afirmava a queda silenciosa e foi substituído.

**Ponta a ponta** (servidor Node de verdade com o terreno, jogadora Node, Mestre Godot, motor falso):
**17/17**, jogadora OK, nenhum canário. O VLAB real fica para o CI.

**CI:** ver «O CI» abaixo.

## O CI

- **Partes A, B e C (runs 43700926678, 43701034311, 43701314240):** 8 dos 9 jobs verdes. O `retoma-pc` estava
  vermelho porque as listas da retoma só se refazem no fim (o job confere que batem).
- **Commit das listas, `8d43087` (run 43701801103): verde, os 9 jobs.** São `servidor`, `validador-glb`,
  `motor-real`, `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta` (motor falso e VLAB real), `retoma-pc` e
  `foto-mestre`. É o código todo da ordem. Os commits seguintes só trazem este documento e as listas.

## O que ficou

1. **A cobertura na faixa da borda não é servida abaixo de 2.** O servidor devolve `null` nas casas a 1,35 m ou
   menos da borda cuja cobertura no mapa de referência é 0 ou 1. Torná-la exacta pedia que o servidor soubesse o
   que o cliente planta fora de cada zona, e isso muda com a semente. As regras ainda não usam a cobertura (ponto 2
   da Ordem 44), por isso nada no jogo muda. Quando a cobertura entrar nas regras, é aqui que se decide: ou o
   cliente deixa de plantar à volta da zona (é visual: outra ordem), ou o servidor trata o `null` como «até 2».
2. **As salas nascem com casas de 1,5 m.** Com terreno, o tamanho tem de caber a 1,5 m (até 50 × 50). As grelhas
   de 51 a 75 casas de lado com casas de 1 m existem no pacote e recortam-se, mas não há como criar uma sala
   nelas (a config não tem escala de nascimento). Isto falha com nome, não em silêncio.
3. **Grelhas maiores do que o mapa** (mais de 75 m) não se servem: falham com nome. O cliente desenha relevo para
   lá do mapa, mas o mapa e os bloqueios acabam nos 75 m.
4. **Altura e cobertura nas regras** (desnível no custo do mover, alcance com altura, cobertura no ataque):
   continua por fazer. É desenho de regra.
5. **A conferência completa não corre no CI**: precisa de ~40 s de Godot. É por ordem expressa (não tocar nos
   workflows). O CI tem a guarda das fontes.

## Resíduos honestos

- **O pacote cresceu de 175 kB para 658 kB.** As redes de 1 m são 22 201 casas, e cada reexportação deixa um blob
  desse tamanho na história do git.
- **O limite de 1,35 m é uma conta à mão.** Vem das regras do `campo_floresta.gd` (alcances das coberturas contra
  as folgas da zona). Está explicada no exportador e confirmada pela sonda (42 zonas, maior alcance visto 0,75 m),
  mas não é derivada do código. Se o campo mudar essas regras, o SHA do `campo_floresta.gd` põe a guarda vermelha
  e a sonda tem de voltar a correr.
- **A garantia do bloqueio é uma conta mais uma sonda, não uma prova formal para todas as zonas.** A conta é a de
  cima («O que encontrei»); a sonda cobre 42 zonas e a prova cliente↔servidor 12. Uma mudança no gerador do mapa
  muda o SHA do `campo_floresta.gd`, e o `rodar_testes` fica vermelho até se reexportar.
- **A fixture do Mestre no Windows.** `servidor/dados-exemplo/mesa-mestre.json` aparece modificado na cópia local:
  só os fins de linha mudam, como a Ordem 44 descreveu. Não a commitei.
- **Node 26 local.** Com `--permission`, os testes de WebSocket precisam de `--allow-net` (o CI usa o Node 24).
- **O Godot de consola não está na bancada.** Em `C:\Users\txcga\godot-472\` só está o
  `Godot_v4.7.2-stable_win64.exe`. Com `--headless` escreve no terminal na mesma, e todas as corridas usaram-no.
- **Onde fica este documento.** A ordem pôs o ESTADO em `rascunhos/cliente/mapa/floresta/`, e é lá que está; os
  ESTADOs das Ordens 44 e 45 estão na raiz. Como fica dentro de `rascunhos/`, as listas da retoma refizeram-se
  outra vez depois dele.
- **Documentos antigos.** `cenas/arena/NOTAS-MEDICAO-ORDEM-42.md` e o `ESTADO-FINAL-ORDEM-44.md` ainda nomeiam a
  função apagada. Não os editei, porque são registos do que foi.
- **Higiene.** Os rascunhos e os registos ficaram em `C:\Users\txcga\fable-mapa\_tmp\o48\`. Conferi com
  `git diff --name-only 8cd941d HEAD`: nada da pasta `referencias-arvore-ancestral/`, nenhum `.avi` e nada de
  `_tmp` nos commits. Não toquei em `main`, nos outros ramos nem nos workflows. O push foi normal, sem força.

## Retoma

A ordem está fechada; não há trabalho a meio. Para conferir o estado, corre-se na raiz:

```
node rascunhos/servidor/ferramentas/conferir-terreno.mjs
```

Deve dizer `TERRENO EM DIA`.
