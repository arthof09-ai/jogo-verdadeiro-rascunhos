# F2 — o «na vez» da caixa contra o banner, 20 vezes seguidas (ORDEM-PLANO-2-F1-FECHO-VIDEO)

**Onde e como.** Ponta `c9fc4ab`, servidor de produção (`servidor-ws.js`, motor real, fichas «acertam»), 2 clientes Godot
reais (jogadora 1280×720 em (-1892,51); Mestre 1600×900 em (0,51)), grelha-mapa 50×50 @ 1,5 m, **modo manual** (o Mestre
conduz os monstros) para que as vezes deles fiquem paradas no ecrã e se possam medir — no modo automático as vezes dos
monstros passam em milissegundos e a jogadora só vê as dela. 26/11/2026, 19:24:33–19:28:35 -03. Vídeo dos dois ecrãs
(um por janela) na sede: `video/f2-na-vez-jogadora.mp4`, `video/f2-na-vez-mestre.mp4` (SHA-256 no README).

**Regra da medição.** Uma medição por vez, 20 vezes seguidas, todas diferentes (seqs de `turno` 3…51 do journal, rodadas 1–7,
nenhuma vez repetida nem saltada). Cada medição é uma captura da janela da jogadora 1,5 s depois de a vez começar
(«início»), antes de a figura agir. Lê-se o texto do banner (faixa de cima) e o nome com «na vez» no cartão grande da
caixa. «Concorda» = os dois apontam a figura que o journal diz estar na vez. Por cada vez há uma segunda captura depois
de a figura agir («depois», coluna à parte, não entra na contagem). As faixas estão em `capturas/f2/f2-grupo-*.png`
(5 vezes por imagem, de cima para baixo; em cada linha: banner e caixa no início | banner e caixa depois).
O journal bruto está em `journal/f2/`, com o relato completo (`journal/f2/relato-journal.md`, 51 ✔ / 0 ✘).

