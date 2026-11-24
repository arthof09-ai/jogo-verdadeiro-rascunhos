# ESTADO-FINAL — ORDEM-D-AUD-04-BANCADA (bancada de rede com fichas fictícias que acertam)

**Estado: FEITA.** A bancada de rede tem agora um 2.º jogo de fichas, `-Fichas acertam`, com fichas FICTÍCIAS e
números jogáveis. Numa batalha inteira na bancada verdadeira (servidor de produção, motor real, cliente da jogadora e
**ecrã do Mestre em Godot**, os dois com janela) houve **18 ataques: 10 acertos, 1 crítico e 7 erros**. Houve também
dano, uma **morte** (o lobo), a **queda** da arqueira a 0, **10 testes de morte** e a **morte** da arqueira, e a
batalha acabou em `fim` com o desfecho `morte`. Ficaram medidos o dano, a queda, a morte, as animações e a HUD de
dano, todos com prova. O jogo não foi tocado. Os desvios que a bancada mostrou estão registados no §4 e não foram
corrigidos. O CI está na nota do fim.

- **Executor:** Claude (opus), PC. **Data:** 23/11/2026. A batalha decorreu das 18:26:58 às 18:40:57 (-03), numa
  1.ª corrida desta ordem. O fecho (extracto, suites, provas e este ESTADO-FINAL) foi feito das ~20:55 às ~21:20.
- **Linha:** `fable/integracao-50`, trabalho directo. A `main` não foi tocada.
- **Ponta de partida:** `96baf99` (nota do CI da D-AUD-01-CORRECCOES), clonada em `ordem-d-aud-04-bancada-pc/repo`.
  Antes de commitar, `git fetch` mostrou que a linha tinha andado para `cef07e7` (os 2 commits da D-AUD-INVESTIGA, só
  em `provas/ordem-d-aud-investiga/` e no ESTADO-FINAL dela, sem ficheiros em comum com esta ordem). Avancei por
  fast-forward. Os commits desta ordem assentam em **`cef07e7`**.
- **A corrida da 1.ª volta morreu às 18:44:28 pelo limite de 5 h; o fecho foi retomado às 20:55 do ponto exacto e feito das ~20:55 às ~21:20.** A batalha acabou às 18:40:57 e todos os processos da bancada (servidor, porteiro e 2 clientes) estão parados. As suites Godot ficaram para o CI (§6), porque esta
  ordem não muda nenhum ficheiro que elas leiam.

## 1. Como a bancada passou a acertar

O defeito era da bancada, não do jogo. O `preparar.mjs` só escrevia as fichas dos testes do servidor, com números
**canário** (CA 5551/9137) contra `1d20+4`, e com elas nenhum ataque pode acertar.

| Ficheiro | Mudança |
|---|---|
| `bancada-rede/preparar.mjs` | Opção nova `--fichas=canario\|acertam`. `canario` fica como por omissão e dá a config e as fichas **byte a byte iguais** às de antes, fora a chave nova `bancada` (conferido contra o `preparar.mjs` da ponta). `acertam` usa as fichas FICTÍCIAS de bancada que já estavam na linha (`rascunhos/servidor/autojogo/fichas-bancada.json`, Ordem AUTOJOGO) e a iniciativa e as senhas do `cenario-bancada.json`. Também escreve `bancada.criaturas` na config, uma chave só da bancada que o servidor não lê. A sala continua **sem `mapa`**, ou seja, na grelha-mapa da linha |
| `bancada-rede/porteiro.mjs` | Lê as criaturas de `bancada.criaturas`. Sem essa chave, usa o orc-teste de origem. Os nomes das jogadoras vêm da config, em vez de estarem fixos |
| `bancada-rede/lancar.ps1` | Opção `-Fichas`, passada ao `preparar.mjs`. Os rótulos das jogadoras vêm da config |
| `bancada-rede/README.md` | A tabela dos dois jogos de fichas |

**As fichas** (todas inventadas e marcadas FICTÍCIO DE BANCADA no próprio ficheiro; nenhum nome é de pessoa):

