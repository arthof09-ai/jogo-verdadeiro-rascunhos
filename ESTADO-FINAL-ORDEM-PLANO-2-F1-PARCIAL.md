# ESTADO FINAL (PARCIAL) — ORDEM-PLANO-2-F1 · A BATALHA QUE SE VÊ (D-AUD-05, D-AUD-12, D-AUD-15)

> **Corrigido no fecho (ORDEM-PLANO-2-F1-FECHO, F4, 26/11):** (a) «igual byte a byte» → as contagens da série 1..N são
> idênticas e os ficheiros diferem (§2.3); (b) «Suspeita AFASTADA» → suspeita não confirmada pela barra da ordem, com o
> sinal amarelo (§2.3); (c) «19 de 19 na ponta» e «corrida de dados na ponta» → `279f0d7` + o caso 10 (§2.1, §2.3); (d) o
> contador de falhas do `resumo.txt` (§3); (e) o `servidor.log` (446/446) no pacote (§3). O resto do texto é o de 26/11.
> O fecho está em `ESTADO-FINAL-ORDEM-PLANO-2-F1-FECHO.md`.

Dono: Muse (CM-000009). Linha `fable/integracao-50`, directamente na linha. Retoma de 26/11/2026 (14:17–14:40 -03), PC do
cunhado. A 1.ª corrida (23/11 21:37 → 24/11 02:11) morreu no limite semanal. O agente da sessão 1 ficou órfão até às
05:03, quando o vigia o parou (`AVISO-VIGIA-JANELA-2026-11-24-0453.txt`).

**Porque é PARCIAL:** falta a batalha de bancada **com vídeo dos dois ecrãs, na ponta actual**, e com ela as capturas do
terço central e as 20 medições seguidas do «na vez». Essa parte precisa da janela do PC. Na retoma a janela esteve
**fechada**: o agente escondido da sessão 1 leu `idle=0` às 14:2x e às 14:36. À frente estavam o Chrome (YouTube, depois
outro site), o Discord, o WhatsApp e, na 1.ª leitura, o jogo «ROB RUN». Não lancei a bancada (regra das ordens anteriores:
`ESTADO-FINAL-ORDEM-AUDITORIA-LINHA-PARCIAL.md`, «Janela fechou … NAO relancar a bancada»). O resto está feito e provado.

## 1. Base

- Medida ao arrancar a retoma: `git fetch` + `git ls-remote` → `279f0d71baa1f18e8a663b1685db50df75f5c74c` (a local estava em
  `e671f49`; fast-forward às 14:17:51). A D-AUD-04-BANCADA não foi reordenada.
- O código da F1 já estava na linha desde a 1.ª corrida: `4739849` (D-AUD-05 + D-AUD-12) e `db9564b` (listas).

## 2. O que está feito

### 2.1 D-AUD-05 — a câmara segue a figura (`4739849` + `4caa2f1`)

- `arena.gd`: `_focar_primeira_vez()` é chamado pelo snapshot **e** pelo evento. `_seguir_minha()` corre nos eventos
  `movimento`/`colocacao` da própria figura e só recentra quando ela sairia do terço central (`SEGUIR_SEMPRE := false`,
  `MEIA_JANELA_SEGUIR := 1/6`). Isto conserva o arrasto; o Panorama não muda. `camera_mesa.gd` não foi tocado.
- Teste `rascunhos/cliente/testes/camera_segue.gd`: **19 de 19** sobre `279f0d7` + o caso 10 (o caso 10 é o `4caa2f1`;
  corri-o antes de o cometer).
- **Achado da retoma, já corrigido no teste (`4caa2f1`):** a mutação SEM-FOCO-NO-EVENTO dava **17 de 17** no teste de 23/11.
  O seguir apanhava a colocação fora do terço central, e o «focar a primeira vez» do evento não tinha caso próprio. O
  caso 10 (a colocação dela numa casa que já se via no terço central) prova-o: com a mutação, 18 de 19.
- O passo do CI está em `provas/ordem-plano-2-f1/ci/passo-camera-segue.patch` (agora `19 de 19`, `git apply --check` OK) e
  **fica por aplicar**: o token deste PC não tem `workflow`. Até lá, o CI só corre o `camera_segue` dentro das suites do PC.

### 2.2 D-AUD-12 — as criaturas têm número (`4739849`)

- O `MASTER_PLACE` guarda `f.ordinal` (1 + o maior já dado ao mesmo nome público). `projecao.js` projecta «Orc 1», «Orc 2»
  no nome público e no verdadeiro (colocação, entrada, snapshot, vista do Mestre, journal). Sem o campo (salas e journals
  antigos), o nome fica como antes. `conferir-estado.js` aceita o campo (inteiro ≥ 1). O ordinal fica com a figura no
  «voltar» e no «Recomeçar» (`sala.js:2922`).