| vez | hora (início) | journal: seq do `turno` · rodada · quem | banner | caixa (cartão grande) | início | depois de agir | porquê |
|---|---|---|---|---|---|---|---|
| 01 | 19:24:33.040 | 3 · r1 · Arqueira de Bancada | A sua vez | (vazia: «A ordem forma-se à medida que as figuras agem.») | **discorda** | 19:24:46.383 · move uma casa ou mais (evento `movimento`) · caixa: Arqueira… na vez → concorda | a caixa ainda não tem ninguém (ninguém agiu); o banner dá a vez a ela |
| 02 | 19:25:08.037 | 8 · r1 · Lobo 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:25:12.296 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Lobo 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |
| 03 | 19:25:38.509 | 10 · r1 · Bruto 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:25:42.917 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Bruto 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |
| 04 | 19:25:48.281 | 12 · r2 · Arqueira de Bancada | A sua vez | Arqueira… na vez | **concorda** | 19:25:54.158 · move uma casa ou mais (evento `movimento`) · caixa: Arqueira… na vez → concorda | a caixa e o banner dão a vez à Arqueira, como o journal |
| 05 | 19:25:59.592 | 15 · r2 · Lobo 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:26:03.894 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Lobo 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |
| 06 | 19:26:08.882 | 17 · r2 · Bruto 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:26:13.228 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Bruto 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |
| 07 | 19:26:18.342 | 19 · r3 · Arqueira de Bancada | A sua vez | Arqueira… na vez | **concorda** | 19:26:24.486 · move uma casa ou mais (evento `movimento`) · caixa: Arqueira… na vez → concorda | a caixa e o banner dão a vez à Arqueira, como o journal |
| 08 | 19:26:29.818 | 21 · r3 · Lobo 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:26:34.177 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Lobo 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |
| 09 | 19:26:39.173 | 23 · r3 · Bruto 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:26:43.756 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Bruto 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |
| 10 | 19:26:48.858 | 25 · r4 · Arqueira de Bancada | A sua vez | Arqueira… na vez | **concorda** | 19:26:54.675 · move uma casa ou mais (evento `movimento`) · caixa: Arqueira… na vez → concorda | a caixa e o banner dão a vez à Arqueira, como o journal |
| 11 | 19:26:59.948 | 30 · r4 · Lobo 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:27:04.226 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Lobo 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |
| 12 | 19:27:09.477 | 32 · r4 · Bruto 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:27:13.850 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Bruto 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |
| 13 | 19:27:19.022 | 34 · r5 · Arqueira de Bancada | A sua vez | Arqueira… na vez | **concorda** | 19:27:24.791 · move uma casa ou mais (evento `movimento`) · caixa: Arqueira… na vez → concorda | a caixa e o banner dão a vez à Arqueira, como o journal |
| 14 | 19:27:30.152 | 36 · r5 · Lobo 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:27:34.454 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Lobo 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |
| 15 | 19:27:39.720 | 38 · r5 · Bruto 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:27:44.023 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Bruto 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |
| 16 | 19:27:49.167 | 40 · r6 · Arqueira de Bancada | A sua vez | Arqueira… na vez | **concorda** | 19:27:54.962 · move uma casa ou mais (evento `movimento`) · caixa: Arqueira… na vez → concorda | a caixa e o banner dão a vez à Arqueira, como o journal |
| 17 | 19:28:00.104 | 45 · r6 · Lobo 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:28:04.406 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Lobo 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |
| 18 | 19:28:09.573 | 47 · r6 · Bruto 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:28:13.950 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Bruto 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |
| 19 | 19:28:19.118 | 49 · r7 · Arqueira de Bancada | A sua vez | Arqueira… na vez | **concorda** | 19:28:24.982 · move uma casa ou mais (evento `movimento`) · caixa: Arqueira… na vez → concorda | a caixa e o banner dão a vez à Arqueira, como o journal |
| 20 | 19:28:30.388 | 51 · r7 · Lobo 1 | O Mestre narra | Arqueira… na vez | **discorda** | 19:28:34.834 · Mestre: Agir → Correr (evento `acao correr`) · caixa: Arqueira… na vez → discorda | o journal dá a vez a Lobo 1; o banner não nomeia ninguém («O Mestre narra») e a caixa nomeia a Arqueira (quem agiu por último que a caixa da jogadora conhece: o `correr` dos monstros não lhe muda a caixa) |

**Contagem (início da vez): 6 concordam, 14 discordam.** Depois de agir: 7 concordam, 13 discordam.

## As discordâncias (para a bancada do coordenador — D-AUD-03; não travam a entrega)

1. **Vez 1 (o arranque):** a caixa está vazia («A ordem forma-se à medida que as figuras agem.») enquanto o banner diz
   «A sua vez». É o modo **dinâmico** de origem: a caixa só mostra quem já agiu (`hud/ordem_turnos.gd:158`:
   `na_vez()` devolve `ultimo` no modo dinâmico; o banner lê `Estado.vez_id`, `hud/hud.gd:497-502`).
2. **As 13 vezes dos monstros (modo manual):** o banner diz «O Mestre narra» (não nomeia a figura) e a caixa continua com
   «Arqueira… na vez». O `acao correr` do Mestre conta como «agiu» no modelo (`ACOES_DA_VEZ`, `ordem_turnos.gd`), mas
   a caixa **da jogadora** nunca passou para o Lobo nem para o Bruto nesta corrida — a caixa dela só mudou com
   `movimento` (o cartão do Lobo/Bruto não chegou a aparecer). Não investiguei a causa (fora do âmbito); fica o facto
   medido para a bancada.
3. **No modo automático (a batalha da F1, mesma ponta):** no início de cada vez dela, rodadas 2–5, o banner diz
   «A sua vez» e a caixa diz «**Bruto 1 na vez**» — quem agiu por último (`capturas/f2/f1-auto-inicio-das-vezes-dela.png`,
   tiradas de `capturas/f1/b07…`, `c-r2…`, `c-r3…`, `c-r4…`). É a discordância que a D-AUD-03 já descrevia; o
   desenho do modo dinâmico explica-a (`ordem_turnos.gd`: «quem está na vez: dinâmico = quem agiu por último»).
