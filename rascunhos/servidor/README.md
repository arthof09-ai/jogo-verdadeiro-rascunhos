# Servidor de mesa — rascunho JV1.1 (06/11/2026)

**Estado:** escrito e **nunca executado**. Pela NAC-OV-05, nada correu no PC PCDANASA. Os testes vão num pacote NAC-OV-05 para a bancada.

Especificação usada (Notion):
- Protocolo v2, com as erratas v0.2 e v0.2.1;
- Porta dos motores, com a errata;
- `fichas/1`, com a errata v0.2;
- Máquina de turnos (REF_7).

## Como rodar os testes

Na pasta `servidor/`, com Node ≥ 18 e sem `npm install` (não há dependências):

```
node --test testes/
```

Se o Node ≥ 21 não aceitar a pasta, use `node --test "testes/*.test.mjs"`. `motor-falso.mjs` e `ajudantes.mjs` não são testes e não correm sozinhos.

## Estrutura

| Arquivo | O que faz |
| --- | --- |
| `nucleo/util.js` | JSON canónico, clone, freeze profundo |
| `nucleo/sha256.js` | SHA-256 e HMAC em JS puro (sem `node:crypto`) |
| `nucleo/carregar-fichas.js` | validador próprio de `fichas/1` + errata v0.2, regras extra e pacote com SHA |
| `nucleo/projecao.js` | lista de campos permitidos por tipo de evento e por papel; snapshot projetado |
| `nucleo/journal.js` | eventos, estado e recibos num só commit; exportação assinada; restauração verificada |
| `nucleo/sala.js` | fila síncrona, turnos, BFS, ataques, AoO, IA, recibos, cartões, pausa, JOIN |
| `adaptadores/node/servidor-ws.js` | HTTP, WebSocket mínimo (RFC 6455, sem bibliotecas) e estáticos |
| `testes/` | `node:test` com um motor FALSO injetado |
| `dados-exemplo/fichas-ficticias.json` | 4 fichas fictícias com valores-canário |

O núcleo não importa `node:*`. Recebe por injeção os motores (`Dmg` e `Vlab`), o `rng`, o `rngSemente`, o relógio `agora` e o `hash`.

## O que falta (TODO no código)

- **Motor real (JV0.3):** confirmar nos vetores-ouro:
  - a assinatura de `resolverAtaque`, `validarCorrer` e `resolverTesteDeMorte`;
  - os nomes de `resultado`, dos estados e da fase final do `estadoMorte`.
- **Verificação das expressões:** hoje é uma regex. O certo é injetar `verificarExpressao` com o Dmg real.
- **Regras ainda abertas:**
  - linha de visão por supercover (C-42);
  - janela de reação (A-4);
  - consumíveis;
  - apanhar a arma caída;
  - valor da reação Defender;
  - dano de `acerta-se` e `acerta-amigo`;
  - sentido de "recusar a desgraça";
  - se o grupo A dos ataques de oportunidade exige sair da zona;
  - raio e fogo.
- **Iniciativa:** ainda não é campo da ficha. Hoje vem da config do Mestre e precisa de errata à JV0.6a.
- **Acesso:** convite de espectador emitido pelo Mestre, e autenticação C-17.
- **Persistência:** o journal já vai a disco no adaptador (ordem 16, abaixo); os checkpoints do "voltar" continuam só em memória.
- **Protocolo:** `correr` tem de entrar na tabela §3.1 por errata.

## Riscos

- O código nunca rodou: pode haver erros de digitação ou de lógica que só os testes vão mostrar.
- Sem `chaveJournal`, o `sha256:` da exportação só apanha adulteração ingénua. Use HMAC.
- Em produção, o `rng` tem de ser CSPRNG (`rngNode()`), porque também gera os `seatToken`.
- O hash da vista é recalculado por lugar a cada commit. Medir o p99 (< 8 ms) na JV3.4.

## Corrida de ponta a ponta do ecrã do Mestre (`e2e/`, I0004, 08/11/2026)

- `e2e/servidor-e2e.mjs <porta>`: arranca o servidor de verdade (o WebSocket de `adaptadores/node/servidor-ws.js`) com o motor falso e as fichas fictícias dos testes. O motor dá sempre falha crítica, por isso o golpe da heroína abre um cartão de desgraça.
- `e2e/jogadora-e2e.mjs <porta>`: a jogadora, em Node, pelo WebSocket. Entra, espera o orc que o Mestre coloca, ataca, vê o recibo passar de AGUARDANDO_MESTRE a APLICADA e vê o «voltar». Confere também que nenhum canário do Mestre lhe chega pelo fio.
- O Mestre é o cliente Godot sem janela: `cliente/testes/e2e_mestre.gd`.
- O job `ponta-a-ponta` do CI corre os três juntos.

## Ordem 6 do CM-000009 — decisões do Mestre (09/11/2026)

- **Decisão 1:** o monstro também tem cartão de desgraça. `montarContexto` manda `modoDesgraca: 'proposta'` a todos; o ataque de oportunidade ficou em `'sorte'` até à ordem 9, que o passou também pelo cartão (abaixo). O cartão é o mesmo das heroínas (Confirmar / Escolher outra, com a mesma lista e a mesma semente).
- **Decisão 4 (Q4, site REF_31):** a estabilizada fica na batalha com 1 de Vida, caída; a vez dela salta (`avancarVez`) sem testes de morte; a derrota é só com todas mortas. A cura levanta-a (`aplicarDepois` com `curou: true`), pela acção `curar` da ordem 7 (abaixo). O desfecho `estabilizada` fica no schema por compatibilidade e já não se emite.
- **Decisão 6 (requisito, não regra):** heroína caída como alvo depende do objectivo da criatura (sobrevivência ignora; caos ou fome ataca). Registado em `proporIA`; a IA de hoje não distingue.
- **Decisão 7:** monstro a 0 de Vida = morto (já era assim): sai da ordem, sem testes de morte nem levantar. Teste em `testes/ordem6-decisoes.test.mjs`.

## Ordem 7 do CM-000009 — acção de cura (09/11/2026)

Regras do site (REF_31): `vlab-completo.js` `aplicarCura` e `jogo.js` `vlabAplicarCuraDepois` / `passarVez`.

- **Protocolo:** `acao = {tipo:'curar', alvoId, tecnica}`; `ROOM_OPTIONS.curas = [{alvoId, tecnica}]`; evento `cura` (Party: `curadorId, alvoId, tecnica`; quem cura, se é jogadora, vê também `faces` e `expressao`; o total só no `soMestre`, como o `vlabFiltrarReciboCura` do site). Errata proposta D-28.
- **Quem cura:** uma técnica da ficha que declara `expressaoCura` (o site: «cura é componente declarado por magia/habilidade documentada»; a origem é a técnica).
- **Quem pode ser curado (o motor decide; as opções espelham-no):** não quem está a morrer (`CURA_SOBRE_QUEM_ESTA_A_MORRER`), não quem está a 0 sem estar estabilizado (`CURA_NAO_RESSUSCITA`), não quem tem a Vida cheia (`CURA_ALVO_VIDA_CHEIA`). O custo é o `custoPA` da técnica; a opção só aparece com PA livre suficiente (nunca `forcarSemPA`).
- **Estabilizada (Q4):** a cura soma por cima do 1; a marca sai, ela levanta-se (`caido` sai) e a vez volta a ser dela. Levantar-se pela cura NÃO gasta o movimento: no site a queda a 0 é só da vista (`entrarAMorrer` → `setVivo(false)`; a cura → `setVivo(true)`); o `caido` que gasta a reserva é o da desgraça. O Fraca (Regra 7) fica se a Vida continuar abaixo de um décimo (o motor só o tira acima).
- **Testes:** `testes/cura.test.mjs` (motor falso com as recusas do real) e `testes-motor-real/cura-real.test.mjs` (o `aplicarCura` real do site, no job motor-real).

