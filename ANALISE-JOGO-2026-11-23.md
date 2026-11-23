# ANÁLISE DO JOGO — 2026-11-23 (ORDEM-ANALISE-PLANO-2)

**Cadeira:** Claude conta 1 (PC), Opus 5.5. **Linha:** `fable/integracao-50`, ponta `8e9bf81` (conferida por
`git ls-remote` no arranque; ver o ESTADO-FINAL). **Método:** só leitura (código, documentos, histórico de 821
commits). Não corri o jogo, as suites, o servidor nem o Godot. Os números «a correr» que cito são da auditoria da
conta 2 de hoje (`ESTADO-FINAL-ORDEM-AUDITORIA-LINHA.md`, commit `e37e16f`), e digo-o sempre que os uso.

**Regra de prova:** cada afirmação leva ficheiro:linha, commit ou documento. Onde não há prova, escrevo **[FALTA]**.

---

## 0. O plano original (os documentos que usei)

O plano original **não está no repositório**. O repositório só o cita: o README do cliente da subida inicial diz
«Especificação: Plano A v1.1 (JV2.1a, JV2.2, JV2.3) e Protocolo v2» (`git show 1325b0b:rascunhos/cliente/README.md`,
linha 8). Os textos estão no Notion, no «Laboratório do Claude», e li-os hoje:

| # | Documento (Notion) | Data | Papel |
|---|---|---|---|
| P1 | **Planos do Jogo Verdadeiro — Criação, Visual e Oficina 3D (v1.1)**, id `410c2b32-4ede-819e-8a7f-e5b9ce16e15d` | 06/11/2026 | Página-mãe: as 11 regras, a ordem geral das etapas 0–4 e o que chega ao Mestre |
| P2 | **Plano A — Criação do Jogo Verdadeiro no Godot (v1.1)**, id `410c2b32-4ede-8159-bfbb-c792e1a5a6fb` | 06/11/2026 | O plano de construção: A0 (o que é «pronto»), A1 (arquitectura), 28 missões JV0.1–JV4.4 e a errata v1.2 |
| P3 | **Plano B — Visual no estilo Arcane (v1.1)**, id `410c2b32-4ede-8137-b98b-f7e75afa7e89` | 06/11/2026 | O visual: 15 missões V0.1–V4.4 e o protocolo de medida B3 |
| P4 | **NAC-OV-06**, id `410c2b32-4ede-8191-a2a8-d863fb6d4a26` (Mestre-only; cito só a regra) | 06/11/2026 | A visão: «o campo de batalha digital das sessões do Mestre»; a régua é o jogo do site (jogo-t1) |

Trato **P1 + P2 + P3 como «o plano original»** (P4 é a visão que eles servem). O Plano C (Oficina 3D, personagens)
é a terceira perna da P1, mas é uma linha de produção fora deste repositório. Aqui só conta onde ela devia
**entrar no jogo** (a V3.1 do Plano B).

**Âncora da nota:** a auditoria de 30/10/2026 deu **4,7/10** à v3 (é anterior ao plano, que é de 06/11). Os eixos
dessa nota e o `GOAL.md` com a «Régua crítica» **[FALTA]**: não estão no PC, segundo a auditoria de hoje
(`ESTADO-FINAL-ORDEM-AUDITORIA-LINHA.md` §2, «Ressalva sobre a régua»). A auditoria de hoje deu **4,6/10** à
linha (mesmo ficheiro, §2).

---

## 1. O jogo hoje, para quem joga

### 1.1 O que acontece quando se abre

- **O Mestre** abre o ecrã do Mestre (`rascunhos/cliente/cenas/mestre/mestre.tscn`). À esquerda fica o tabuleiro 3D;
  à direita, a folha com abas. Na aba **Mesa** procura fichas, guarda a mesa, monta esquemas de colocação, carrega
  duas vezes em «Começar a batalha» e coloca cada criatura numa casa (`aba_mesa.gd`; README do cliente §«Ecrã do
  Mestre»). Na aba **Agir** comanda a criatura da vez em Manual, Semi ou Automático (`aba_agir.gd`). Recebe
  **cartões** para aprovar o que a IA propõe, as desgraças e os dados físicos. Tem o **Registo**, o «Voltar até
  aqui», «Exportar registo», «Terminar batalha» e «Recomeçar» (commit `4c3f093`). Também tem o painel do ambiente:
  raio, fogo e chuva (`servidor/nucleo/ambiente.js`).
