# Protocolo v2 da mesa — schemas, exemplos e conferência

Os schemas JSON (Draft 2020-12) das mensagens entre o servidor da mesa e os clientes (jogadoras, espectador e Mestre). A especificação é a página **JV0.4 — Protocolo v2 da Mesa** no Notion (rascunho 0.2.1 e erratas). Onde a regra só existe no servidor (`servidor/nucleo/sala.js` e `projecao.js`), a descrição do schema diz «errata proposta D-xx».

Estado: **rascunho conferido contra o tráfego real do servidor** (CM-000008-I0004, 08/11/2026). Nada disto foi corrido no PC.

## O que está aqui

```
protocolo/
├── README.md                     este ficheiro
├── v2/
│   ├── comum.schema.json         peças partilhadas (ids, acao, mapa, figuraPublica, ...)
│   ├── <TYPE>.schema.json        um schema por `type` de mensagem (30)
│   └── exemplos/<TYPE>.json      casos reais, tirados dos testes do servidor
└── ferramentas/
    ├── conferir-schemas.py       confere schemas, exemplos e tráfego real
    └── gerar-exemplos.py         gera v2/exemplos/ a partir do tráfego real
```

## As mensagens

| `type` | Sentido |
| --- | --- |
| `ROOM_JOIN` | cliente → servidor |
| `ROOM_WELCOME` | servidor → quem entrou |
| `ROOM_INTENT` | jogadora → servidor |
| `ROOM_RESYNC` | cliente → servidor |
| `RECEIPT_QUERY` | cliente → servidor |
| `ROOM_RECEIPT` | servidor → o autor |
| `ROOM_REJECT` | servidor → o autor |
| `ROOM_EVENT` | servidor → cada lugar, projetado pelo papel |
| `ROOM_SNAPSHOT` | servidor → cada lugar, projetado pelo papel |
| `ROOM_OPTIONS` | servidor → a jogadora da vez (e o Mestre na vez de criatura) |
| `ROOM_PAUSED` / `ROOM_RESUMED` | servidor → todos |
| `ERRO` | servidor → quem causou |
| `MASTER_LOBBY_SET`, `MASTER_START`, `MASTER_PLACE`, `MASTER_MODE`, `MASTER_ACT`, `MASTER_APPROVE`, `MASTER_CONFIRM_DICE`, `MASTER_AMBIENTE`, `MASTER_SUPERVISOR`, `MASTER_PAUSE`, `MASTER_RESUME`, `MASTER_SEARCH` | Mestre → servidor |
| `MASTER_VIEW` | Mestre ↔ servidor (pedido vazio; resposta com a vista inteira) |
| `MASTER_CARD`, `MASTER_RESULTS`, `MASTER_ALERTA`, `MASTER_EXPORT` | servidor → Mestre |

`ROOM_EVENT` e `ROOM_SNAPSHOT` têm um ramo por papel: `#/$defs/paraMestre`, `#/$defs/paraJogadora` e `#/$defs/paraEspectador`. A «outra jogadora» vê o mesmo que o espectador: os campos `propria` só chegam à jogadora a quem o evento diz respeito. Essa regra é semântica (depende de quem recebe) e a ferramenta de conferência confere-a.

## Como conferir

A partir de `rascunhos/`, com Node 22 ou 24 e Python 3 com `jsonschema` (>= 4.18):

```sh
PROTOCOLO_DUMP=/tmp/trafego.jsonl node --test --test-concurrency=1 servidor/testes/*.test.mjs
python3 protocolo/ferramentas/conferir-schemas.py /tmp/trafego.jsonl
```

Com `PROTOCOLO_DUMP`, os ajudantes dos testes (`servidor/testes/ajudantes.mjs`) escrevem cada mensagem que entra ou sai do servidor. Sem a variável, não escrevem nada. A conferência:

1. meta-valida os 31 schemas e confirma que todos os `$ref` resolvem;
2. valida os exemplos de `v2/exemplos/`;
3. valida cada mensagem que **sai** do servidor contra o schema do seu `type`; em `ROOM_EVENT` e `ROOM_SNAPSHOT`, contra o ramo do papel de quem recebeu;
4. confere a regra da outra jogadora: um evento que não é da jogadora tem de caber em `paraEspectador`;
5. falha se o servidor mandar um `type` sem schema.

As mensagens que **entram** e falham são só informação: os testes mandam entradas inválidas de propósito (o servidor recusa-as), e é bom ver que o schema também as recusa. Os ids dos testes (`it-1`, `cmd-1`) não são UUID v4 e contam-se à parte.

Com `--test-concurrency=1` os ficheiros de teste correm um a um e o tráfego sai sempre igual (conferido: o mesmo SHA-256 em duas corridas); por isso os exemplos são reprodutíveis.

Para refazer os exemplos depois de mudar o servidor ou os schemas:

```sh
python3 protocolo/ferramentas/gerar-exemplos.py /tmp/trafego.jsonl
```

