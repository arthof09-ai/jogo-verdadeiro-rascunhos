# ESTADO-FINAL — Ordem CAIXA-RELATO-B7-CORRECOES-7

Esta ordem faz as correcções JD2–JD6 da sentença da CAIXA-RELATO-B7-CORRECOES-6, que deu **FUNDE COM CORRECÇÕES — 925**.
O trabalho foi feito no PC, na conta 1 do Claude, a 22/11/2026.

- **Trabalho directo na linha** `fable/integracao-50`, sem ramo lateral e sem fusão.
- **Base:** `bfe4c3c`, a ponta da linha no lançamento. A RELATO-CORRECOES-8 já tinha entrado (`47ef646`/`bfe4c3c`),
  por isso a dependência nomeada estava satisfeita.
- **Rebase antes de publicar:** durante o trabalho entrou na linha a `33d9185` (CAIXA-TESTES-CORRECOES-12, que só mexe
  em dois `.md` da raiz). O rebase foi limpo e não houve conflitos.
- **Commits desta ordem na linha:**
  - `687bd92` — as correcções e os registos: 13 ficheiros;
  - `30c4c76` — as listas da retoma;
  - o commit deste ficheiro, que leva também o verificador acertado e o `verificacao-pin.log` regenerado (ver B2).

**Privacidade:** nenhum ficheiro cometido por esta ordem tem o valor do PIN antigo, o do PIN novo de 20 dígitos ou o
de uma corrida, e este ficheiro também não tem. Nos ficheiros novos ou mudados há **0** cadeias de 20 ou mais dígitos
seguidos, e todo o PIN de corrida tem 20. **Há um achado fora do território**, descrito no ponto 1 para o coordenador.

## B1 (JD2) — o 4.º lançador e o `.pathname`

**Feito, e correu.**

### O servidor da caixa

- Em `provas/ordem-caixa/ferramentas/servidor-bancada-prova.mjs`, os 3 `.pathname` (cenário, motor por omissão e
  pasta `.cache`) passam a usar `fileURLToPath`, como na cópia do HUD.
- No código, fora dos comentários, ficam **0** `.pathname` e **3** `fileURLToPath(`.
- Arranque vivo no Windows, com o cenário novo e um PIN fresco: `pronto: true`, a linha `pronto-prova-caixa` está
  presente, há 0 chaves `"pin"` no info e o PIN da corrida aparece 0 vezes no info e no log.
- Antes da correcção, este servidor não abria o cenário no Windows.

### O lançador `provas/ordem-caixa/ferramentas/correr-prova-caixa.sh`

- Aceita agora `<godot> <vlab-completo.js> <pasta-tmp> [<pasta-saída>]`, como os outros 3 lançadores.
- Os caminhos passam pela função `absolutizar` da relato.
- Só usa o `xvfb-run` quando ele existe.
- **Sem argumentos, mantém o modo antigo tal como estava** (Linux, `~/workspace/claude2-hud`).
- **Decisão:** a ordem dizia «a corrida, no Linux», mas esta máquina não tem Linux (nem WSL). Por isso tornei o
  lançador portátil e corri-o aqui.

### A corrida (`b7-correcoes-7/lancador-caixa.log`)

- Deu **rc=0** e **23 de 23**.
- O relato tem 40 linhas e é igual ao `provas/ordem-caixa/cliente/relato.txt` cometido (corrida de Linux). Só mudam o
  render (RTX 4060 contra llvmpipe) e o tamanho das capturas: 1028×720, como nas outras provas deste PC.
- **Contagem do PIN da corrida:**
  - chaves `"pin"` no stdout, no info e no log do servidor: 0 / 0 / 0;
  - cadeias de 20 ou mais dígitos no stdout, no info, no log e no relato: 0 / 0 / 0 / 0;
  - ficheiros cometidos novos: 0 (ver o verificador).
- **O `relato.txt` da caixa não se comete.** É a vista do Mestre e traz os 2 nomes verdadeiros inteiros, tal como o
  relato já cometido em `provas/ordem-caixa/cliente/`. Ficou na pasta tmp, junto com as 5 capturas. No registo ficam o
  sha256, o resumo e o diff contra o relato cometido, e as linhas desse diff não têm nomes.

## B2 (JD3) — o autojogo como os servidores de bancada

**Feito.**

- `rascunhos/servidor/autojogo/servidor-autojogo.mjs` passa a validar o `--pin=` **antes** do `lerCenario` e sai com
  **2** (`:117`). Antes lançava um erro depois de ler o cenário e saía com 1.
