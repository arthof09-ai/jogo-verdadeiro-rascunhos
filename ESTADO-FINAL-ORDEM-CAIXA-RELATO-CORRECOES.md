# ESTADO FINAL — ORDEM CAIXA-RELATO-CORRECOES (Claude conta 2, PC · 21/11/2026)

Ordem: fechar as correcções **B1–B6** da conferência da Ordem CAIXA-RELATO (sentença do coordenador, 21/11/2026;
FUNDE COM CORRECÇÕES 880). A B7 (o passo de CI do teste) é do coordenador e já está na linha (`e0e2510`).
Base: `origin/fable/integracao-50` @ `e0e2510` (com a CAIXA-RELATO já fundida). Ramo: `claude2/caixa-relato-correcoes`.
**Não fundido**: a fusão é do coordenador.

## 1. O que mudou, ponto a ponto
Os ficheiros mexidos são o relato da prova da caixa (`provas/ordem-caixa-relato/`), o teste dele, o ESTADO-FINAL da
CAIXA-RELATO e as duas ferramentas das provas vivas que alimentam o contador (ver §4.1). Não mexi em `rascunhos/`, no
HUD nem nas cores.

- **B1 — a frase dos eventos diz a verdade.** Escolhi as duas vias ao mesmo tempo.
  - O contador ouve a **aplicação** e não a recepção. Antes estava ligado a `Rede.snapshot_recebido` /
    `Rede.evento_recebido`; agora está ligado a `Estado.snapshot_aplicado` / `Estado.evento_aplicado`. O seq e a revisão
    lêem-se do Estado no momento da aplicação.
  - Conta todos os eventos e, à parte, os **de actor** (`OrdemTurnos.actor_do_evento` ≠ ""), que são os únicos que
    podem adiantar a caixa. O `turno` que um `encerrar` produz (`sala.js` `encerrar` → `avancarVez`) não tem actor.
  - A linha perdeu o «que a adiantaram». Agora diz:
    `ROOM_SNAPSHOT seq 13, revisão 10, aplicado às 22:01:51.796; 5 evento(s) aplicado(s) depois dele [movimento,
    turno, ataque, estado, turno], 2 de actor (só esses podem adiantá-la)`.
  - O contador fica num só sítio, no ajudante `relato_caixa.gd` (`novo_snap`, `anotar_evento`). As duas provas e o
    teste usam esse mesmo código.
- **B2 — o número de eventos é verificado.**
  - Os tipos ficam escritos na linha.
  - Cada prova viva tem uma verificação nova no §4. A contagem e os tipos do relato têm de ser exactamente os que o
    Estado aplicou desde o snapshot (`Estado.eventos_desde_snapshot`, uma fonte independente do contador), pela mesma
    ordem, com 2 de actor e 2 `turno` (as duas vezes que a bancada joga). No caso vivo saiu
    `5 evento(s) ["movimento","turno","ataque","estado","turno"] = os 5 que o Estado aplicou … 2 de actor (esperados 2),
    2 turno (esperados 2)`.
  - O teste ganhou o caso vivo exacto: depois do snapshot, a figura na vez faz `encerrar`, o que dá um único `turno`.
    O teste afirma 1 evento, `[turno]`, 0 de actor, «JSON actual» e que a linha não diz «que a adiantaram».
  - O caso do §4 no teste passou também a ter contagem exacta: 6 eventos, 3 de actor, os tipos pela ordem.
- **B3 — a hora leva milissegundos.** A hora sai como `HH:MM:SS.mmm`, e os segundos e os milissegundos lêem-se do
  mesmo instante. Nas corridas, o §1 e o §4 têm o mesmo `seq 13, revisão 10`, mas as horas são `22:01:48.105` e
  `22:01:51.796`. O teste confere o formato e que dois snapshots iguais, a 5 ms um do outro, dão linhas diferentes.
