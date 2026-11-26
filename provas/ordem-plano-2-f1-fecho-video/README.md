# Provas da ORDEM-PLANO-2-F1-FECHO-VIDEO (F1 batalha na ponta com vídeo · F2 «na vez» 20× · F3 patch do CI)

O ESTADO-FINAL é `ESTADO-FINAL-ORDEM-PLANO-2-F1-FECHO-VIDEO.md`, na raiz. Este README é o índice das provas da F1 e da F2. As provas da F3 estão em `provas/ordem-plano-2-f1/ci/` (o patch e a pasta `guarda-n-de-n/`).

## F1 — a batalha (26/11/2026, 19:29:09–19:31:19 -03)

- **Código:** ponta `c9fc4ab` da `fable/integracao-50` (medida por `git fetch` + `git ls-remote` imediatamente antes de
  lançar; é o commit da F3 1/2, que só mexe em `provas/`). Servidor de produção `rascunhos/servidor/adaptadores/node/servidor-ws.js`
  com o VLAB real (vlabSha `a91c021c…`), fichas «acertam», modo auto, grelha-mapa 50×50 @ 1,5 m (`arena-teste`).
- **Clientes:** 2 Godot 4.7.2 reais, na sessão 1 (o ambiente de trabalho real), conduzidos por mensagens à janela
  (PostMessage; o cursor e o teclado do PC não mexem). Jogadora 1280×720 com o canto em (-1892,51); Mestre 1600×900 em (0,51).
- **Vídeo — um por janela:** ecrã virtual `(-1920,0)-(3520×1080)` = DISPLAY2 `(-1920,0,1920×1080)` + DISPLAY1
  `(0,0,1600×1024)`. Área da jogadora `(-1892,51)-(-612,771)`, do Mestre `(0,51)-(1600,951)`: as duas dentro do ecrã
  virtual (verificado no guião antes de lançar cada ffmpeg; o erro de 23/11 era a área sair dele). Ficheiros na sede
  (não vão para o git pelo tamanho):

  | ficheiro (na sede) | duração | resolução | SHA-256 |
  |---|---|---|---|
  | `video/f1-batalha-ponta-jogadora.mp4` | 2:01.27 | 1280×720 | `0a17b70deeb31e37d3d9218c3b8973e8b80dcd95b9d578138f0f607827131ddd` |
  | `video/f1-batalha-ponta-mestre.mp4` | 2:00.70 | 1600×900 | `2ad36bd3ef2a384e448dba66653ab7f616b6f2e4b3f648de5a7c9e10c52c96d9` |

  Gravação de 19:29:18.5 a 19:31:19.9 (`q` no stdin, rc=0 nos dois).

### Critérios de aceite

**(a) `fim {"desfecho":"morte"}`** — seq 78, 22:31:00.053 UTC (19:31:00 -03), rodada 6. A Arqueira morre por testes de
morte: falha no teste da rodada 5 (d20 = 1), +1 falha pela clava do Bruto enquanto estava a morrer (seq 72–73), falha no
teste da rodada 6 (d20 = 2) → 3 falhas. Acabada por morte, não por «Terminar».

**(b) 0 colocações duplicadas** — 3 colocações (seq 2, 4, 5): Arqueira (38,4) `fda7ef73…`, Lobo 1 (36,3) `ffebaea1…`,
Bruto 1 (41,1) `f14bc8a1…`. **0 ids repetidos, 0 casas repetidas** (contado pela ferramenta: `relato-journal-f1.md`, cabeçalho).

**(c) A figura no terço central** — no arranque e depois de cada movimento (os dois dela: seq 7 e seq 24) e ainda depois
de cada ronda dos monstros. Medido por píxeis (`ferramentas/pix.py figura`: píxeis da cápsula azul, B > 140 e
B − max(R,G) > 50, fora da caixa e da barra; centro = mediana): terço central = x ∈ [426,7; 853,3], y ∈ [240; 480].