- **A jogadora** entra no lobby com o nome da personagem e uma senha, e espera (`cenas/lobby/lobby.gd`). Quando o
  Mestre começa, entra na arena (`project.godot:11`, a cena principal é `cenas/arena/arena.tscn`). Tem a barra
  **Ataque · Mover · Consumível** (`hud/hud.gd:201-203`), com Correr, Transformação, «Sair c/ segurança» e «Apagar o
  fogo» (`hud.gd:642-708`). Na ficha há o «Declarar Defender» (`hud.gd:652-668`). A ⚙ traz o perfil gráfico, a câmara
  (Fixa, 360° e Panorama: `camera/camera_mesa.gd:15`), «Repor o zoom», a tela vermelha e o pulso, e «Sair da mesa»
  (`hud.gd:299-337`). Vê números de dano, a tela vermelha e as frases de batalha do site (`hud/frases_batalha.gd`).
- **As duas pontas** vêem a **caixa da ordem de turnos**: o cartão grande da figura na vez e as 4 seguintes; com o
  rato ou um toque, a ordem inteira, com retratos em busto (`hud/caixa_ordem.gd`, `hud/retratos.gd`, commit `878b13e`).
- **O mundo** é o **mapa da floresta**: relevo, lago (que se pisa e onde se nada), relva que se dobra, árvores, ciclo
  de dia e noite com lua, vento, chuva e neve (`rascunhos/cliente/mapa/floresta/`, 139 ficheiros; `arena.gd:11`,
  «Ordem 42: o campo de batalha é o MAPA DA FLORESTA»). A escala é de 1, 1,5 ou 2 m por casa (commit `084b690`).

### 1.2 O que funciona (medido a correr pela auditoria de hoje, não por mim)

- **Uma batalha corre do lobby ao fim** com o servidor de produção, o motor VLAB real e 2 clientes Godot reais: 9
  rodadas, 18 ataques, a IA a jogar, pausa e retomada quando o Mestre cai, e 0 SCRIPT ERROR
  (`ESTADO-FINAL-ORDEM-AUDITORIA-LINHA.md` §1).
- O ecrã do Mestre corre a 144 FPS com vsync (mesmo ficheiro, §4). As suites estão verdes: servidor 421/421 e
  cliente 321/321 (mesmo ficheiro, §5).
- Sem janela, o autojogo leva batalhas até à morte com o motor real (3/3 partidas com vencedor:
  `provas/ordem-autojogo/ESTADO-FINAL.md`).

### 1.3 O que um jogador NÃO consegue fazer hoje

1. **Jogar no seu próprio aparelho.** Não há export (não existe `rascunhos/cliente/export_presets.cfg`, e o
   `.github/workflows/testes.yml` não tem nenhum passo de export). Não há build web, nem APK, nem `.exe`, nem QR. A
   batalha mais completa até hoje correu com **2 clientes no mesmo PC** (auditoria §1).
2. **Ver um golpe acertar** na bancada de rede: as fichas da bancada têm CA-canário, e 18 de 18 ataques erraram
   (D-AUD-04).
3. **Ver um corpo a mexer-se.** As figuras do jogo são primitivas: cilindro e icosaedro, copiados do marcador do site
   (`cenas/comum/marcador_figura.gd:1-10, 40-71`). Os únicos GLB com ossos (`testes/manequim/andar-v3.glb`,
   `nado-v1.glb`) só aparecem nos testes, nos vídeos de prova e nos retratos da caixa (`hud/retratos.gd`). Nenhum
   ataque tem animação (auditoria, eixo Animações = 2).
4. **Usar um consumível ou uma reacção:** o servidor devolve sempre listas vazias (`servidor/nucleo/sala.js:947`,
   `consumiveis: [], … reacoes: []`; `sala.js:2227` TODO).
