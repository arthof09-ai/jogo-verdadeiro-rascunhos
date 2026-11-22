# ESTADO FINAL — ORDEM CAIXA-LOBBY (Claude conta 2, PC do cunhado · 21/11/2026)

Ordem: correcções B6 e B7a da conferência CAIXA-HUD-JOGADORA. Ramo `claude2/caixa-lobby`, **sem fundir**.
Marcas: VERIFICADO (conferido nesta sessão), NÃO APLICADO (com a razão e a prova).

**Resumo: o B7a está feito. O B6 NÃO foi aplicado.** A premissa do B6 («a caixa do lobby é só ruído») não se verifica: o
snapshot do lobby é o único que leva a escolha do Mestre à jogadora que já estava na mesa quando a batalha começa.
Tirá-lo deixava-a sem caixa a batalha inteira. Fica um teste que prova isto e que avisa quando o B6 passar a ser possível
(§2). A decisão é do coordenador.

## 0. Base
- `origin/fable/integracao-50` estava em **`7c97b48`** (um commit por cima do `2949d16` da ordem: «CI: passo da caixa
  da jogadora (caixa_jogadora.gd) no job cliente — correcção B2…, aplicada pelo coordenador»). Como a ordem manda
  partir de `origin/fable/integracao-50`, parti do `7c97b48`.

## 1. B7a — `conferirOrdemDinamica` recusa chaves a mais — VERIFICADO
- `rascunhos/servidor/nucleo/conferir-estado.js`: lista fechada `CHAVES_ORDEM_DINAMICA = ['ordem', 'fechada', 'ultimo',
  'vezes']` (as de `ordem-dinamica.js ordemDinamicaVazia`). Qualquer outra chave recusa o journal com
  `estado da sala inválido em <campo>.<chave> (campo a mais)`, como a `caixaMestre` já fazia. Vale para as duas ordens
  que usam a função: `ordemDinamica` (a do Mestre) e `ordemDinamicaParty`.
- Teste (`rascunhos/servidor/testes/caixa-hud-jogadora.test.mjs`, «a ordem dinâmica do journal com uma chave a mais é
  recusada; as de hoje abrem»):
  - **Recusadas:** as chaves `inventado`, `valores` (com um valor de iniciativa) e `modo`, em cada uma das duas ordens.
    São 6 casos, e cada um tem de falhar com o caminho certo e «campo a mais».
  - **Abrem:** a ordem de uma batalha jogada (exportada a sério), a ordem vazia, a ordem preenchida (`fechada: true`,
    `ultimo`, `vezes`), `null`, e o campo ausente (journals de antes).
  - Sem a correcção, o teste falha (conferido).
- Os outros testes de journal da suite (export/restauro, «voltar», disco) continuam verdes: nenhum escritor de hoje põe
  chaves a mais.

## 2. B6 — a caixa no snapshot do lobby — NÃO APLICADO (com prova)
**O que encontrei:** quando o Mestre começa o combate, a Party **não recebe nenhum ROOM_SNAPSHOT**, só `ROOM_EVENT` e
`ROOM_OPTIONS` (sonda: `ROOM_EVENT ×4, ROOM_OPTIONS ×2`). Do lado do cliente, `Estado.caixa` só se preenche num
snapshot (`estado.gd` linha 145), e o HUD lê-a ao abrir a arena (`hud.gd _carregar_caixa`; a janela lobby→arena da
CAIXA-JANELA conta com «o snapshot do lobby já está no Estado e a caixa leu-o»). Portanto, para a jogadora que estava no
lobby, o snapshot do lobby é o **único** que lhe traz a escolha do Mestre (incluindo uma escolha feita no lobby, que já
segue num snapshot de lobby).

**O que acontecia com o B6 tal como foi pedido:** apliquei-o (`fase` fora do combate → sem `caixa`) e corri tudo:
- servidor 416/416, só com a fixture `mesa-mestre.json` refeita (saía-lhe a caixa do snapshot de lobby); cliente todo
  verde. **As suites não apanham o defeito:** os testes do cliente usam snapshots sintéticos, e os do servidor só
  tinham a caixa com reentrada a meio da batalha.