Os exemplos vêm do servidor, não são escritos à mão (excepto `MASTER_CONFIRM_DICE` e `MASTER_EXPORT`, que nenhum teste gera ainda). Os canários dos testes passam a `EXEMPLO-…`, as senhas a marcadores, o PIN a `12345678` e os ids de intenção a UUID v4 fixos.

## Conferência de 08/11/2026 (CM-000008-I0004)

Tráfego: 5.082 mensagens dos 57 testes do servidor (com os patches da 4.ª corrida). Resultado final: **zero falhas nas mensagens que saem**; todos os exemplos válidos.

**Corrigido nesta conferência**

1. `ROOM_EVENT` não tinha `teste_morte` para a Party; a jogadora recebia um evento que nenhum schema aceitava. Entrou `dados_teste_morte` (só `figuraId`).
2. Cinco mensagens que o servidor manda ao Mestre não tinham schema: `MASTER_CARD`, `MASTER_VIEW`, `MASTER_RESULTS`, `MASTER_ALERTA` e `MASTER_EXPORT`. Foram escritas a partir de `sala.js`.
3. `desgraca` ganhou o ramo `dados_desgraca_propria`, com `perdeQuarto` (REF_19), só para a própria.

**Pendente ou fraco (por decidir ou apertar)**

1. `ROOM_EVENT` e `comum` citam `../validar.mjs` (`conferirPropria()`) e `../DIVERGENCIAS.md`, que **não estão no repositório**. Se existirem no PC, falta a ponte; se não, a conferência acima faz o papel do `conferirPropria()`.
2. O schema exige `intentId` UUID v4 (§3); o servidor aceita qualquer id opaco (`RE_ID`). O cliente tem de gerar UUID v4; o servidor fica tolerante.
3. O bloco `mestre` do snapshot: `figuras` já está fixado (`#/$defs/figuraMestre`, ver abaixo); `vez`, `lobby` e `cartoes` ainda só dizem «objeto».
4. `MASTER_CONFIRM_DICE` e `MASTER_EXPORT` não aparecem em nenhum teste: os schemas não foram conferidos contra tráfego real.
5. Em `comum.schema.json`, os `$defs` `desgraca` e `tipoAcao` não são usados por nenhum schema.
6. As erratas propostas D-xx não foram conferidas, uma a uma, contra a página JV0.4 nesta sessão.

## Lacunas L1 e L2 do ecrã do Mestre (08/11/2026, CM-000008-I0004)

Pedidas pela revisão do Muse (CM-000009) ao desenho JV3.1 (Notion: «JV3.1 — Ecrã do Mestre no cliente: desenho para revisão»).

- **L1, vista do Mestre:** cada figura de `mestre.figuras` (no `MASTER_VIEW` e no snapshot do Mestre) traz agora, além do estado interno, `nome` (verdadeiro), `nomePublico`, `vidaTotal` e `paTotal`, tirados da ficha (`projecao.js`, `figuraDoMestre`). Schema: `ROOM_SNAPSHOT.schema.json#/$defs/figuraMestre`, com os campos obrigatórios. Nada disto vai à Party (canários em `servidor/testes/privacidade.test.mjs` e controlo positivo em `mestre-vista.test.mjs`).
- **L2, cartão de desgraça:** o `MASTER_CARD` tem o campo obrigatório `desgracas`: a lista que o Mestre pode escolher no «Editar» (as 6 desgraças e «nenhuma»), e `null` nos outros tipos de cartão. O servidor recusa (`acao_invalida`) um `MASTER_APPROVE` com `edicao.desgraca` fora dessa lista, e o cartão fica aberto. O enum vive em `comum.schema.json#/$defs/desgracaEditavel`.
  - **«nenhuma»:** é o que «Recusar» aplica hoje (PERGUNTA PARA O MESTRE 11).
  - **«acerta-amigo»:** espera a PERGUNTA 12.
- **Tráfego desta conferência:** 6.002 mensagens dos 64 testes do servidor, com zero falhas nas mensagens que saem. Os exemplos foram gerados outra vez a partir do tráfego.

## Lacuna L8 do ecrã do Mestre: os pontos de «voltar» (08/11/2026, CM-000008-I0004)

- A `MASTER_VIEW` (resposta) tem agora o campo obrigatório `pontos`: até 50 pontos a que o `MASTER_SUPERVISOR` `voltar` aceita ir, do mais novo ao mais velho.
  - Cada ponto é `{journalSeq, ts, fase, rodada, vezId, tipos}` (`MASTER_VIEW.schema.json#/$defs/ponto`).
  - O `journalSeq` do ponto é o `ateSeq` a mandar.
  - O ponto actual nunca aparece, porque o servidor recusa voltar a ele.
  - O ponto inicial tem `tipos: ["inicio"]` e `ts: null`.
- **Privacidade:** só o lugar do Mestre recebe os pontos. O teste `servidor/testes/mestre-vista.test.mjs` confere que nenhuma mensagem da Party os leva.
- **Limite conhecido:** os pontos vivem em memória, como os checkpoints. Depois de a sala acordar de um journal guardado, só há pontos a partir daí (é o mesmo TODO(JV1.x) dos checkpoints).