- **O verificador novo:** `provas/ordem-caixa-relato/ferramentas/verificar-pin-b7-correcoes-7.sh`.
  - O da -6 fica como estava, porque é o registo da -6.
  - Exige o código **2** do autojogo em três casos:
    - sem `--pin`;
    - com um `--pin` que não é só de dígitos;
    - sem `--pin` e com um `--cenario` que não existe. Este caso prova a ordem das validações: antes da correcção dava
      1, com `ENOENT`.
  - Os 3 casos dão 2.
- **Sha256 e cadeias de dígitos:** o verificador tira os sha256 (64 caracteres hexadecimais) antes de contar as cadeias de 20+ dígitos. Na
  primeira versão, as listas novas da retoma davam 4 cadeias, que estão dentro de 2 sha e não são PINs. O log foi
  regenerado na ponta `30c4c76`, já com esta correcção, e vai neste commit.
- **Arranque vivo do autojogo:** `pronto: true`, a linha `pronto-autojogo` está presente, 0 `"pin"` e 0 PINs.

## B3 (JD4) — o PIN do autojogo sem enviesamento

**Feito.**

- Em `rascunhos/cliente/autojogo/autojogo.gd:212–218`:
  - o `_pin = ""` repõe-se antes da geração;
  - os bytes vêm em blocos de 32 do `Crypto`;
  - os bytes **≥ 250 rejeitam-se** antes do `% 10`;
  - o ciclo pára aos 20 dígitos.
- Como 250 = 25 × 10, cada dígito sai com probabilidade exacta de 1/10. Um byte rejeita-se com probabilidade 6/256,
  por isso o ciclo quase nunca precisa de um segundo bloco.
- O verificador confirma três coisas: o `_pin = ""` vem antes do `generate_random_bytes`, há 1 rejeição `< 250` e há
  0 `% 10` sem rejeição.
- **Partida viva:** semente 1, motor real, rc=0, vitória em 14 turnos. As 109 linhas são iguais, linha a linha, às de
  `provas/ordem-autojogo/s1.jsonl`, menos a linha `inicio`, onde só muda o `cenarioSha256`, como na -6.

## B4 (JD5) — as mutações

**Corridas e cometidas:** `b7-correcoes-7/mutacoes.log`.

- O `correr-mutacoes.sh` correu tal como a -6 o deixou (PIN fresco e `--pin=`), sem precisar de mudanças, nos modos
  `base4` e `novo`.
- **36 mutações:** em cada modo, 7 do teste, 7 do HUD e 4 do MANEQUIM.
- **Comparação com `correcoes-4/mutacoes.log`, bloco a bloco:** em todos os blocos, o rc, os resumos «N de M» e as
  linhas FALHA são iguais. Só mudam as horas na `B5-bias-zero`, porque essa mutação regista a hora da corrida.
- **Conferidor:** 0 achados, tanto no critério alargado como no `--velho`.
- **No fim**, os ficheiros das provas voltaram limpos: o `git status` só mostrava as correcções.
- **Nota sobre o modo `base4`:** usa, durante a corrida, os `.gd` de `da6683e`, que ainda têm o literal do PIN antigo
  (lêem o `--pin=` por cima). O literal só está na árvore enquanto a mutação corre, nunca se comete, e o verificador
  correu depois.
- **Um incidente meu, sem efeito:** a meio da corrida fiz um `git stash` / `stash pop` para medir o autojogo antigo.
  Isso tirou e repôs, em cerca de 1 s, os ficheiros que a mutação em curso tinha alterado. Comparei depois os 36
  blocos com a referência e são todos iguais, por isso não repeti nenhuma.

## B5 (JD6) — o registo corrigido

Fica registado, como manda a sentença, que a -6 teve **74 ficheiros** e **6 commits**, incluindo o `126765f`. Não
emendei o ESTADO-FINAL da -6, porque a emenda é opcional.

## B6 (opcional; O1/O2)

- **O1:** fica confirmado como desenho aceite **um PIN por invocação do lançador**. Dentro de uma invocação, o servidor
  e as provas partilham-no, e entre invocações nunca se repete. O autojogo gera um por partida. Não passei a um PIN por
  prova ou por mutação: o servidor só ouve em 127.0.0.1 e morre no fim, e o ganho não justifica a mudança.
- **O2:** o relato da janela desta corrida está cometido em `b7-correcoes-7/cliente-janela/relato.txt` (41/41, 82
  linhas). É igual, linha a linha, ao de `provas/ordem-caixa-janela/cobertura-correcoes-6/cliente/relato.txt` e não tem
  nomes verdadeiros inteiros.

