# ESTADO FINAL — ORDEM CAIXA-RELATO (Claude conta 2, PC · 21/11/2026)

Ordem: fechar a correcção **B7b** da conferência da CAIXA-HUD-JOGADORA — o relato §4 da prova da caixa imprimia o JSON
do snapshot desactualizado ao lado de «fechada: true».
Base: `origin/fable/integracao-50` @ `7c97b48`. Ramo: `claude2/caixa-relato`. **Não fundido** (a fusão é do coordenador).

## 1. O que mudou (ficheiro a ficheiro) — só ferramentas e registo das provas; nada em `rascunhos/`
- `provas/ordem-caixa-relato/ferramentas/relato_caixa.gd` (novo) — o ajudante sem estado: `caixa_actual` (a caixa
  da jogadora na forma da do snapshot: ligada/ordemPor do snapshot, ordemDinamica do modelo do HUD `hud.ordem_turnos`),
  `desactualizado` (compara as duas, normalizando tipos), `linha` (o texto da verificação).
- `provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd` — guarda a origem do último ROOM_SNAPSHOT
  (seq, revisão, hora a que chegou) e conta os ROOM_EVENT que chegam depois; a linha «a caixa que lhe chegou…» usa o
  ajudante. Duas verificações novas: §4 o relato marca o JSON como DESACTUALIZADO (com eventos depois dele e
  `fechada` diferente) e a caixa actual que imprime é a do servidor (ordem, fechada, ultimo); §5 o JSON da reentrada
  sai como actual. 36 → **38** verificações.
- `provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd` — a mesma correcção (é cópia da anterior com o
  manequim e tinha a mesma linha). 46 → **48**.
- `provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd` (novo) — o teste do registo sem servidor nem ecrã,
  com o modelo REAL do HUD (`res://hud/ordem_turnos.gd`): reproduz o §4 (snapshot com 3 figuras e fechada false; os
  eventos de Bruto e Arqueira fecham a volta) e confere que a linha marca «DESACTUALIZADO» antes do JSON velho, imprime a
  caixa ACTUAL depois, diz seq/revisão/eventos do velho e a revisão do actual; o contrário (snapshot acabado de chegar,
  ou evento que não muda a caixa) sai «JSON actual»; nada de nomes, vida, alma, PA.
- `provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh` (novo) — corre o teste e as duas provas vivas
  com saída em `provas/ordem-caixa-relato/` (as capturas vão para a pasta tmp, não para o ramo).
- `provas/ordem-caixa-relato/{README.md, teste-relato.log, cliente-hud/, cliente-manequim/, suites/}` (novos) — o
  registo das corridas.
- `provas/ordem-caixa-hud-jogadora/README.md`, `provas/ordem-caixa-manequim/README.md` — uma nota no fim: a linha §4
  do `cliente/relato.txt` antigo é o JSON do snapshot desactualizado, e onde está a corrida nova. **Os relatos antigos
  não foram reescritos** (são o registo do que se viu nessa altura).

## 2. A linha do registo — antes e depois (§4, prova da CAIXA-HUD-JOGADORA)
**Antes** (`provas/ordem-caixa-hud-jogadora/cliente/relato.txt`, linha 47, logo abaixo de «… fechada: true»):
```
  ok    4: a caixa que lhe chegou só tem ligada, ordemPor e ordemDinamica {"ligada":true,"ordemDinamica":{"fechada":false,"ordem":["ff2acf60bd672e76e","f08e6e9dc41e7a378","f20af3254ba898103"],"ultimo":"f20af3254ba898103"},"ordemPor":"dinamico"}
```
**Depois** (`provas/ordem-caixa-relato/cliente-hud/relato.txt`, linha 47):
```
  ok    4: a caixa que lhe chegou só tem ligada, ordemPor e ordemDinamica — JSON DESACTUALIZADO (é o do ROOM_SNAPSHOT seq 13, revisão 10, chegou às 21:02:52; 5 evento(s) depois dele, que a adiantaram): {"ligada":true,"ordemDinamica":{"fechada":false,"ordem":["ff2acf60bd672e76e","f08e6e9dc41e7a378","f20af3254ba898103"],"ultimo":"f20af3254ba898103"},"ordemPor":"dinamico"} · a caixa ACTUAL dela (revisão 13): {"ligada":true,"ordemDinamica":{"fechada":true,"ordem":["ff2acf60bd672e76e","f08e6e9dc41e7a378","f20af3254ba898103","f1c67641aa5cdfe28"],"ultimo":"ff2acf60bd672e76e"},"ordemPor":"dinamico"}
  ok    4: o relato marca o JSON do snapshot como DESACTUALIZADO (5 eventos depois dele; fechada false → true) e a caixa actual que imprime é a do servidor
```
Nos §1 e §5 (snapshot acabado de chegar) a linha diz «— JSON actual (do ROOM_SNAPSHOT seq …, revisão …, chegou às …;
0 evento(s) depois dele; a caixa dela é esta): {…}». A prova do MANEQUIM tem as mesmas linhas (§4 na linha 53).