5. **Ver a própria vida e os PA** em combate (D-AUD-09), ou ver a fórmula do dado: a jogadora só lê «Errou. Total
   14.» (`hud.gd:841-849`), sem as faces nem a soma.
6. **Ver-se na água:** a figura desaparece ao entrar no lago (D-AUD-02). A câmara também não a segue (D-AUD-05).

---

## 2. Avanço contra o plano original, item a item

As marcas são estas:
- **FEITO** — cumpre o objectivo da ficha; o aceite completo pode faltar e, nesse caso, digo-o.
- **EM PARTE** — parte do objectivo existe.
- **NÃO COMEÇADO** — não há código nem documento no repositório.
- **DESVIADO** — foi feito outra coisa no lugar.

### 2.1 Plano A — A0, o que é «pronto» na v1 (P2 §A0)

| Critério | Marca | Prova |
|---|---|---|
| Sessão real: o Mestre narra e comanda, as jogadoras jogam cada uma no seu aparelho | **NÃO COMEÇADO** | Não há export nem prova em aparelhos (JV2.1b, JV3.4b e JV4.4, abaixo); a bancada usa 2 clientes no mesmo PC (auditoria §1) |
| Batalha completa em 20×20 com as regras oficiais e zero dados do Mestre no aparelho das jogadoras | **EM PARTE** | Corre do princípio ao fim (auditoria §1) e a projecção tem canários a 10/10 (auditoria §5). Faltam os consumíveis e as reacções (`sala.js:947`), e não é possível acertar na bancada (D-AUD-04) |
| Visual: a Clareira de prova aprovada pelo olho do Mestre | **NÃO COMEÇADO** (aprovação) | A `arte/cenas/clareira_prova.gd` é «tudo PLACEHOLDER» (README do cliente §Clareira). Uma aprovação do Mestre **[FALTA]**: procurei «o Mestre aprov…», «Aprovo» e «olho do Mestre aprov…» em todo o repositório e não há nenhuma sobre a cena |

### 2.2 Plano A — as 28 missões (P2 §A3)

