# ESTADO FINAL — ORDEM-PLANO-2-F1-FECHO · F1 (batalha na ponta com vídeo) + F2 («na vez» 20×) + F3 (patch do CI)

Linha `fable/integracao-50`, sem fusão. 26/11/2026, PC do cunhado. Sentença de origem: a conferência da retoma da F1,
**APROVADA COM RESSALVAS (entrega parcial), 817/1000**, com a adenda da sentença F1-F4-F5-F6 (886/1000). A sentença não
está neste PC (`~/workspace/conferencias/…` não existe aqui). Segui os textos citados na ordem.

**Resumo:** F1 feita: batalha na ponta, por morte, com vídeo dos dois ecrãs (um por janela), (a)–(g) com provas.
F2 feita: 20 medições, 6 concordam e 14 discordam; vão para a bancada do coordenador (D-AUD-03). F3 feita até onde a
credencial deixa: o patch passou a N de N e o README das provas foi actualizado, ambos enviados. O commit que aplica o
patch ao `testes.yml` está feito mas **por enviar**: o push foi recusado por falta do âmbito `workflow` (ver §3). Falta o
`gh auth refresh -h github.com -s workflow` pelo dono da conta.

## 0. Base, janela do PC e o que encontrei

- **Ponta ao arrancar (19:12):** `git fetch` + `git ls-remote` → `cf1d315` (ANDROID-SHADER E5, 18:58). Antes de lançar a
  bancada medi outra vez e era `c9fc4ab`, o meu commit F3 1/2, que só mexe em `provas/`. **As duas batalhas e a F2
  correram em `c9fc4ab`.**
- **PC livre:** medido na sessão 1 (o ambiente de trabalho real), com o agente da tarefa `Plano2F1BancadaS1`. O Claude
  corre na sessão 0, onde o ecrã aparece como «WinDisc» 1024×768 e o gdigrab dá o erro 5. Isto não quer dizer que o
  monitor esteja desligado. Às 19:16 o idle era de 11 002 s (≈ 3 h). O Chrome «YouTube» estava minimizado, a janela da
  frente era a barra de tarefas e só os nossos Godot usavam a GPU. Cada passo da bancada verificava o idle antes de agir:
  `Guarda`, ≥ 120 s, e ≥ 300 s para lançar. O idle nunca baixou: 11 876 s no fim. O Daniel não voltou durante o trabalho.
- **Uma corrida anterior desta ordem** (16:52–17:08, noutra sessão) jogou uma batalha no `e89235a`, também por morte e com
  vídeo. Começou a F2 e parou pelo limite de 5 h, deixando **dois ffmpeg a gravar há 2 h** (1,8 GB) e a bancada aberta.
  Matei os ffmpeg; esses mp4 não têm fim e não servem. Fechei essa bancada e o journal parcial dela ficou guardado na sede
  (`tmp/f2-parcial-17h04/`). A batalha do `e89235a` ficou fora do pacote porque a ponta mudou entretanto.

## 1. F1 — batalha na ponta com vídeo

Provas em **`provas/ordem-plano-2-f1-fecho-video/`** (o `README.md` é o índice). Corrida das **19:29:09–19:31:19 -03** em
`c9fc4ab`. Servidor de produção `servidor-ws.js` com o VLAB real (`a91c021c…`) e as fichas «acertam», modo auto,
grelha-mapa 50×50 @ 1,5 m, 2 clientes Godot 4.7.2 reais.

**Vídeo — um por janela, as duas áreas dentro do ecrã virtual** `(-1920,0)-(1600,1080)`:

| | área | ficheiro (na sede) | duração | SHA-256 |
|---|---|---|---|---|
| jogadora | `(-1892,51)-(-612,771)` | `video/f1-batalha-ponta-jogadora.mp4` | 2:01.27, 1280×720 | `0a17b70d…131ddd` |
| Mestre | `(0,51)-(1600,951)` | `video/f1-batalha-ponta-mestre.mp4` | 2:00.70, 1600×900 | `2ad36bd3…96d9` |

**Caminho do vídeo (sede):** `RPG_Local/jogo-verdadeiro/ordem-plano-2-f1-fecho-video-pc/video/`, com o `SHA256.txt` ao lado.