- Mas, no fluxo normal (a jogadora entra no lobby e o Mestre começa a batalha), ela ficava com `caixa_ligada = false`
  a batalha inteira, até o Mestre mexer na caixa ou ela sair e voltar a entrar. Isto desfaz a CAIXA-HUD-JOGADORA no
  caso mais comum.

Por isso retirei o B6 (os commits ainda não estavam publicados) e deixei, na mesma suite, o teste que guarda isto:
- «a escolha do Mestre feita no lobby chega à batalha pelo snapshot do lobby (o começo do combate não manda
  snapshot)»: a Party entra no lobby e o Mestre escolhe `iniciativa`. Quando o combate começa, nenhum ROOM_SNAPSHOT
  chega à Party, e o último snapshot que cada uma tem (jogadoras e espectador) é o do lobby, com a escolha.
- **Com o B6 aplicado, este teste FALHA; sem ele, passa** (conferido nos dois sentidos). A mensagem da asserção sobre
  o snapshot avisa que, se o começo do combate passar a mandar snapshot à Party, o B6 já se pode fazer.

**Privacidade:** a caixa que vai no lobby tem só `ligada`, `ordemPor` e uma `ordemDinamica` vazia. Não tem nome
verdadeiro, vida, alma, PA nem valores de iniciativa (é o teste dos canários da CAIXA-HUD-JOGADORA). Nada mudou aqui.

**Caminhos para o coordenador decidir (nenhum foi feito, porque passam a fronteira «só isto»):**
1. **Deixar como está** (recomendo). A caixa vazia do lobby é inócua e é necessária. O B6 fica fechado como «não
   procede», com o teste de guarda.
2. **Snapshot à Party no começo do combate** (`tx.snapshotsParty = true` em `iniciarCombate`, o mesmo mecanismo do
   `escolherCaixa`), e depois o B6. Muda o tráfego de todas as batalhas e mexe na janela lobby→arena do cliente
   (`eventos_desde_snapshot` / `_repetir_eventos_antes_do_hud`). Pede ordem própria, com a prova ponta-a-ponta.
3. **Levar a escolha no evento de início** (`caixa` no `ROOM_EVENT` do começo) e o cliente lê-la de lá. É uma mudança
   de protocolo e de cliente.

Nota: suprimir a caixa só no `fim` (o outro caso fora do combate) também não é seguro sem rever o «Recomeçar»
(`fim → combate`) — mas o «Recomeçar» manda snapshot a todos (`sala.js:2922`), por isso esse caso está coberto.
Não o fiz nesta ordem.

Registo do coordenador (correcção B3 da sentença): o sintoma que a ordem descrevia já estava suprimido antes
desta ordem — `projecao.js:209` tira a caixa do snapshot quando `salaDeEspera === true`, com teste
pré-existente a afirmá-lo. O B6 não tinha alvo válido; quem o tentar outra vez pela mesma razão vai encontrar
esta nota e o teste de guarda.

## 3. Ficheiros mudados (`7c97b48..` ponta do ramo)
- `rascunhos/servidor/nucleo/conferir-estado.js` (B7a, +5 linhas).
- `rascunhos/servidor/testes/caixa-hud-jogadora.test.mjs` (+2 testes: o B7a e o de guarda do B6; importa
  `jsonCanonico`).
- `MANIFESTO-SHA256.txt`, `retoma-i0004/depois.txt` (refeitos por `actualizar-listas.py`; `antes.txt` não muda).
- `ORDEM-CAIXA-LOBBY.md` (a ordem tal como chegou, com a linha final de estado), este ficheiro,
  `provas/ordem-caixa-lobby/suites/*.log` (os registos das corridas abaixo).
- `projecao.js` e `dados-exemplo/mesa-mestre.json` **não mudam** (o B6 foi retirado).

