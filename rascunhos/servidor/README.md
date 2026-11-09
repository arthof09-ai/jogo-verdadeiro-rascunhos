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

- **Decisão 1:** o monstro também tem cartão de desgraça. `montarContexto` manda `modoDesgraca: 'proposta'` a todos; só o ataque de oportunidade fica em `'sorte'` (resolve-se a meio do movimento dela, numa série que não pára à espera do Mestre — fica como pergunta para o desenho). O cartão é o mesmo das heroínas (Confirmar / Escolher outra, com a mesma lista e a mesma semente).
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