| captura (`capturas/f1/`) | píxeis | centro | caixa da figura | no terço central |
|---|---|---|---|---|
| `a00-arranque-jog.png` (arranque) | 523 | (639,341) | (629,329)–(650,353) | **sim** |
| `b02-depois-mov1-jog.png` (depois do movimento 1, seq 7) | 692 | (598,337) | (587,321)–(608,353) | **sim** |
| `b03c-caixa-compacta-jog.png` | 693 | (598,336) | (587,321)–(608,353) | **sim** |
| `b04-ataque-alvos-jog.png` | 694 | (598,337) | (587,321)–(608,353) | **sim** |
| `b07-depois-monstros-r1-jog.png` (depois dos movimentos do Lobo e do Bruto, seq 13 e 21) | 701 | (598,337) | (587,321)–(608,353) | **sim** |
| `b09-depois-mov2-jog.png` (depois do movimento 2, seq 24) | 517 | (640,341) | (629,329)–(650,353) | **sim** |
| `b10-ataque2-alvos-jog.png` | 532 | (640,341) | (629,329)–(650,353) | **sim** |
| `c-r2-depois-monstros-jog.png` (depois dos movimentos seq 31 e 37) | 544 | (640,340) | (629,327)–(650,353) | **sim** |
| `c-r3-depois-monstros-jog.png` | 544 | (640,340) | (629,327)–(650,353) | **sim** |
| `c-r4-depois-monstros-jog.png` (já caída) | 9 | (633,352) | — | inconclusivo pelo detector |
| `d01-fim-jog.png` (morta) | 0 | — | — | inconclusivo pelo detector |

Depois de cair (rodada 4 em diante) o ecrã leva o véu vermelho de quem está a morrer e a figura fica deitada: o
detector de azul deixa de a ver. À vista, a etiqueta «Arqueira de Bancada» e o corpo continuam em ≈(640,320–345), dentro
do terço central. Nas capturas que contam para o critério (arranque e depois de cada movimento: `a00`, `b02`, `b09`),
a figura está dentro, medida.

**(d) O tamanho dos marcadores de alvo, em píxeis** — medido em DUAS capturas, por diferença com a mesma vista sem
marcadores (`ferramentas/pix.py marcadores`: vermelho vivo, R > 180, G < 110, B < 110, que não estava na vista de
referência). Cada marcador tem duas peças: a seta por cima e o anel na base. Caixas desenhadas em
`medicoes/marcadores-b04-anotado.png` e `medicoes/marcadores-b10-anotado.png` (recorte 400×220 ampliado ×2); números em
`medicoes/marcadores-px.jsonl`.

| captura | alvo | seta (L×A) | anel (L×A) | caixa do anel |
|---|---|---|---|---|
| `b04-ataque-alvos-jog.png` (ref. `b03c`) | Lobo 1 (36,3), Manhattan 2 | 15×19 px | **43×33 px** | (536,277)–(578,309) |
| `b04-ataque-alvos-jog.png` | Bruto 1 (41,1), Manhattan 7 | 13×18 px | **39×27 px** | (732,226)–(770,252) |
| `b10-ataque2-alvos-jog.png` (ref. `b09`) | Lobo 1 (37,3), Manhattan 2 | 15×18 px | **42×32 px** | (578,281)–(619,312) |
| `b10-ataque2-alvos-jog.png` | Bruto 1 (39,3), Manhattan 2 | 14×17 px | **41×31 px** | (659,294)–(699,324) |

**(e) O nome inteiro na caixa** — `capturas/f1/b03-caixa-expandida-jog.png`: com o rato por cima da caixa (vista
expandida) lê-se «**Arqueira de Bancada**» inteiro, «na vez». Na compacta (`b03c`) o cartão abrevia («Arqueira …»), como
está desenhado.

**(f) Relato COMPLETO do journal** — `relato-journal-f1.md`: as 78 seqs, sem selecção nem buracos, cada linha com a
conferência; **121 conferências ✔, 0 ✘**. Traz declaradas, lidas no código que correu:
- a **regra do crítico**: verificação 3d6 à parte, 6-6 e o 3.º ≥ 5. Nesta batalha não houve críticos. Há um no anexo
  das 19:18, seq 8: «[8] = 14 → CRÍTICO», com a verificação [6,6,6];
- a **regra dos testes de morte**: d20 + CON contra CD = CON + 3 (bronze), sucesso com d20 ≥ 4, corrida 3×3, e +1 falha
  por cada dano directo enquanto está a morrer;
- **cada recibo de duas faces explicado** — um nesta batalha: seq 25, «[15] | [4] = 21». São dois conjuntos de 1d20,
  porque o ataque de oportunidade leva `niveisVantagem: 1`. Cada um soma +4 da ficha e +2 da vantagem: 21 e 10. Fica o
  maior, 21;
- **cada distância conferida contra Manhattan**: os 6 movimentos, passo a passo; custo = passos × 1,5 m = Manhattan × 1,5 m
  em todos. Nos 12 ataques fica a distância de Manhattan e de Chebyshev entre as figuras.

**(g) O journal bruto** — `journal/f1-1929/registo-MESTRE-ONLY-bancada-rede.json` (SHA-256
`3f5f6e35882cee3dbb07642a0ecf3755d1ac85bc4e9aab2d287508682ecf9978`), com os alertas e o `porteiro.log`. As fichas são as
fictícias de bancada (`ferramentas/fichas-bancada-usadas.json`). Ficam **de fora** o `servidor.log` e o `preparar.log`:
trazem os IPs da rede de casa, o QR da mesa e caminhos do PC (a sonda de privacidade do CI recusa-os). Não têm nada da
batalha que o journal não tenha.

