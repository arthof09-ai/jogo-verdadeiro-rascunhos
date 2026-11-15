# Ordem 44: o terreno no servidor e o pé das figuras nas encostas. ESTADO FINAL

*Fecho da ordem, 2026-11-14 (22:10–22:40), conta 1, Opus, segunda sessão. A primeira morreu às 19:01 no
limite das 5 horas. PCDANASA: RTX 4060, Godot 4.7.2 (Compatibility), Node 26 local. Ramo
`fable/servidor-terreno-44`, tirado de `c7bf15b` (ponta da Ordem 42). As duas partes estão feitas,
commitadas e empurradas. O veredicto visual é do Mestre; o que está «provado» abaixo foi corrido ou visto
por mim nesta máquina, e o resto está dito.*

## A sucessão: o que encontrei e de onde continuei

A primeira sessão não fez nenhum commit. O ramo estava criado no `c7bf15b`, com este trabalho por
commitar:

- a regra do assentamento (`assentamento.gd`);
- a arena ligada a ela;
- o exportador do terreno;
- o pacote `terreno-floresta.json`;
- o núcleo `terreno.js`, a sala e o adaptador ligados a ele;
- os 7 testes do servidor;
- a ferramenta `juizo-terreno.mjs`, que apontava para uma prova do cliente que ainda não existia.

Antes de continuar conferi o que ela deixou:

- o exportador em `--conferir` deu **EM DIA**: o pacote é o que o cliente gera hoje, byte a byte;
- a suite do servidor passou, a menos de uma fixture que só falha por fins de linha (ver «Resíduos»).

Não apaguei nem refiz nada do que ela fez. Continuei a partir daí:

- a prova cliente↔servidor;
- a medição do pé reescrita para a base inclinada;
- os testes do cliente;
- as capturas;
- os commits, o push e este documento.

## O que mudou (commits)

| commit | o quê |
|---|---|
| `9abe814` | **Parte B.** A regra única do assentamento (`cenas/arena/assentamento.gd`): a base inclina-se com a encosta. A arena desenha com ela (mancha de base 080c12 a 35 %, corpo a prumo que sobe o justo). `provar_assentamento.gd` mede antes e depois com uma régua independente. |
| `fa1bc2a` | **Parte A.** O exportador (`cenas/arena/ferramentas/exportar_terreno.gd`), o pacote `servidor/dados/terreno-floresta.json`, o núcleo `nucleo/terreno.js`, a sala que julga o terreno, o adaptador e o e2e que o carregam, `testes/ordem44-terreno.test.mjs`, a ferramenta `ferramentas/juizo-terreno.mjs`, a prova `provar_terreno_servidor.gd` e os testes novos do `rodar_testes.gd`. |
| `e67e135` | As provas para o Mestre (`provas/ordem-44-terreno/`): 21 capturas etiquetadas, as duas medições em JSON e o README. Também a ferramenta `capturar_terreno_44.gd`. |
| `4297540` | Listas da retoma e MANIFESTO refeitos (`actualizar-listas.py`: 271 em `depois.txt`, 8 novos no MANIFESTO). |
| *(este)* | Este ESTADO FINAL. |

## Parte A: o terreno do mapa no servidor

**Como funciona.** Há uma só fonte de verdade, e nenhum número é escrito à mão.

1. A arena desenha com `assentamento.gd` e com o `Relevo`/`grelha_floresta.gd` do mapa.
2. O exportador abre a arena do jogo sem janela, para cada grelha, e escreve o pacote casa a casa com as
   mesmas funções:
   - a altura do centro (`arena.centro_casa`);
   - o pé da figura (`arena.pe_figura`);
   - o bloqueio do mapa e o motivo;
   - a cobertura.
3. Os números vão com 17 algarismos (o double que o cliente calcula). O pacote leva o SHA das 5 fontes de
   que depende.
4. O servidor lê o pacote. `prepararTerreno` falha fechado: um pacote com forma desconhecida não abre a
   sala.

O pacote tem 6 grelhas: 20 × 20 e 30 × 30, nas escalas de 1, 1,5 e 2 m.

