# ESTADO FINAL — ORDEM ESCALA (Claude conta 2, PC · 20/11/2026)

Ordem: a escala do mundo no jogo verdadeiro — **1 · 1,5 · 2 m por casa, pré-definida 1,5 m**, escolhida pelo Mestre
(como no protótipo, `hudt1-escala`; decisão do Mestre de 20/11/2026). Base: `fable/integracao-50` @ `87197f1`.
Ramo: `claude2/escala`. Marcas: VERIFICADO (conferido nesta sessão), PENDENTE (com a razão), [FALTA] (sem fonte).
Regime: EM_USO (o PC estava a ser usado para jogar) — só código e verificações curtas, sem GPU (Godot só `--headless`).

## 0. O que se encontrou (antes de mexer)

A escala do mundo **já era um parâmetro vivo no servidor e já tinha selector do Mestre** — trabalho das Ordens 8, 11,
48 e 62 do CM-000009:
- servidor: `nucleo/sala.js` `ESCALAS_CASA_M = [1, 1.5, 2]` e `CASA_M = 1.5` (a sala nasce aí); a escala viva é
  `mapa.casaM` do mundo, lida por `casaDe(m)` em **todas** as contas: deslocamento (`maxCasas = floor(reservaM / casaM)`,
  `custoM = casas × casaM`), alcance (`max(1, alcanceM / casaM)` casas pelo caminho), ataque de oportunidade, terreno
  (`terrenos.para(largura, altura, casaM)`), journal/restauro e «voltar»;
- op `MASTER_SUPERVISOR {op: 'escala', casaM}` — só do Mestre, sem custo, recusa outros valores (ESCALA_INVALIDA) e
  escalas em que a grelha não cabe no mapa ou deixa figuras em casas bloqueadas;
- **o terreno do servidor já acompanha a escala** (o aviso da Passagem do HUD): `servidor/dados/terreno-floresta.json`
  tem uma tabela de origens por escala (1 / 1,5 / 2) e o servidor recorta a grelha viva para a escala viva;
- protocolo: `MASTER_SUPERVISOR.schema.json` `casaM ∈ {1, 1.5, 2}`; `mapa.casaM` no ROOM_SNAPSHOT / MASTER_VIEW;
- cliente: o selector do Mestre (`cenas/mestre/mestre.gd`, aba Sala: «Escala: X m por casa», − / + e «Mudar a escala»
  com segundo toque) e as duas arenas (`arena.gd`, `arena_mestre.gd`) já redesenham a grelha com `mapa.casaM`;
- a jogadora vê a vigente só pelo efeito (a grelha e os metros do HUD); não a muda.

O que **faltava** à letra da ordem: no cliente a escala não vivia num sítio único — a lista estava em `mestre.gd`
(`ESCALAS := [1.0, 1.5, 2.0]`) e havia **seis 1,5 soltos** como escala por omissão (`mestre.gd`, `arena.gd` ×2,
`arena_mestre.gd` ×3) fora da tabela DADOS (`dados/apresentacao.gd`, que já tinha `CASA_M = 1.5`); e não havia uma prova
automática da distância conhecida (6 m → 6 / 4 / 3 casas). Foi isso que esta ordem fez.

## 1. O que mudou (ficheiro a ficheiro)

### Cliente Godot — VERIFICADO
- `rascunhos/cliente/dados/apresentacao.gd` (a tabela DADOS — a fonte que a casa já usava): novo
  `ESCALAS_CASA_M := [1.0, 1.5, 2.0]` ao lado de `CASA_M := 1.5` (a pré-definida), com o comentário da decisão e o par
  do servidor. A linha «Casa: a ordem diz 1,0 m…» das `PENDENCIAS` fica **FECHADA** com a palavra do Mestre (20/11).
  As outras pendências (as 6 cores [FALTA] da paleta incluídas) **não foram tocadas**.