- **B4 — a suposição «só dinâmico» ficou escrita.** O comentário de `caixa_actual` diz agora três coisas:
  - só vale em modo dinâmico;
  - em iniciativa o HUD mostra `Estado.iniciativa`/`vezId`, que o ajudante não lê;
  - não é «o modelo do HUD» por inteiro: `ligada`/`ordemPor` vêm do snapshot, e só a `ordemDinamica` vem de
    `hud.ordem_turnos`.

  O cabeçalho do ajudante deixou de dizer «o modelo do HUD».
- **B5 — as capturas entram no ramo.** As 10 capturas (≈11,6 MB) estão em
  `provas/ordem-caixa-relato/correcoes/cliente-{hud,manequim}/`, e a decisão está escrita no README da prova. A razão
  para as deixar fora era «conteúdo quase igual, nada de HUD mudou», e isso **não se confirmou** (ver §4.2).
- **B6 — cosmético e cobertura.**
  - O §5 do `ESTADO-FINAL-ORDEM-CAIXA-RELATO.md` estava numerado 1, 2, 3, 4, 6, 5. Ficou 1, 2, 3, 4, 5, 6, porque são 6
    pontos e não 5. O texto dos pontos não mudou; o ponto 4 ganhou uma nota que remete para a B5.
  - O teste de privacidade varre agora as 4 linhas que gera: 3 «JSON actual» (§1/§5, o `encerrar` e a mesma vez) e a
    do §4. Afirma também que são 4 e que 3 delas são «JSON actual».

Ficheiros:
- `provas/ordem-caixa-relato/ferramentas/relato_caixa.gd`
- `provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd`
- `provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh`: um 4.º argumento opcional para a pasta de saída.
- `provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd`
- `provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd`
- `provas/ordem-caixa-relato/README.md`: uma secção nova.
- `provas/ordem-caixa-relato/correcoes/` (novo): relatos, capturas, servidor e suites.
- `ESTADO-FINAL-ORDEM-CAIXA-RELATO.md`

## 2. Corridas (PC, Godot 4.7.2 Windows, RTX 4060; motor VLAB real sha256 `a91c021c…3261`, o do CI; semente 7) — VERIFICADO
| Corrida | Resultado |
|---|---|
| Teste do registo `teste_relato_caixa.gd` (`correcoes/teste-relato.log`) | **21/21**, rc 0 (eram 15) |
| Prova viva CAIXA-HUD-JOGADORA (`correcoes/cliente-hud/relato.txt`) | **39/39**, rc 0 (eram 38) |
| Prova viva CAIXA-MANEQUIM (`correcoes/cliente-manequim/relato.txt`) | **49/49**, rc 0 (eram 48) |
| Servidor `node --test` (sem `--permission`, ver §4.4) | **418/418** |
| Prova da caixa do servidor (`provas/ordem-caixa/ferramentas/prova-servidor.mjs`) | **PROVA OK** |
| Cliente `rodar_testes.gd` | **290/290** |
| `caixa_jogadora` / `caixa_janela` / `hud_acoes` / `canario_privacidade` | **18/18**, **69/69**, **50/50**, **10/10** |
| `abrir_scripts` | **107 scripts, 0 falhas** |

Nenhum SCRIPT ERROR, Parse Error nem Compile Error nos registos das provas, do teste nem das suites.

Corri 3 mutações temporárias no ajudante e reverti-as todas. O teste apanhou as três:

| Mutação | Resultado do teste |
|---|---|
| Contar todos os eventos como de actor | 17/21 |
| Pôr os milissegundos a zero | 20/21 |
| Repor «que a adiantaram» | 20/21 |

`retoma-i0004/actualizar-listas.py` correu depois do commit `1c4d9f8`: antes.txt 37 · depois.txt 415 · MANIFESTO 459
ficheiros, **0 diferenças**. O ramo não toca em `rascunhos/`, por isso não havia listas a incluir.