- Teste `d-aud-12-ordinal.test.mjs`. A mutação SEM-ORDINAL dá **3 pass, 5 fail**.
- Na bancada de 23/11: «Lobo 1», «Lobo 2», «Bruto 1» no journal; «Lobo de Bancada 2 (Lobo 2)» no tabuleiro e no Registo do
  Mestre (`corrida-23-11/capturas/d02-mestre-registo-fim.png`).

### 2.3 D-AUD-15 — os dados são justos (`279f0d7` + o caso 10, 26/11)

`provas/ordem-plano-2-f1/dados/` (ferramenta `ferramentas/dados-justos.mjs`, pelo caminho real do ataque:
`criarSala` → `ROOM_INTENT atacar` → `Vlab.resolverAtaque`, motor VLAB `a91c021c…`):

- **(b) Sequência registada reproduzida: 6/6** (seq 30, 45, 56, 67, 78, 89 → faces 10, 18, 18, 18, 18, 19; recibo e semente
  iguais). O ataque tira a face da **1.ª saída de `mulberry32(contexto.semente)`** (`vlab-completo.js:788-801`), sem
  sorteios antes. A simulação da auditoria usava o `xorshift32` da Parte C (`novoCursorC`, `:1115-1130`), que não é o
  gerador do ataque. Por isso dava 13, 15, 15, 15, 7, 16.
- **(a) Distribuição, N = 2 000 000 em cada série** (com 200 000, a barra seria só 1,2 σ):

| série | faces | maior desvio | barra ±0,06 pp | χ² (19 g.l.) | pares seguidos (399 g.l.) |
|---|---|---|---|---|---|
| sementes 1..N (repetível) | 4,966 % – 5,033 % | 0,034 pp | DENTRO | 31,97, p = 0,031 | p = 0,027 |
| CSPRNG do servidor (`rngNode`) | 4,973 % – 5,025 % | 0,027 pp | DENTRO | 16,96, p = 0,592 | p = 0,831 |

- **Veredicto: suspeita não confirmada pela barra da ordem (±0,06 pp); χ² p=0,031 e pares p=0,027 na série 1..N ficam
  registados como sinal amarelo.** Quatro ou mais faces iguais seguidas em 6 d20 têm probabilidade de 0,035 % pelo Monte
  Carlo da ferramenta (sem semente). O valor exacto é 29/80000 = 0,03625 % (F5, `dados/recontar/`).
  O journal privado da auditoria já não está no disco (saiu nas limpezas). Os 6 registos ficaram em
  `dados/registados-auditoria.json` (tirados dele em 24/11) e a ferramenta lê-os com `--registados`. Na série 1..N, as contagens de
  26/11 e de 24/11 (`dados/24-11/`) são idênticas. Os ficheiros diferem (ms, série CSPRNG, corrida4em6).

### 2.4 A batalha de bancada de 23/11 (sobre `4739849`) — feita, **sem vídeo**

Arranjo: grelha-mapa 50×50 @ 1,5 m (`bancada-rede`, banner «grelha-mapa da linha (50 x 50 casas de 1,5 m)»,
`tmp/lancar.log`), servidor de produção (`servidor-ws.js` via bancada) na porta 8791, motor real, «fichas acertam»,
2 clientes Godot reais: a jogadora em 1280×720 e o Mestre em 1600×900, no ecrã dele.

- **Acabou por morte**, não por «Terminar»: `fim {"desfecho":"morte"}` no seq 72. A Arqueira tem
  `estadoMorte {falhas: 3, sucessos: 1}` e vida 0. Pelo caminho viram-se ataques que acertam (incluindo um crítico),
  dano, a queda («A Arqueira de Bancada caiu — a batalha continua à volta dela»), o teste de morte e «Fim da batalha».
  Relato: `provas/ordem-plano-2-f1/corrida-23-11/relato-journal.md`.
- **0 colocações duplicadas** (4 colocações: 0 ids repetidos, 0 casas repetidas). Os journals das outras duas tentativas
  também dão 0.
- Terço central nas capturas da jogadora: arranque (640, 342) → (0,50; 0,48); depois do 2.º movimento (640, 352) →
  (0,50; 0,49). As duas estão dentro. No arranque a caixa (canto superior direito) não tapa a figura. O tamanho dos
  marcadores de alvo não foi medido.
- **Vídeo: não há.** O `gdigrab` recusou a área («Capture area … extends outside window area»). O vídeo de
  `tmp/vid/` (2 GB) é da 2.ª tentativa e o de `tmp/vid3/` (1,08 GB) é da 3.ª, parada na rodada 2. Nenhum mostra esta morte.

### 2.5 «Na vez» da caixa contra o banner (só medir; D-AUD-03 é da bancada do coordenador)

Medição **preliminar**, não as 20 vezes seguidas:

- Há concordância (23/11 `b17`: banner «A sua vez», caixa «Arqueira… na vez»).
- Há também discordância (24/11, sobre `e671f49`, `corrida-24-11/capturas/c01`, `c30`): banner «A sua vez», caixa
  «Bruto 1 na vez», e o Mestre a dizer «vez de Arqueira de Bancada». As 30 amostras dessa noite são todas do mesmo
  momento.

Isto não trava a entrega e vai para a bancada do coordenador (D-AUD-03).

## 3. Suites (neste PC, Godot 4.7.2 `--headless`, sobre `279f0d7` + o caso 10, que é o `4caa2f1`)

Guião `provas/ordem-plano-2-f1/suites.sh`. Os logs e o `resumo.txt` estão em `provas/ordem-plano-2-f1/suites/`.

| Suite | Resultado |
|---|---|
| servidor (`testes/*.test.mjs`, sem `--permission`, como nas ordens anteriores) | 446/446 (`suites/servidor.log`, no pacote) |
| motor real | 6/6 |
| prova da caixa | PROVA OK |
| `abrir_scripts` · `medir_painel_config` · `medir_mestre` · `aparelhos_f2` | exit 0 |
| `rodar_testes` | 333 de 333 |
| `abrir_clareira` | 22 de 22 |
| `abrir_mestre` | 67 de 67 |
| `pecas_mestre` | 336 de 336 |
| `hud_acoes` | 70 de 70 |
| `caixa_jogadora` | 70 de 70 |
| **`camera_segue`** | **19 de 19** |
| `caixa_janela` | 123 de 123 |
| **canário de privacidade** | **10 de 10** |
| `teste_relato_caixa` · `teste_nomes_relato` | 31 de 31 · 26 de 26 |
| validar-mensagens (pecas_mestre, abrir_mestre) | exit 0 · exit 0 |
| Sonda dos caminhos do PC | na cópia limpa: 0 novas, exit 0. Na árvore de trabalho deu exit 1 só por 5 ficheiros que o git ignora (`bancada-rede/privado/…/preparar.log` ×4 e `.godot/editor/project_metadata.cfg`). |

Todas as suites deram 0 `SCRIPT ERROR / Parse Error / Compile Error`. As mutações deram: SEM-FOCO-NO-EVENTO 18/19,
SEM-SEGUIR 15/19, SEM-ORDINAL 5 falhas. No `resumo.txt`, o contador de falhas conta testes falhados, não linhas `✖`.
O SEM-ORDINAL falha 5, não 11: as 11 linhas `✖` do log são 5 testes, o cabeçalho `✖ failing tests:` e os mesmos 5
repetidos no fim. Os três ficheiros foram repostos e o `git diff` ficou vazio.

Privacidade: só nomes fictícios (Arqueira de Bancada, Lobo, Bruto). Não há e-mails nas provas e os caminhos do PC saem
como `<sede>`.

## 4. Commits

| Commit | O quê |
|---|---|
| `4739849` | (23/11) D-AUD-05 + D-AUD-12 — código e testes |
| `db9564b` | (23/11) listas da retoma (2 novos, 0 tirados) |
| `4caa2f1` | (26/11) `camera_segue` com o caso 10 |
| `6c46c22` | (26/11) listas da retoma (0 novos, 0 tirados) |
| `5227011` | provas e este ESTADO-FINAL |
| (este) | a nota do CI |

## 5. O que falta (para a retoma com a janela aberta)

1. Uma batalha de bancada **na ponta**, acabada por morte e com vídeo dos dois ecrãs. O vídeo deve sair um por janela, ou
   com a área dentro do ecrã virtual, porque o erro de 23/11 foi a área sair do ecrã (`-1892,51` → `(-1920,0)-(1600,1080)`).
   A mesma batalha tem de dar 0 colocações duplicadas e as capturas do terço central no arranque e depois de cada movimento.
2. O «na vez» contra o banner em **20 vezes seguidas**, em vezes diferentes (não 20 amostras do mesmo momento).
3. O passo `camera_segue` no CI (`ci/passo-camera-segue.patch`), aplicado por quem tiver o âmbito `workflow`.

Ferramentas da 1.ª corrida, fora do repositório (`<sede>/tmp/`): `s1-agente.ps1` (tarefa agendada `Plano2F1BancadaS1`, input
só por PostMessage), `c.sh`, `journal.sh`, `ffmpeg.exe`. O agente ficou parado (`tmp/cmd/PARAR`).

## 6. Nota do CI

No `5227011`: **Testes dos rascunhos 45869295421 success**, **Sonda de privacidade 45869295432 success**, **Aparelhos (F2)
45869295437 success**. O job `retoma-pc` está verde: as listas do `6c46c22` batem. O CI ainda não corre o `camera_segue`
(o patch está por aplicar, §2.1).
