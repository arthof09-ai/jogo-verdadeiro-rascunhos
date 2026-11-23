# ESTADO FINAL — ORDEM MAPA-JOGÁVEL-CUSTO-CÂMARA (Claude conta 1, PC · 23/11/2026)

Ordem: [COORDENADOR] CM-000009, 23/11/2026, com **dispensa única** da regra «testar é do coordenador» (só esta ordem,
só esta cadeira). Linha: `fable/integracao-50`. A ordem nasceu sobre `e91fb95`; a ponta ao lançar era **`5ab2aea`**,
conferida por `git ls-remote` às 16:45 (-03) e outra vez antes do primeiro push (andou com a AUDITORIA-LINHA, a
ANALISE-PLANO-2 e a D-AUD-01, que só mexeram no ecrã do Mestre; a arena e a câmara não mudaram). Commits directos na
linha; `main` não foi tocado.
Marcas: VERIFICADO (medido nesta sessão), ACHADO, PENDENTE, [FALTA], PROPOSTO (como nas ordens anteriores).

**Condição de lançamento — VERIFICADO.** O PC estava LIVRE, conferido às 16:43–16:49 (-03):
- inactivo há 9.772–10.072 s pelo sensor da sessão 1 (`_muse_gui/idle_live.txt`), com o Chrome à frente e sem jogo
  nem stream;
- GPU a 9 %; nenhum Godot, node ou ffmpeg vivo; disco C: com 25 GB livres (acima de 15).

A auditoria (conta 2) já tinha fechado às ~15:49 e a D-AUD-01 às 16:33, por isso **não houve nada em simultâneo**.
O sensor de inactividade não se actualizou durante as corridas (último carimbo 16:48:58; `corridas/estado-do-pc.txt`).

**Resultado em curto:**

| Item | Resultado |
|---|---|
| A1 custo GPU | VERIFICADO: 4 grelhas × 3 corridas registadas. **ACHADO (severidade baixa):** a 75×75 fica **fora** da banda de ruído da referência (+0,081 ms/quadro com banda 0,012; −26,5 FPS com banda 3,0; +23 chamadas de desenho). A CPU do lago fica **dentro** da banda. |
| A2 câmara | VERIFICADO: **16/16** nas 3 grelhas-mapa, nas 6 leituras de cada uma. **Sem correcção.** |
| A3 resíduo | VERIFICADO: 18 grelhas, **TUDO PASSOU**, código 0, 0 divergências afirmadas. Resíduo cliente ≠ referência **0 em todas** (0 nas 3 grelhas-mapa). |
| A4 ponta-a-ponta | VERIFICADO: verde na grelha-mapa **50×50 @ 1,5 m** (motor falso e VLAB real), com a cópia adaptada. |
| A5 suites | VERIFICADO: tudo verde na ponta (números no §5). CI: ver §5. |
| A7 privacidade | VERIFICADO: Sonda limpa (0 e-mails), canário 10/10, caminhos com `<utilizador>`. |

As provas estão em `provas/ordem-mapa-jogavel/custo-gpu-camara/` (README, `medicao.json`, `tabelas.md`). As provas antigas
(as 9 PNG da CAPTURAS-MAPA, `medicao.json`, os registos da PROVAS-MAPA) **não foram tocadas**. **Nenhum ficheiro do
jogo mudou**: só há ficheiros novos nessa pasta e este ESTADO.

---

## 1. A1 — o custo GPU da grelha-mapa — VERIFICADO

**Como.**
- O renderizador é o do projecto: Godot 4.7.2 `gl_compatibility` na RTX 4060.
- 1920×1080, `--disable-vsync` e `Engine.max_fps = 0`, perfil «alto» (o das fotos), câmara em Panorama a enquadrar a
  grelha.
- Houve **um processo por grelha e por corrida**, intercalados (c1: 20, 50, 75, 37; depois c2 e c3). Cada um aquece
  240 quadros e mede **1200**.