| ID | Missão | Marca | Prova |
|---|---|---|---|
| JV0.1 | Régua R0 (inventário do site, 44 itens + fotos) | **EM PARTE** | O site foi lido aos bocados, por «sondas temporárias» (commits `6b06182`, `bd2393a`, `0396f60`) e referências REF_n no código. A página «Régua R0» **[FALTA]**: a busca no Notion não a encontrou. O código ainda tem perguntas R0 abertas (`sala.js:820, 931, 935, 1443, 1462, 1586, 1594, 1599, 1676`) |
| JV0.2 | Repositório e CI | **EM PARTE** | O repositório privado é provisório (`README.md`: «A decisão definitiva do repositório fica na JV0.5»). Tem CI de testes e sonda (`.github/workflows/testes.yml`, `privacidade.yml`). **Faltam** o export web de prévia e o «pronto» no Chromium (aceite da ficha), e o repositório público de builds |
| JV0.3 | Vetores-ouro (≥500 casos, 9 grupos) | **NÃO COMEÇADO** | Nenhum `vetores-ouro` no repositório (`git ls-files`). No lugar deles o CI baixa o motor vivo e corre a integração (`testes.yml:49-55`). O `servidor/README.md:39` continua a dizer «confirmar nos vetores-ouro» |
| JV0.4 | Protocolo v2 | **EM PARTE** | Há 32 schemas e exemplos em `rascunhos/protocolo/v2/`, validados no CI (`testes.yml:76-80`). **Falta** o `VISIBILIDADE.md` (não existe; a visibilidade vive em `servidor/nucleo/projecao.js`) |
| JV0.5 | Bancada da fundação (5 sentenças) | **EM PARTE** | Dono: o Muse. As sentenças **[FALTA]**. Na prática: o repositório ficou provisório (README) e o papel do Mestre foi para dentro do app Godot (JV3.2, abaixo), sem a sentença (c) à vista |
| JV0.6a | Fichas: formato e carregador | **FEITO** | `servidor/nucleo/carregar-fichas.js` (543 linhas), `testes/fichas.test.mjs`, `dados-exemplo/fichas-ficticias.json`. O ficheiro `schema-fichas.json` pedido não existe: o validador está no carregador |
| JV0.6b | Fichas: pacote real | **[FALTA]** | Dono: o Muse, fora do repositório por regra. Não há nenhuma prova de que exista. A bancada só tem fichas-canário (D-AUD-04) |
| JV1.1 | Sala autoritativa | **FEITO** (o aceite do workerd não) | `sala.js` (3570 linhas): turnos, BFS, ataques, AoO, cartões, recibos e idempotência (`testes/idempotencia.test.mjs`); núcleo sem `node:*` (`servidor/README.md`, «Estrutura»); motor real no CI (`testes.yml:55`). Bugs da ficha: B7 (`sala.js:608`), B13 (`ordem9-oportunidade.test.mjs`). **Falta** o workerd (só existe em comentários) |
| JV1.2 | Projecção por destinatário | **FEITO** | `projecao.js`, `testes/privacidade.test.mjs` e `cliente/testes/canario_privacidade.gd` (10/10, auditoria §5). A re-corrida independente pelo Muse **[FALTA]** |
| JV1.3 | Dados e rolagens | **EM PARTE** | A semente fica no evento (`soMestre.semente`, D-AUD-15) e o Mestre confirma os dados físicos (`MASTER_CONFIRM_DICE`, `sala.js:2534, 2662`). **Falta** validar o intervalo das faces (`sala.js:201`, TODO M-28). A suspeita sobre os dados (D-AUD-15) está por confirmar |
| JV1.4 | Journal, salvar e restaurar | **FEITO** | `journal.js`; o journal grava em disco (`ordem16-journal-disco.test.mjs`); restauração com fuzz (`ordem34-n31-1.test.mjs`, commit `7585489`). Resto: os checkpoints do «voltar» só vivem em memória (`sala.js:1229`) |
| JV1.5 | Medição da hospedagem (Cloudflare) | **NÃO COMEÇADO** | Não há adaptador workerd nem medição (`grep workerd`: só comentários em `sala.js`, `sha256.js` e `util.js`) |
| JV2.1a | Cliente Godot base | **FEITO** | `rede/rede.gd`, `estado/estado.gd`, `cenas/arena/`; 108 scripts abrem e há 321 verificações (auditoria §5) |
| JV2.1b | Pipeline de export (web, Android, Windows) | **NÃO COMEÇADO** | Não há `export_presets.cfg` nem passo de export no CI (`testes.yml`) |
| JV2.2 | Arena, grelha e câmaras | **EM PARTE** | A arena é o mapa inteiro, em qualquer escala (commit `d123f9f`). Câmaras Fixa, 360° e Panorama (`camera_mesa.gd:15`). **Faltam** a câmara dinâmica e o retrato (M-33), e a câmara que segue a figura (D-AUD-05) |
| JV2.3 | HUD da régua | **EM PARTE** | Há a barra, a ⚙, a tela vermelha e os números de dano (`hud.gd`). **Falham** o «na vez» atrasado (D-AUD-03), a vida e os PA que a jogadora não vê (D-AUD-09) e o dano por tipo, porque o servidor manda um só valor (`estado/estado.gd:510`, «DIVERGÊNCIA»). A checklist R0 **[FALTA]** |
| JV2.4 | Batalha completa contra o servidor | **EM PARTE** | Lobby → fim na bancada (auditoria §1) e morte no autojogo (`provas/ordem-autojogo/ESTADO-FINAL.md`). **Faltam** os consumíveis e as reacções (`sala.js:947, 2227`) e a batalha roteirizada contra os vetores-ouro (que não existem) |
| JV3.1 | Lobby e entrada | **FEITO** | Nome e senha (`lobby.gd`). O Mestre escolhe o mapa, as criaturas e os NPCs (`MASTER_LOBBY_SET`, `sala.js:2516-2517, 2585`) e coloca cada uma (`MASTER_PLACE`), também por esquema (L5, README do cliente) |
| JV3.2 | Ligação da superfície do Mestre (C-17) | **DESVIADO** | Em vez de ligar a C-17 da Cloudflare, o ecrã do Mestre foi feito **dentro do app Godot** (`cenas/mestre/`, 1453 linhas só no `mestre.gd`), pelo desenho «JV3.1 — Ecrã do Mestre no cliente», aprovado com emendas (Notion `412c2b32-4ede-817c-9c60-e3738c621ef6`). O conteúdo pedido existe: modos H10, cartões, dados físicos, voltar e exportar, pesquisa. A sentença JV0.5 (c) que o autorizava **[FALTA]**. Os testes HUD-SM-01 a 12 **[FALTA]** |
| JV3.3a | Regras do ambiente | **EM PARTE** | Raio, fogo e chuva em `ambiente.js`. **Desvio:** o dano 15 está no código (`ambiente.js:35`, `DANO_RAIO = 15`), e a ficha mandava que viesse do pacote do Mestre. O deslizador da hora no servidor **[FALTA]** (o ciclo existe no cliente: `mapa/floresta/ciclo_dia.gd`) |
| JV3.4 | Rede local e reconexão | **EM PARTE** | Funcionam a ressincronização, a pausa quando o Mestre cai e a retomada (auditoria §2, Continuidade; `estado.gd`, ROOM_RESYNC). O servidor serve estáticos (`servidor-ws.js:432-455`), mas não há export para servir nem QR. O teste de 3 bots com 25 s sem rede **[FALTA]** |
| JV3.4b | Prova em aparelhos reais | **NÃO COMEÇADO** | Precisa de export, e não há |
| JV3.5a | IA de batalha no servidor | **EM PARTE** | Há a «IA simples (REF_7 §6)» (`sala.js:2232`), e a razão vai só para o Mestre, nos cartões (`sala.js:1049`). A doutrina «gerar → 6 críticos → Juiz» não está |
| JV3.5b | Exame da IA (≥10 000 batalhas por arena) | **NÃO COMEÇADO** | O autojogo correu 3 partidas, com uma IA de bancada «a mais simples possível» (`provas/ordem-autojogo/ESTADO-FINAL.md`) |
| JV4.1 | Capítulo de Tiro | **NÃO COMEÇADO** | A linha de visão continua TODO (`servidor/README.md`, «Regras ainda abertas»). Há cobertura do terreno (`ordem59-fronteira-cobertura.test.mjs`), mas não o capítulo |
| JV4.2 | Replay e salvar/carregar | **EM PARTE** | A restauração e o «Continuar» funcionam (auditoria §1, `retomada`). O replay colectivo não existe (`sala.js:3231`, TODO) |
| JV4.3 | Ficha interativa e machucado | **NÃO COMEÇADO** | A FICHA só tem «Reacção / Declarar Defender» (D-AUD-09; `hud.gd:652-668`). Não há machucado no corpo: as figuras são primitivas |
| JV4.4 | Publicação | **NÃO COMEÇADO** | Não há builds |