**O que o servidor faz com ele.** Na grelha viva (tamanho e escala do momento), as casas bloqueadas não
se pisam, não se ocupam e não se atravessam. Isto vale para:

- o caminho e o alcance do mover;
- a colocação do Mestre;
- a primeira casa livre.

A recusa vai ao Mestre com nome, por exemplo `CASA_BLOQUEADA: (1,0) menir`. A altura e o pé de cada
casa ficam no juízo da sala (`depuracao.juizoTerreno()`). Sem pacote, ou sem a grelha viva no pacote, a
sala é exactamente a de antes.

**A função que a ordem pede.** A ordem nomeia `exportar_terreno()`. A `grelha_floresta.gd` já tinha uma
`exportar_terreno()`, da Ordem 38, mas arredonda as alturas ao centímetro e mede a casa do mapa, não a
casa do jogo. Com ela o desvio nunca daria 0, e ninguém a chama. A fonte do servidor é o exportador desta
ordem; a função antiga ficou intocada (ver «Resíduos»).

### Medição: cliente contra servidor

A prova é `provar_terreno_servidor.gd`. Chama o servidor de verdade (núcleo `sala.js` com o pacote),
abre a arena com o que o servidor mandaria e compara casa a casa. A comparação das alturas é feita pelos
bits do double, porque o analisador de JSON do Godot erra 1e-16 no último algarismo e uma prova de «0» não
pode depender disso.

| grelha | casas dentro da zona livre / fora | desvio da altura do centro | desvio do pé | figuras desenhadas vs `peM` do servidor | bloqueadas (juízo diferente) | recusas | mover oferecido (bloqueadas no cliente) | marcos que bloqueiam (batem) |
|---|---|---|---|---|---|---|---|---|
| 30 × 30 de 1,5 m | 400 / 500 | **0 m / 0 m** | **0 m / 0 m** | 14 figuras, **0 m** | 43 (0) | 4: menir ×2, santuário, água, todas bloqueadas no cliente com o mesmo nome | 41 (0) | 6 (6) |
| 30 × 30 de 2 m | 196 / 704 | **0 m / 0 m** | **0 m / 0 m** | 10 figuras, **0 m** | 42 (0) | 0 | 30 (0) | 4 (4) |
| 20 × 20 de 1,5 m (a de sempre) | 400 / 0 | **0 m** | **0 m** | 10 figuras, **0 m** | 0 (0) | 0 | 47 (0) | 0 |

Os motivos e a cobertura batem nas 2 200 casas. As figuras pedidas no teste incluem as 6 casas da
encosta (5–7 na grelha 30 × 30), o anel de fora e casas em cima de marcos. O detalhe casa a casa está em
`provas/ordem-44-terreno/medicao-terreno-cliente-servidor.json`.

### Regressão na zona livre

- O teste do servidor corre o mesmo combate na grelha de sempre com e sem terreno. As opções do mover e o
  hash do estado gravado são iguais, e as 400 casas pisam-se.
- O exportador confirma 0 casas bloqueadas em 20 × 20, como a Ordem 42 deixou.
- O e2e de ponta a ponta com o servidor de verdade (que agora carrega o terreno) dá 17/17.

**Guarda contra pacote velho.** O `rodar_testes.gd` confere que o SHA das 5 fontes no pacote é o de hoje.
Se alguém mudar o relevo, o mapa ou a regra do pé sem correr o exportador, o CI do cliente fica vermelho.

## Parte B: o pé das figuras nas casas inclinadas

**A decisão.** A figura não pode flutuar nem enterrar-se, e a leitura em jogo tem de ser limpa. Medi as
três saídas possíveis nas 6 casas:

| regra | enterra (pior) | flutua (pior) | serve? |
|---|---|---|---|
| base horizontal à média da pegada | 0,30 m | 0,30 m | não |
| base horizontal ao ponto mais alto | 0 | 0,60 m | não |
| **base inclinada com a encosta** | **0,020 m** | **0,019 m** | **sim** |

A base inclinada é o plano dos mínimos quadrados do relevo debaixo da pegada (centro e dois anéis de 16
pontos), deslocado para que o pior enterramento e a pior flutuação fiquem iguais (minimax). É a única
regra que cumpre numa encosta de 36°.

