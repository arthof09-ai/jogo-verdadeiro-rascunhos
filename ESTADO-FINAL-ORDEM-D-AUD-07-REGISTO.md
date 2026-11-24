# ESTADO-FINAL — ORDEM-D-AUD-07-REGISTO (o rótulo do Registo do Mestre diz quem fez a jogada)

**Estado: FEITA** (o resultado do CI fica na nota do fim).

O rótulo de cada linha do Registo do Mestre passou a mostrar **o autor e a rodada de antes da jogada**. O caso da
auditoria (`r-40`) e da INVESTIGA (`l30`) era «Rodada 2 · vez de Heroína Teste · Ação do monstro, vez nova» e passa a
ser «Rodada 1 · vez de Orc Verdadeiro Teste 1 (Orc 1) · Ação do monstro, vez nova». Os encerrar da heroína, que
apareciam como «vez de Orc…», passam a dizer a heroína.

- **Executor:** Claude (opus), PC, conta 2. **Data:** 24/11/2026 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. **Ponta de partida:** `d256202`. A `main` não foi tocada.
- **Commits:** `5208fb0` (código + testes + fixture), `38170f6` (listas da retoma), e o commit destas provas e
  deste ESTADO-FINAL (o hash fica na nota do CI).
- **Não toquei** na C-6, no «na vez» da caixa (D-AUD-03), nos dados, nos workflows, na `main` nem no cliente da
  jogadora. No servidor, só o rótulo dos pontos do «voltar» (ver §1).

## 1. A correcção

| ficheiro | mudança |
|---|---|
| `rascunhos/servidor/nucleo/sala.js:1121-1126` | `transacao()` guarda no `tx`, a partir do `antes` (`:1108` na ponta de partida), `autorId: antes.vez?.figuraId ?? null` e `rodadaAutor: antes.rodada ?? 0` — quem tinha a vez, e em que rodada, **antes** da transacção |
| `rascunhos/servidor/nucleo/sala.js:1244-1247` | `guardarCheckpoint` põe os dois em cada ponto. Sem `tx` (o ponto inicial) não houve jogada: ficam iguais ao estado. A `rodada`/`vezId` do ponto **não mudam**: são o estado para onde o «voltar» vai; o «voltar» continua a usar só o `journalSeq` |
| `rascunhos/protocolo/v2/MASTER_VIEW.schema.json:193-194` + `protocolo/README.md` | `autorId` (`idOuNull`) e `rodadaAutor` (inteiro ≥ 0) em `$defs/ponto`, **fora do `required`** (vistas de antes desta ordem continuam válidas). Era preciso: o `ponto` tem `additionalProperties: false` |
| `rascunhos/cliente/cenas/mestre/modelo_mestre.gd:276-292` (`linha_ponto`) | o cliente compõe o rótulo, por isso passa a usar `rodadaAutor`/`autorId`. Sem os dois campos (sala de antes desta ordem) fica a linha de antes. O texto (`textos_mestre.gd` `PONTO`) não mudou |
| `rascunhos/servidor/dados-exemplo/mesa-mestre.json` | regenerada com `ESCREVER_FIXTURE=1` (o `fixture-mestre.test.mjs` exige que seja o que o servidor gera hoje): o diff são **só** as linhas `autorId`/`rodadaAutor` novas em cada ponto |

**Privacidade:** os pontos só vão na `MASTER_VIEW` (só o Mestre). O teste novo confere que nenhuma mensagem da heroína,
da aliada ou do espectador leva `pontos` nem `rodadaAutor`; o `canario_privacidade.gd` e o e2e (jogadora: «nenhum
canário do Mestre») passaram.

## 2. Os testes

### 2.1 Novos

- `rascunhos/servidor/testes/d-aud-07-registo.test.mjs` (4 testes, servidor real, motor falso, IA em «auto», duas
  voltas):
  1. **o encerrar da IA do orc na rodada 1 fica rotulado com o orc e a rodada 1, mesmo com a vez já da heroína na
     rodada 2** — a prova pedida pela ordem: `vezId` = heroína e `rodada` = 2 (o estado depois), `autorId` = orc e
     `rodadaAutor` = 1 (quem jogou, quando);
  2. o encerrar da heroína fica rotulado com a heroína (não com o orc que vem a seguir), nas rodadas 1 e 2;
  3. as acções a meio da vez têm autor = vez; o lobby e o START (`colocacao`+`turno`) não têm autor (`null`, rodada 0);
  4. os campos novos vão só nos pontos do Mestre.
- `rascunhos/cliente/testes/pecas_mestre.gd:103-121` (4 verificações, «rótulo do Registo: quem fez a jogada»): o
  `linha_ponto` com o ponto do encerrar da IA, o encerrar da heroína, o START, e um ponto sem os campos novos (fica
  como antes).