### 2.3 Plano B — as 15 missões (P3 §B4)

| ID | Missão | Marca | Prova |
|---|---|---|---|
| V0.1 | Guia de estilo | **[FALTA]** | Dono: o Muse; nenhuma prova no repositório. Os shaders do repositório citam o Plano B, mas não um guia (`arte/shaders/*.gdshader`) |
| V0.2 | Triagem de assets | **[FALTA]** | Dono: o Muse; nenhuma prova |
| V1.0 | Linha de base no aparelho (link de 1 minuto) | **NÃO COMEÇADO** | Precisa do export web, e não há |
| V1.1 | Kit de materiais e luz | **EM PARTE** | `arte/shaders/` (toon pintado, contorno, folhagem com vento, céu), `arte/rampas/gerar_rampas.gd`, `arte/ambiente/color_script.gd`. **Faltam** o `docs/orcamento-perfis.md` (não existe), as rampas geradas (README do cliente §Clareira, ponto 2) e as métricas B3 no aparelho |
| V1.2 | Kit de feedback | **EM PARTE** | Há os números de dano e a tela vermelha (`hud.gd:75-104, 813-820`). Não há flash, recuo nem VFX em flipbook (auditoria: Animações 2, «nenhum ataque tem animação visível») |
| V2.0a | Bloco T1 | **[FALTA]** | Dono: o Muse |
| V2.0b | Lapidação | **[FALTA]** | Dono: o Muse |
| V2.0c | Vagalumes no Godot | **EM PARTE** | Só existem na Clareira de prova (`arte/cenas/clareira_prova.gd`), não no mapa do jogo |
| V2.1 | A Clareira (o marco principal) | **DESVIADO** | A Clareira ficou em placeholder (README do cliente §Clareira, «tudo PLACEHOLDER»). No lugar dela cresceu o **mapa da floresta** (139 ficheiros, 140 commits em `mapa/` + `arte/`), que passou a ser o campo de batalha (`arena.gd:11`). A página de entrega «Aprovo / Quero ajustes» **[FALTA]** |
| V3.1 | Entrada dos personagens | **NÃO COMEÇADO** | As figuras são marcadores do site (`marcador_figura.gd:1-10`). Nenhum GLB de personagem entra na arena |
| V4.1 | Kit modular T1–T8 | **[FALTA]** | Dono: o Muse |
| V4.1b | Integração dos kits | **NÃO COMEÇADO** | Não há `cliente/arte/materiais/` |
| V4.2 | Vida ambiente D-01 a D-13 | **EM PARTE** | Há vento, relva que se dobra e água que reage (commits `aa26e65` e `861a9fe`; `mapa/floresta/rastro_relva.gd`). A lista D-01 a D-13, para conferir, **[FALTA]** |
| V4.3 | Clima e hora (visual) | **FEITO** (o raio pintado não) | Ciclo de dia e lua, chuva, neve e vento (Ordens 40, 41, 42, 43 e Neve; `arte/clima/`, `mapa/floresta/ciclo_dia.gd`). O flash pintado do raio e o fogo em flipbook **[FALTA]** |
| V4.4 | Perfis (confirmação) | **EM PARTE** | Há os perfis Baixo, Médio e Alto (`arte/perfis/aplicar_perfil.gd`). Não houve medição em aparelhos reais (V1.0 não existe) |