- O FPS médio é quadros ÷ tempo de parede; ms/quadro é a mediana dos intervalos.
- As chamadas de desenho saem de `RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME`, em média por quadro.
- A CPU do lago é `LagoFloresta.custo_medio_us()`: o `avancar()` em µs/quadro, no mesmo intervalo.
- Ferramenta: `ferramenta/medir_custo_camara.gd`, uma cópia de trabalho da `foto_mapa_jogavel.gd` que vive só na pasta
  de provas.

**A figura.** Está nas casas das provas: (36,9) @ 1,5 m, e o mesmo sítio nas outras escalas, (54,14) @ 1 m e
(27,6) @ 2 m. Todas são casas de água e nenhuma é recusada. **A referência 20×20 não chega ao lago**: o canto NO fica em
−15 m e o sítio de (36,9) em x ≈ 17,25 m. Por isso, na referência, a figura está na casa mais perto desse sítio,
(19,0), que é seca. É uma limitação geométrica e fica registada.

| grelha | FPS médio (c1 · c2 · c3) | ms/quadro mediana (c1 · c2 · c3) | chamadas de desenho | CPU do lago µs/quadro (c1 · c2 · c3) |
|---|---|---|---|---|
| 20×20 @ 1,5 m (referência) | 585,8 · 584,5 · 582,8 | 1,674 · 1,680 · 1,668 | 80 · 80 · 80 | 19,19 · 19,01 · 20,50 |
| 50×50 @ 1,5 m | 568,7 · 560,1 · 559,0 | 1,726 · 1,750 · 1,758 | 103 · 103 · 103 | 18,39 · 19,59 · 19,57 |
| 75×75 @ 1 m | 561,2 · 556,6 · 555,9 | 1,738 · 1,764 · 1,762 | 103 · 103 · 103 | 21,08 · 19,45 · 20,34 |
| 37×37 @ 2 m | 562,5 · 561,7 · 560,7 | 1,736 · 1,744 · 1,748 | 103 · 103 · 103 | 20,76 · 19,11 · 19,42 |

As primitivas (média) são 1 126 947 na 20×20, 1 233 575 na 50×50, 1 258 775 na 75×75 e 1 224 756 na 37×37. O p95 e
os extremos de cada corrida estão em `tabelas.md` e `medicao.json`.

**75×75 − 20×20 contra a banda de ruído (o maior − o menor das 3 corridas da referência):**

| medida | 75×75 − 20×20 | banda da referência | os intervalos [mín, máx] sobrepõem-se? | leitura |
|---|---|---|---|---|
| FPS médio | **−26,5** (−4,5 %) | 3,0 | não | **fora da banda** |
| ms/quadro (mediana) | **+0,081** (+4,8 %) | 0,012 | não | **fora da banda** |
| chamadas de desenho | **+23** (+28,8 %) | 0 | não | **fora da banda** |
| primitivas | +131 828 (+11,7 %) | 3 | não | fora da banda |
| CPU do lago | +0,72 µs (+3,7 %) | 1,49 | sim | **dentro da banda** |

**ACHADO A1-1 — severidade: BAIXA.** A grelha 75×75 @ 1 m custa mais do que a referência 20×20, fora do ruído:
+0,081 ms por quadro (1,674 → 1,755 ms) e +23 chamadas de desenho (80 → 103).

Dei severidade baixa por três razões, todas tiradas dos números e não de um limiar de FPS:
- a diferença é de 4,8 % do tempo de quadro, numa máquina que mede ~560 FPS;
- as três grelhas-mapa têm **as mesmas 103 chamadas** e ficam a ≤ 0,012 ms umas das outras (em médias), por isso o
  custo extra acompanha o enquadramento e não o número de casas. A câmara está a ~61 m em vez de 26 m e vê mais
  mapa; da 50×50 para a 75×75 só se somam ~25 mil primitivas, as linhas a mais;
- a CPU do lago não muda.

Isto é uma **leitura dos números, não uma causa isolada**: nenhuma medição separou a câmara da grelha. **O juízo «é lento
de mais» é do Mestre/coordenador**; esta ordem não fixa nenhum limiar.