Para a leitura em jogo ficar limpa, só a mancha da base se inclina. O corpo de pé fica a prumo, porque
uma figura não se deita com a encosta, e sobe o justo para a cápsula tocar o plano sem o atravessar: até
0,097 m na casa pior. A figura caída deita-se no plano da base. Num chão plano tudo dá o mesmo que antes.

**Medição antes/depois.** A régua tem 129 pontos (centro e 4 anéis de 32 até 0,42 m), independente dos 33
do ajuste. Está em `provar_assentamento.gd`.

| casa | encosta | ANTES enterra / flutua | DEPOIS enterra / flutua |
|---|---|---|---|
| (0, 0) | 35,7° | 0,603 / 0,000 m | 0,004 / 0,004 m |
| (1, 0) | 33,2° | 0,549 / 0,000 m | 0,008 / 0,008 m |
| (2, 0) | 26,1° | 0,411 / 0,000 m | 0,013 / 0,013 m |
| (0, 1) | 34,9° | 0,585 / 0,000 m | 0,006 / 0,006 m |
| (1, 1) | 26,1° | 0,411 / 0,000 m | 0,017 / 0,017 m |
| (0, 2) | 25,4° | 0,399 / 0,000 m | 0,020 / 0,019 m |
| **as 6** | | **0,603 / 0,000 m** | **0,020 / 0,019 m** (limite 0,10) |
| **as outras 394** | | 0,341 / 0,003 m | **0,028 / 0,028 m** (limite 0,10) |

São as mesmas 6 casas que a Ordem 42 mediu (a régua dela dava 0,60 m na (0, 0)). As 49 figuras da prova
estão no pé da casa, com a base no plano da encosta: enterra até 0,025 m, flutua até 0,024 m. As 400 casas,
uma a uma, estão em `provas/ordem-44-terreno/medicao-pe-encosta-antes-depois.json`.

## Capturas para o veredicto do Mestre

Estão em `provas/ordem-44-terreno/`, com o README. As 21 imagens têm 1920 × 1080 e uma etiqueta no canto.

- **B01–B06 (depois) e B09–B14 (antes):** um grande plano de cada uma das 6 casas.
- **B07/B15 e B08/B16:** o grupo, de lado e de baixo, depois e antes.
- **A17–A21:** a grelha 30 × 30 com o que o servidor de verdade deu: as figuras, o mover da heroína e um
  poste vermelho, de pé na altura do servidor, em cada uma das 43 casas que ele julga bloqueadas.

O que vi com os meus olhos:

- **antes**, a encosta corta a cápsula de viés por baixo; **depois**, ela assenta inteira, com a mancha
  escura deitada na encosta;
- na roda dos menires, fora da zona livre, os destaques do mover que o servidor oferece param nas casas
  dos menires;
- os postes nascem do chão desenhado.

## Provas corridas no fecho (ponta `4297540`)

**Cliente, sem janela (Godot 4.7.2):**

| suite | resultado |
|---|---|
| `abrir_scripts` | 64 scripts, 0 falhas (60 antes, mais os 4 novos) |
| `rodar_testes` | **176/176** (167 da Ordem 42, mais 9 novas: pacote em dia e regra do pé) |
| `clima_forte` | 119/119 |
| `pecas_mestre` | 235/235 |
| `hud_acoes` | 32/32 |
| `abrir_clareira` | 22/22 |
| `abrir_mestre` | 57/57 |
| `canario_privacidade` | 10/10 |
| `medir_mestre`, `medir_painel_config` | saída 0 |

Nenhuma suite teve SCRIPT ERROR. Também correram:

- o arranque `--quit-after 600`: «pronto», 0 erros;
- `provar_assentamento` e `provar_terreno_servidor`: tudo passou;
- o `exportar_terreno --conferir`: em dia.

**Servidor (como o CI):** 348 testes: **338 passam, 0 falham**, 10 saltados (condicionais, que já
existiam).