| Ficha | Lado | CA | Vida | RD | Ataque usado na batalha | Dano |
|---|---|---|---|---|---|---|
| Arqueira de Bancada | jogadora | 13 | 22 | 0 | `tiro-certeiro-bancada` 1d20+6, 2 PA, 12 m | 2d6+2 perfurante |
| Lobo de Bancada | criatura | 13 | 16 | 0 | `mordida-bancada` 1d20+4, 1,5 m | 1d6+2 perfurante |
| Bruto de Bancada | criatura | 12 | 34 | 1 | `clava-bancada` 1d20+4, 1,5 m | 1d10+3 contundente |
| (Espadachim de Bancada, com `-Aliada`) | jogadora | 14 | 30 | 0 | — (não entrou nesta batalha) | — |

Aviso: o `cenario-bancada.json` traz `mapa: {20, 20}` e `mapaId: "floresta"` («na grelha 20 x 20 da arena») — é o mapa do harness do AUTOJOGO, que o `preparar.mjs` não lê (só lê `cenario.fichas`, `cenario.heroinas` e `cenario.iniciativa`); a batalha usou a grelha-mapa 50×50 @ 1,5 m (§2).

**As casas:** a arqueira em (38,4), em terra a norte do lago, que é a casa da heroína de origem. O lobo em (36,3) e o
bruto em (41,1), também em terra e ao alcance do arco. Ficaram em terra de propósito, porque dentro de água as figuras
somem (D-AUD-02).

**Calibração sem janelas** (`provas/.../ferramentas/ensaio-rede.mjs`, servidor de produção pela rede, motor real):
- No 1.º ensaio o bruto estava em (34,5), encurralado entre uma árvore e rochas. A IA ficou em «nada a fazer» até à
  rodada 61 (3 ataques). Por isso o bruto passou para (41,1). (A posição (34,5) está no nome do ficheiro e no comentário do `preparar.mjs`, não no JSON do ensaio.)
- O 2.º ensaio chegou ao fim: rodada 23, **28 ataques, 18 acertos**, 16 testes de morte, desfecho `morte`
  (`provas/.../ensaios/`).

## 2. A batalha medida e o §5.3