**Notas da medição.**
- A janela Godot corre na sessão 0 do Windows, como a CAPTURAS-MAPA.
- O valor «água acima do pé» da referência (0,567 m) é numa casa seca fora do lago e não tem significado.
- A 50×50 tem a maior banda de FPS (9,7), com a c1 acima das outras duas. Isto não muda a leitura: a 75×75 e a 20×20
  não se sobrepõem em nenhuma corrida.

## 2. A2 — o enquadramento da câmara, medido — VERIFICADO (16/16, sem correcção)

**Como.**
- Usei o critério do próprio `_recalcular_panorama`: os **16 pontos** são os 4 cantos e os 4 meios de borda, a 0 m e a
  1,8 m acima do relevo nesse ponto.
- Testei-os com `is_position_in_frustum` **na câmara real**, depois de `_saltar()` e de 60 quadros. A distância real
  câmara–centro é igual a `_dist_panorama`, por isso a leitura é na distância final aplicada, fora do ciclo.
- Li antes e depois da medição do custo, nas 3 corridas: **6 leituras por grelha, todas iguais**.
- As iterações deduzem-se de `_dist_panorama = d0 × 1,06ⁿ × 1,03`, com d0 = max/2 e resíduo da fórmula 0.

| grelha | pontos no frustum | `_dist_panorama` (m) | distância real (m) | d0 (m) | crescimentos ×1,06 | iterações do ciclo | tecto 60 | folga mínima ao bordo |
|---|---|---|---|---|---|---|---|---|
| **50×50 @ 1,5 m** | **16/16** | 61,562 | 61,562 | 37,5 | 8 | 9 | não | 38,6 px |
| **75×75 @ 1 m** | **16/16** | 61,562 | 61,562 | 37,5 | 8 | 9 | não | 38,6 px |
| **37×37 @ 2 m** | **16/16** | 60,742 | 60,742 | 37,0 | 8 | 9 | não | 38,3 px |
| 20×20 @ 1,5 m (referência, fora do critério) | 16/16 | 26,102 | 26,102 | 15,0 | 9 | 10 | não | 51,2 px |

A 50×50 @ 1,5 m e a 75×75 @ 1 m cobrem os mesmos 75 m, por isso dão a mesma distância. A FIXA ficou fora da medição,
como manda a ordem. **Como a A2 passou, o § «A câmara» não se aplicou**: `_recalcular_panorama`, os ângulos da FIXA, o
`ZOOM_PADRAO` e `distancia_no_zoom_1` ficaram intactos, e as 9 fotos não se refizeram.

**A prova independente (as fotos).** As 9 fotos das CAPTURAS-MAPA são de `62dfa61`, **antes** da LAGO-MAIOR (`ded3272`),
que mudou o relevo (`relevo_floresta.gd`, +117/−35). As alturas dos 16 pontos dependem do relevo. Por isso juntei
**3 fotos de controlo do Panorama na ponta** (`controlo-panorama/`, uma por grelha-mapa, tiradas pela mesma
ferramenta). Não são as 9 refeitas: essas só se refariam com correcção.

Nas três fotos a grelha inteira e o lago estão no ecrã. **Observação para o Mestre (não é defeito do frustum):** junto
às bordas, as copas da orla **tapam** partes da grelha. Os pontos estão dentro do frustum, mas por baixo das copas. É
oclusão, fora dos limites da correcção desta ordem, e não se mexeu.

## 3. A3 — o resíduo de cobertura julgado — VERIFICADO

`provar_terreno_servidor.gd`, a **original, como está**, com o servidor de verdade (`juizo-terreno.mjs`), nas **18
grelhas**:
- **TUDO PASSOU**, código de saída **0**, 0 linhas `FALHA`, 0 SCRIPT ERROR, 70 s (`terreno/provar-terreno-servidor.log`);
- 0 juízos, motivos ou coberturas afirmadas diferentes; desvio de altura, pé e figuras 0 em todas;
- tabela completa em `tabelas.md`.