- `rascunhos/cliente/cenas/mestre/mestre.gd`: `ESCALAS := Apresentacao.ESCALAS_CASA_M` (o selector anda na lista da
  tabela); `escala_atual()` sem escala do servidor devolve `Apresentacao.CASA_M` (era `1.5`).
- `rascunhos/cliente/cenas/arena/arena.gd`: `casa_m` nasce em `Apresentacao.CASA_M`; `_construir_grelha` cai em
  `Apresentacao.CASA_M` com escala inválida (eram `1.5`).
- `rascunhos/cliente/cenas/mestre/arena_mestre.gd`: a grelha inicial é
  `GRELHA_LARGURA_PADRAO × GRELHA_ALTURA_PADRAO × CASA_M` da tabela (era `20, 20, 1.5`); `construir_grelha` e
  `aplicar_vista` caem em `Apresentacao.CASA_M` (eram `1.5`).
- `rascunhos/cliente/testes/rodar_testes.gd`: `_teste_escala_do_mundo` (22 verificações, corre no CI no passo já
  existente — **não foi preciso mexer no workflow**).

Os valores são os mesmos (1,5 → `CASA_M` = 1,5; 20 → `GRELHA_*_PADRAO` = 20): a 1,5 m o código faz o mesmo de antes.

### Servidor — VERIFICADO
- Nenhuma mudança de código: a fonte única já era `sala.js` (`ESCALAS_CASA_M`, `CASA_M`) e todas as contas passam por
  `casaDe(m)`. Auditado (grep de `1.5` / `CASA_M` / `casaM` em `nucleo/`, `motores/`, `adaptadores/`, `autojogo/`): o
  único `CASA_M` fixo usado é o da sala que nasce (`construirEstadoInicial`) e o do motivo do terreno à criação — os dois
  são a pré-definida, como manda a ordem.
- `rascunhos/servidor/testes/ordem-escala.test.mjs` (novo, 9 testes; entra no CI sozinho por `testes/*.test.mjs`).

### Repositório
- `provas/ordem-escala/suites/` — os registos das suites corridas nesta sessão.
- `MANIFESTO-SHA256.txt`, `retoma-i0004/depois.txt` — refeitos com `retoma-i0004/actualizar-listas.py`.

## 2. As provas (com números)

### (a) Regressão a 1,5 m — VERIFICADO
- Servidor, todas as suites: **389/389** (as 380 de antes + 9 novas), 0 falhas, 0 saltados
  (`provas/ordem-escala/suites/servidor-todos.txt`).
- Conferência dos schemas com o tráfego de todos os testes (`PROTOCOLO_DUMP` + `conferir-schemas.py`): **0 falhas nas
  mensagens que saem** do servidor (`conferir-schemas.txt`).
- Cliente headless (Godot 4.7.2, sem GPU): `rodar_testes.gd` **265/265** (243 de antes + 22 novas);
  `abrir_scripts` limpo; `abrir_mestre` **67/67** (inclui o selector: «Escala: 1,5 m por casa», − / +, segundo toque →
  `MASTER_SUPERVISOR {op: 'escala', casaM: 2}`, pára em 1 m e em 2 m); `pecas_mestre` **286/286**; `hud_acoes`
  **50/50**; `caixa_jogadora` **16/16**.
- Teste novo (a): a sala nasce a 1,5 m no lobby e no combate; a jogadora recebe `mapa.casaM = 1.5`.
- «Pixel a pixel»: provado por **igualdade de valores**, não por captura — cada 1,5 / 20 substituído é a constante da
  tabela com o mesmo valor (o teste confere `CASA_M == 1.5`). Capturas lado a lado não foram tiradas (GPU; ver §4).

### (b) 6 m a 1 m e a 2 m (e a 1,5 m) — VERIFICADO
Servidor (`ordem-escala.test.mjs`, heroína com 6 m de deslocamento e técnica de 6 m de alcance):