**Onde o site é omisso — PARADO, sem regra inventada (precisa da palavra do Mestre):**

1. **Economia da acção.** O site não diz se curar gasta a acção padrão, a de movimento ou outra. PROVISÓRIO no servidor: gasta a acção padrão (`vez.atacou = true`), como as outras técnicas e o Transformar. Trocar quando houver regra.
2. **Alcance e alvo.** O site não diz se a cura é de toque ou à distância, nem se se pode curar um inimigo. O servidor usa o `alcanceM` declarado na técnica (o mesmo dado que o ataque usa) e só oferece aliados (não inimigos, a própria incluída).
3. **Técnica que cura e ataca.** O schema da técnica exige `expressaoAtaque`; uma técnica com `expressaoCura` aparece também como ataque. O site não diz se a técnica de cura também ataca. Nada mudado.
4. **`curaBloqueada` (ferida-fonte, `heal_blocked`).** O motor recebe-a por cura; o servidor não guarda que técnica fez cada ferida, e o site não liga o campo da ficha à cura. Não é enviado.
5. **IA e monstros.** O site não tem consumidor de cura de monstro («nenhuma cura de monstro tem consumidor vivo nesta casca»). A sala aceita a acção para quem tiver a técnica (o Mestre pelo MASTER_ACT), mas a IA (`proporIA`) não propõe curas.
6. **Cliente.** O protocolo e o servidor estão prontos; o botão de curar no HUD da jogadora não foi feito (fora desta ordem). O cliente ignora o evento `cura` e o campo `curas` sem partir.
7. **Estabilizar por ajudante** (`resolverTesteDeMorte` com `ajudante`) continua sem acção no protocolo (TODO R0, já antes).

## Ordem 8 do CM-000009 — «Não acontece nada» e mudar a escala (09/11/2026)

**Item 5 — «Não acontece nada»** (desempate do Mestre 09/11 08:17; site REF_34, `jogo.js` T-DESGRACA-NADA). Num cartão de desgraça (heroína ou monstro), o Mestre recusa a proposta com `MASTER_APPROVE {decisao:'recusar', edicao:{semDesgraca:true}}`. É escolha SÓ dele: não é linha da tabela 1d100 (a lista `desgracas` do cartão continua a ser só as 6), não tem peso, nunca vem do acaso (desde a ordem 9 já não há `'sorte'` em lado nenhum) nem da IA (nenhum caminho automático manda `semDesgraca`). Escolhida: a segunda chamada ao motor NÃO se faz — aplica-se a saída da proposta guardada no cartão (`saidaProposta`, só Mestre), que o motor devolveu sem nada aplicado; zero efeitos de desgraça, a Party vê só o ataque em `falha_critica`; os custos da falha crítica (PA) pagam-se na mesma, como no site. Fica no registo do Mestre (evento interno `acao` `sem_desgraca`). `recusar` sem `semDesgraca` continua recusado (o cartão fica por decidir, como o «← Voltar» do site); `semDesgraca` com outra decisão ou noutro cartão é recusado.

**Item 8 — mudar a escala a meio da batalha** (desempate do Mestre 09/11 08:18). `MASTER_SUPERVISOR {op:'escala', casaM}`: acção só do Mestre, sem custo (não toca na vez, na acção, no PA, na reacção nem na Vida). A escala viva é `mapa.casaM` do estado (nasce 1,5, a Q5 do site); todas as contas em metros usam-na (`casaDe`): distâncias e alcance, casas que a reserva paga, custo do movimento, técnica corpo-a-corpo do ataque de oportunidade. As posições guardam-se em casas (ninguém mexe). A reserva e o andado da vez estão em metros e não se reconvertem: o já gasto conta em metros na escala nova (9 m de base, anda 2 casas a 1,5 = 3 m → sobram 6 m; a 3 m por casa pagam 2 casas). Em lobby ou combate; com um cartão aberto: `cartao_aberto`; a mesma escala: recusada. A Party recebe o evento `escala` SEM campos e o snapshot novo (com `mapa.casaM`), e as opções novas pela revisão; o antes/depois e a reserva da vez ficam no `soMestre`. O «voltar» repõe a escala do instante (o `mapa` está no checkpoint). Testes: `testes/ordem8-decisoes.test.mjs`.

**Onde o site cala — registado, sem regra inventada:**

1. *(Respondido na ordem 11: só 1 / 1,5 / 2 m, REF_36.)* **Que escalas valem.** O site só tem a casa fixa de 1,5 m (`CASA_M`, Q5) e o validador de saves do site exige a reserva múltipla de 1,5. O servidor aceita qualquer `casaM > 0`; o ecrã do Mestre anda em passos de 0,5 m com mínimo de 0,5 m (só ecrã).
2. *(Respondido na ordem 11: piso de 1 casa, REF_36 Emenda 1.)* **Alcance corpo-a-corpo numa casa maior.** Uma técnica de 1,5 m deixa de chegar à casa vizinha quando a casa passa de 1,5 m (o alcance é em metros). Não se mudou: precisa de palavra (o corpo-a-corpo é «a casa vizinha» ou «1,5 m»?). O mesmo para o ataque de oportunidade, que só usa técnicas com alcance ≤ uma casa.
3. **Correr já declarado.** A reserva do Correr também fica em metros (não se recalcula com a escala nova).
4. **Mudar a escala com um cartão aberto ou em pausa.** Recusado (o cartão decide-se primeiro; a pausa bloqueia tudo) — nenhuma regra do site.
5. **Save do site.** O validador de saves do site (reserva múltipla de 1,5) não conhece a escala variável; o journal do servidor guarda a escala viva.

## Ordem 9 do CM-000009 — cartão também na oportunidade (09/11/2026)

Decisão do Mestre 09/11 11:29, «Opção C — Sim, cartão também na oportunidade» (extensão M2 da frente das desgraças dos monstros, registada no site). A falha crítica do ataque de oportunidade do MONSTRO passa pelo cartão do Mestre como as outras: `montarContexto` manda `modoDesgraca: 'proposta'` sempre.

- **O movimento termina primeiro.** `aplicarMover` move-a, debita a reserva e emite o `movimento`; só depois corre a série de AoO (`serieDeOportunidade`, pela ordem de iniciativa). O recibo do movimento fica `APLICADA` (ela já chegou ao destino).
- **A série pára no cartão.** Uma falha crítica abre o cartão de desgraça (`ataqueDeOportunidade: true`, `origem: null`) e guarda os monstros que ainda faltam em `aooRestantes`. Com o cartão aberto ninguém age (`aguardando_mestre`; a IA não corre). Decidido o cartão, aplica-se e a série continua com os que faltam; outra falha crítica abre outro cartão (um de cada vez).
- **As mesmas opções do cartão:** Confirmar, Escolher outra (segunda chamada com a mesma semente, `modoDesgraca: 'escolha'`, ainda como AoO) e recusar com «Não acontece nada» (`semDesgraca`), que aplica a `saidaProposta` guardada e NÃO chama o motor outra vez. A IA propõe; só o Mestre decide (o cartão abre em auto, semi e manual).
- **Voltar:** o cartão (com `aooRestantes`) está no checkpoint; volta por decidir como os outros.
- Testes: `testes/ordem9-oportunidade.test.mjs`.

**Onde o site cala — registado, sem regra inventada:**