## As corridas

PC Windows 11 com Git Bash, Godot 4.7.2 `win64_console`, motor VLAB real `a91c021c…3261`, semente 7, cenário
`7037229e…`, fichas `3c498137…`. O registo está em `b7-correcoes-7/corridas.log`.

| Corrida | Resultado | Registo |
|---|---|---|
| Teste do relato | **31/31**, rc 0 | `b7-correcoes-7/teste-relato.log` |
| HUD-JOGADORA, pelo lançador da relato | **43/43**, rc 0, 68 linhas | `b7-correcoes-7/cliente-hud/relato.txt` |
| MANEQUIM, pelo lançador da relato | **53/53**, rc 0, 78 linhas | `b7-correcoes-7/cliente-manequim/relato.txt` |
| JANELA, pelo lançador dela | **41/41**, rc 0, 81 linhas | `b7-correcoes-7/cliente-janela/relato.txt` |
| O 4.º lançador (caixa) | **23/23**, rc 0 | `b7-correcoes-7/lancador-caixa.log` |
| Autojogo, semente 1 | rc 0, vitória em 14 turnos, 109 linhas | `corridas.log` |
| Suite do servidor | **421/421** | — |
| `prova-servidor.mjs` | `PROVA OK` | — |
| Mutações `base4` + `novo` | 36, iguais à referência | `b7-correcoes-7/mutacoes.log` |
| Verificação do PIN (na ponta `30c4c76`) | 4 falhas, todas do achado fora do território | `b7-correcoes-7/verificacao-pin.log` |

- **Comparação com as corridas anteriores:** o teste, o HUD e o MANEQUIM são iguais aos de `b7-correcoes-6/`, tirando
  as horas.
- **Nomes verdadeiros inteiros** em todos os ficheiros cometidos por esta ordem: **0**.
- **O `actualizar-listas`** correu depois de `687bd92`:
  - deu `antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados)`;
  - mudaram 2 linhas em cada lista, as de `autojogo.gd` e `servidor-autojogo.mjs`;
  - os sha batem com os ficheiros;
  - corri-o de novo depois do rebase e antes do commit deste ficheiro, e não mudou nada.

## CI

Em `30c4c76`, a ponta com as correcções e as listas:

- **Sonda de privacidade** (run 45044185498): success.
- **Testes dos rascunhos** (run 45044185411): **10/10 jobs** — cliente, **retoma-pc**, servidor, provas-mapa, motor-real, protocolo, foto-mestre, godot-cliente, validador-glb e ponta-a-ponta.

## Pontos para o coordenador

1. **ACHADO NOVO, fora do território: o PIN antigo voltou à árvore da linha.**
   - **Onde:** `provas/ordem-caixa-janela/cobertura-correcoes-6/cliente/servidor-info.json` e `servidor.log` estão
     seguidos e têm 1 ocorrência do PIN antigo cada um. Foram cometidos pela CAIXA-JANELA-COBERTURA-CORRECOES-6
     (`e4072d0`), em paralelo com a B7-CORRECOES-6.
   - **Contagens por ponta:** na ponta do ramo da -6 (`5282c99`) dava **0**, e foi essa que a conferência contou. Na
     ponta da linha depois da fusão (`880f601`) e na base desta ordem (`bfe4c3c`) dá **2**.
   - **Porque não lhes mexi:** estão fora do território e o PIN antigo está morto, porque foi rodado na -5. É o mesmo
     agravante que a -6 já tinha apanhado na COBERTURA-CORRECOES-5.
   - **O que falta decidir:** se se apagam, numa ordem com esse território (são 2 `git rm`), e se o lançador da janela
     dessa época precisa de ser revisto.
   - **Por isso o verificador desta ordem sai com 1.** As 4 falhas são só este achado, e o log tem uma nota que o diz.
2. **B1 sem Linux:** a corrida foi feita no Windows, com o lançador tornado portátil, e não no Linux da ordem. O modo
   sem argumentos continua o de Linux, mas ficou sem corrida nesta ordem.
3. **O relato da caixa não está cometido** porque traz nomes verdadeiros inteiros (é a vista do Mestre). O que fica
   cometido é o registo da corrida, com o sha, o resumo e o diff.
4. **O incidente do `stash`** durante as mutações não teve efeito (B4).
5. **A linha final do ficheiro da ordem** (`Estado: NOVA`) é do ficheiro da ordem, que está na sede e fora do
   repositório. Não lhe mexi.