| escala | 6 m cobrem | opções de mover (casa mais longe) | mover N casas | mover N+1 | técnica de 6 m a N casas | a N+1 |
|---|---|---|---|---|---|---|
| 1 m   | **6 casas** | custo 6 m (6 × 1)   | APLICADA, reserva 0, andou 6 m | recusada | ao alcance | fora |
| 1,5 m | **4 casas** | custo 6 m (4 × 1,5) | APLICADA, reserva 0, andou 6 m | recusada | ao alcance | fora |
| 2 m   | **3 casas** | custo 6 m (3 × 2)   | APLICADA, reserva 0, andou 6 m | recusada | ao alcance | fora |

Cada opção de mover confere `custoM = casas × escala`. Cliente (`_teste_escala_do_mundo`, a geometria das arenas —
`Assentamento.centro_casa`/`origem_no_mapa`, as funções que `arena.gd` e `arena_mestre.gd` usam): do centro da casa 0
ao centro da casa N vão **6,000 m** com N = 6 / 4 / 3; a grelha de 20 casas mede 20 / 30 / 40 m.

### Fonte única — VERIFICADO (`_teste_escala_do_mundo`)
- a tabela tem `[1.0, 1.5, 2.0]` e a pré-definida 1,5 é uma delas;
- o servidor diz o mesmo (lido de `servidor/nucleo/sala.js`: `ESCALAS_CASA_M` e `CASA_M`);
- o selector do Mestre (`mestre.gd ESCALAS`) é a lista da tabela; o exportador do terreno (`exportar_terreno.ESCALAS`) e
  o pacote do terreno do servidor (`terreno-floresta.json`, `escalas[].casaM`) cobrem exactamente as três;
- o Mestre vê a pré-definida sem escala do servidor e a escala viva quando ela vem (1 / 1,5 / 2);
- nenhum `1.5` em `arena.gd`, `arena_mestre.gd`, `mestre.gd`, `hud.gd`, `estado.gd`.

### Persistência e só o Mestre — VERIFICADO (`ordem-escala.test.mjs` (c) e (d))
- Persistente na partida: a escala fica depois de encerrar a vez; a jogadora que sai e volta recebe-a no snapshot; a
  sala **restaurada do journal** (`criarSala({restaurarDe: sala.exportar()})`) reabre a 2 m.
- A jogadora que manda `MASTER_SUPERVISOR {op: 'escala'}` é recusada; a escala fica.

### (c) Privacidade — VERIFICADO
- `canario_privacidade.gd` **10/10**; `testes/privacidade.test.mjs` (servidor) dentro dos 389.
- Teste novo (d): depois de o Mestre mudar a escala, jogadora e espectador recebem `mapa.casaM` e o evento `escala`
  **vazio**; o varrimento de canários (números do monstro: CA, Vida, PA; `ESCALA_`; `casaMAntes`, `casasQuePaga`) dá
  **0 achados**; sanidade: o Mestre recebeu o `casaMAntes` (o varrimento não varre o vazio). Nada de vida/alma à jogadora.

### (d) CI — VERIFICADO
Verde em `66e637c` antes da fusão (ver §3).

## 3. CI e fusão — VERIFICADO
- Commits no ramo `claude2/escala`: `084b690` (código + provas) · `66e637c` (listas da retoma e MANIFESTO). Sem mudança
  no workflow (os dois testes novos entram nos passos que já existiam).
- CI em `66e637c`: **Testes dos rascunhos** run 44809719535 — **9/9 jobs verdes** (servidor, protocolo, motor-real,
  ponta-a-ponta, retoma-pc, cliente, godot-cliente, foto-mestre, validador-glb); **Sonda de privacidade** run
  44809719584 — verde.
- Fusão **fast-forward** `87197f1..66e637c -> fable/integracao-50`, só depois do CI verde (a linha estava em `87197f1`,
  conferido com `git ls-remote` antes de empurrar). Depois, este ESTADO FINAL nas duas pontas.

## 4. O que NÃO foi medido
- **Capturas** a 1 m / 1,5 m / 2 m (arena da jogadora e do Mestre): não tiradas — GPU proibida no regime EM_USO. A
  regressão a 1,5 é por igualdade de valores e pelas suites; o desenho a 1 m e a 2 m é provado pela geometria e pelos
  testes antigos das arenas, não por olho.