1. **O código do site ainda está em `'sorte'`.** No gh-pages (6cd30ee), `vlabResolverSaidaAdjacencia` chama o motor sem `modoDesgraca` (= `'sorte'`) e aplica a desgraça sem cartão. A M2 é decisão do Mestre, ainda não código do site: o JV segue a decisão.
2. **O resto da série enquanto o cartão está aberto.** O site não diz; aqui a série pára e retoma depois da decisão, pela mesma ordem de iniciativa (um monstro que entretanto caia ou morra já não ataca).
3. **O que a Party vê à espera.** Nada novo: o golpe aparece quando o Mestre decide; as intenções dela entretanto são recusadas com `aguardando_mestre`. Sem frase do site para a espera.
4. **O `MASTER_CARD` não diz que é de oportunidade.** O schema não mudou; o ecrã do Mestre mostra-o como o cartão de desgraça do monstro (o marcador fica só no cartão interno). Mostrar «de oportunidade» no ecrã precisa de palavra.
5. **Reacção com erro do motor.** No site a reacção do monstro só se gasta com a resolução feita; aqui gasta-se antes da chamada (já era assim antes desta ordem). Não mudado.

## Ordem 11 do CM-000009 — paridade da escala (09/11/2026)

Itens P8a e P8b da auditoria da ordem 10: o JV alinha-se à regra do site (REF_36 + Emenda 1). A forma é do JV; a regra é a do site.

- **P8a — só 1 / 1,5 / 2 m por casa** (site: `ESCALAS_CASA_M`). `ESCALAS_CASA_M` em `nucleo/sala.js`; `mudarEscala` recusa qualquer outro valor com `acao_invalida` (texto fixo, sem números, E-P7) e o detalhe `ESCALA_INVALIDA: <v> m por casa; só valem 1 / 1.5 / 2 m` no evento interno `recusa`, só do Mestre. A forma da mensagem continua a exigir um número > 0 (o valor confere-se depois, para a recusa levar o detalhe). Schema `MASTER_SUPERVISOR.casaM`: `enum [1, 1.5, 2]`. O ecrã do Mestre anda só por estes três valores e pára nas pontas (`ESCALAS` em `cliente/cenas/mestre/mestre.gd`). Isto responde ao omisso 1 da ordem 8.
- **P8b — piso de 1 casa no alcance** (site: `alcanceEmCasas = max(1, metros / CASA_M)`). `alcanceEmCasas(m, metros)` e `aoAlcance` em `nucleo/sala.js`; usam-nos o ataque e a cura nas opções da vez. A métrica continua a do JV (euclidiana em casas, «B9 corrigido»): a diferença de métrica com o site (caminho de 4 vizinhos) fica como estava, à espera do coordenador. Com casa de 1 m uma técnica de 1,5 m chega à vizinha e à diagonal (√2 ≤ 1,5 casas); com casa de 2 m chega à vizinha (antes: 2 m > 1,5 m, fora). Na escala de 1,5 nada muda. Responde ao omisso 2 da ordem 8.
- **Ataque de oportunidade.** Com o piso, toda a técnica chega à casa vizinha: `tecnicaCorpoACorpo` deixa de exigir `alcanceM <= casaM` e usa, entre as técnicas utilizáveis, a de menor alcance (empate: a ordem da ficha) — com as fichas de hoje (uma técnica de 1,5 m por monstro) é a mesma de antes. Consequência a saber: um monstro só com técnicas de longe passa a golpear de oportunidade (no site todos golpeiam com a sua arma; o piso dá-lhes a vizinha).
- Testes: `testes/ordem11-escala.test.mjs` (valores aceites e recusados; 1,5 m com casa de 1 m, de 1,5 m e de 2 m, no golpe e no ataque de oportunidade); `testes/ordem8-decisoes.test.mjs` passou a usar 2 m (3 m deixou de valer); `cliente/testes/abrir_mestre.gd` (o ecrã pára em 1 e em 2).
- **Fora desta ordem (como registado na auditoria):** a confirmação da escala (site muda na hora; o JV pede segundo toque), a guarda com cartão aberto, a métrica de distância e o resto da lista da ordem 10 esperam leitura do coordenador.

## Ordem 13 do CM-000009 — dano do ambiente: raio e fogo (10/11/2026)

Dívida E1 da auditoria da ordem 10 (o site tem o painel Ambiente do Mestre desde a REF_39). As regras são as do Mestre, as mesmas do site (`jogo.js`, «RAIO E FOGO»); a construção é nova: `nucleo/ambiente.js` (sem estado próprio, com o dado injetado) e a ligação em `sala.js`.

- **As seis regras:** (1) onde o raio cai, a casa pega fogo — e a cruz das 4 vizinhas (palavra do Mestre de 09/11, cortada na borda); (2) a casa sorteia-se no tabuleiro inteiro; (3) raio numa pessoa: pega fogo e sofre dano; (4) raio = 15 fixo, PROVISÓRIO (`DANO_RAIO`); (5) fogo = 1d8 no início da vez enquanto ela arde (ou começa a vez numa casa a arder); sair para a chuva apaga, sem chuva não; (6) a RD fica fora (`rd: 0` no soMestre).
- **O relógio (o do site):** o momento de ambiente abre cada rodada a partir da 2.ª, antes da primeira vez — extinção pela chuva (pouca 1–2, forte 1–5 em 1d6, apaga também a pessoa na casa), combustível (1d6 rodadas por casa; o re-impacto renova), depois o raio pedido e o automático (pouca 1, forte 1–2 em 1d6). Tick: um por figura e rodada; na rodada do impacto soma-se ao raio. Quem arde fora do fogo com chuva apaga-se no início da vez ou ao acabar um movimento. A heroína já a morrer ou estabilizada não leva dano do ambiente (sem falhas novas); a Vida a 0 deita-a a morrer com 0/0; o monstro a 0 morre, e a vitória pode sair do momento de ambiente.
- **O painel (só o Mestre):** `MASTER_AMBIENTE` ganha `raios` (booleano) e `raioAgora` (`true`: um raio para o momento de ambiente seguinte; só em combate, com chuva e raios, um pendente e um pedido por rodada; a recusa leva o detalhe `RAIO_*` só ao Mestre). A chuva vem do clima: `chuva` = pouca, `tempestade` = forte. Desligar a chuva ou os raios cancela o pedido.
- **Quem vê o quê:** a Party recebe `raio` {x, y, alvoId?, desfecho?}, `fogo` {casas, aArder, apagados?} e `dano_ambiente` {alvoId, origem, desfecho} (+ `valor`/`tipos` só a quem o sofreu); o snapshot leva `fogo` (sem combustível). O Mestre tem ainda o combustível (`mestre.fogo`), a origem do raio, as faces do 1d8, o pedido pendente e o `rd: 0`. O pedido e os raios nunca geram evento na Party (`ambiente_mestre`).
- O `fogo` entra no checkpoint do «voltar»; o «Recomeçar» começa sem fogo e sem pedido (o painel fica). O dano do ambiente conta no `danoSofrido` das estatísticas.
- **Testes:** `testes/ordem13-ambiente.test.mjs` (as regras no `ambiente.js` com o dado na mão, e a sala: painel e recusas, raio pedido em cima dela com tick, chuva/sem chuva ao sair, RD fora, vitória pelo raio, queda a morrer 0/0, voltar e recomeçar, sorteio sem roteiro). `criarSala({dadoAmbiente})` e `montarMesa({dadoAmbiente})` recebem o dado do teste.
- **Parte C (verbo do golpe):** a ficha aceita `verbos {acerto, falha}` (site `FRASES_IA`); a vista do Mestre leva-os em cada figura (`verbos`, null sem eles). Só texto. As fichas fictícias do orc e do lobo têm os verbos do site para esses dois.

## Ordem 15 do CM-000009 — alcance pelo caminho das casas e apagar-se sem chuva (10/11/2026)

