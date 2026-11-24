# Provas — ORDEM-F4-PARCIAL-A7-CANARIOS (errata A-7: os três canários do grupo 07)

Corrido no PC, com Node `v26.13.0` (`logs/node-versao.txt`), e com o motor oficial `a91c021c…`. É o mesmo motor da
F4-PARCIAL (`logs/sha256-motor-usado.txt`). Foi baixado do endereço público do job `motor-real` e embrulhado com
`motores/embrulhar.mjs`, como no CI.

- Ponta de partida: `e8b9dc3`.
- Commits da ordem: `b3c3c8d` (a troca e a regeneração) e `f71b070` (as listas da retoma).
- CI no `f71b070`: Testes dos rascunhos `45380773607` (10/10 jobs `success`, incluído o `motor-real`) e Sonda de
  privacidade `45380773642` (`success`).

Os caminhos absolutos do PC foram redigidos nos dois logs de geração (`<pasta-da-ordem>`). Nada mais mudou nos logs.

## A troca

`rascunhos/servidor/testes-motor-real/vetores-ouro.mjs`, l. 225. O texto novo é o da ordem, letra a letra:

```js
  h.paTotal = 20; h.vidaTotal = 60; h.ca = 12; // fictícios (os canários 4040, 5150 e 5551 da fixture não importam aqui: o guião não varre privacidade)
```

## Os logs

| Ficheiro | O que prova |
|---|---|
| `logs/motor-real-antes-da-troca.log` | A linha de base, na ponta `e8b9dc3`, antes da troca: 517/517 e o SHA velho do grupo 07 (`43706ae3…`) |
| `logs/gerar-corrida-1.log`, `logs/gerar-corrida-2.log` | A geração depois da troca, em dois processos separados (pastas `vo-1` e `vo-2`). O grupo 07 dá o SHA `db2b87ae…`. Os outros 8 grupos dão os SHAs de antes |
| `logs/sha256-corrida-1.txt`, `logs/sha256-corrida-2.txt` | O `sha256sum` dos 10 ficheiros gerados em cada corrida. Os dois são **iguais** (`diff` vazio). Comparados com os ficheiros gravados antes da troca, só mudam duas linhas: `07-transformacao.json` e `MANIFESTO.json`. Para o repositório copiei só esses dois ficheiros |
| `logs/canarios-grupo-07.txt` | No `07-transformacao.json` gravado, o 5150 aparecia 74 vezes e o 5551 aparecia 30 vezes. Agora aparecem **0** vezes cada um. O 4040 já não aparecia antes (0 → 0). Os 30 casos continuam 30, e a saída de todos mudou (a vida e a CA da heroína entram na saída) |
| `logs/motor-real-corrida-1.log`, `logs/motor-real-corrida-2.log` | O job `motor-real` reproduzido no PC, depois da troca, duas vezes: 6/6 testes. Os vetores-ouro dão **517/517**, com o **07 a 30/30**. O teste dos bytes compara duas gerações com os ficheiros gravados e passa |
| `logs/ci-motor-real-45380773607.log` | O mesmo job no CI (run `45380773607`, ponta `f71b070`): motor `a91c021c…`, 6/6 testes, **517/517**, 07 a 30/30 |
| `logs/servidor-com-allow-net.log` | A suite do servidor com o comando do CI e mais `--allow-net` (Node 26 neste PC): 442 testes, 432 passam, **0 falham**, 10 saltados. São os mesmos números da F4-PARCIAL. No CI, o job `servidor` deu o mesmo: 442, 432, 0 e 10 |

## Os SHAs novos

| Ficheiro | Antes | Depois |
|---|---|---|
| `vetores-ouro/07-transformacao.json` | `43706ae3def33333273c65f34af9bac6645a9cf306e91c26846988a05c6a9d8a` | `db2b87aec69b79c7788139b83735b09f3e01f15c65cee1f1e875b9c01d87dd4c` |
| `vetores-ouro/MANIFESTO.json` | `7b297ee5a026f1d23fc7d62f9610567d70d09bbdd8112f863b4f38bcc226b7c4` | `c06b6e1f94c055486065b3646b2de747bba05335363c5c887bb14ea85417e0af` |

Actualizei também os `provas/ordem-f4-parcial/logs/sha256-corrida-*.txt`: só mudaram estas duas linhas. Agora são
byte-iguais aos desta pasta, e o README da F4-PARCIAL tem uma nota a dizê-lo.

## Como repetir

```sh
# na pasta rascunhos/servidor/
node motores/embrulhar.mjs <vlab-completo.js> <motores.mjs>
node testes-motor-real/gerar-vetores.mjs <motores.mjs> <pasta>        # gera numa pasta à parte
sha256sum <pasta>/*.json                                              # comparar com logs/sha256-corrida-1.txt
MOTOR_MJS=<motores.mjs> node --test --test-reporter=spec "testes-motor-real/*.test.mjs"
```