### O que correu mal (dito às claras)

- A **primeira batalha na ponta** (19:18:10–19:22:52, também por morte, journal e capturas em `journal/f1-1918/` e
  `capturas/f1-1918/`, relato completo 133 ✔ / 0 ✘) **perdeu o vídeo**. O guião da F2 que escrevi a seguir trocava mal o
  caminho de saída, e o ffmpeg com `-y` gravou a F2 por cima dos dois mp4. Por isso a batalha foi repetida às 19:29 com
  pastas novas, e conferi o caminho com grep antes de lançar. Essa corrida mostra o que a das 19:29 não tem: um crítico
  (seq 8, [6,6,6]), uma estabilização (3 sucessos, vida 1, seq 50–51) e a reentrada a 0/0 quando foi ferida outra vez
  (seq 56).
- A corrida desta ordem que começou às 16:57 (no `e89235a`, a ponta de então) também acabou por morte, com vídeo. Ficou
  fora do pacote porque a ponta mudou entretanto (`cf1d315`, um commit do Android) e a ordem pede a batalha na ponta.

## F2 — o «na vez» 20 vezes (26/11/2026, 19:24:33–19:28:35 -03)

A tabela com as 20 medições está em **`f2-na-vez.md`**: vez, banner, caixa, concorda/discorda. Mesma ponta, mesmo
servidor e os mesmos dois clientes, em **modo manual**, para as vezes dos monstros ficarem paradas no ecrã. São 20 vezes
seguidas e todas diferentes (os `turno` com seq 3 a 51, rodadas 1 a 7). No início da vez **6 concordam e 14 discordam**.
As discordâncias ficam registadas para a bancada do coordenador (D-AUD-03). Vídeos na sede:

| ficheiro (na sede) | duração | resolução | SHA-256 |
|---|---|---|---|
| `video/f2-na-vez-jogadora.mp4` | 4:34.70 | 1280×720 | `f31420f7226620f1eabaa4188317a3b93ebe5ebea21ac79be2f06b7748d76195` |
| `video/f2-na-vez-mestre.mp4` | 4:34.53 | 1600×900 | `5bfb29374a8782d84381733689c4efafec443b5842b5466fe5474aa06cd7b886` |

| caminho | o quê |
|---|---|
| `f2-na-vez.md` | a tabela das 20 vezes e as discordâncias explicadas |
| `journal/f2/` | o journal bruto da F2 + `relato-journal.md` (51 ✔ / 0 ✘) |
| `capturas/f2/f2-grupo-*.png` | as faixas de cima da jogadora (banner + caixa), início e depois, 5 vezes por imagem |
| `capturas/f2/f1-auto-inicio-das-vezes-dela.png` | o mesmo recorte no modo auto (a batalha F1): «A sua vez» × «Bruto 1 na vez» |
| `guioes/lancar4.ps1`, `ligar4.ps1`, `v.ps1`, `f2-vezes.sh` | os guiões da F2 |

## Índice

| caminho | o quê |
|---|---|
| `relato-journal-f1.md` | o relato completo da batalha F1 (19:29) |
| `journal/f1-1929/` | o journal bruto da batalha F1, os alertas, o porteiro |
| `journal/f1-1918/` | a corrida de 19:18 sem vídeo (anexo): journal bruto + `relato-journal.md` |
| `capturas/f1/` | 17 capturas da batalha F1 (jogadora e Mestre), PNG sem perdas |
| `capturas/f1-1918/` | 4 capturas da corrida das 19:18 (caixa expandida, D-AUD-03, fim) |
| `medicoes/` | posições da figura, tamanhos dos marcadores (JSONL) e as duas capturas anotadas |
| `ferramentas/relato.mjs` | `node relato.mjs <registo.json> <fichas.json> "<título>"` → o relato (todas as seqs, com contas) |
| `ferramentas/pix.py` | `python pix.py figura <png>…` / `python pix.py marcadores <com.png> <sem.png>` (usa o ffmpeg) |
| `ferramentas/c.sh`, `s1-agente.ps1`, `journal.sh` | o canal para a sessão 1 (o agente lê `cmd/*.ps1` e escreve `*.out`) e o resumo do journal |
| `guioes/` | os guiões que conduziram a batalha (`lancar5`, `ligar5`, `m1`, `a1`, `t1s1`, `m2`, `a2`, `t2b`, `rondas-ate-ao-fim.sh`, `fim3`) |

Os caminhos do PC nos guiões estão trocados por `<JV>` (a pasta `jogo-verdadeiro`) e `<GODOT>`.
