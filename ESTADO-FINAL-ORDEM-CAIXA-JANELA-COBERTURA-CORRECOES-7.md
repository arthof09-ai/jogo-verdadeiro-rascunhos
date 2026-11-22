# ESTADO FINAL — ORDEM CAIXA-JANELA-COBERTURA-CORRECOES-7 (Claude conta 2, PC · 22/11/2026)

Esta ordem faz as correcções B1, B2, B4 e B5 da sentença da CAIXA-JANELA-COBERTURA-CORRECOES-6 (760/1000, NÃO FUNDE).
São todas de prosa e registo. A B3 (a linha «Estado: NOVA» do `ORDEM.md`) é acto do coordenador e não lhe toquei.

- **Quem executou:** a **conta 2** (o lançador chama `run-claude-conta2.cmd`; o ramo tem o prefixo `claude2/`).
- **Ramo:** `claude2/caixa-janela-cobertura-correcoes-6`, o mesmo da ordem anterior. **Não fundido.**
- **Base:** `5e67145`, a ponta de `origin/fable/integracao-50` à hora do lançamento. O ramo já vinha rebasado na sede
  (reflog: `rebase (start): checkout origin/fable/integracao-50`). Os dois commits da CORRECOES-6 passaram a ser
  `d0d5783` (era `7f1dab7`) e `adda683` (era `6dafdaf`); `git range-diff` dá os dois como `=` (iguais em conteúdo).
- **Commit:** um só commit de correcção, em cima de `adda683`, com B1, B2, B4, B5 e este ficheiro. Como o ramo foi
  rebasado, a publicação é com `--force-with-lease` contra o `6dafdaf` que estava no remoto.
- **A conferência:** não está neste PC (`~/workspace/conferencias/` não existe). Trabalhei pelo texto da ordem e conferi
  cada número nas fontes, como abaixo.
- **Território:** `ESTADO-FINAL-ORDEM-CAIXA-JANELA-COBERTURA-CORRECOES-6.md`, `provas/ordem-caixa-janela/README.md`, a
  cópia do `import.log` (B4) e este ficheiro. Nada em `rascunhos/` nem `.github/` (`git diff --stat 5e67145 --
  rascunhos/ .github/` dá saída vazia). Sem código do jogo, HUD ou cores. Não toquei no `ORDEM.md`.
- **Privacidade:** não há valores novos. Os números em causa são os valores-canário de bancada; o `import.log` copiado só
  traz a saída do Godot a importar o projecto.

## 1. Ponto a ponto

### B1 (D1) — os dois prefixos SHA no ESTADO-FINAL da CORRECOES-6, §2

- **Antes:** `depois.txt` `b2fe7042…` e `MANIFESTO-SHA256.txt` `9433f1c2…`.
- **Agora:** `depois.txt` `99db48dc846152cf…` e `MANIFESTO-SHA256.txt` `c70f1314e08554…`, com uma nota de emenda.
- **Prova, contra o log** (`provas/ordem-caixa-janela/cobertura-correcoes-6/actualizar-listas.log`, linhas 8–9 e 20–21):
  - `99db48dc846152cf0517b8b6694d6accb067275c8413bd0d4485ad842f3e190c *retoma-i0004/depois.txt`
  - `c70f1314e085542a6d26570ee03e5cd9972d978ab9184cd646061a8b160eddde *MANIFESTO-SHA256.txt`
- **Prova, contra os commits:** `git show <c>:retoma-i0004/depois.txt | sha256sum` dá `99db48dc846152cf` e
  `git show <c>:MANIFESTO-SHA256.txt | sha256sum` dá `c70f1314e085542a` em `1b907bc`, `7f1dab7` e `6dafdaf`. O log
  estava certo; o erro era só no resumo. O `antes.txt` (`cf3b16fa…`) já estava certo.

### B2 (D1b) — «4 vezes» → «8 vezes no servidor»