### 2.4 Contagem (sustentada pelas tabelas 2.1–2.3)

| Marca | Plano A (28 missões) | Plano B (15 missões) | A0 (3 critérios) |
|---|---|---|---|
| FEITO | 6 — JV0.6a, 1.1, 1.2, 1.4, 2.1a, 3.1 | 1 — V4.3 | 0 |
| EM PARTE | 12 — JV0.1, 0.2, 0.4, 0.5, 1.3, 2.2, 2.3, 2.4, 3.3a, 3.4, 3.5a, 4.2 | 5 — V1.1, 1.2, 2.0c, 4.2, 4.4 | 1 |
| NÃO COMEÇADO | 8 — JV0.3, 1.5, 2.1b, 3.4b, 3.5b, 4.1, 4.3, 4.4 | 3 — V1.0, 3.1, 4.1b | 2 |
| DESVIADO | 1 — JV3.2 | 1 — V2.1 | 0 |
| [FALTA] (de outro dono, sem prova) | 1 — JV0.6b | 5 — V0.1, 0.2, 2.0a, 2.0b, 4.1 | — |

Plano A: 6 + 12 + 8 + 1 + 1 = 28. Plano B: 1 + 5 + 3 + 1 + 5 = 15.

**Leitura:** a **fundação** (Fase 0–1 do Plano A: servidor, projecção, journal, cliente base, lobby, ecrã do Mestre)
está **feita e sólida**. O que **falta** é quase tudo o que o jogador vê e toca: **exportar para os aparelhos**
(JV2.1b, JV3.4b, JV4.4, V1.0), **personagens e animação** (V3.1, V1.2, JV4.3), as **duas acções que faltam**
(consumível e reacção) e a **aprovação visual** do Mestre (V2.1).

---

## 3. Onde o rumo se perdeu

**Sem rodeios: o rumo perdeu-se, e em duas curvas datadas.**

### 3.1 O esforço medido pelo histórico

Classifiquei os 821 commits pelo assunto (`git log --format=%s`):