- **Contraprova por mutação:** com o `guardarCheckpoint` a pôr o estado **depois** nos campos novos, caem 3 dos 4
  testes do servidor (`provas/ordem-d-aud-07-registo/logs/mutacao-rotulo-depois.log`).

### 2.2 Os nomes dos testes afectados (a correcção apontada pela conferência)

O relatório da INVESTIGA (`provas/ordem-d-aud-investiga/RELATORIO-LOCALIZACAO.md`, D-AUD-07, «Risco») nomeava como
afectados só o `servidor/testes/mestre-vista.test.mjs` («o único que lê `pontos`») e o `cliente/testes/pecas_mestre.gd:98-100`.
**A lista estava errada.** Conferida com `grep` na ponta de partida, a lista certa é:

| teste | lê | afectado por esta ordem? |
|---|---|---|
| `servidor/testes/fixture-mestre.test.mjs` | gera e compara a fixture inteira (com `pontos`) | **sim — foi o único que caiu**; resolvido regenerando a fixture (§1) |
| `servidor/testes/mestre-vista.test.mjs:116-155` (L8) | `pontos` (`journalSeq`, `tipos`, `rodada`) | não (os campos novos são aditivos); passou sem mudança |
| `servidor/testes/caixa-hud-jogadora.test.mjs:215`, `:236`, `:293` | `pontos` (o «voltar» e a caixa) | não; passou sem mudança. **Faltava na lista** |
| `cliente/testes/pecas_mestre.gd:98-101` (N25-2) e `:160-161` (um botão por ponto) | `linha_ponto` / `pontos` | não (só o fim da linha / a contagem); passou. A `:160-161` **faltava na lista** |
| `cliente/testes/e2e_mestre.gd:107-110` | `pontos[1].journalSeq` (o «voltar» real) | não; 17/17. **Faltava na lista** |
| `provas/ordem-caixa/ferramentas/prova-servidor.mjs:141`, `provas/ordem-iniciativa/ferramentas/prova-servidor.mjs:86` | `p.vezId` | não: o `vezId` não mudou. **Faltavam na lista** |

`ordem32-varredura.test.mjs` e `ordem25-n24-1.test.mjs` não lêem `pontos` — aqui o relatório estava certo. Os nomes
dos testes novos dizem o que provam (todos começam por «D-AUD-07:»).

> **Nota:** a ordem não traz o texto da conferência (sentença 685). Li «os testes do D-AUD-07 com nomes errados» como
> a lista de testes afectados do relatório da INVESTIGA, que estava incompleta e apontava o teste errado como o único.
> Corrigi-a aqui; não reescrevi o relatório da INVESTIGA (é prova de outra ordem). Se a conferência apontava outra
> coisa, fica por fazer.

## 3. Suites (no `5208fb0`)

| suite | resultado |
|---|---|
| servidor (`testes/*.test.mjs`) | **446/446** (eram 442 + 4 novos) |
| tráfego dos testes contra os schemas (`conferir-schemas.py`) | 0 falhas nas mensagens que saem |
| `pecas_mestre.gd` | **329/329** (4 novas) |
| `rodar_testes` 333/333 · `abrir_scripts` 112/0 falhas · `abrir_mestre` 67/67 · `medir_mestre` 0 falhas · `medir_painel_config` 0 falhas · `hud_acoes` 50/50 · `caixa_jogadora` 70/70 · `caixa_janela` 123/123 · `canario_privacidade` 10/10 · `teste_relato_caixa` 31/31 · `teste_nomes_relato` 26/26 | todas verdes |
| e2e (servidor + jogadora + Mestre, motor falso) | Mestre 17/17; jogadora OK |
| sonda de caminhos do PC (local) | 0 novas no que vai para o git |

Logs e capturas: `provas/ordem-d-aud-07-registo/` (README). Os testes com o motor real (VLAB) e as fotos com render do
CI ficam para o CI.

## 4. Para o Mestre (decisões que não tomei)

- **O START** (colocação + primeira vez) fica «Rodada 0 · vez de — · colocação, vez nova»: antes dele não havia vez
  nem rodada, e é verdade. Antes dizia «Rodada 1 · vez de Heroína Teste». Se o Mestre preferir outra palavra para as
  linhas sem autor (por exemplo «Mestre»), é só o texto.
- **O «→ vez de SEGUINTE»** que a INVESTIGA propôs (mostrar também quem fica com a vez) **não entrou**: a ordem pediu só
  o autor e a rodada de antes, e o texto é palavra do Mestre. Os dados já lá estão (`vezId`/`rodada`), por isso é só
  cliente se o Mestre o quiser.
- O **agrupamento** (a IA faz `ia` + acção + `turno` numa só linha, porque é uma só transacção) não mudou: cada linha
  continua a ser um ponto de «voltar».

## Nota do CI

_(por preencher depois do push)_