**Parte B — o alcance mede-se pelo CAMINHO DAS CASAS** (palavra do Mestre, 2026-11-10). **A decisão B9 do JV (régua a direito) CAI.** `distanciaCasas(m, a, b)` em `nucleo/sala.js` é a régua do site (`jogo-t1/jogo.js` `distanciaEntre`, gh-pages `b9c46be`): BFS de 4 vizinhos dentro do mapa, com as OUTRAS figuras vivas a bloquear a passagem (quem mede e o alvo não contam; o cadáver não bloqueia, T-J12J13) e a casa do alvo a contar como destino; sem caminho, `Infinity`. `aoAlcance` passa a usá-la, com o piso de 1 casa da ordem 11 (`alcanceEmCasas`), nos dois sítios onde o alcance se calcula: os ataques da vez (e por eles a verificação da intenção, `acaoNasOpcoes`, e o `MASTER_ACT`) e as curas (que já usavam a régua do ataque). Os valores de alcance das fichas não mudam.
- **Consequência a saber:** a diagonal fica a 2 passos. Uma técnica de 1,5 m já não chega à diagonal em nenhuma escala (antes, com casa de 1 m, chegava: √2 ≤ 1,5). O `ordem11-escala.test.mjs` mudou nesse ponto.
- **Testes:** `testes/ordem15-alcance-caminho.test.mjs`: a direito chega, mas o caminho está tapado (heroína fechada no canto por dois lobos; o orc a √8 casas fica fora, nas opções e na intenção); a direito chega (6 casas), mas o desvio à volta de um lobo dá 8 passos (fora); o inverso: com o caminho livre, os mesmos 6 passos chegam e o ataque passa; o alvo atrás de uma figura chega pelo desvio curto; a diagonal com 1,5 m em 1, 1,5 e 2 m por casa. Os três primeiros falham com a régua antiga (conferido).

**Parte D — apagar-se sem chuva, como no site** (palavra do Mestre, 2026-11-10; site `jogo.js` `rfPodeApagarFogo`, acção `'apagar-fogo'`, `RF_FIM_SECO = 'acao-movimento'`). Acção nova da jogadora `apagar_fogo` (sem parâmetros). O servidor oferece-a quando ela está a arder, fora de qualquer casa a arder, sem chuva nenhuma (`Amb.podeApagarSeco`), na vez dela e fora do relógio da morte. Aplicada: ela deixa de arder, a reserva da vez zera (gasta a Acção de Movimento) e o ataque continua livre. A mesa recebe o `fogo` com `apagados: [{figuraId, porque: 'seco'}]`. Com chuva continua automático, como na ordem 13 (a opção nunca aparece com chuva).
- **Testes:** `testes/ordem15-apagar-fogo.test.mjs` (as regras no `ambiente.js`; com chuva não há opção e sair apaga; sem chuva, na casa a arder não; fora dela sim, a reserva zera, o ataque fica, a Party e o espectador vêem `seco` e nada do Mestre; com a reserva já gasta, também pode, como no site).

**Onde o site cala ou o JV fica como estava — registado, sem regra inventada:**

1. **Monstros a apagar-se.** O site só dá o botão à jogadora («a IA dos monstros não o faz nesta casca»). Não diz se o Mestre pode mandar um monstro apagar-se à mão. Aqui só a jogadora o pode fazer (`apagar_fogo` de outra figura é recusado).
2. **A Acção de Movimento já gasta.** O site não exige reserva por gastar: zera-a (como ao levantar-se do Caído). O JV segue o código, e ela apaga-se mesmo depois de andar a reserva toda. Se o Mestre quiser exigir a Acção de Movimento ainda inteira, precisa da palavra dele.
3. **O inverso literal da parte B não existe.** Na grelha de 4 vizinhos o caminho nunca é mais curto do que a linha a direito, por isso «o caminho chega e a direito não» não acontece. O inverso testado é o caminho livre, que devolve o alcance.
4. **A IA continua com as réguas dela.** A ordem do alvo «mais perto» (`distanciaM`) e a aproximação (`distMinima`) não são alcance e não mudaram. O site também tem duas réguas (o mapa de pontuação da IA atravessa corpos).
5. **A Q12 «amigo ao alcance»** (adjacente ou na linha, supercover) é julgamento da casa sobre a desgraça, não o alcance do ataque, e fica como estava. O TODO C-42 (linha de visão por supercover no alcance) cai com o B9: o site não tem linha de visão, tem o caminho.
6. **A frase da recusa por caminho tapado** (site M-019: «O caminho até ele está tapado por outras figuras…»). No JV o alvo fora do alcance não chega a aparecer nas opções, por isso não há recusa a explicar. Mostrar o porquê na HUD é outra peça e precisa da palavra do Mestre. *(Ordem 17: o lado do Mestre está feito — o porquê vai no evento interno `recusa`. A HUD da Party continua à espera da palavra.)*

## Ordem 16 do CM-000009 — o journal vai a disco (10/11/2026)

**O TODO JV1.x do adaptador fecha-se** com a recomendação do estudo da ordem 14. Tudo em `adaptadores/node/servidor-ws.js`; o núcleo, o protocolo e os schemas não mudam (`MASTER_EXPORT`, o texto do journal e o `restaurarJournal` ficam iguais).

- **Configuração** (o `config.json` do Mestre, fora do repositório): `"journal": "<caminho>"` e, opcional, `"chaveJournal"` (HMAC, já existente no `criarSala`). O nome do ficheiro **tem de dizer `MESTRE-ONLY`** e o ficheiro **não pode ficar na pasta estática** (E-P13); senão a sala não abre (`conferirCaminhoJournal`).
- **Gravar:** o ficheiro é o envelope do «Exportar registo» do ecrã do Mestre, sem a narração (o servidor não a tem): `{"formato":"registo-mestre/1","marca":"MESTRE-ONLY","registo":"<sala.exportar() intacto>"}`. Grava-se depois de cada commit e **antes** de as saídas irem à mesa (no `entregar` e logo a seguir ao `sala.entrar`); só quando a exportação mudou. Escreve-se `<ficheiro>.a-gravar` e troca-se o nome, para o ficheiro nunca ficar a meio (`criarGravadorJournal`, `gravarJournalEmDisco`).
- **Ler e restaurar ao arrancar** (`abrirSalaComJournal`, `lerJournalDoDisco`, `abrirFicheiroJournal`): `JSON.parse`; se der **string**, é a forma antiga (antes da ordem 13) e é o próprio texto; se der o **envelope** com `formato` `registo-mestre/1`, `marca` `MESTRE-ONLY` e `registo` texto, passa-se **só o `registo`** ao `criarSala({restaurarDe})` → `restaurarJournal`. A `narracao` (se vier, do ecrã do Mestre) nunca é lida: não entra no estado nem serve de prova. Sem ficheiro: sala nova.
- **Falha fechada:** qualquer outra forma (texto cru, JSON inválido, outro formato ou marca, `registo` que não é texto ou vazio, lista, número, `null`, ficheiro vazio) ou um `registo` que o `restaurarJournal` recuse (assinatura, moldura, cadeia) → `journal recusado`, código de saída 1, **a sala não abre e nada é escrito por cima do ficheiro**. O `registo` vazio é recusado à parte porque o `criarSala` trataria `''` como «sem restauro».
- **Testes:** `testes/ordem16-journal-disco.test.mjs`. Sem disco (correm sempre): o envelope leva o registo byte a byte; as duas formas abrem e restauram o mesmo estado (hash, `journalSeq`, eventos, estado e a exportação byte a byte); o envelope do Mestre com narração-canário restaura sem a narração no estado; as formas inválidas lançam `ErroJournal`; o registo adulterado no envelope certo é recusado; nome e pasta. Com disco (numa pasta temporária nova; o passo «só leitura» do job `servidor` não pode escrever e salta-os; no CI correm no job `protocolo`, que corre todos os testes do servidor sem o modelo de permissões; o workflow não mudou): ponta-a-ponta exportar → gravar → ler → restaurar (e a heroína volta com o `seatToken`; outro commit e o restauro acompanha); as duas formas em disco; as inválidas deixam o ficheiro intacto e nenhuma sala; sem ficheiro, sala nova; o `criarServidor` com uma ligação simulada (sem rede) grava o journal antes de a resposta ao `ROOM_JOIN` sair. Os testes antigos (`journal.test.mjs`, com `sala.exportar()` directo) não mudaram.