| critério | resultado | onde |
|---|---|---|
| (a) `fim {"desfecho":"morte"}` | **sim**, seq 78 (19:31:00 -03), rodada 6; morte por testes de morte (falha d20=1, +1 falha pela clava enquanto estava a morrer, falha d20=2) | `relato-journal-f1.md` |
| (b) 0 colocações duplicadas | **3 colocações, 0 ids e 0 casas repetidos** | idem, cabeçalho |
| (c) figura no terço central | **arranque (639,341); depois do movimento 1 (598,337); depois do movimento 2 (640,341)**, todas dentro de [426,7–853,3]×[240–480]. Também dentro depois de cada ronda dos monstros até ela cair (6 capturas). Caída, sob o véu vermelho, o detector deixa de a ver; à vista continua no centro | `README.md` (c), `medicoes/figura-terco-central.jsonl` |
| (d) marcadores em px, ≥ 2 capturas | **b04:** Lobo, anel 43×33 e seta 15×19; Bruto, anel 39×27 e seta 13×18. **b10:** Lobo, anel 42×32 e seta 15×18; Bruto, anel 41×31 e seta 14×17 | `medicoes/marcadores-px.jsonl` e as duas capturas anotadas |
| (e) «Arqueira de Bancada» inteiro na caixa | **sim**, na vista expandida | `capturas/f1/b03-caixa-expandida-jog.png` |
| (f) relato completo | **as 78 seqs**, sem selecção; **121 ✔ / 0 ✘**. Regra do crítico declarada (3d6 à parte, 6-6-≥5). Regra dos testes de morte declarada (d20+CON > CON+3, d20 ≥ 4; 3×3; +1 falha por dano a quem está a morrer). O recibo de duas faces explicado (seq 25: [15] e [4], +4 da ficha +2 da vantagem do ataque de oportunidade → 21 e 10, fica 21). Os 6 movimentos conferidos contra Manhattan (custo = Manhattan × 1,5 m em todos) | `relato-journal-f1.md` |
| (g) journal bruto | **incluído**: `journal/f1-1929/registo-MESTRE-ONLY-bancada-rede.json` (SHA-256 `3f5f6e35…f9978`). Fora: `servidor.log` e `preparar.log`, que têm IPs da rede de casa, o QR e caminhos do PC | `journal/f1-1929/` |

**Um erro meu, dito às claras.** A primeira batalha na ponta foi a das **19:18–19:22**, também por morte. O journal, as
capturas e o relato completo (133 ✔ / 0 ✘) estão no pacote como anexo. **O vídeo dela perdeu-se**: o guião da F2 que
escrevi a seguir trocava mal o caminho de saída, e o ffmpeg (`-y`) gravou a F2 por cima dos dois mp4. Por isso a batalha
foi repetida às 19:29 com pastas novas, e conferi o caminho com grep antes de lançar. A corrida das 19:18 serve de
anexo: tem um crítico (seq 8, verificação [6,6,6]), uma estabilização (vida 1) e uma reentrada a 0/0.

## 2. F2 — «na vez» 20 vezes

Tabela completa em **`provas/ordem-plano-2-f1-fecho-video/f2-na-vez.md`**. Mesma ponta, mesmo servidor, 2 clientes
reais, em **modo manual**: no auto as vezes dos monstros passam em milissegundos e só as dela se podem medir. As 20
vezes são seguidas e todas diferentes (turno seq 3 a 51, rodadas 1 a 7), das 19:24:33 às 19:28:35. Há uma captura 1,5 s
depois de cada vez começar. Vídeo dos dois ecrãs na sede: `video/f2-na-vez-jogadora.mp4` (4:34.70) e
`video/f2-na-vez-mestre.mp4` (4:34.53).

| vez | quem (journal) | banner | caixa | |
|---|---|---|---|---|
| 01 | Arqueira (r1) | A sua vez | vazia («A ordem forma-se…») | discorda |
| 02, 05, 08, 11, 14, 17, 20 | Lobo 1 | O Mestre narra | Arqueira… na vez | discorda (×7) |
| 03, 06, 09, 12, 15, 18 | Bruto 1 | O Mestre narra | Arqueira… na vez | discorda (×6) |
| 04, 07, 10, 13, 16, 19 | Arqueira (r2–r7) | A sua vez | Arqueira… na vez | **concorda (×6)** |