- **ESTADO-FINAL da CORRECOES-6, §1 B1:** a frase passa a dizer que a palavra aparece **8 vezes no servidor**
  (`rascunhos/servidor/`, ficheiros seguidos: 4 no núcleo e 4 nos testes), sempre em comentário ou prosa, nunca chave,
  com uma nota de emenda.
- **README §(f) da `cobertura-correcoes-6/`:** a mesma qualificação, a seguir aos 3 comentários de `ordem-dinamica.js`.
- **Prova** (`git grep -c -w alma -- rascunhos/servidor`, na árvore desta ordem):
  - `nucleo/ordem-dinamica.js:3` + `nucleo/sala.js:1` = **4 no núcleo**;
  - `testes/caixa-hud-jogadora.test.mjs:1` + `testes/ordem-escala.test.mjs:3` = **4 nos testes**;
  - total **8**; em todo o `rascunhos/` são **12**, como a decisão registada diz.
  - Um `grep -r` sem o git apanha mais uma linha, em `rascunhos/servidor/autojogo/.cache/motores-a91c021c….mjs`. Não é
    ficheiro seguido (é a cache do motor), por isso não entra na conta.

### B4 — o `import.log` da CORRECOES-5 trazido para o repo

- **Origem:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-caixa-janela-cobertura-correcoes-5\tmp\import.log`.
  Ainda existia, com data de modificação 22/11 09:17 (a hora da corrida dessa ordem), anterior ao engano do `al.sh`
  (10:23, ver R1).
- **Destino:** `provas/ordem-caixa-janela/cobertura-correcoes-6/godot-import-correcoes-5.log`, ao lado do
  `godot-import.log` da CORRECOES-6. Cópia **byte a byte** (`cp -p`), sem cabeçalho acrescentado.
- **sha256:** `4f566c9bcdcf55ee91ce8e1e65b97a8010cd87e806dbb017a39e7b84b58d4609` (o mesmo na sede e no repo).
- **Conteúdo:** 405 linhas, começa por `Godot Engine v4.7.2.stable.official.ed1daf0bf`; 0 `SCRIPT ERROR`/`Parse Error`/
  `Compile Error`. Traz os códigos de cor ANSI do Godot tal como saíram.
- **Limite:** o ficheiro não traz o rc nem o comando, porque só a saída foi guardada na sede. Fica provada a saída do
  `--import` da CORRECOES-5, não o rc.
- O README da `cobertura-correcoes-6/` cita o caminho novo.

### B5 (D3) — «47/76/78» qualificados

- **ESTADO-FINAL da CORRECOES-6, §2 (a linha da prova viva)** e **README** (a linha `cobertura-correcoes-6/cliente/`):
  47/76/78 passam a dizer que são as contagens da verificação das **chaves**; a dos **nomes** conta 46/75/77.
- **Prova** (`relato.txt`, linhas 47–48, 76–77 e 78–79): «nenhum nome verdadeiro no relato (46 linhas …)» / «nenhuma
  chave privada no relato (47 linhas …)»; 75/76 na passagem 2; 77/78 no fim. A corrida desta ordem dá os mesmos.

### Reserva R1 — `tmp/al.sh` da sede da CORRECOES-5

O original não está à mão: o ficheiro foi alterado e reposto às 10:23 e não há cópia anterior. O que confirmei no PC:
- `diff` entre `…correcoes-5/tmp/al.sh` e o `al.sh` desta sede (`…correcoes-6/scripts/al.sh`) dá só as linhas 3 e 4,
  as duas repostas: `cd /c/Users/txcga/RPG_Local/jogo-verdadeiro/ordem-caixa-janela-cobertura-correcoes-5/repo || exit 9`
  e `O=$1; BASE=3b84797`.
- `diff` entre o `al.sh` da CORRECOES-4 e o da CORRECOES-5 dá também só essas duas linhas (pasta `…-4`, base `30a16b5`).
  O molde é o mesmo nas três sedes; só muda a pasta e a base.
- A base `3b84797` é a da CORRECOES-5 (o ESTADO-FINAL dela diz `Base: 3b84797`), e o `actualizar-listas.log` cometido
  dessa ordem mostra `$ git diff --stat 3b84797 -- rascunhos/ .github/`, que é o que a linha 4 do original produziu.

Isto confirma as duas linhas por evidência indirecta (o molde e o log cometido), não por comparação com o original.
Essa comparação já não é possível; a confirmação fica só no PC, como está aqui.

## 2. Corridas

Ambiente: PC, Godot 4.7.2 Windows `_console.exe`, Node, motor VLAB real sha256 `a91c021c…3261`, semente 7, HEAD
`adda683` (as fontes do jogo são as da base `5e67145`). As saídas ficaram fora do repo, em `…\correcoes-6\tmp\c7\`,
porque esta ordem não junta registos novos de corrida.

| Corrida | Resultado |
|---|---|
| Teste dos nomes do relato | **26 de 26**, rc=0, 0 SCRIPT ERROR; «correram as 25 verificações do teste (esperadas 25)». **Igual byte a byte** (`cmp`) ao `cobertura-correcoes-6/teste-nomes-relato.log` |
| Prova viva da caixa-janela | **41 de 41**, rc=0, 0 SCRIPT ERROR. Nomes: 46/75/77 linhas; chaves: 47/76/78 linhas; 0 achados. `relato.txt` **igual byte a byte** (`cmp`) ao da CORRECOES-6 |
| `actualizar-listas` (antes do commit) | «antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)»; listas iguais antes e depois; `git diff --stat 5e67145 -- rascunhos/ .github/` vazio |

- **Capturas desta corrida** (sha256, 16 primeiros): `1-janela-1280x720.png` `288edf324d093fcb`,
  `2-baixo-844x390.png` `c834279c875b650a`, `3-baixo-780x360.png` `8beb70dc21058f21`. Como nas ordens anteriores, os
  PNG mudam de corrida para corrida; o relato não.
- **SHA-256 das listas, agora** (iguais antes e depois do script): `antes.txt` `cf3b16fa1b1b924b…`, `depois.txt`
  `c5902574a1954fae…`, `MANIFESTO-SHA256.txt` `50890680772dba03…`. São diferentes dos da CORRECOES-6 (`99db48dc…`,
  `c70f1314…`) porque o rebase trouxe as listas já sincronizadas da ponta `5e67145`
  (`git diff --stat origin/fable/integracao-50 HEAD -- retoma-i0004 MANIFESTO-SHA256.txt` dá saída vazia). Não havia
  nada a sincronizar: o ramo não toca em `rascunhos/`.

## 3. CI

O CI do commit de correcção não pode estar dentro deste ficheiro (é o mesmo commit). Dou-o no relatório final da
corrida.

## 4. Pontos para o coordenador

1. **B1 e B2/B5 emendam o ESTADO-FINAL e o README da CORRECOES-6 no próprio sítio**, com uma nota «emenda da
   CORRECOES-7» em cada frase mudada, porque o ramo ainda não está fundido. Os logs cometidos não mudaram.
2. **B4:** o `import.log` existia e está no repo, byte a byte. Prova a saída, não o rc (não foi guardado).
3. **R1:** confirmação só por evidência indirecta no PC (§1); o original do `al.sh` já não existe.
4. **O rebase mudou os SHA dos commits da CORRECOES-6** (`7f1dab7` → `d0d5783`, `6dafdaf` → `adda683`). O ESTADO-FINAL
   da CORRECOES-6 continua a citar os antigos (e a base `1b907bc`), como registo da corrida dela; não os emendei, porque a
   ordem não o pede.
5. **B3** fica contigo; não toquei no `ORDEM.md`.