- A prova do cliente com servidor de bancada real a mudar a escala a meio (como a da CAIXA-HUD-JOGADORA): não feita.
- `abrir_clareira.gd`, `medir_mestre.gd`, `medir_painel_config.gd`, `foto_mestre.gd` e os vídeos: não corridos aqui
  (correm no CI os que lá estão; os vídeos/fotos precisam de GPU). A Clareira já lia `Apresentacao.CASA_M`.
- O passo «na vez seguinte, 3 casas de 2 m» do teste (c) só se confere se a vez voltar à heroína dentro do teste (com o
  motor falso em auto pode não voltar); a persistência está provada pelos outros três pontos.

## 5. Passagem

**Onde parou:** ordem cumprida — código, provas, CI verde e fusão em `fable/integracao-50` (§3).

**A escala e o mapa — o ponto registado, e parado aí (fronteira da ordem):**
- A **malha do mapa** (`mapa/floresta/grelha_floresta.gd CASA_M` e `relevo_floresta.gd CASA_M`, 1,5 m; o mapa tem
  50 × 50 casas de 1,5 m) **não é a escala do mundo**: é a resolução do relevo e das casas bloqueadas do terreno. Não
  muda com a escala — o servidor recorta a grelha viva do mapa inteiro para cada escala. Esses ficheiros, o
  `assentamento.gd` e o `exportar_terreno.gd` são **fontes do terreno do servidor conferidas por SHA**: mexer-lhes obriga a
  refazer `servidor/dados/terreno-floresta.json`. Por isso o `exportar_terreno.ESCALAS` ficou como estava (a mesma
  lista) e o teste amarra-o à tabela, em vez de o religar.
- `Assentamento.origem_no_mapa` só alinha a grelha às casas do mapa quando a escala é 1,5 (a da malha). A 1 m e a 2 m a
  grelha fica centrada sem esse encaixe (comportamento das Ordens 42/48, intocado). Se o «todo o mapa jogável» (a ordem
  seguinte) fizer a grelha = o mapa, é aí que a malha do mapa e a escala se encontram: a 1 m ou 2 m a casa da batalha
  deixa de coincidir com a casa do relevo. **Decisão para essa ordem**, não desta.
- Tamanhos que cabem no mapa por escala (já recusados com nome pelo servidor, Ordem 48): 40 × 40 cabe a 1 e a 1,5 m,
  não a 2 m.

**Próximo passo:** a ordem «todo o mapa jogável» (decisão do Mestre de hoje), com o ponto acima à cabeça.

**O que falta conferir (coordenador / Mestre):**
1. O olho do Mestre: a grelha a 1 m e a 2 m na arena, quando o PC estiver livre (capturas com GPU).
2. Se a jogadora deve **ver** a escala vigente escrita no HUD (o protótipo deixa-a ver; hoje ela só a vê pelo efeito:
   a grelha e os «pode andar até X m»). A ordem diz «no máximo»; não acrescentei nada ao HUD para não mexer no ecrã dela
   a 1,5 m. O `mapa.casaM` já lhe chega (é público), por isso é só cliente.
3. Três cópias da lista que valem continuam a existir por razões de fronteira: `sala.js` (servidor), a tabela DADOS
   (cliente) e o `enum` de `MASTER_SUPERVISOR.schema.json` (protocolo) — mais `exportar_terreno.ESCALAS` (fonte do
   terreno, por SHA). O teste do cliente amarra as três do cliente/terreno ao servidor; o `enum` do schema é conferido
   pelo `conferir-schemas.py` no tráfego dos testes.
4. As pendências que **não eram desta ordem** continuam: as 6 cores [FALTA] da paleta, as 3 cores da caixa/retrato por
   ligar, o lago fora da grelha, quem roda a iniciativa, o `caixa_jogadora.gd` fora do CI (token sem `workflow`).