| grelha | cobertura não afirmada | … com cliente ≠ referência |
|---|---|---|
| 1 30×30 @ 1,5 | 76 | 0 |
| 2 30×30 @ 2 | 98 | 0 |
| 3 20×20 @ 1,5 | 75 | 0 |
| 4 25×25 @ 1,5 | 78 | 0 |
| 5 25×25 @ 1 | 184 | 0 |
| 6 25×25 @ 2 | 37 | 0 |
| 7 21×17 @ 1 | 87 | 0 |
| 8 33×27 @ 2 | 103 | 0 |
| 9 44×20 @ 1,5 | 107 | 0 |
| **10 50×50 @ 1,5 (o mapa)** | **0** | **0** |
| **11 50×50 @ 1 → 75×75 @ 1 (o mapa)** | **0** | **0** |
| **12 37×37 @ 2 (o mapa)** | **0** | **0** |
| 13 49×49 @ 1,5 | 87 | 0 |
| 14 50×20 @ 1,5 | 83 | 0 |
| 15 20×50 @ 1,5 | 75 | 0 |
| 16 49×30 @ 1,5 | 90 | 0 |
| 17 37×20 @ 2 | 51 | 0 |
| 18 35×37 @ 2 | 64 | 0 |

**Não há casas a nomear**: na PROVAS-MAPA havia 0–4 casas com cliente ≠ referência por grelha; hoje há 0 em todas.
As contagens de bloqueadas e de resíduo mudaram desde a PROVAS-MAPA (por exemplo, 35×37 @ 2: 43 → 92 bloqueadas).
Isto bate com a LAGO-MAIOR ter devolvido a floresta ao campo. É uma leitura; não fui confirmar o porquê casa a casa.
Nenhum ACHADO nas grelhas-mapa.

## 4. A4 — ponta-a-ponta na grelha-mapa — VERIFICADO

- **O CI corre este ficheiro.** O job do CI corre `servidor/e2e/servidor-e2e.mjs` directamente (`testes.yml`
  l. 294); não há outra config. O ficheiro fixa `mapa: { largura: 20, altura: 20 }` (l. 55) e só aceita a porta
  (l. 22).
- **A cópia adaptada.** `provas/…/custo-gpu-camara/e2e/servidor-e2e-mapa.mjs` difere do original só em duas coisas: tira a linha
  `mapa` e reaponta os imports e o terreno para `rascunhos/servidor`. Não foi commitada em `e2e/` e o CI não foi
  tocado.
- **Invocação**, na raiz do repo:
  `GODOT=<godot> MOTORES=<motores.mjs> SAIDA=<pasta> bash provas/ordem-mapa-jogavel/custo-gpu-camara/e2e/correr-e2e-mapa.sh`.
  É o guião do job do CI com essa única troca; o `motores.mjs` vem do `vlab-completo.js` vivo, por `embrulhar.mjs`.
- **Resultado:**
  - motor falso: Mestre = 0, jogadora = 0 (Mestre 17/17 verificações; a jogadora com 23 mensagens e 0 canários);
  - **VLAB real: Mestre = 0, jogadora = 0** (o servidor carregou o «motor REAL»);
  - os registos estão em `e2e/registos/`.
- **A grelha, conferida.** A `sonda-grelha.mjs` entra como a jogadora e lê o `mapa` do primeiro snapshot. A cópia
  adaptada serve `{"largura":50,"altura":50,"casaM":1.5}` e o original do CI serve `{"largura":20,"altura":20,"casaM":1.5}`
  (`e2e/registos/sonda-grelha.log`).
- **Limite.** As casas do guião, (2,2) e (2,3), ficam na grelha-mapa no canto NO do mapa e não no centro. A
  ponta-a-ponta do CI continua a 20×20.

## 5. A5 — suites e CI — VERIFICADO

Na ponta `5ab2aea`, antes das medições (`suites/antes/resumo.txt`, 16:47–16:49), com 0 SCRIPT ERROR em todas:

| suite | resultado |
|---|---|
| servidor | 421/421 |
| prova-caixa | código 0 |
| motor-real | 2/2 |
| `abrir_scripts` | 108 scripts, 0 falhas |
| `rodar_testes` | 321/321 |
| `abrir_mestre` | 67/67 |
| `pecas_mestre` | 290/290 |
| `medir_mestre` | 0 falhas |
| `hud_acoes` | 50/50 |
| `caixa_jogadora` | 70/70 |
| `caixa_janela` | 123/123 |
| `canario_privacidade` | 10/10 |