**Ponta a ponta** (servidor Node de verdade, jogadora Node e Mestre Godot, motor falso): **17/17**,
jogadora OK, nenhum canário. O VLAB real fica para o CI.

**Com render:** `capturar_terreno_44.gd` fez 21 capturas, 0 erros.

**CI:**

- run da Sonda de privacidade 43663000824: verde;
- run dos «Testes dos rascunhos» 43663000763: verde (ver abaixo).

Resultado do run 43663000763 (ponta `4297540`): **verde, os 9 jobs**: `servidor`, `validador-glb`, `motor-real`, `protocolo` (schemas contra o tráfego, já com as recusas novas), `cliente`, `godot-cliente`, `ponta-a-ponta` (motor falso e VLAB real), `retoma-pc` e `foto-mestre`. O run do commit deste documento não mexe em `rascunhos/`.

## O que ficou por fazer

1. **Grelhas fora do pacote.** O servidor conhece as 6 grelhas exportadas. Num tamanho que não esteja lá
   (por exemplo, 25 × 25), a sala volta ao comportamento de antes: todas as casas se pisam, enquanto o
   cliente desenha o relevo e os marcos. Fica coberto pelo teste «sem a grelha no pacote». Para fechar,
   juntar os tamanhos que o Mestre usa à lista `GRELHAS` do exportador (cada grelha custa ~3 s e ~30 kB)
   ou passar a exportar o mapa de 50 × 50 e fazer o recorte no servidor.
2. **Altura e cobertura nas regras.** A altura, o pé e a cobertura estão no servidor (`juizoTerreno`) mas
   ainda não entram nas regras: desnível no custo do mover, alcance com altura, cobertura no ataque.
   Também não vão no protocolo, porque o cliente calcula o mesmo. É desenho de regra, não desta ordem.
3. **`--conferir` no CI.** O CI guarda o SHA das 5 fontes. A conferência completa (refazer o pacote e
   comparar) só corre à mão, porque precisa de abrir a arena 6 vezes (~20 s). Não toquei nos workflows.

## Resíduos honestos

- **Fixture do Mestre no Windows.** `servidor/dados-exemplo/mesa-mestre.json` falha localmente com
  `core.autocrlf=true`: o checkout põe-no em CRLF e o teste compara bytes. Regenerado, o `git diff` dá
  vazio (só os fins de linha mudam). No CI (Linux, LF) passa. Deixei a cópia local em LF e não a commitei.
- **Node 26 local.** Com `--permission`, o Node 26 fecha também a rede: os 7 testes de WebSocket dão
  `ERR_ACCESS_DENIED`. Com `--allow-net` passam todos. O CI usa o Node 24 e não é afectado.
- **A função antiga.** A `exportar_terreno()` da `grelha_floresta.gd` (Ordem 38, alturas ao centímetro)
  ficou intocada e sem uso. Mexer-lhe mudava uma das 5 fontes do pacote. Ou se apaga, ou passa a delegar
  no exportador numa próxima ordem.
- **A ferramenta do servidor** (`juizo-terreno.mjs`) escreve o JSON só em ASCII, por causa da
  descodificação do stdout no Windows, e manda os bits de cada altura. É só para a prova; a sala não muda.
- **Capturas do «antes».** Foram desenhadas na arena actual, aplicando a regra da Ordem 42 às figuras (pé,
  corpo a 0,85 m, sem mancha de base). Não são da build do `c7bf15b`. A forma é a mesma; a mancha de base
  não existia antes.
- **Relva nos grandes planos.** A relva alta da encosta tapa parte dos grandes planos. Pus a câmara 1,3 m
  acima do pé, um pouco de cima; as vistas do grupo lêem-se melhor.
- **Blender:** não lhe toquei, e o guia das extensões não foi preciso.
- **Higiene:** os rascunhos e os registos ficaram em `C:\Users\txcga\fable-mapa\_tmp\o44\`. Nada em `/tmp`
  e nada da pasta `referencias-arvore-ancestral/`, de `.avi` ou de `_tmp` nos commits (conferido pelo
  `git diff --name-only c7bf15b HEAD`). Não toquei em `main`, nos outros ramos nem nos workflows. O push
  foi normal, sem força.