Lançamento: `bancada-rede/lancar.ps1 -Fichas acertam -Modo auto -Porta 8791 -HostServidor 127.0.0.1`. O servidor
de produção (`servidor-ws.js`) correu com o motor real (VLAB, em cache). O porteiro preparou a mesa
(LOBBY_SET → START → lobo e bruto) e abriram-se **dois clientes Godot 4.7.2 com janela**: o da jogadora e o
**ecrã do Mestre**. O cliente headless `e2e_mestre.gd` **não** foi usado. O porteiro só sai quando «o ecrã do Mestre
(Godot) entrou na sala» (`logs/porteiro.log`). Os dois `godot.log` dizem Godot 4.7.2 com a RTX 4060 e
**0 SCRIPT ERROR**. Entre as 18:34 e as 18:35 o Mestre saiu da sala e voltou a entrar pelo ecrã do PIN do próprio
Godot. O servidor pôs a sala em pausa (`mestre_desconectado`, journal #7) e retomou-a quando o Mestre carregou em
«Continuar» (#8). O journal só regista `mestre_desconectado` e a retoma por «Continuar»; nada nas provas distingue uma saída deliberada de uma queda.

**§5.3 — a batalha correu na grelha-mapa 50×50 @ 1,5 m.** As fontes são estas:
1. **A configuração da sala que produziu a batalha** (`provas/ordem-d-aud-04-bancada/journal/config-da-sala.json`,
   cópia redigida de `bancada-rede/privado/config.json`, escrita pelo `preparar.mjs --fichas=acertam`): a `sala` não
   tem a chave `mapa`, e por isso o servidor usa a grelha-mapa da linha (ORDEM MAPA-JOGÁVEL §0).
2. **O journal do servidor dessa batalha** regista `estado.mapa = {"largura": 50, "altura": 50, "casaM": 1.5}`
   (`journal/journal-extracto.json`, campo `mapa`).
3. **O ecrã do Mestre em Godot** mostra «Escala: 1,5 m por casa» na aba Sala (`capturas/c01`). O `godot.log` dos dois
   clientes dá `casas: 2500` (= 50 × 50).

O `mapaId: "arena-teste"` que o journal e o `porteiro.log` trazem é um rótulo fixo do porteiro (`porteiro.mjs`, l.125), guardado como metadado do lobby (`sala.js`, l.2592) e nunca lido para construir a geometria — a grelha vem de `config.mapa` ou do omisso MAPA-JOGÁVEL (`sala.js`, l.316–322, l.573). Não é um mapa.

## 3. As medições (provas em `provas/ordem-d-aud-04-bancada/`, mapa no README de lá)

### 3.1 Dano, ataque a ataque

Os números vêm de `journal/medicoes.json`. O 3d6 é a verificação de crítico do VLAB. Regra do crítico (VLAB, `sala.js`): crítico é o 3d6 «6,6 e o 3.º ≥ 5» (margem 0); o 20 natural não é crítico por si só — por isso o #40 (d20 20, 3d6 [5,6,6]) é acerto e o único crítico é o #90 (d20 17, 3d6 [6,6,6]).

| # | Atacante → alvo | d20 | Total vs CA | 3d6 | Resultado | Dano (expressão) | Vida do alvo |
|---|---|---|---|---|---|---|---|
| 9 | Arqueira → Lobo | 15 | 21 vs 13 | 3,6,2 | acerto | **8** (2d6+2) | 16 → 8 |
| 16 | Lobo → Arqueira | 5 | 9 vs 13 | 3,6,6 | erro | — | 22 |
| 23 | Arqueira → Lobo | 3 | 9 vs 13 | 4,3,6 | erro | — | 8 |
| 27 | Lobo → Arqueira | 15 | 19 vs 13 | 3,5,6 | acerto | **7** (1d6+2) | 22 → 15 |
| 35 | Bruto → Arqueira | 15 | 19 vs 13 | 3,6,5 | acerto | **11** (1d10+3) | 15 → 4 |
| 40 | Arqueira → Lobo | 20 | 26 vs 13 | 5,6,6 | acerto | **11** (2d6+2) | 8 → **0, morto** |
| 46 | Bruto → Arqueira | 19 | 23 vs 13 | 4,1,4 | acerto | **13** | 4 → **0, caída** |
| 55 | Bruto → Arqueira | 1 | 5 vs 13 | 3,3,5 | erro | — | 0 |
| 62 | Bruto → Arqueira | 6 | 10 vs 13 | 6,1,3 | erro | — | 0 |
| 69 | Bruto → Arqueira | 13 | 17 vs 13 | 3,3,4 | acerto | **10** | 0 |
| 77 | Bruto → Arqueira | 7 | 11 vs 13 | 5,6,3 | erro | — | 1 (estabilizada) |
| 81 | Bruto → Arqueira | 15 | 19 vs 13 | 5,3,4 | acerto | **11** | 1 → 0 |
| 90 | Bruto → Arqueira | 17 | 21 vs 13 | **6,6,6** | **crítico** | **22** | 0 |
| 98 | Bruto → Arqueira | 6 | 10 vs 13 | 4,6,2 | erro | — | 0 |
| 105 | Bruto → Arqueira | 14 | 18 vs 13 | 6,2,5 | acerto | **10** | 1 → 0 |
| 114 | Bruto → Arqueira | 3 | 7 vs 13 | 6,1,6 | erro | — | 0 |
| 121 | Bruto → Arqueira | 11 | 15 vs 13 | 4,1,6 | acerto | **9** | 0 |
| 129 | Bruto → Arqueira | 17 | 21 vs 13 | 6,4,2 | acerto | **12** | 0 → **morta** |

- **Contas:** 18 ataques, com 10 acertos, 1 crítico e 7 erros. Dano total **rolado**: arqueira 19, lobo 7, bruto 98. (Rolado, não aplicado: a arqueira só tinha 22 de vida; a maior parte dos 98 caiu sobre uma figura já a 0.)
- **Todos os danos cabem na expressão da arma:** 2d6+2 ∈ [4,14], 1d6+2 ∈ [3,8], 1d10+3 ∈ [4,13]. O crítico deu 22,
  o que cabe tanto em 2×(1d10+3) como em 2d10+3.
- **Toda a vida bate com o dano:** 22 − 7 − 11 = 4, e 16 − 8 = 8. Nenhuma ficha que levou dano tinha RD, por isso o
  dano aplicado é igual ao bruto. O bruto, o único com RD 1, nunca levou um golpe.
- **As faces dos dados de dano não ficam no journal.** O journal só guarda o total (`totalEfectivo`), por isso a
  «parcela» de cada dado de dano não se pode auditar depois (ver §4, DV-8).
- **D-AUD-15 (os dados):** as 28 faces de d20 desta batalha (18 ataques e 10 testes de morte) foram 15, 5, 3, 15,
  15, 20, 19, 1, 6, 13, 7, 15, 17, 6, 14, 3, 11, 17 e 15, 5, 1, 18, 19, 8, 8, 3, 6, 13. São um dado a mais para essa
  investigação, sem conclusão. A amostra é pequena.

### 3.2 Queda, testes de morte e morte

- **Morte de uma criatura:** o lobo chegou a 0 com 11 de dano (#40). Ficou `visivel: morta`, sem fase a morrer, e na
  lista do Mestre aparece «vida 0/16 · morta» (`c11`).
- **Queda:** a arqueira foi de 4 a 0 com 13 do bruto (#46) e ficou `caida`, com
  `estadoMorte {fase: aMorrer, 0/0}`. A jogadora vê «A Arqueira de Bancada, caída, aguenta-se — continua a respirar.»
  (`c12`) e a tela fica vermelha, só com «Encerrar» activo (`c13`).
- **Testes de morte** (10), sempre `1d20+1` no recibo contra CD 14:

| # | Dado | Const. somada | Total | Resultado | Estado depois |
|---|---|---|---|---|---|
| 51 | 15 | 11 | 26 | sucesso | 1 suc / 0 falhas |
| 58 | 5 | 11 | 16 | sucesso | 2 / 0 |
| 65 | 1 | 11 | 12 | falha | 2 / 1 |
| 73 | 18 | 11 | 29 | sucesso (já com +1 falha do golpe #69) | **estabilizada**, vida 1 (3 / 2) |
| 86 | 19 | 11 | 30 | sucesso (golpe #81 reabre a fase) | 1 / 0 |
| 94 | 8 | 11 | 19 | sucesso (já com +1 falha do crítico #90) | 2 / 1 |
| 101 | 8 | 11 | 19 | sucesso | **estabilizada**, vida 1 (3 / 1) |
| 110 | 3 | 11 | **14** | **falha (14 vs CD 14)** | 0 / 1 |
| 117 | 6 | 11 | 17 | sucesso | 1 / 1 |
| 125 | 13 | 11 | 24 | sucesso (já com +1 falha do golpe #121) | 2 / 2 |

- **Morte da jogadora:** o golpe #129 (12) junta a 3.ª falha → `visivel: morta`, `FIM {desfecho: morte}` (#132),
  na rodada 14. A jogadora vê «Fim da batalha» com a tela vermelha (`c15`). O Mestre vê «Sala: batalha acabada»
  (`c16`).
- **Regras que se viram a funcionar:** um golpe num moribundo soma 1 falha. Um golpe numa figura estabilizada reabre
  a fase `aMorrer` com 0/0. Três sucessos estabilizam com vida 1. Três falhas matam.

### 3.3 Animações (fotogramas a 10 fps: `f01`–`f06`; vídeos `v01`, `v03`, `v04`)

| Momento | Ecrã da jogadora | Ecrã do Mestre |
|---|---|---|
| **Acerto** (8 no lobo) | Não há projéctil, golpe nem clarão no alvo. Cerca de 0,3 s depois de fechar o menu «Com o quê?», aparece um **número de dano flutuante** («8», cor creme) por cima do alvo. Sobe devagar e desvanece até sumir por volta de **1,5 s** (`f01`) | **Nada no tabuleiro**: nem número nem animação. Só muda a lista das Figuras (vida 8/16) (`f02`, `c06`) |
| **Erro** | Não aparece nenhum número no tabuleiro. O banner diz «Errou. Total 9.» (`c07`) | nada |
| **Morte do lobo** | Aparece o número «11», que sobe e desvanece em ~1,5 s. Quando o número aparece, a **cápsula do lobo já não está lá**: não se vê queda nem desvanecimento. O rótulo «Lobo» fica (`f03`, `c12`) | **Não se distingue no tabuleiro.** O peão do lobo fica tapado pelos rótulos e pelas outras duas figuras (`f04`, ampliação `z01` c09 → c11). A lista diz «morta» (`c11`) |
| **Queda da arqueira** | Aparece o número «13», em **cor salmão** (o dano na própria figura), que sobe e desvanece em ~1,5 s. A **tela tinge-se de vermelho** (vinheta) a partir de 0,3 s e a cápsula azul escurece (`f05`) | **Nada no tabuleiro.** O peão continua de pé (`f06`, ampliação `z01` c14). A lista diz «vida 0/22», sem «caída» (`c14`) |
| **Morte da arqueira** | «Fim da batalha», com a tela toda vermelha. A cápsula azul já não se vê (`c15`) | O **peão fica deitado** e perde o arco amarelo (ampliação `z01` c16). É o único sinal de morte que se viu no tabuleiro do Mestre |
| **Dois golpes no mesmo instante** (7 do lobo e 11 do bruto, a 6 ms um do outro) | Os dois números **sobrepõem-se no mesmo ponto** e ficam ilegíveis («11» por cima de «7») (`c08`) | nada |

### 3.4 HUD de dano

- **Jogadora:** o banner mostra o resultado do ataque dela («Acertou! Total 21.», «Errou. Total 9.»), mas sem o
  dano. O dano só aparece no número flutuante. Quando é ela a levar dano, não há banner com o número; há o número
  flutuante e a vinheta vermelha. Os testes de morte aparecem como frase, sem números («caída, aguenta-se — continua
  a respirar»). Não vê a própria vida em nenhum sítio (D-AUD-09, que se confirma).
- **Mestre:** a aba Figuras mostra «vida N/total · PA» de cada figura e acompanha cada golpe (22 → 15 → 4 → 0;
  16 → 8 → 0). A coluna do meio mostra o último alerta, cortado («Lobo de Bancada tentou», «Bruto de Bancada
  desferiu a…»). O Registo lista as vezes e os tipos de evento («Ação do monstro, ataque, dano»), mas **sem números**
  (`c17`). Os números completos (d20, total, CA e dano) só estão no journal e no «Exportar registo».

## 4. Desvios que a bancada mostrou (registados, NÃO corrigidos; cada um vira ordem própria se o Mestre quiser)

| Id | Onde | O quê | Prova |
|---|---|---|---|
| **DV-1** | Motor / testes de morte | O recibo diz `1d20+1` (a `testes.fortitude` da ficha), mas o total é **dado + Constituição (11)**, e o `+1` não entra: 15 → 26, 1 → 12, 3 → 14. O campo `constituicaoSomada: 11` no `soMestre` confirma-o. Com CD 14 e +11, só um dado de 1 ou 2 falha, e mesmo com o +1 o 3 também falharia (#110). Ou o recibo engana ou a soma está errada: **é decisão do Mestre** qual das duas é a regra | `journal/medicoes.json` (`testesDeMorte`), journal #51–#125 |
| **DV-2** | Motor / testes de morte | **Total igual à CD dá falha** (14 vs CD 14 → falha, #110). Se a regra for «≥ CD», é defeito. Se for «> CD», está certo e o recibo devia dizê-lo | #110 |
| **DV-3** | Motor / regras | Um **crítico** num moribundo soma só **1** falha (#90 → #94: 1 falha), como um golpe normal. É matéria de regra (o Mestre decide) | #90, #94 |
| **DV-4** | HUD do Mestre | A lista das Figuras **não marca «caída»**. A arqueira caída aparece «vida 0/22 · PA 0/6», sem estado, enquanto o lobo morto tem «· morta» | `c14` |
| **DV-5** | Animações / Mestre | No tabuleiro do Mestre **não há sinal nenhum de dano**: nem número, nem clarão, nem marca de queda (a figura caída fica de pé). A única mudança que se vê é a da morte da arqueira: o peão deita-se. A morte do lobo não mudou pose nenhuma no tabuleiro do Mestre. | `f02`, `f06`, `z01` |
| **DV-6** | Animações / jogadora | Dois danos no mesmo instante → **números sobrepostos** no mesmo ponto, ilegíveis | `c08`, `v02` |
| **DV-7** | Animações (ambos) | **Não há animação de ataque**: nem projéctil, nem golpe, nem reacção do alvo. A morte é instantânea: na jogadora a figura some, e no Mestre o peão aparece já deitado, sem transição. Pode ser âmbito ainda não feito, e não um defeito. Fica para a nota de Animações | `f01`–`f06` |
| **DV-8** | Journal | As **faces dos dados de dano** não ficam no journal, só o total. O dano não se pode auditar parcela a parcela. O d20 e o 3d6 do crítico ficam | `journal-extracto.json` (eventos `ataque`) |
| (confirma) | D-AUD-03, -07, -09 | Isto já estava registado e voltou a ver-se: «A sua vez» na jogadora com «Bruto · na vez» na caixa (`c08`, `c13`); no Mestre, «vez de Arqueira» no texto com «Bruto · na vez» na caixa (`c09`); o Registo agrupa a «Ação do monstro» na vez seguinte (`c17`); a jogadora não vê a própria vida | `c08`, `c09`, `c13`, `c17` |

Nenhum destes desvios impediu a bancada de medir. A batalha correu do princípio ao fim sem erros.

## 5. O que isto destranca para as notas de Ataques e Animações

- **Ataques (era 3, limitada pela bancada):** o caminho inteiro já está medido. Ataque → alvo → acerto ou erro →
  dano → vida → queda → testes de morte → morte → fim, nos dois ecrãs e pela rede, com o motor real. Os números estão
  coerentes com as fichas (§3.1) e as regras de morte comportam-se de forma consistente (§3.2). O D-AUD-04 deixa de
  limitar esta nota. O que ainda pesa nela: os DV-1 e DV-2 (o teste de morte não soma o que o recibo diz), o DV-8
  (dano sem parcelas no journal), os marcadores de alvo minúsculos (D-AUD-06) e a HUD da jogadora sem o dano no
  banner e sem a própria vida (D-AUD-09).
- **Animações (antes sem medição de dano):** agora há uma medição quadro a quadro. Do lado da jogadora há um número
  flutuante, que sobe e desvanece em ~1,5 s, e a vinheta vermelha ao ficar ferida, caída ou morta. Do lado do Mestre
  não há nada no tabuleiro, a não ser o peão deitado depois da morte. Não há animação de ataque, de golpe nem de
  morte. A nota pode ser dada com
  base nisto (DV-5, DV-6, DV-7).
- **A bancada fica reutilizável:** `correr-com-o-mestre.cmd -Fichas acertam [-Aliada] [-Modo auto]`. Uma correcção
  futura do DV-1 a DV-7 mede-se com a mesma bancada. O ensaio sem janelas (`ensaio-rede.mjs`) dá uma contraprova
  rápida sem GPU.

## 6. Suites (neste PC, no fecho, com as mudanças desta ordem)

| Suite | Resultado |
|---|---|
| servidor (`testes/*.test.mjs`) | **421/421** |
| motor real (`testes-motor-real`, com o `motores.mjs` da bancada) | **2/2** |
| prova da caixa (`prova-servidor.mjs`) | **PROVA OK** |
| `preparar.mjs --fichas=canario` contra o da ponta | config e fichas **iguais** (fora a chave `bancada`) |
| `preparar.mjs --fichas=acertam --aliada` | 2 jogadoras, 2 criaturas, CA 12–14, sem `sala.mapa` |
| clientes Godot da batalha | 0 SCRIPT ERROR (jogadora e Mestre) |

**As suites Godot headless não correram neste PC.** A corrida tinha morrido às 18:44:28 pelo limite de 5 h e o fecho foi feito depois, das ~20:55 às ~21:20; esta ordem não muda nenhum ficheiro do cliente, do servidor, dos testes nem do CI. Os únicos ficheiros mudados são `bancada-rede/*`,
`provas/ordem-d-aud-04-bancada/*` e este ESTADO-FINAL, e nenhuma suite lê `bancada-rede/` (conferido por `grep`). As
suites Godot correm no CI sobre estes commits (nota do fim). `retoma-i0004/actualizar-listas.py` não se aplica, porque
nada em `rascunhos/` mudou.

## 7. Commits (sobre `cef07e7`)

- `524d093`: bancada (`bancada-rede/`, `-Fichas acertam`) e README;
- `aac7f8f`: provas (`provas/ordem-d-aud-04-bancada/`) e este ESTADO-FINAL;
- este commit: a nota do CI.

## Nota do CI

Sobre o `aac7f8f`, os dois workflows deram **success**:
- **Testes dos rascunhos** (run `45293983246`). Os 10 jobs passaram: servidor, cliente, godot-cliente, motor-real,
  protocolo, validador-glb, ponta-a-ponta, foto-mestre, provas-mapa e retoma-pc. As suites Godot headless, que não
  correram neste PC (§6), estão incluídas aqui;
- **Sonda de privacidade** (run `45293982242`).

Sobre a errata A1–A10 (`2fec62b`), os dois workflows deram **success**:
- **Testes dos rascunhos** (run `45303441022`);
- **Sonda de privacidade** (run `45303441155`).
