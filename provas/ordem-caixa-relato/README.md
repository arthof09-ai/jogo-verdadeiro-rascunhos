# Provas — Ordem CAIXA-RELATO (B7b da conferência da CAIXA-HUD-JOGADORA · 21/11/2026, Claude conta 2, PC)

**O defeito:** no §4 do relato da prova da caixa, a linha «a caixa que lhe chegou só tem ligada, ordemPor e
ordemDinamica …» imprimia `Estado.caixa` — o JSON do último ROOM_SNAPSHOT (`"fechada":false`, 3 figuras) — logo abaixo
de «fechada: true», sem dizer que os eventos recebidos depois desse snapshot já tinham adiantado a caixa. O JSON velho
passava por actual.

**A correcção (só nas ferramentas das provas; nada de código do jogo):** a linha diz sempre de que snapshot é o JSON
(seq, revisão, hora a que chegou, quantos eventos chegaram depois) e compara-o com a caixa ACTUAL dela (o modelo do HUD,
`hud.ordem_turnos`, que os eventos adiantam). Se forem diferentes: «JSON DESACTUALIZADO (…)» antes do JSON velho e, na
mesma linha, «a caixa ACTUAL dela (revisão N): {…}». Se forem iguais: «JSON actual (…)». Só ids opacos e os campos da
caixa da Party — nenhum nome verdadeiro, vida, alma ou PA.

## Ficheiros
- `ferramentas/relato_caixa.gd` — o ajudante sem estado (a linha, a caixa actual, a comparação).
- `ferramentas/teste_relato_caixa.gd` — o teste do registo sem servidor nem ecrã, com o modelo real do HUD:
  **15/15** (`teste-relato.log`).
- `ferramentas/correr-prova-caixa-relato.sh` — corre o teste e as duas provas vivas com as ferramentas corrigidas
  (`provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd` e
  `provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd`, que carregam o ajudante).
- `cliente-hud/` — a prova da CAIXA-HUD-JOGADORA: **38/38** (as 36 de antes + 2 novas: §4 o relato marca o JSON como
  DESACTUALIZADO e a caixa actual que imprime é a do servidor; §5 o JSON da reentrada sai como actual).
- `cliente-manequim/` — a prova da CAIXA-MANEQUIM: **48/48** (46 + as mesmas 2).
- `suites/` — as suites do cliente e do servidor que cobrem a caixa.

Servidor de mesa real (`provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs`, semente 7, motor VLAB
real sha256 `a91c021c…`, cenário `7703320c…`, fichas `3c498137…`), Godot 4.7.2 Windows, RTX 4060. As capturas das duas
corridas não entram no ramo (não são o objecto desta ordem; o lançador move-as para a pasta tmp).

Correr de novo (Git Bash, na raiz do repo; num clone novo, primeiro `godot --headless --path rascunhos/cliente --import`):
`bash provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh <Godot_console.exe> <vlab-completo.js> <pasta-tmp>`

---

# Correcções B1–B6 da conferência (Ordem CAIXA-RELATO-CORRECOES · 21/11/2026, Claude conta 2, PC)

As corridas das correcções estão em **`correcoes/`** (as de cima, da ordem CAIXA-RELATO, ficam como estavam — são o
registo do que se viu nessa altura).

- **B1 — a frase dos eventos diz a verdade.** O contador ouve agora a APLICAÇÃO no Estado (`Estado.snapshot_aplicado`
  / `Estado.evento_aplicado`), não a recepção na Rede (`Rede.snapshot_recebido` / `Rede.evento_recebido`): um snapshot
  velho que o Estado recusa ou um evento repetido já não lhe mexem. Conta todos os eventos aplicados e, à parte, os
  **de actor** (`OrdemTurnos.actor_do_evento` ≠ ""), os únicos que podem adiantar a caixa. O `turno` que um `encerrar`
  produz não tem actor. A linha deixou de dizer «que a adiantaram»: diz «N evento(s) aplicado(s) depois dele [tipos],
  K de actor (só esses podem adiantá-la)». A contagem está em `ferramentas/relato_caixa.gd` (`novo_snap`,
  `anotar_evento`), e as provas e o teste usam a mesma.
