# Provas — ORDEM-D-AUD-01 (23/11/2026)

O defeito D-AUD-01 é este: com «Colocar» armado, o clique de Mover coloca uma 2.ª cópia da criatura. Foi provado na
**mesma rota da auditoria**: a bancada de rede (`bancada-rede/lancar.ps1`), com o servidor de produção
(`servidor-ws.js` + motor real VLAB, SHA-256 `a91c021c…3261`) e 2 clientes Godot 4.7.2 verdadeiros (Jogadora
«Heroína Teste» e Mestre). O input chega às janelas por PostMessage (`ferramentas/s1-agente.ps1`, uma cópia do agente
da auditoria) e o journal do servidor é lido por `ferramentas/journal.mjs`, que troca os ids das figuras por `ficha#n`.
Só aparecem nomes fictícios das fichas de teste.

Correu-se o **mesmo guião duas vezes, com as mesmas coordenadas de clique**: a 1.ª na ponta `8e9bf81` sem a
correcção (`a*`, `antes-*`) e a 2.ª com a correcção (`d*`, `depois-*`). O guião foi este:

1. o porteiro da bancada prepara a batalha e põe o orc#1 no lago, em (38,11);
2. o Mestre sai pela engrenagem, entra no lobby com o PIN, prime Sala → Continuar e abre a aba Mesa;
3. **«Colocar orc-teste» → 1 clique no tabuleiro** (casa do ecrã 350,420). Fica posto o orc#2 e «Parar de colocar»
   continua à vista, ou seja, o modo fica armado (é assim de propósito: há o botão «Parar de colocar»);
4. a jogadora prime Encerrar → «Sim, encerrar», e a vez passa ao orc#1;
5. no Agir, o Mestre prime **Mover** (aparecem 40 casas a azul) e clica na casa azul (ecrã 585,158), que é a casa **(35,12)**.

## O resultado, lido no journal do servidor

| | antes (`journal-antes.txt`) | depois (`journal-depois.txt`) |
|---|---|---|
| passo 3, «Colocar» sozinho | evento 8 `colocacao` orc#2 em (24,26): **1** | evento 8 `colocacao` orc#2 em (24,26): **1** |
| passo 5, clique de Mover | evento 10 **`colocacao` orc#3 em (35,12)**: cópia | evento 10 **`movimento` orc#1 (38,11)→(35,12)**, 6 m |
| figuras orc-teste no fim | **3** | **2** |
| eventos `movimento` | 0 | 1 |

O «evento 10» de antes é o mesmo número que a auditoria registou (journal seq 10, `colocacao` de um 2.º orc).

## Capturas (`capturas/`)

| Ficheiro | O que mostra |
|---|---|
| `a09`/`d09-mestre-colocar-armado` | «Colocar orc-teste» escolhido |
| `a10`/`d10-mestre-colocou` | 1 orc posto; «Parar de colocar» à vista (o modo continua armado) |
| `a11-jog`, `a12-jog-encerrar`, `d12-jog-encerrou` | a jogadora encerra a vez |
| `a14`/`d14-mestre-mover-armado` | Mover com as casas azuis à volta do orc#1, no lago |
| `a15-jog-apos-clique-mover`, `d15-*-apos-clique-mover` | depois do clique na casa azul |
| `a16-mestre-figuras` | **antes:** 3 orcs na aba Figuras, e o orc#1 continua no mesmo sítio |
| `d16-mestre-figuras` | **depois:** 2 orcs, e o orc#1 andou dentro do lago |
| `d17-mestre-mesa-desarmada` | **depois:** a Mesa já não mostra «Parar de colocar», porque o Mover desarmou o Colocar |

## Vídeos (`videos/`)

| Ficheiro | O que prova |
|---|---|
| `antes-mestre.mp4` (1:48, 1280×720) | o guião inteiro no ecrã do Mestre, sem a correcção: o clique de Mover faz aparecer um 3.º peão na casa azul |
| `antes-jogadora.mp4` (0:36) | o lado da jogadora no mesmo momento: encerra a vez e passa a «O Mestre narra». O orc a mais **não se vê** neste enquadramento (fica na água e fora da câmara dela: D-AUD-02/05). Que chegou à Party, prova-o o journal (`colocacao` com `visivel: de_pe`) |
| `depois-mestre.mp4` (1:04) | o mesmo guião com a correcção: o orc#1 anda e não aparece peão nenhum |
| `depois-jogadora.mp4` (1:04) | o lado da jogadora com a correcção (com o mesmo limite de enquadramento) |

O ecrã do Mestre foi gravado a 1280×720 dentro do monitor principal. Assim o `gdigrab` não recusou a área, como
tinha recusado na auditoria (1600×900 em x=8).

## Suites (`suites/`)

São os logs das suites corridas sobre a correcção (o resumo está em `suites/resumo.txt`; os números estão no
ESTADO-FINAL). `pecas_mestre` tem 4 verificações novas (D-AUD-01). Antes da correcção deram 14 FALHA: as 4 novas e
10 em cascata, porque o toque do Mover ia para o Colocar. Depois da correcção passam **290 de 290**.