**Onde o estudo da ordem 14 não chega — registado, sem regra inventada:**

1. **«Append» a cada commit.** O TODO dizia «append»; o formato exportado é um texto assinado inteiro (corpo canónico + assinatura), por isso o adaptador regrava o ficheiro inteiro a cada commit. Um journal em append pedia um formato novo, que nenhuma ordem definiu. Custo: a exportação inteira (e o SHA-256 em JS puro) a cada commit; medir com a sessão longa (ver «Riscos», p99).
2. **Falha ao gravar a meio da sessão** (disco cheio, permissões). O adaptador regista o erro e a mesa continua; o próximo commit volta a tentar. Parar a mesa nesse caso precisa da palavra do Mestre. *(Ordem 17: a gravação pendente também se tenta de novo no relógio do ping, sem esperar commit, e a falha não deixa o `.a-gravar` para trás. Parar a mesa ou avisar o ecrã do Mestre continua à espera da palavra.)*
3. **Ficheiro recusado ao arrancar.** Interpretado como «a sala não abre» (como as fichas recusadas), para não escrever uma sala nova por cima do ficheiro do Mestre. Se o Mestre quiser outra coisa (abrir uma sala nova com outro nome, guardar o ficheiro de lado), precisa da palavra dele.
4. **O servidor não escreve a narração.** A narração vive no ecrã do Mestre; o ficheiro do servidor leva só `formato`, `marca` e `registo`. O leitor aceita os dois (com e sem narração).
5. **Mudar a chave entre sessões.** O adaptador restaura com a `chaveJournal` da config de agora. Um ficheiro assinado com outra chave (ou com `sha256:` quando agora há chave, ou o inverso) é recusado pelo `restaurarJournal` e a sala não abre (falha fechada). Migrar de chave não está previsto.
6. **O ecrã do Mestre ainda não envia ficheiros ao servidor.** Restaurar a partir de um «Exportar registo» do Godot faz-se copiando esse ficheiro para o caminho de `journal` antes de arrancar; não há mensagem de protocolo para isso (e esta ordem não a pede).

## Ordem 17 do CM-000009 — omissos implementáveis e varredura do servidor (11/11/2026)

Tudo MESTRE-ONLY. O contrato não muda (nenhum schema, tipo de mensagem ou campo novo); o formato `registo-mestre/1`, o texto do journal (`journal-sala/1`) e o journal em disco ficam iguais no comportamento. A Party não recebe nada novo. Testes: `testes/ordem17-varredura.test.mjs` (cada um falhava antes da correcção; os de Windows conferidos no Windows).

**Parte B — omissos das ordens 15 e 16 que não precisam da palavra do Mestre:**

- **B1 (omisso 16-2, a parte implementável).** A gravação do journal que falhou fica `pendente()` no gravador e o relógio do ping do adaptador (20 s) volta a tentá-la, mesmo com a mesa parada sem commits (antes só o commit seguinte a tentava: com a mesa calada o disco ficava atrás do que a mesa viu). A falha já não deixa o `<ficheiro>.a-gravar` ao lado do journal. O erro regista-se uma vez por falha (e «reposta» quando volta), em vez de a cada tentativa. Sem nada pendente, o relógio não exporta.
- **B2 (omisso 15-6, o lado do Mestre).** Um `atacar` ou `curar` recusado por alcance leva o porquê ao Mestre no evento interno `recusa` (como o `ESCALA_INVALIDA`): `ALVO_FORA_DO_ALCANCE: <n> passos pelo caminho das casas; a técnica chega a <k> casas` ou `CAMINHO_TAPADO: …`. É diagnóstico com a mesma régua das opções (`aoAlcance`), não regra nova. A Party vê a recusa fixa de sempre (E-P7) e nenhum evento novo.

**Não implementáveis sem a palavra do Mestre (ficam como estavam):** 15-1 (monstro a apagar-se), 15-2 (exigir a Acção de Movimento inteira), 15-6 na HUD da Party; 16-2 parar a mesa ou avisar o ecrã; 16-3 (outra saída para o ficheiro recusado); 16-5 (migrar de chave). Não são lacunas de código: 15-3 (o inverso não existe na grelha), 15-4 e 15-5 (réguas da IA e Q12, já decididas), 16-4 (o servidor não tem a narração). 16-1 (append) pedia um formato novo e 16-6 uma mensagem de protocolo nova: ambos mudam o contrato, fora desta ordem.

**Parte C — varredura (achados corrigidos):**