## 3. Commits e CI
- `1c4d9f8`: as correcções, o teste, as corridas, as capturas, o README e a renumeração.
- `b675eb5`: este ESTADO-FINAL. O ramo está publicado e a `fable/integracao-50` não foi tocada (continua em `e0e2510`).
- **CI em `b675eb5`: VERIFICADO.**
  - **Testes dos rascunhos: success** (run 44969814375). Os 10 jobs passaram: godot-cliente, provas-mapa, servidor,
    foto-mestre, **retoma-pc**, validador-glb, protocolo, ponta-a-ponta, cliente e motor-real. No job `cliente`, o passo
    B7 dá «teste do relato da caixa: 21 de 21 verificações passaram».
  - **Sonda de privacidade: success** (run 44969814327).
  - O commit que traz este registo só muda este ficheiro.

## 4. Para o coordenador
1. **Mexi nas duas ferramentas das provas vivas**, fora de `provas/ordem-caixa-relato/`. O contador da B1 vive lá
   (`prova_caixa_jogadora.gd`, `prova_caixa_manequim.gd`): não havia maneira de o pôr a ouvir o Estado sem tocar nelas.
   A ordem CAIXA-RELATO já as tinha mexido pela mesma razão. Mudei só as ligações do contador, a cópia funda da origem
   e a verificação nova do §4. Nada de código do jogo.
2. **O ramo não tinha nenhuma imagem da caixa como ela está hoje.** Comparei as capturas ao píxel (limiar 0,06 por
   canal RGB — **emendado pela Ordem CAIXA-RELATO-CORRECOES-2, B4**: o método está agora cometido em
   `provas/ordem-caixa-relato/ferramentas/comparar_capturas.gd`, e as saídas em
   `provas/ordem-caixa-relato/correcoes-2/comparacao-capturas.log`).
   - As da HUD-JOGADORA no ramo (`provas/ordem-caixa-hud-jogadora/cliente/`, commit `fd7f978`) diferem **35–44 %**
     das de hoje (43,9 / 36,7 / 35,3 / 35,3 / 36,3 %). São de antes da PALETA-C ponto 2 (`a63c2c1`, as cores da caixa),
     do LAGO-MAIOR (`ded3272`) e da CAIXA-JANELA (`e38b4fc`): a caixa era escura e o lago pequeno.
   - As do MANEQUIM diferem **2–19 %** (19,0 / 4,7 / 2,4 / 2,6 / 13,5 %).
   - As da corrida CAIXA-RELATO (21:02, na pasta tmp dela, fora do ramo) já eram as de hoje: **1,0 %** de diferença
     no §4 da HUD.
   - *Emenda (B4):* os números que aqui estavam (54–65 %, 7–38 %, 2,7 %) saíram de um script não cometido que contava
     um píxel quando a SOMA |ΔR|+|ΔG|+|ΔB| passava 0,06, e não quando algum canal passava 0,06. Esse critério é mais
     apertado. O script cometido reproduz os dois (`--metodo=soma`; saídas em `correcoes-2/comparacao-capturas-soma.log`).
     A conclusão (as capturas antigas já não são a caixa de hoje) não muda.

   Daí a escolha de as incluir. Esta ordem não mudou nada visível.
3. **O caso vivo do §4 tem um `estado` que a ordem não previa.** Os 5 eventos são
   `[movimento, turno, ataque, estado, turno]`, e o `estado` vem do ataque. A verificação nova não fixa o total (5);
   fixa a igualdade com o Estado, 2 de actor e 2 `turno`. Assim não quebra se o ataque deixar de produzir `estado`,
   mas apanha qualquer contagem errada do relato.
4. **Neste PC não há `Godot_v4.7.2-stable_win64_console.exe`.** Em `C:\Users\txcga\godot-472\` só existe o
   `Godot_v4.7.2-stable_win64.exe`, e corri tudo com ele (a saída redirigida para ficheiro funciona). O servidor correu
   sem `--permission`: com essa opção, o Node deste PC recusa a rede aos testes de socket, como a CAIXA-TESTES-CORRECOES
   já registou.
5. Privacidade: a linha só ganha a origem do snapshot (seq, revisão, hora, número e tipos dos eventos) e ids opacos.
   Não tem nomes verdadeiros, vida, alma nem PA, e o teste varre todas as linhas.
