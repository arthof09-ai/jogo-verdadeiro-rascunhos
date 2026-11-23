# ESTADO-FINAL — ORDEM-ANALISE-PLANO-2

**Cadeira:** Claude conta 1 (PC), Opus 5.5 · **Data:** 2026-11-23 · **Ordem do Mestre:** 15:51, passada pelo
coordenador CM-000009.
**Sede:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-analise-plano-2-pc\` (clone fresco em `repo\`).

## Ponta de partida

- `git ls-remote https://github.com/arthof09-ai/jogo-verdadeiro-rascunhos.git fable/integracao-50` →
  **`8e9bf81479708b73506fee2aed1ef11949601a2b`** («AUDITORIA-LINHA: nota do CI…», 2026-11-23 15:49 -0300). Foi
  conferida no arranque e outra vez antes do commit, e não andou entretanto. Nessa ponta a linha tem 821 commits.
- `main` = `2383737` (não tocada).

## Método

Fiz só leitura: o código, os documentos do repositório, o `git log` e as páginas do plano no Notion. **Não executei**
o jogo, as suites, o servidor nem o Godot. Os números «a correr» são todos da auditoria da conta 2 de hoje
(`ESTADO-FINAL-ORDEM-AUDITORIA-LINHA.md`, `e37e16f`), que já estava fechada na linha quando comecei.

## O plano original (os documentos identificados)

**Não está no repositório.** O repositório só o cita (`git show 1325b0b:rascunhos/cliente/README.md`, linha 8:
«Plano A v1.1 … e Protocolo v2»). Li-o no Notion, no «Laboratório do Claude»:

1. **Planos do Jogo Verdadeiro — Criação, Visual e Oficina 3D (v1.1, 06/11/2026)**, `410c2b32-4ede-819e-8a7f-e5b9ce16e15d` (página-mãe).
2. **Plano A — Criação do Jogo Verdadeiro no Godot (v1.1)**, `410c2b32-4ede-8159-bfbb-c792e1a5a6fb` (A0, A1, 28 missões JV, errata v1.2).
3. **Plano B — Visual no estilo Arcane (v1.1)**, `410c2b32-4ede-8137-b98b-f7e75afa7e89` (15 missões V, protocolo B3).
4. Como visão que os três servem: **NAC-OV-06**, `410c2b32-4ede-8191-a2a8-d863fb6d4a26` (Mestre-only; só cito a regra).

Os itens 1, 2 e 3 são «o plano original». O Plano C (Oficina 3D) só entra onde toca o jogo (V3.1). Também conta
como início do plano o primeiro commit, `1325b0b` (06/11, subida inicial: cliente, servidor e validador GLB).

**Âncora:** 4,7/10 para a v3 em 30/10 (anterior ao plano). Os eixos dessa nota e o `GOAL.md` estão em [FALTA]. A
auditoria de hoje deu **4,6/10**.

## Os ficheiros entregues (raiz da linha)

| Ficheiro | Bytes | Conteúdo |
|---|---|---|
| `ANALISE-JOGO-2026-11-23.md` | 25 892 | §0 o plano; §1 o jogo para quem joga; §2 item a item: A0 (3), Plano A (28), Plano B (15), com a contagem; §3 onde o rumo se perdeu (commits e ficheiros por tema e por período); §4 melhorias por ordem de importância |
| `PLANO-2-FECHO-DO-JOGO.md` | 19 818 | A regra de rumo; as fases F1–F8, cada uma com a entrega visível, as dependências e o critério de aceitação; a tabela «pontas da análise → onde fecham» |
| `ESTADO-FINAL-ORDEM-ANALISE-PLANO-2.md` | este ficheiro | — |

O perímetro foi respeitado: só estes três ficheiros, sem código, provas nem outros ficheiros. Também não há nomes
verdadeiros de pessoas: as jogadoras do plano aparecem como «as jogadoras».

## Resultado em três linhas

- **Medida item a item** (análise §2.4):
  - Plano A: 6 FEITO, 12 EM PARTE, 8 NÃO COMEÇADO, 1 DESVIADO e 1 [FALTA], de 28.
  - Plano B: 1 FEITO, 5 EM PARTE, 3 NÃO COMEÇADO, 1 DESVIADO e 5 [FALTA], de 15.
  - A0: 0 de 3 critérios cumpridos (1 em parte).