| Tema | Commits | 06–15/11 | 16–23/11 |
|---|---|---|---|
| Núcleo: servidor, ecrã do Mestre, lobby (I0004, JV3.1) | 159 | 158 | **1** |
| Mapa, ambiente, água e escala (Ordens 36–66, Clima, Neve, Grama, Lago, Nado, Escala) | 230 | 173 | 57 |
| **Caixa da ordem de turnos** (CAIXA-*) | **128** | 2 | **126** |
| **Ferramentas de prova e conferências** (F25–F156, redigir-nomes, mutação, D1) | **66** | 6 | **60** |
| Arrumação (listas da retoma, manifesto, notas do CI) | 189 | 85 | 104 |
| HUD, iniciativa, bancada, CI, fusões e outros | 49 | 8 | 41 |

E o que tocou **código do jogo**, fora dos testes e das ferramentas (`git log -- rascunhos/cliente/*.gd …
rascunhos/servidor/nucleo …`):

| Período | Commits | Tocam código do jogo |
|---|---|---|
| 06–15/11 | 432 | 177 (41 %) |
| 16–20/11 | 104 | 40 (38 %) |
| **21–23/11** | **285** | **15 (5 %)**, e 13 desses 15 são a caixa da ordem |

Em linhas, pela soma das linhas acrescentadas por pasta (`git log --numstat`): `provas/` recebeu **+1 044 662**
linhas (1482 ficheiros, 679 MB); 677 desses ficheiros são da caixa. O código do jogo inteiro (cliente + servidor +
protocolo) soma ≈ **+85 000**. A raiz tem **108** ficheiros `ESTADO-FINAL-*`.

### 3.2 Primeira curva (≈ 13–20/11): o mapa no lugar da Clareira

- O plano mandava fazer **uma clareira pequena, aprovada pelo olho do Mestre, antes de crescer**. A regra está na P3
  §V2.1: «a sessão de teste com o Mestre só acontece com a Clareira aprovada».
- Em vez disso foi construído um **mapa da floresta grande e completo**: céu cozido, lua com fases, estações, vento,
  relva, lago, nado, neve, chuva e altura única (Ordens 36–66; 230 commits no tema; 139 ficheiros em `mapa/`). Ele
  passou a ser o campo de batalha (`arena.gd:11`).
- O resultado é bonito a correr («o terreno, o lago, as árvores… são bonitos no GPU real», auditoria, Estética 5). Mas:
  1. a aprovação do Mestre **[FALTA]**;
  2. as figuras que andam nele continuam a ser peões (V3.1 não começou);
  3. a água esconde a figura (D-AUD-02), que é custo da própria obra do lago.
- **O que ficou por fazer por causa disso:** a V1.0 (medir no celular), a V3.1 (personagens) e a JV2.1b (export),
  que eram da etapa 1–2 e são pré-requisitos da sessão com o Mestre.

### 3.3 Segunda curva (20–23/11): a caixa da ordem e a máquina de provas

- **A caixa da ordem de turnos não está no plano original** (não aparece nem na P2 nem na P3). É palavra posterior
  do Mestre (`ORDEM-CONTINUACAO-HUD.md`; a regra «cartão grande + 4 próximos», commit `878b13e`; a paleta C de
  21/11 12:12, commit `a63c2c1`). Era legítimo fazê-la.
- O problema é a **proporção**. A caixa levou **128 commits** e **677 ficheiros de prova**. Correu em cascatas de
  correcção de correcção:
  - `CAIXA-RELATO-CORRECOES` até à **-12**;
  - `CAIXA-RELATO-B7-CORRECOES` até à **-9**;
  - `CAIXA-TESTES-CORRECOES` até à **-14**;
  - `CAIXA-JANELA-COBERTURA-CORRECOES` até à **-7**.
  
  Em 21–23/11, essas ordens mexeram em **13 commits** de código.
- Depois vieram **60 commits de «F-n»** (F25 a F156) sobre a **ferramenta que apaga nomes dos logs das provas**, a
  mutação do canário, a frase de um README e o tabulador. Exemplos: `da4f73e` (F132, guarda do tabulador),
  `77ba415` (F128, a frase do limite), `8124dce` (F116, o mutante). **Nenhum** muda o jogo.