## 4. Corridas (PC do cunhado, código final do ramo) — VERIFICADO
Registos em `provas/ordem-caixa-lobby/suites/`.
- **Servidor:**
  - **416 testes, 406 passam, 0 falham, 10 saltados** (o passo do CI: `--permission --allow-fs-read`, `--allow-net`
    acrescentado por causa do Node local; `servidor.log`). Os 10 saltados são de propósito: testes de disco e de
    `../protocolo` que o passo só-de-leitura deixa para o job protocolo.
  - Sem `--permission`: **416/416** (`trafego.log`).
  - `caixa-hud-jogadora.test.mjs`: **7/7** (5 de antes + 2 novos).
- **Protocolo:** tráfego dos testes contra os schemas: **0 falhas** (`schemas.log`, rc 0).
- **Cliente** (Godot 4.7.2 headless, Windows):
  - `abrir_scripts` 107 scripts, 0 falhas
  - `rodar_testes` 290/290
  - `abrir_clareira` 22/22
  - `medir_painel_config` 0 falhas
  - `abrir_mestre` 67/67
  - `pecas_mestre` 286/286
  - `medir_mestre` 0 falhas
  - `hud_acoes` 50/50
  - `caixa_jogadora` 18/18
  - `canario_privacidade` 10/10
  - comandos do Mestre contra os schemas: 9 e 26 mensagens, 0 falhas
  - arranque «pronto»
  - Nenhum «SCRIPT ERROR / Parse Error / Compile Error».
- **retoma-pc** (a receita do CI, ensaiada localmente em Windows PowerShell sobre o `9cbaca8`): ensaio rc 0 → aplicar
  «414 ficheiros iguais ao ramo (SHA conferido)» rc 0 → ensaio outra vez rc 0. O controlo divergente pára
  («PC DIFERENTE DO 9cbaca8: …sala.js») e não copia.
- **Sonda de privacidade** (o grep do `privacidade.yml`): limpa.
- **Não corridos localmente:** `motor-real`, `godot-cliente` (Linux), `ponta-a-ponta`, `foto-mestre` e `provas-mapa`.
  Ficam para o CI do GitHub no push.

## 5. Pontos para o coordenador
1. **B6:** ver §2. A minha recomendação é o caminho 1.
2. **`--permission` e Node 26:** no Node 26 do PC, o passo do servidor tal como está no CI dá 7 falhas
   `ERR_ACCESS_DENIED (Net)`, todas em testes de WebSocket (V20, ordem 30), porque esse Node pede `--allow-net`. No CI
   (Node 24) não acontece. Com `--allow-net` dá 0 falhas (`servidor-permission.log` tem a corrida sem ele). Se o CI
   subir para o Node 26, o passo precisa de `--allow-net`.
3. **B7a endurece os dois campos.** Um journal gravado por uma versão futura com uma chave nova na ordem dinâmica
   deixa de abrir numa versão antiga. Isto é o comportamento fail-closed pedido, igual ao da `caixaMestre`.

## 6. Commits (ramo `claude2/caixa-lobby`, por cima de `7c97b48`)
- `5808221` B7a e o teste de guarda do B6.
- `cf800cd` listas da retoma e MANIFESTO (`actualizar-listas.py`).
- o commit seguinte: a ordem, os registos das corridas e este ESTADO-FINAL (fora de `rascunhos/`, não mexe nas listas).

## 7. CI do GitHub — VERIFICADO
- No `a780d5e` (ramo `claude2/caixa-lobby`):
  - **Testes dos rascunhos: success** (run 44961797194). Todos os jobs deram success: servidor, validador-glb,
    motor-real, protocolo, cliente, godot-cliente, ponta-a-ponta, foto-mestre, provas-mapa e **retoma-pc**.
  - **Sonda de privacidade: success** (run 44961797191).
- Este parágrafo entra num commit só de documentação, por cima do `a780d5e`, e o CI corre outra vez nele.
- Fusão: **não feita** (é do coordenador).