## 3. Corridas (PC, Godot 4.7.2 Windows, RTX 4060; Node; motor VLAB real `a91c021c…3261`, o do CI) — VERIFICADO
- Teste do registo `teste_relato_caixa.gd`: **15/15**, rc 0.
- Prova viva CAIXA-HUD-JOGADORA (`cliente-hud/relato.txt`): **38/38**, rc 0 — o caso produzido (§4: 5 eventos depois
  do snapshot, fechada false → true) e marcado.
- Prova viva CAIXA-MANEQUIM (`cliente-manequim/relato.txt`): **48/48**, rc 0 — idem.
- Suites (`provas/ordem-caixa-relato/suites/`): servidor **414/414**; caixa_jogadora **18/18**; caixa_janela **69/69**;
  hud_acoes **50/50**; canario_privacidade **10/10**; abrir_scripts **107 scripts, 0 falhas**. Nenhum SCRIPT ERROR /
  Parse Error / Compile Error.
- `retoma-i0004/actualizar-listas.py` corrido depois do commit: antes.txt 36 · depois.txt 414 · MANIFESTO 459
  ficheiros, **0 diferenças** (o ramo não toca em `rascunhos/`; as listas já estavam sincronizadas — nada a incluir).
- CI do GitHub: ver §4.

## 4. Commits e CI
- `dbf98d6` — a correcção, o teste, as corridas e as notas. Este ESTADO-FINAL no commit seguinte.
- `9d9d979` — este ESTADO-FINAL. Ramo `claude2/caixa-relato` publicado; `fable/integracao-50` intocado (`7c97b48`).

## 5. Para o coordenador
1. **Escolha feita:** a linha continua a imprimir o JSON do snapshot (é o que a verificação de chaves confere), mas
   marca-o «DESACTUALIZADO» ANTES do JSON e imprime na mesma linha a caixa actual dela. A comparação é com o modelo do
   HUD (o que a jogadora vê), e a verificação nova do §4 confere que esse actual é a ordem do servidor.
2. **O seq não distingue os snapshots aqui:** o snapshot da entrada (§1) e o da religação (§4) chegam ambos com
   `seq 13, revisão 10` (a caixa está fora do hash da revisão, por desenho da CAIXA-HUD-JOGADORA; o snapshot ao op
   `caixa` reusa o seq). Por isso a linha leva também a **hora** a que o snapshot chegou e quantos eventos vieram depois —
   é isso que o identifica. Não é defeito desta ordem; fica registado.
3. **O teste novo não está no CI:** é um teste da ferramenta de prova (`provas/`), corre com Godot sem ecrã em ~1 s.
   Para o pôr no job `cliente` precisa de um token com o âmbito `workflow` (o deste PC não o tem). YAML proposto:
   ```yaml
      - name: O registo da caixa no relato da prova (Ordem CAIXA-RELATO)
        if: always()
        run: |
          set -o pipefail
          timeout 120 "$GODOT" --headless --path . -s "$GITHUB_WORKSPACE/provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd" 2>&1 | tee "$RUNNER_TEMP/teste_relato_caixa.log"
          ! grep -E "SCRIPT ERROR|Parse Error|Compile Error" "$RUNNER_TEMP/teste_relato_caixa.log"
   ```
   (o job `cliente` corre com `working-directory: rascunhos/cliente` — conferido; por isso `--path .` e o caminho absoluto do teste).
4. As capturas das corridas novas não entram no ramo (12 MB, iguais em conteúdo às das ordens antigas — nada de HUD
   mudou); ficaram na pasta tmp da sede.
6. **A linha avançou durante a ordem:** `fable/integracao-50` está agora em `6381f50` (CAIXA-TESTES: `f0d24ac`,
   `7008328`, `6381f50`), por cima da minha base `7c97b48`. Conferido: `git merge-tree` sem conflitos; nenhum
   ficheiro em comum (a CAIXA-TESTES mexe nas listas da retoma, este ramo não). Não é fast-forward — a fusão precisa
   de merge ou de rebase; deixei para o coordenador.
5. Privacidade: a linha só ganha a origem do snapshot (seq, revisão, hora, nº de eventos) e ids opacos — nenhum nome
   verdadeiro, vida, alma ou PA (o teste confere).

## CI — VERIFICADO
- Em `9d9d979` (ramo `claude2/caixa-relato`): **Testes dos rascunhos success** (run 44964900369 — validador-glb,
  protocolo, provas-mapa, ponta-a-ponta, cliente, foto-mestre, motor-real, servidor, **retoma-pc**, godot-cliente:
  todos success) e **Sonda de privacidade success** (run 44964900334).
- O commit que traz esta secção só muda este ficheiro (fora de `rascunhos/`).