- **V1 — E-C11 furado ao restaurar uma sala já em pausa.** Com o motor de outra versão, `pausar` não fazia nada numa sala que já vinha em pausa (ex.: o Mestre tinha caído, origem `desconexao`); a volta do Mestre (RESYNC) ou o `MASTER_RESUME` retomavam a mesa com o motor novo. Agora a pausa passa a ser do motor (`origem: 'motor'`), com um evento interno `pausa` (`soMestre: {origem, origemAnterior}`); sem anúncio novo, e o motivo que a Party já viu fica igual.
- **V2 — `restaurarJournal` com a estrutura errada.** Sem chave, o `sha256:` recalcula-se; um corpo bem assinado com `fluxos: null`, eventos ou mensagens `null`, recibos que não são pares `[texto, objecto]`, `estado` que não é objecto ou `hashCadeia` que não é texto dava `TypeError` (o adaptador só converte `ErroJournal` em «journal recusado»). Agora é `ErroJournal`. Os journals válidos não mudam.
- **V3 — o journal guardava referências.** O `commit` guardava os eventos e as mensagens dos fluxos que lhe passavam; a mesma mensagem vai ao fluxo e à mesa (`saidas`), e o RESYNC devolvia os objectos gravados. Quem mexesse numa saída mudava o registo exportado, e um evento mexido partia a cadeia do restauro. Agora o journal guarda cópias congeladas (eventos, fluxos, recibos) e `fluxo()` devolve uma lista nova.
- **V4 — journal na pasta estática, no Windows.** `conferirCaminhoJournal` comparava com `startsWith`: `c:\mesa\CLIENTE\…` passava por fora de `C:\Mesa\cliente`. Agora usa o `path.relative` da plataforma (`dentroDaPasta`), que no Windows ignora maiúsculas.
- **V5 — dotfiles nos estáticos, no Windows.** `/sub%5C.segredo` («\» é separador no Windows) e o nome curto 8.3 (`/SEGRED~1` abre `.segredo`) serviam o ficheiro. Agora os pedaços cortam-se em `/` e `\`, e o caminho real (`realpath`, nome longo) tem de ficar dentro da pasta e sem dotfiles. Consequência a saber: uma ligação simbólica dentro da pasta estática que aponte para fora deixa de ser servida.
- **V6 — alerta falso de segunda ligação.** A ligação que repetia o `ROOM_JOIN` no lugar onde já estava contava-se a si mesma: o Mestre recebia `MASTER_ALERTA segunda_ligacao` sem haver outra. O adaptador passa `seatIdDaLigacao` ao `sala.entrar`; uma segunda ligação de verdade continua a dar o alerta e a fechar a anterior (4002).
- **V7 — quadros de controlo do WebSocket.** Um ping/pong/close fragmentado ou com mais de 125 bytes era aceite; agora fecha com 1002 (RFC 6455 §5.5).

**Omissos da ordem 17 — registados, sem correcção:**

1. **O travão do `ROOM_JOIN` não tem tecto de memória.** `tentativas` guarda uma entrada por IP que falhou e só a apaga quando esse IP entra; com muitos IPs (IPv6) cresce sem limite. Limpar as entradas velhas perde a escada de espera (`nivel`), que é política de segurança (E-P9): precisa de decisão.
2. **Sala restaurada em combate sem o Mestre ligado não fica em pausa.** Depois de restaurar, ninguém está ligado mas a mesa não está pausada (E-C4 fala de o Mestre cair, não de acordar sem ele): a jogadora pode entrar e agir, e a IA em auto joga, antes de o Mestre voltar. Pausar ao acordar mudaria o que a Party vê (`ROOM_PAUSED`) e o journal restaurado (um evento novo): precisa da palavra do Mestre.
   **DECIDIDO (palavra do Mestre, 11/11/2026 14:27): «Uma batalha não pode acontecer sem mim; se entrar antes de mim, fica no lobby que criamos.»** Quem entra antes do Mestre fica no lobby (sala de espera); a batalha só retoma com o Mestre dentro. Substitui a pausa da ordem 18. IMPLEMENTADO na ordem 22 (ver abaixo).
3. **Motor de outra versão numa sala restaurada no fim.** `pausar` não pausa o fim, por isso o «Recomeçar» do Mestre começa a batalha com o motor novo. Pausar no fim seria visível à Party: precisa da palavra (junto com o TODO da migração de motor, E-C11).
   **DECIDIDO — FICA A RECUSA (sentença da bancada, ratificada pelo Mestre a 11/11/2026 15:02: «Pode seguir o crítico»).** O «Recomeçar» continua recusado (`acao_invalida`, `MOTOR_DIFERENTE`, o porquê só ao Mestre), como a ordem 18 o implementou. Não há «pausa no fim»: o `pausar` não cobre o fim, a pausa não resolveria a versão e criaria uma sala sem saída no protocolo. A guarda de versão em `recomecarBatalha` fica intocável e não é substituível por bloqueio por estado. A migração de motor (E-C11) continua TODO(JV3.x) e é a única porta de saída destas salas; sem ela, a repetição faz-se por sala nova com o encontro remontado. Ver ordem 22 (dívida menor registada).
4. **`ROOM_RESYNC` e `RECEIPT_QUERY` fora do ritmo.** O limite de 10/s (§2) só conta comandos; um lugar autenticado pode pedir RESYNC com `lastSeq: 0` sem limite, e cada um devolve o fluxo inteiro. Pôr-lhes ritmo mudaria o contrato (recusas novas): precisa de errata.

*(Ordem 18: os quatro fechados por ordem do coordenador — ver abaixo.)*

## Ordem 18 do CM-000009 — os omissos 17-1..17-4 e varredura nova (11/11/2026)

O contrato não muda: nenhum tipo de mensagem, campo, schema ou código de erro novo; o texto do journal (`journal-sala/1`), o `MASTER_EXPORT`, o `restaurarJournal` e o envelope `registo-mestre/1` ficam iguais. Testes: `testes/ordem18-omissos.test.mjs` (cada teste de correcção falhava com o código de 9314401; os de controlo passam nos dois).

**Parte B — os quatro omissos da ordem 17:**

- **17-1 — tecto do travão do `ROOM_JOIN`.** `MAX_TRAVAO = 4096` entradas. Acima disso poda-se até 90 %: primeiro as entradas `ip:` que **não** estão bloqueadas, da falha mais velha para a mais nova; só se não chegar, as bloqueadas cujo bloqueio acaba primeiro. As entradas `lugar:` (uma por lugar configurado) nunca saem. Um IP bloqueado continua bloqueado durante uma enxurrada de IPs novos (testado). A espera que dobra (E-P9) fica igual.
- **17-2 — sala restaurada em combate sem o Mestre.** Depois de restaurar, enquanto o Mestre não se ligar, a primeira entrada de outro lugar com a sala em combate pausa a mesa como uma queda do Mestre (`mestre_desconectado`, origem `desconexao`, E-C4): a jogadora entra e vê a pausa, as intenções são recusadas (`sala_pausada`) e a IA não corre. A volta do Mestre (JOIN + RESYNC) retoma-a, como sempre. Se o Mestre entra primeiro, nada muda (nenhum evento novo; restaurar, só por si, continua a não escrever nada no journal). Uma sala nova não é afectada.
  **SUBSTITUÍDO na ordem 22 (palavra do Mestre, 11/11/2026 14:27):** quem entra antes do Mestre já não pausa a mesa; fica no lobby (sala de espera) até o Mestre entrar.
- **17-3 — «Recomeçar» com motor de outra versão.** Recusado (`acao_invalida`, o texto fixo de sempre) quando o motor do journal (`estado.motores.vlabSha`) não é o motor injectado; o porquê (`MOTOR_DIFERENTE: …`) vai só ao Mestre no evento interno `recusa`. A Party não recebe nada. A migração de motor continua TODO(JV3.x) (E-C11).
  **DECIDIDO — FICA A RECUSA (sentença da bancada, ratificada pelo Mestre a 11/11/2026 15:02).** Sem «pausa no fim»; a guarda fica intocável. Ver a ordem 22.
- **17-4 — ritmo do `ROOM_RESYNC` e da `RECEIPT_QUERY`.** 10 por segundo por lugar (o número do §2), num balde próprio, separado do dos comandos (quem volta a ligar-se pede-os em rajada). Fora do ritmo: a mesma recusa que o excesso de comandos já tinha (`ROOM_REJECT` `formato`, `intentId: null`, já válida no schema), sem o fluxo; o adaptador fecha a ligação se o excesso se repetir (§2).

**Parte C — varredura (achados corrigidos):**

- **V8 — o `ERRO` `formato` não contava para fechar a ligação.** Só o `ROOM_REJECT` `formato` contava; o JSON inválido (no adaptador), o tipo desconhecido ou a sala errada (no núcleo, `ERRO` `formato`) e o `ROOM_JOIN` sem `v` (que não passa pelo travão de credenciais) não, e um cliente mandava lixo sem fim. Agora contam todos para as 5 rejeições seguidas que fecham com 1008. Qualquer outra resposta repõe a contagem, como antes.
- **V9 — UTF-8 inválido.** O texto do WebSocket era descodificado com substituição (U+FFFD) e seguia para o núcleo; a RFC 6455 §8.1 manda fechar. Agora fecha com 1007 e nada chega ao núcleo. O BOM continua como estava.
- **V10 — estado restaurado sem a forma da sala.** O `restaurarJournal` confere a assinatura e o corpo do journal, não o estado; sem chave, o `sha256:` recalcula-se. Um estado sem `lugares` (ou com lugares estragados, sem Mestre, fase desconhecida…) dava `TypeError` — que o adaptador deixa escapar em vez de «journal recusado» — ou abria uma sala que rebentava no primeiro `ROOM_JOIN`. Agora o `criarSala` confere a forma que o próprio servidor escreve (`sala/1`) e lança `ErroJournal`. Só forma, nenhuma regra de jogo; os journals válidos não mudam.

**Registado, sem regra inventada (N18-):**

1. **N18-1 — o que se perde ao podar o travão.** A entrada podada leva a contagem das falhas recentes e o `nivel` da escada de espera de quem já não está bloqueado: esse IP volta a começar do nível 0. O tecto (4096) e a ordem da poda são escolha de implementação; outra política (agrupar IPv6 por /64, guardar o `nivel` mais tempo) precisa da palavra do Mestre.
   **DECIDIDO — SEM MUDANÇA (palavra do Mestre, 11/11/2026, ordem 21):** a limpeza do registo recomeça a escada de espera do IP limpo do nível 0; a política simples fica.
2. **N18-2 — 17-3 só recusa.** O Mestre não é avisado ao restaurar (isso seria um evento novo no journal restaurado); sabe-o ao tentar «Recomeçar». Avisar à entrada precisa da palavra.
   **DECIDIDO — SIM, avisar (palavra do Mestre, 11/11/2026): IMPLEMENTADO na ordem 21** (evento `aviso_motor`, ver abaixo).
3. **N18-3 — 17-2 e o lobby.** Uma sala restaurada no lobby não pausa quando a jogadora entra sem o Mestre (no lobby ela não pode agir). Se o Mestre quiser a pausa também aí, precisa da palavra.
   **DECIDIDO — SEM MUDANÇA (palavra do Mestre, 11/11/2026, ordem 21):** no lobby ela não pode agir; a sala restaurada no lobby não pausa.
4. **N18-4 — o `ROOM_JOIN` com outra versão do protocolo** (`ERRO` `versao`) continua sem contar para fechar a ligação: é um cliente legítimo de outra versão, não formato mal feito. O mesmo para as mensagens bem formadas antes de entrar (`ERRO` `sem_lugar`). Pôr-lhes limite precisa da palavra (não são rejeições de formato do §2).
   **DECIDIDO — SEM MUDANÇA (palavra do Mestre, 11/11/2026, ordem 21):** os erros de versão e as mensagens pré-JOIN bem formadas não contam para fechar a ligação.

## Ordem 19 do CM-000009 — varredura crítica alargada: servidor, cliente e protocolo (11/11/2026)

O contrato não muda: nenhum tipo de mensagem, campo, schema ou código de erro novo; `journal-sala/1`, `MASTER_EXPORT`, `restaurarJournal` e `registo-mestre/1` iguais. Nada novo chega à Party. Os omissos registados até à ordem 18 (README acima e listas das ordens) precisam todos da palavra do Mestre ou mudam o contrato: nenhum foi implementado nesta ordem.

**Achados corrigidos (cada um com um teste que falhava antes):**

- **V11 — servidor/protocolo: a `RECEIPT_QUERY` ecoava ids inválidos.** Um id que não passa no `RE_ID` (65 caracteres ou mais, ou caracteres fora de `[A-Za-z0-9_-]`) voltava tal e qual no `ROOM_RECEIPT` `DESCONHECIDA`; com mais de 64 caracteres a mensagem que saía do servidor violava o próprio schema (`intentId`, `maxLength: 64`). Agora o id inválido volta `null` — a forma que o schema já tinha para o id que não é texto. Um id válido (próprio, alheio ou nunca visto) volta como antes. Teste: `testes/ordem19-varredura.test.mjs` (falhava em 258171d, conferido localmente; o tráfego do teste também passa na conferência dos schemas do job `protocolo`).
- **V12 — cliente: o snapshot da reentrada era deitado fora.** Se o servidor for restaurado de um journal a que falta o fim (a gravação em disco falhou antes da queda; ordem 17, B1), o lugar volta com `seq` e `revision` mais baixos do que o aparelho viu. O `ROOM_JOIN` leva `lastSeq` acima do `seq` do servidor e o servidor responde, como deve, com um `ROOM_SNAPSHOT` (`mensagensDeSincronizacao`). O `estado.gd` ignorava qualquer snapshot com `seq` abaixo do seu e guardava sempre a revisão maior: o aparelho ficava preso no estado velho, os eventos novos pareciam repetidos e as opções nunca valiam (intenções com a revisão errada). Agora, entre o `ROOM_WELCOME` e a primeira sincronização, o snapshot que vier manda: o `seq` e a revisão recomeçam dele e a espera velha limpa-se. Fora da reentrada, um snapshot mais velho continua ignorado. Teste: `cliente/testes/rodar_testes.gd`, «Reentrada num servidor restaurado» (o commit ed8c493 trouxe só o teste e o job `cliente` do CI falhou nele; a correcção vem no commit seguinte).

**Registado, sem correcção (N19-):**

1. **N19-1 — o exemplo do `MASTER_EXPORT` não tem a forma real.** `protocolo/v2/exemplos/MASTER_EXPORT.json` (escrito à mão em `gerar-exemplos.py`) mostra `conteudo` como objecto `{corpo, assinatura}`; o servidor manda o texto de `journal.exportar()` (`<corpo>\n<assinatura>\n`). O schema aceita os dois (`["object", "string"]`), por isso nada falha. O `MASTER_EXPORT` está na lista do que não se mexe: acertar o exemplo (e, se se quiser, estreitar o schema para `string`) precisa da palavra do coordenador. Nenhum teste do servidor pede o `exportar` pelo protocolo; o «NENHUM teste o gera ainda» do schema continua verdadeiro.
2. **N19-2 — o `ROOM_JOIN` do cliente não leva `roomId` na primeira entrada.** O schema `ROOM_JOIN` exige `roomId`; o servidor não o exige no JOIN (`sala.entrar` nem o olha) e o cliente só o manda depois de o conhecer de um `ROOM_WELCOME` (o `roomId` é sorteado a cada arranque sem journal). As mensagens do cliente à jogadora não passam pelo `validar-mensagens.py` (só as do Mestre), por isso nada falha. Tornar o `roomId` opcional no schema (ou dá-lo ao cliente antes do JOIN) muda o contrato: precisa de errata.

*(Ordem 21: N19-1 corrigido por decisão do coordenador; N19-2 corrigido com errata, por decisão do Mestre — ver abaixo.)*

## Ordem 21 do CM-000009 — as decisões sobre os omissos N18/N19 (11/11/2026)

O Mestre aprovou, a 11/11/2026, as cinco recomendações do coordenador; o coordenador decidiu o N19-1. Cada mudança tem um teste que falhava em 92c0983 (`testes/ordem21-decisoes.test.mjs`, 4 de correcção + 4 de controlo; `cliente/testes/pecas_mestre.gd`, 7 verificações novas).

**Implementado:**

- **N18-2 — SIM, avisar.** Sala restaurada **no fim** com um motor de outra versão (o caso 17-3, em que o «Recomeçar» vai ser recusado): na transacção do restauro nasce o evento `aviso_motor` no journal, só do Mestre (`dados: {}`; `soMestre: {codigo: 'MOTOR_DIFERENTE', recomecar: 'recusado', motorGravado, motorAgora}`). A Party não o recebe (não está na lista de tipos dela; o `seq` dela não mexe). O Mestre recebe-o pelo seu fluxo ao voltar (JOIN com o token e o `lastSeq`, ou RESYNC); o ecrã do Mestre põe-no nos alertas, uma vez por `seq` («Sala restaurada com outra versão do motor: «Recomeçar» não vai funcionar.»), e o registo chama-lhe «aviso do motor». O aviso fica no journal: restaurar outra vez com o motor certo não o apaga nem cria outro. Com o mesmo motor, restaurar continua a não escrever nada; em combate continua a pausa de manutenção (E-C11), sem `aviso_motor`. Schema: `ROOM_EVENT` `paraMestre` ganha o tipo `aviso_motor` (errata D-35).
- **N19-2 — SIM, errata de contrato.** O schema `ROOM_JOIN` deixa de exigir `roomId` (errata D-34, no schema e no `protocolo/README.md`). O servidor já se comportava assim (o JOIN entra com ou sem `roomId`). No cliente, o JOIN passou a ser montado por `rede.gd` `montar_join()` (sem mudar o que manda): sem `roomId` na primeira entrada, com ele depois do `ROOM_WELCOME`. O `pecas_mestre.gd` escreve esses JOIN no ficheiro dos comandos e o job `cliente` confere-os com o schema (`validar-mensagens.py`); com o schema antigo, os dois primeiros eram recusados.
- **N19-1 — decisão do coordenador.** O exemplo `protocolo/v2/exemplos/MASTER_EXPORT.json` (e o `gerar-exemplos.py` que o escreve) tem `conteudo` como o texto que o servidor manda (`journal.exportar()`: corpo, nova linha, assinatura, nova linha). Valida contra o schema (o job `protocolo` confere os exemplos). O schema continua a aceitar `["object", "string"]` (não foi pedido estreitá-lo); a descrição já não diz «NENHUM teste o gera»: o teste novo pede o `exportar` pelo protocolo e o `MASTER_EXPORT` entra no tráfego conferido.

**Decidido — sem mudança (palavra do Mestre, 11/11/2026; não voltar a perguntar):**

- **N18-1:** a limpeza do registo do travão recomeça a escada de espera do IP limpo do nível 0. A política simples fica.
- **N18-3:** a sala restaurada no LOBBY não pausa quando entra a jogadora sem o Mestre (no lobby ela não pode agir). Fica.
- **N18-4:** o `ERRO` `versao` e as mensagens pré-JOIN bem formadas (`ERRO` `sem_lugar`) não contam para fechar a ligação. Fica.

**Registado, sem regra inventada (N21-):**

1. **N21-1 — o Mestre que entra sem `lastSeq` não recebe o evento.** O `aviso_motor` chega pelo fluxo: um aparelho do Mestre que se religa com o token e o `lastSeq` (o caso normal quando o servidor reinicia com o ecrã aberto) recebe-o; um aparelho que entra de novo sem `lastSeq` (PIN num aparelho novo, ou a app reaberta) recebe o snapshot, que não traz eventos, e só sabe ao tentar o «Recomeçar» (recusa com `MOTOR_DIFERENTE`, como na ordem 18) ou ao ler o journal exportado. Pôr o aviso também na vista do Mestre (ex.: um campo na `MASTER_VIEW`, ou um `MASTER_ALERTA` com motivo novo a cada entrada do Mestre) muda o contrato: precisa da palavra.
   **DECIDIDO — SIM (palavra do Mestre, 11/11/2026 16:13): IMPLEMENTADO na ordem 22** (campo `avisoMotor` na `MASTER_VIEW`, errata D-36; ver abaixo).

## Ordem 22 do CM-000009 — duas decisões do Mestre, uma sentença ratificada e varredura (11/11/2026)

Testes: `testes/ordem22-decisoes.test.mjs` (8; em 276e573 falhavam 6 — 17-2 a, b, a-pausa; N21-1 e os dois controlos do campo novo — e passavam os 2 controlos do 17-2); `cliente/testes/pecas_mestre.gd` (+4 verificações; 2 falhavam antes) e `cliente/testes/rodar_testes.gd` (+3, controlo: o cliente já aceitava). O teste 17-2 da ordem 18 foi trocado pelo comportamento novo.

**Implementado:**

- **17-2 — sala de espera antes do Mestre** (palavra do Mestre, 11/11/2026 14:27: «Uma batalha não pode acontecer sem mim; se entrar antes de mim, fica no lobby que criamos.»). Uma sala restaurada **a meio de uma batalha** (em `combate`, ou em `pausa` vinda do combate — a pausa de manutenção do motor incluída) acorda em espera do Mestre. Até o Mestre entrar (`ROOM_JOIN` dele), quem entra fica no **lobby**: o `ROOM_SNAPSHOT` dela tem `fase: 'lobby'`, sem figuras, ordem, vez, rodada, ambiente nem fogo; leva só a ficha dela (`propria`, como no lobby de sempre, e o schema da jogadora exige-a). Não recebe eventos, opções, `ROOM_PAUSED`/`ROOM_RESUMED`; o RESYNC e a reentrada com token e `lastSeq` devolvem o mesmo lobby (nada do fluxo da batalha); a intenção é recusada como no lobby (`fora_da_vez`). Nada se escreve no journal por isso: nem pausa, nem retomada (o fluxo dela continua a gravar-se). Quando o Mestre entra, cada lugar ligado recebe o snapshot da batalha (o mesmo `seq`: o cliente aceita-o e passa do lobby à arena) e as opções, se for a vez dela. O Mestre a entrar primeiro: nada muda. Sala restaurada no lobby ou no fim, ou sala nova: como sempre. Depois de o Mestre ter entrado, a queda dele volta a ser a E-C4 de sempre (pausa). A espera vive só em memória (um restauro novo volta a começar nela). Contrato igual: tipos, campos e schemas do snapshot os de sempre.
- **N21-1 — o aviso do motor também na vista do Mestre** (palavra do Mestre, 11/11/2026 16:13: sim). A `MASTER_VIEW` ganha `avisoMotor`: `null`, ou os campos do `soMestre` do evento `aviso_motor` (`codigo: 'MOTOR_DIFERENTE'`, `recomecar: 'recusado'`, `motorGravado`, `motorAgora`) enquanto a sala estiver no fim gravada com outro motor. O Mestre que entra de fresco (PIN, sem `lastSeq`) recebe-o na vista que vem com a entrada e em cada pedido. Em combate continua a pausa de manutenção, sem aviso. O ecrã do Mestre põe-no nos alertas uma vez por par de versões (gravada → agora), venha pela vista ou pelo fluxo. Só o Mestre recebe a `MASTER_VIEW`. Errata D-36 no schema `MASTER_VIEW` e no `protocolo/README.md` (campo fora do `required`, para as vistas de antes; o servidor manda-o sempre).

**Decidido — sem código novo:**

- **17-3 — FICA A RECUSA** (sentença da bancada, ratificada pelo Mestre a 11/11/2026 15:02: «Pode seguir o crítico»). Ver o 17-3 nas ordens 17 e 18 acima. A guarda de versão em `recomecarBatalha` não foi tocada.

**Errata futura, sem pressa (registada, NÃO corrigida nesta ordem):**

- **E-22-1 — a guarda de versão compara só o `vlabSha`.** `recomecarBatalha` (e o restauro, e agora o `avisoMotor`) comparam `estado.motores.vlabSha` com o do motor injectado; `null === null` passa: duas salas sem sha registado (motor sem `MOTOR_SHA256`) não se distinguem, mesmo que o motor tenha mudado (o `dmgVersao` e o `levelupSha` não entram na conta). Dívida menor; a correcção, quando vier, é na guarda (não por bloqueio por estado).


**Varredura (o espírito das V1-V12; `testes/ordem22-varredura.test.mjs`, cada teste de correcção falhava em 7e36ede):**

- **V13 — `MASTER_PLACE` com `orientacao: ""`.** O servidor só limitava o comprimento máximo da orientação; a vazia era aceite, a figura ficava com orientação `""` e o evento `colocacao` e o snapshot que saíam para a Party violavam o próprio schema (`comum.schema.json` `orientacao`: `minLength 1`). O schema de entrada `MASTER_PLACE` já a recusava; agora o servidor também (`ROOM_REJECT` `formato`, nada gravado). Sem orientação, ou `null`, continua a dar `'S'`.
- **V14 — hora do painel fora do relógio.** `efeitoAmbiente` só olhava para a hora ≥ 18: `"25:70"` ou `"99:00"` davam `luz: 'noite'` à Party. Uma hora que não existe não diz se é dia ou noite: `luz: null`, como sem hora. As horas válidas (00:00..23:59) não mudam.
- Lidos de novo sem achados: o restauro do journal, a sincronização (RESYNC/JOIN com `lastSeq`), as validações dos comandos do Mestre e das intenções, e os caminhos novos da sala de espera (eventos, opções, pausa/retomada e recusas não chegam a quem espera; o fluxo grava-se).

**Registado, sem regra inventada (N22-):**

1. **N22-1 — a sala de espera só existe depois de um restauro.** A palavra do Mestre («uma batalha não pode acontecer sem mim») foi implementada para o caso pedido: sala restaurada a meio da batalha, antes de o Mestre entrar. Numa sala que não foi restaurada, ou depois de o Mestre ter entrado uma vez, a queda do Mestre continua a ser a E-C4 de sempre: a mesa pausa e quem entra (ou volta) nessa altura vê a batalha em pausa, não o lobby. Levar quem entra durante a ausência do Mestre também para o lobby nesses casos muda o que a Party vê numa queda normal: precisa da palavra do Mestre.
