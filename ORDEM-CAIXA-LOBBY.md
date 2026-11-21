# ORDEM-CAIXA-LOBBY — a caixa vazia sai do snapshot do lobby simples + a validação da ordem dinâmica rejeita chaves a mais

**Executor:** Claude conta 2, no PC do cunhado. **Base:** a ponta da linha
`fable/integracao-50` @ `2949d16` (faz `git fetch origin` e parte de
`origin/fable/integracao-50`). **Ramo novo:** `claude2/caixa-lobby`.
**Sede:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-caixa-lobby\`.

Esta ordem fecha as correcções **B6** e **B7a** da conferência da Ordem
CAIXA-HUD-JOGADORA (sentença do coordenador, 21/11/2026). **Não fundas** — a fusão é do
coordenador.

## B6 — o snapshot do lobby simples não traz a caixa vazia

- Hoje, o snapshot da sala de espera simples (sem Mestre) traz a `caixa` por omissão,
  vazia. Não é fuga (o cliente esconde-a fora de combate), mas é ruído: **suprime a
  `caixa` do snapshot quando a fase não é combate** (`fase !== 'combate'`), no mesmo
  espírito fail-closed do resto da peça.
- Em combate, o snapshot continua a trazer a caixa como hoje — comportamento intacto.
- **Teste em falta (criar):** o lobby simples — o snapshot da espera sem Mestre **não**
  traz `caixa`; e o snapshot de combate traz. Junta-o à suite que já cobre o snapshot
  (servidor), com o nome que a casa usa.

## B7a — `conferirOrdemDinamica` rejeita chaves a mais

- A validação da ordem dinâmica passa a **rejeitar chaves a mais**, como a de
  `caixaMestre` já faz: uma ordem dinâmica com uma chave fora da lista permitida é
  recusada, não ignorada.
- **Teste:** uma ordem dinâmica com uma chave estranha (ex.: um campo inventado) é
  rejeitada; as ordens válidas de hoje continuam a passar todas.

## Fronteiras

- Só isto: snapshot do lobby + validação da ordem dinâmica + os testes. Nada de HUD,
  nada de cores, nada de retratos (isso é a frente da conta 1).
- Privacidade intacta: nenhum nome verdadeiro, vida, alma ou PA ganha caminho novo para
  a jogadora.

## Prova e entrega

- Corridas: as suites do servidor e do cliente que a casa corre para esta peça, mais os
  testes novos a passar; os números exactos vão no ESTADO-FINAL.
- **Antes do commit final:** corre o `actualizar-listas` da retoma e inclui as listas
  sincronizadas no commit — o ramo tem de passar o CI inteiro, incluindo o passo
  retoma-pc.
- Commit(s) publicado(s) no ramo `claude2/caixa-lobby`, **sem fundir**.
- `ESTADO-FINAL-ORDEM-CAIXA-LOBBY.md` na raiz do ramo: o que mudou (B6 e B7a, ficheiro a
  ficheiro), os testes novos e os números das corridas, e os pontos que julgares que o
  coordenador deve saber.
- O ficheiro da ordem termina com a linha exacta: <b>Estado: NOVA</b>

<b>Estado: NOVA</b>