**Não houve correcção da câmara**, por isso não há segunda passagem. Nenhum ficheiro de `rascunhos/` mudou, por isso
as listas da retoma não mudam (conferido com `actualizar-listas.py` no commit deste ESTADO, ver a nota do CI).
**CI — VERIFICADO, verde nos dois commits da ordem:**
- provas `de0d550`: Testes `45254569478` success, Sonda `45254569718` success;
- **ESTADO `f4aa10a`: Testes `45254861564` success, Sonda `45254861796` success.**

`actualizar-listas.py` no `f4aa10a`: 0 novos, 0 tirados, árvore limpa.

## 6. A7 — privacidade — VERIFICADO
- Sonda: o `grep` dos e-mails pessoais da `privacidade.yml`, corrido no repo, dá **0** achados.
- Canário: **10/10**.
- Os caminhos com o nome de utilizador do Windows foram trocados por `<utilizador>` nos registos novos.
- Só há fichas fictícias. Nenhum nome verdadeiro nas capturas nem nos registos.

## 7. O que esta ordem não decidiu (e não inventou)

**Pendente do Mestre:**
1. **[FALTA] O custo da água.** O custo provisório é **o actual: igual a uma casa seca**, por confirmar pelo Mestre.
   `sala.js` não foi tocado. Quando o número vier, a regra entra em **dois sítios**, `sala.js` l. 889 e l. 2065.
2. **A regra da mudança de escala na grelha-mapa é PROPOSTA**: guarda o sítio no mapa, não o índice. Esta ordem
   assume-a, como as anteriores: a grelha 11 da A3 (50×50 @ 1 m pedida → 75×75 @ 1 m servida) e a escala de cada
   grelha-mapa dependem dela. **Não a certifica.** Se o Mestre a rejeitar, a A3 (grelha 11) volta a ser julgada.
3. **O olho do Mestre** sobre as 9 fotos das CAPTURAS-MAPA, e agora também sobre as 3 fotos de controlo (§2).
4. **O ACHADO A1-1** (o custo da 75×75 fora do ruído, severidade baixa): o juízo «é lento de mais» é dele ou do
   coordenador.
5. **As copas da orla que tapam as bordas da grelha no Panorama** (§2, observação): se ele as quiser fora do caminho, é
   outra ordem (o recorte da vista ou a orla), fora dos limites desta.
6. **PENDENTE (b) observado — a figura na parte funda.** Nas três casas das provas a água fica hoje **1,80–1,97 m acima
   do pé**. Nas CAPTURAS (antes da LAGO-MAIOR) ficava ~0,5 m. O marcador de 1,7 m está submerso e não se vê nas fotos
   de controlo. Não é defeito a corrigir aqui: o esqueleto é da A2 (MIS-025). As medições não dependem disto; o custo
   do lago fica dentro do ruído.
7. A floresta dentro do campo (árvores e rochas como casas bloqueadas) e o esqueleto da A2: outra ordem.

**Em aberto, à espera da auditoria:** a bancada de rede com o ecrã do Mestre em Godot na grelha-mapa. O
`ESTADO-FINAL-ORDEM-AUDITORIA-LINHA.md` **não diz explicitamente** que a batalha correu na grelha-mapa 50×50 @ 1,5 m.
Há indícios: «1,5 m/casa» (l. 24) e casas como (38,4) e (26,21) no parcial, que não cabem numa 20×20. Mas a condição
da ordem pede a afirmação explícita. **Não fecho este item**; fica para o coordenador ou a auditoria.

**Para a auditoria / coordenador conferir:**
- as fotos de controlo contra os 16/16;
- se a severidade baixa do A1-1 se aceita;
- a escolha da casa seca (19,0) para a referência 20×20;
- que a sessão 0 do Windows é o mesmo regime de render da CAPTURAS-MAPA.

## 8. Passagem

**Onde parou:** a ordem está cumprida: A1–A7, sem correcção da câmara e sem corte da A3.

**Próximo passo:** a palavra do Mestre sobre os pontos 1–6 do §7, e a conferência deste ESTADO pelo coordenador.