- **O rumo perdeu-se em duas curvas:**
  - o mapa da floresta cresceu no lugar da Clareira aprovada (V2.1);
  - de 20 a 23/11, a caixa da ordem (128 commits) e as ferramentas de prova (60 commits F-n) ocuparam a casa. De 21 a
    23/11 só **15 de 285** commits tocaram código do jogo.
  
  Nunca houve nenhuma ordem de export: o jogo **não corre em nenhum aparelho de jogadora**.
- **Plano 2:** primeiro a batalha que se vê (F1) e os aparelhos (F2), em paralelo; depois a HUD e os dados com a
  fórmula (F3), as acções que faltam (F4), as figuras de corpo inteiro (F5), o olho do Mestre (F6) e a sessão real
  (F7). Por fim, F8 para lapidar.

## [FALTA] encontradas

1. O texto do plano original **dentro do repositório** (só está no Notion).
2. O `GOAL.md` («Régua crítica») e as notas por eixo da v3 (4,7 em 30/10).
3. A página «Régua R0» (JV0.1): não a encontrei no Notion.
4. As sentenças da bancada JV0.5 (a)–(e), incluindo a (c), que autorizaria o ecrã do Mestre no app em vez da C-17.
5. O pacote real de fichas (JV0.6b).
6. A re-corrida independente dos canários pelo Muse (JV1.2).
7. O teste de 3 bots com 25 s sem rede (JV3.4).
8. O deslizador da hora no servidor (JV3.3a).
9. Os testes HUD-SM-01 a 12 (JV3.2).
10. A checklist HUD da R0 (JV2.3).
11. A aprovação do Mestre sobre qualquer cena visual (Clareira ou mapa da floresta).
12. O guia de estilo V0.1, a triagem V0.2, o bloco T1 V2.0a, a lapidação V2.0b e o kit V4.1 (todos do Muse).
13. A lista D-01 a D-13 da vida ambiente (V4.2).
14. O raio pintado e o fogo em flipbook (V4.3).
15. O texto da M-33 (câmara dinâmica e retrato).
16. O texto da C-43 (machucado).
17. O `DESENHO-CONTADOR-VD-v2.md` (está na VM do Muse).
18. O estado do Plano C (personagens prontos para a V3.1).

## [DECISÃO DO MESTRE] levantadas no Plano 2

1. A regra de rumo: prova proporcional e o tecto de correcções de correcção (proposta de modo de trabalho).
2. D-AUD-01: o «Colocar» desarma ou o Mover tem prioridade.
3. D-AUD-03: no modo dinâmico, o «na vez» quer dizer «quem agiu por último» ou «quem joga agora».
4. A máquina do servidor na sessão, enquanto não houver a sentença JV0.5 (b).
5. A posição da caixa no ecrã da jogadora, se a actual tapar (D-AUD-06).
6. A vida e os PA da jogadora na HUD: se aparecem e onde (D-AUD-09).
7. O desenho da fórmula do dado no ecrã: onde, quanto tempo e se as rolagens dos outros também aparecem.
8. As perguntas P-VD-1 a 4 do contador de Vantagem/Desvantagem.
9. O conteúdo dos consumíveis.
10. A janela de reacção (A-4) e o valor do Defender.
11. O valor final do dano do raio (hoje 15, provisório).
12. As perguntas R0 abertas no servidor (correr depois de andar, arma sem reserva, levantar o monstro, ajudante,
    defesa na AoO, margem de crítico), se a R0 não aparecer.
13. Usar o manequim da casa no lugar dos marcadores enquanto não houver personagens do Plano C.
14. A fundura da água e quanto a figura afunda (D-AUD-02).
15. O aspecto do machucado (JV4.3).
16. Aceitar o mapa da floresta no lugar da clareira pequena (V2.1).
17. A velocidade do ciclo de dia e noite e a tabela do clima (D-AUD-13).
18. As perguntas Q-01/Q-02 da prévia de tiro (JV4.1).
19. O conteúdo da ficha interactiva (C-20).
20. O alvo e o âmbito do exame da IA (JV3.5b).
21. Jogar pela internet (JV1.5).
22. Ratificar o ecrã do Mestre no app Godot no lugar da C-17 (JV3.2).

## Commit

Os três ficheiros entram num só commit em `fable/integracao-50`. O hash e o CI ficam na mensagem da corrida.
