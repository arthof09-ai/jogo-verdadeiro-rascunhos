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
- **Persistência:** journal em disco no adaptador; checkpoints do "voltar" só em memória.
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