**6 concordam, 14 discordam.** As discordâncias ficam registadas para a **bancada do coordenador (D-AUD-03)** e não
travam a entrega:
1. No modo dinâmico a caixa mostra quem agiu por último (`hud/ordem_turnos.gd:158`), e o banner mostra a vez do servidor.
2. O `correr` dos monstros, feito pelo Mestre, nunca mudou a caixa da jogadora, embora o modelo o conte como agir.
3. No modo auto da batalha F1 a discordância é «A sua vez» × «Bruto 1 na vez» (`capturas/f2/f1-auto-inicio-das-vezes-dela.png`).

## 3. F3 — patch do CI

- **O patch corrigido (commit `c9fc4ab`, enviado):** `provas/ordem-plano-2-f1/ci/passo-camera-segue.patch` deixou de
  ter o grep cravado em `22 de 22` (no README ainda dizia «19 de 19»). Agora tem uma **guarda N de N**:
  - exactamente uma linha final `N de N verificações passaram.`, lida do próprio teste;
  - os dois N iguais e > 0 (o CRLF normalizado com `tr`).

  O log vai para o **artefacto `camera-segue`** (`actions/upload-artifact@v4`, `if: always()`). Testei a guarda com
  `bash -eo pipefail` em 5 casos: ok (22 de 22) → 0; 21 de 22 → 1; sem linha final → 1; duas linhas → 1; 0 de 0 → 1
  (`provas/ordem-plano-2-f1/ci/guarda-n-de-n/`). `git apply --check` OK na ponta.
- **A adenda:** a linha `ci/passo-camera-segue.patch` do `provas/ordem-plano-2-f1/README.md` diz agora «N de N
  genérico» no mesmo commit, `c9fc4ab`.
- **`git apply` na ponta:** feito, mas **o push foi recusado**: `! [remote rejected] … (refusing to allow an OAuth App to
  create or update workflow .github/workflows/testes.yml without workflow scope)`. A credencial do PC tem os âmbitos
  `gist`, `read:org` e `repo`. Não tentei contornar. **O commit está feito e é o último da linha local, por cima deste
  ESTADO-FINAL**, com a mensagem «PLANO-2-F1-FECHO-VIDEO F3 2/2: git apply do …passo-camera-segue.patch no testes.yml».
  Está guardado na sede, no ref local `f3-workflow-pendente`, e em `ordem-plano-2-f1-fecho-video-pc/f3-workflow-pendente.patch`
  (`git format-patch`).
- **Pendente do dono da conta:** `gh auth refresh -h github.com -s workflow` e depois `git push` desse commit, ou
  `git am` do `.patch` na ponta. Só então há run do Testes com o passo `camera_segue` e o artefacto. Esses dois
  critérios (o run verde com o passo e o artefacto descarregável) **ficam por cumprir** até lá.

## 4. Commits (um por ponto, push a cada um)

| commit | ponto | push |
|---|---|---|
| `c9fc4ab` | F3 1/2: patch N de N + artefacto, README das provas, a guarda testada | ✔ (CI do `c9fc4ab`: Testes, Sonda e Aparelhos, success) |
| `bdb8cfc` | F1: a batalha na ponta com vídeo, (a)–(g) | ✔ (Sonda de privacidade 45906393401: success; Testes e Aparelhos a correr quando escrevi isto) |
| `9f06b71` | F2: o «na vez» 20× | ✔ (Sonda 45906426186: success; Testes e Aparelhos a correr) |
| este | o ESTADO-FINAL | ✔ |
| (por cima deste) | F3 2/2: `git apply` no `testes.yml` | **✘ recusado (sem `workflow`)**: pendente |

## 5. Para quem conferir

- Na sede: os vídeos em `video/`. Os journals das três corridas de hoje estão em `tmp/journal-f1-ponta/` (19:29, a
  batalha F1), `tmp/journal-ponta/` (19:18, o anexo) e `tmp/journal-f2/` (a F2). As capturas completas estão em
  `tmp/cap4/` (19:29), `tmp/cap2/` (19:18) e `tmp/cap3/` (F2). O pacote tem uma selecção delas.
- As ferramentas que geram o relato e as medições estão no pacote (`ferramentas/relato.mjs`, `ferramentas/pix.py`) e
  correm sobre o journal bruto e os PNG do pacote. Os guiões da bancada estão em `guioes/`, com os caminhos do PC
  redigidos.
- A sonda de privacidade (`caminhos_pc.py`) corrida sobre o pacote: limpa. A regra dos emails também.