- **Resultado medido:** a nota não se mexeu (4,7 → **4,6**, auditoria §2). Os eixos que o jogador vê ficaram em
  baixo: Animações 2, Ataques 3, HUD 4. E a própria caixa tem 2 dos 15 defeitos (D-AUD-03 e D-AUD-06).

### 3.4 O que NÃO se perdeu (para ser justo)

- As Fases 0–1 do Plano A seguiram o plano à risca entre 06 e 15/11: 158 commits de núcleo. Estão provadas por
  testes e, hoje, por uma batalha real de ponta a ponta (§2.2: JV1.1, JV1.2, JV1.4, JV2.1a e JV3.1 FEITO).
- O ecrã do Mestre é o melhor bocado do jogo (Código/Sistemas 7, 144 FPS). Desviou-se da C-17, mas cumpre o
  objectivo da JV3.2.

### 3.5 A causa (pelo que os documentos mostram)

1. **As ordens deixaram de partir do plano.** Desde a Ordem 36 os assuntos dos commits citam «Ordem n», «sentença da
   F-n» e «CORRECOES-n», e não as missões JV/V. A última referência a uma missão do plano num assunto é «JV3.1 ordem
   35», de 13/11 (`git log`). A partir daí nenhuma ordem diz que missão fecha.
2. **O critério de aceitação passou a ser a prova e não o jogo.** As conferências pedem provas da prova (mutação,
   redacção dos logs, frases do README), e cada sentença abre uma ordem nova.
3. **A etapa que desbloqueia o Mestre — export + aparelhos + Clareira — nunca foi ordenada.** Não há nenhum commit
   com «export», «preset», «APK» ou «web» como obra (`git log --format=%s | grep -iE 'export (web|android)|preset'`
   devolve 0 linhas).

---

## 4. Como o jogo pode melhorar (por ordem de importância para quem joga)

1. **Pôr o jogo nos aparelhos.** Export web, Android e Windows; o servidor serve o export com QR; prova numa rede de
   casa com 1 telemóvel e 1 PC. Sem isto, a visão («cada um no seu aparelho») é zero. Missões: JV2.1b, JV3.4,
   JV3.4b, V1.0.
2. **Fichas de bancada que acertam.** Fichas fictícias jogáveis, para se ver dano, queda e morte na mesa de rede
   (D-AUD-04). Sem elas não se medem os ataques nem as animações.
3. **Ver-se a si mesma.** A câmara segue a figura da jogadora (D-AUD-05). A figura vê-se na água (D-AUD-02; a
   profundidade é [DECISÃO DO MESTRE], auditoria §6). A caixa não tapa a figura nem as casas (D-AUD-06).
4. **A HUD diz a verdade.** O «na vez» certo (D-AUD-03), a vida e os PA da jogadora (D-AUD-09, onde é [DECISÃO DO
   MESTRE]), o dano por tipo (`estado.gd:510`). E **o dado com a fórmula à vista**: hoje só há «Total 14» (`hud.gd:849`).
5. **O Mestre sem armadilhas.** O «Colocar» desarma depois de colocar (D-AUD-01: hoje duplica criaturas), as
   criaturas iguais ganham número (D-AUD-12) e o tabuleiro ocupa o ecrã (D-AUD-14).
6. **Figuras com corpo e animação.** Personagens GLB com ossos (V3.1, pela linha do Plano C), andar, atacar, ser
   atingido, cair e nadar; o mesmo corpo nos dois ecrãs (D-AUD-11); flash e recuo no acerto (V1.2).
7. **As acções que faltam:** consumível e reacção (`sala.js:947, 2227`).
8. **A aprovação visual do Mestre** sobre o mapa da floresta, como «Clareira» (V2.1), de dia e de noite (com o
   contraste nocturno, D-AUD-13).
9. **Depois:** tiro (JV4.1), replay (JV4.2), ficha interativa e machucado (JV4.3) e publicação (JV4.4).

O como, por fases e com os critérios de aceitação, está em `PLANO-2-FECHO-DO-JOGO.md`.
