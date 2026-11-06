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