- **B2 — o número de eventos é verificado.** Os tipos ficam na linha. A prova viva tem uma verificação nova no §4: a
  contagem e os tipos do relato têm de ser **exactamente** os que o Estado aplicou desde o snapshot
  (`Estado.eventos_desde_snapshot`), com 2 de actor e 2 `turno` (as duas vezes jogadas). No caso vivo foram
  `[movimento, turno, ataque, estado, turno]`: 5 eventos, 2 de actor. O teste ganhou o caso exacto de um `encerrar` (só
  um `turno`) que não muda a caixa: 1 evento, 0 de actor, «JSON actual».
- **B3 — a hora leva milissegundos** (`HH:MM:SS.mmm`, segundos e milissegundos lidos do mesmo instante). O snapshot do
  §1 e o do §4 continuam a chegar com o mesmo `seq 13, revisão 10`, mas agora distinguem-se sempre pela hora. O teste
  confere que dois snapshots iguais a 5 ms um do outro dão linhas diferentes.
- **B4 — `caixa_actual` só vale em modo dinâmico.** Fica escrito no comentário: em iniciativa o HUD mostra
  `Estado.iniciativa`/`vezId`, que o ajudante não lê. Também fica escrito que `ligada`/`ordemPor` do «actual» vêm do
  SNAPSHOT e que só a `ordemDinamica` vem do modelo do HUD.
- **B5 — as capturas entram no ramo (decisão).** As 10 capturas das duas corridas das correcções estão em
  `correcoes/cliente-hud/` e `correcoes/cliente-manequim/` (≈11,6 MB). O motivo para não as incluir era que o
  conteúdo seria «quase igual ao das ordens antigas, nada de HUD mudou». Isso não se confirmou. As capturas da
  HUD-JOGADORA no ramo (`provas/ordem-caixa-hud-jogadora/cliente/`) são de antes da PALETA-C ponto 2 (as cores da
  caixa), do LAGO-MAIOR e da CAIXA-JANELA. A caixa e o lago de hoje já não são os dessas imagens: 54–65 % dos píxeis
  diferem (limiar 0,06 RGB). Nas do MANEQUIM diferem 7–38 %. Esta ordem não mudou nada no HUD, mas a linha mudou, e
  sem as capturas novas o ramo não teria nenhuma imagem da caixa como ela é hoje. As da corrida CAIXA-RELATO
  (21:02) ficaram fora: são da base `7c97b48` e, no essencial, iguais a estas (2,7 % de diferença no §4 da HUD).
- **B6 — cosmético e cobertura.** Corrigi a numeração do §5 do `ESTADO-FINAL-ORDEM-CAIXA-RELATO.md`. O teste de
  privacidade varre agora as 4 linhas que o teste gera (3 «JSON actual» e a do §4), não só a do §4.

Números (Godot 4.7.2 Windows, motor VLAB real `a91c021c…`, semente 7):
- teste do registo `correcoes/teste-relato.log`: **21/21** (eram 15);
- prova HUD-JOGADORA `correcoes/cliente-hud/relato.txt`: **39/39** (eram 38);
- prova MANEQUIM `correcoes/cliente-manequim/relato.txt`: **49/49** (eram 48);
- suites `correcoes/suites/`: servidor 418/418, prova da caixa do servidor PROVA OK, rodar_testes 290/290,
  caixa_jogadora 18/18, caixa_janela 69/69, hud_acoes 50/50, canario_privacidade 10/10, abrir_scripts 107 / 0 falhas.

Correr de novo: `bash provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh <godot.exe> <vlab-completo.js>
<pasta-tmp> "$PWD/provas/ordem-caixa-relato/correcoes"`. O lançador continua a mover as capturas para a pasta tmp; as
desta pasta foram copiadas de lá à mão.
