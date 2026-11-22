# ESTADO-FINAL — Ordem CAIXA-RELATO-B7-CORRECOES-3

As correcções B1–B5 da sentença da conferência da CAIXA-RELATO-B7-CORRECOES-2. Só o teste do registo, um script de
mutações, o README e as corridas em `provas/ordem-caixa-relato/`: **nada do código do jogo mudou**
(`git diff a12b905 -- rascunhos/` vazio).

- **Executor:** conta 2, no PC.
- **Base:** `a12b905`, a ponta de `fable/integracao-50` à hora do lançamento. **A linha andou durante a ordem:** antes
  do push a ponta era `ed3ae11` (`518990d` + `ed3ae11`, a CAIXA-TESTES-CORRECOES-6, 07:53 UTC). Esses dois commits tocam
  `rascunhos/servidor/` e as listas da retoma; **nada** em `provas/ordem-caixa-relato/`. Não refiz a base.
- **Ramo:** `claude2/caixa-relato-b7-correcoes-3`, **sem fusão**.
- **Commits:**
  - `d2a3ccc`: as correcções, o teste, o script de mutações, o README e as corridas;
  - o commit deste ESTADO-FINAL, que só junta este ficheiro.
- **A conferência:** não está neste PC (`~/workspace/conferencias/caixa-relato-b7-correcoes-2/` não existe). Trabalhei
  pelo texto da ordem.

## 1. Ponto a ponto

### B1 — ordem futura R1: a retenção por listas permitidas

**Feito** (`provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd`).

- **Uma linha só se ecoa se cumprir as três condições:**
  - não tem nenhuma palavra de `PROIBIDAS`;
  - **as chaves JSON estão todas em `CHAVES_PERMITIDAS`:** `ligada`, `ordemPor`, `ordemDinamica`, `ordem`, `fechada`,
    `ultimo`;
  - **as palavras estão todas em `PALAVRAS_PERMITIDAS`**, ou são números ou ids hexadecimais de 17. A lista tem as
    palavras fixas de `linha()` e `_origem()`, os valores JSON da caixa (`true`, `false`, `null`, `dinamico`), os tipos
    de evento e os rótulos do teste.
- **O que está fora das listas conta-se, mas nunca se imprime**, porque num vazamento o achado seria o próprio valor.
  A linha retida diz só, por exemplo, `RETIDA (não se imprime; tem ["chave(s) fora da lista: 1", "palavra(s) fora da
  lista: 3"])`. O rótulo também só sai se for permitido; senão sai o número da linha.
- **As duas verificações de privacidade passam a usar estas listas**, sem `_ok` novo: a do §B6 e a do caso do
  `limpar()`.
- **A reprodução do R1, executada.** Mutação `"alcunha": "Canario-R1"` na caixa do snapshot do caso do `limpar()`:

  | | Resultado | `Canario-R1` no log |
  |---|---|---|
  | teste antigo (`a12b905`) | **31/31**, código 0 | **2 vezes** (linhas B7-1 e B7-4) |
  | teste novo | **30/31**, código 1 | **0 vezes**; B7-1 e B7-4 RETIDAS |

  (`b7-correcoes-3/mutacoes/r1-alcunha-teste-*.log`)
- **«Nenhum campo novo entra na caixa sem passar por esta conferência»** fica escrito nas listas: um campo novo só se
  ecoa se for acrescentado a `CHAVES_PERMITIDAS`, e essa mudança vê-se na conferência.

### B2 — a comparação sem acentos

**Feito.** A função `_normal` passa o texto a minúsculas, troca as letras acentuadas pela letra de base e tira as marcas
combinantes (U+0300–U+036F). Aplica-se dos dois lados: às linhas e às palavras de `PROIBIDAS`. As listas permitidas
comparam-se pelo mesmo texto normalizado.

| Mutação | Teste antigo | Teste novo |
|---|---|---|
| `"própria": {"figuraId": a}` | **31/31**, **2 ecos** | **30/31**, **0 ecos**; a `PROIBIDAS` acusa `propria` |
| `"pro◌́pria"` (acento à parte, U+0301) | **31/31**, **2 ecos** | **30/31**, **0 ecos**; a `PROIBIDAS` acusa `propria` |

`b7-correcoes-3/mutacoes/b2-propria-*.log`. Nos dois casos a linha retida mostra `"propria"` entre os achados. Isto
prova que a `PROIBIDAS` apanha a palavra sozinha, sem depender das listas permitidas, que também a apanham.

### B3 — `estado.gd:56` → `estado.gd:57`

**Corrigido** no comentário de `PROIBIDAS`. Conferido: `rascunhos/cliente/estado/estado.gd:57` é `var propria:
Dictionary = {}`.

### B4 — registo: a B7-2 e a B7-3 distinguem-se só pelo rótulo

**Mantido, sem âncora inventada.** O teste explica agora, junto da verificação, porque é que uma troca ou duplicação
dos dois passos do meio passa: os dois passos dão o mesmo corpo de linha. Este limite foi executado. Mutação «o passo 3
sem o evento à espera», em que o passo 3 fica igual ao 2:

- teste novo e teste antigo: **31/31**, código 0.

`b7-correcoes-3/mutacoes/b4-passo-3-igual-ao-2-teste-*.log`. É o limite inerente aos dados, como diz a sentença.

### B5 — o total afirmado

**Afirmado no próprio teste**, dentro do território: `const TOTAL_ESPERADO := 31`. Se o total for diferente, o teste
imprime `FALHA o total: N verificações, esperadas 31` e sai com **código 1**. O CI usa `set -o pipefail`, por isso o
passo falha.

- **O total é 31, não 30.** A sentença diz «30 de 30», mas a base `a12b905` já dá **31 de 31**: corri o teste da base
  sem mudanças. Na `fable/integracao-50`, as 30 verificações da B7-CORRECOES-2 juntaram-se à verificação do fuso
  injectado da CORRECOES-3 (B6). As listas de verificações da B7-CORRECOES-2 e da base diferem só nessa linha.
- **Mutação «sem uma verificação»** (a «sem caixa no snapshot»):

  | | Resultado |
  |---|---|
  | teste antigo | **30 de 30**, código 0: passava calado |
  | teste novo | **30 de 30**, com `FALHA o total: 30 verificações, esperadas 31`, **código 1** |

- **A sugestão ao coordenador (no workflow, fora do meu território)** está no ponto 2 da secção 4.

## 2. Corridas

Neste PC, sobre `d2a3ccc`, com o Godot 4.7.2 (`Godot_v4.7.2-stable_win64_console.exe`), o Node 26.13.0 e o motor VLAB
real sha256 `a91c021c…3261`, semente 7. Os registos estão em `provas/ordem-caixa-relato/b7-correcoes-3/`.

| Corrida | Resultado | Registo |
|---|---|---|
| Teste do relato (`teste_relato_caixa.gd`) | **31/31**, código 0 | `teste-relato.log` |
| Prova viva HUD-JOGADORA (`prova_caixa_jogadora.gd`) | **43/43** | `cliente-hud/relato.txt` |
| Prova viva MANEQUIM (`prova_caixa_manequim.gd`) | **53/53** | `cliente-manequim/relato.txt` |
| Suite do servidor (`node --test`) | **419/419**, 0 falhas, 0 saltados | `suites/servidor.log` |
| Prova da caixa do servidor (`prova-servidor.mjs`) | **PROVA OK** | `suites/prova-servidor.log` |
| Mutações (12 corridas: 6 × teste novo/antigo) | ver abaixo | `mutacoes/mutacoes.log` |

As mutações:

| Mutação | Teste novo | Teste antigo |
|---|---|---|
| nenhuma (controlo) | 31/31, código 0 | 31/31, código 0 |
| B1 `"alcunha": "Canario-R1"` | **30/31, código 1, 0 ecos** | 31/31, código 0, 2 ecos |
| B2 `"própria"` | **30/31, código 1, 0 ecos** | 31/31, código 0, 2 ecos |
| B2 `"pro◌́pria"` | **30/31, código 1, 0 ecos** | 31/31, código 0, 2 ecos |
| B5 sem uma verificação | **30 de 30 + FALHA do total, código 1** | 30 de 30, código 0 |
| B4 passo 3 = passo 2 | 31/31, código 0 (limite registado) | 31/31, código 0 |

- **No `mutacoes.log`, `FALHA=2` quer dizer uma falha.** O `_ok` escreve cada FALHA no stdout e no stderr, e o script
  junta os dois.
- **Como se repetem as mutações:** `bash provas/ordem-caixa-relato/ferramentas/correr-mutacoes-b7-correcoes-3.sh
  <godot.exe> <pasta-saída> [<base>]`. O script faz cada mutação numa cópia em `ferramentas/` e apaga-a no fim
  (`trap`). O teste cometido não muda. Depois da corrida, o `git status` só mostrava os ficheiros desta ordem.
- **O lançador das provas vivas** recebeu a pasta de saída em caminho absoluto. As capturas ficaram na pasta tmp da sede
  e nada caiu em `rascunhos/`.
- **`actualizar-listas`:** corri-o antes do commit. Deu `antes.txt` 37, `depois.txt` 415, MANIFESTO 459, **0 novos, 0
  tirados**, e nenhum ficheiro mudou. Nada em `rascunhos/` mudou, por isso não há listas a cometer. O CI confirma:
  retoma-pc verde, com «FEITO: 415 ficheiros no PC iguais ao ramo».

## 3. CI

**Verde em `d2a3ccc`:**

- **Testes dos rascunhos** (run 45000971022): **10/10 jobs**. São eles validador-glb, motor-real, protocolo,
  provas-mapa, cliente, foto-mestre, **retoma-pc**, godot-cliente, servidor e ponta-a-ponta.
- **Sonda de privacidade** (run 45000971061): success.
- **No registo do CI:**
  - teste do relato: `teste do relato da caixa: 31 de 31 verificações passaram.`, sem `FALHA o total`;
  - servidor: 419 testes, 419 passaram;
  - prova da caixa do servidor: PROVA OK;
  - retoma-pc: `FEITO: 415 ficheiros no PC iguais ao ramo (SHA conferido).`

## 4. Pontos para o coordenador

1. **O total é 31, não 30 (B5).** A sentença fala em «30 de 30», mas na base o teste já tem 31 verificações: as 30 da
   B7-CORRECOES-2 e a do fuso injectado da CORRECOES-3 (B6), juntas na integração. Por isso `TOTAL_ESPERADO = 31`.
2. **A sugestão B5 para o workflow** (`.github/workflows/testes.yml`, passo «Relato da caixa»; está fora do meu
   território, por isso não lhe mexi). O teste já falha sozinho com o total errado, mas o CI pode afirmá-lo também,
   para não depender do teste:
   `grep -qx "teste do relato da caixa: 31 de 31 verificações passaram." "$RUNNER_TEMP/teste_relato_caixa.gd.log"`.
   O número tem de ser actualizado ao mesmo tempo que o `TOTAL_ESPERADO`.
3. **B1: as listas permitidas valem para as linhas deste teste**, que são sintéticas. O canário das provas vivas não
   mudou (está fora desta ordem e é outro mecanismo); lá continua a valer o atenuante `keys().size() == 3`.
4. **B1: a regra dos ids é «hexadecimal de 17»**, como os ids do teste. Um valor que fosse por acaso 17 caracteres
   hexadecimais passaria como id. Não há nome assim nos valores em causa, mas fica registado.
5. **B4 continua um limite**, agora executado: a duplicação dos passos do meio passa 31/31 nos dois testes.
6. **A linha andou durante a ordem** (`a12b905` → `ed3ae11`, a CAIXA-TESTES-CORRECOES-6). Não há sobreposição de
   ficheiros com este ramo, e este ramo não muda as listas da retoma.
7. **Os valores nos logs de mutação são os canários de bancada, fictícios:** `Canario-R1` e as chaves `alcunha` e
   `própria`. Aparecem só nos logs do teste ANTIGO, 2 vezes cada, como prova do defeito. Nos logs do teste novo
   aparecem 0 vezes.
8. **A fronteira:** só mudou `provas/ordem-caixa-relato/` (o teste, o script novo de mutações, o README e
   `b7-correcoes-3/`), mais este ESTADO-FINAL. Não mexi em `rascunhos/`, no HUD, nas cores nem no workflow.
9. **Não mexi no `ORDEM.md` da sede**, como nas ordens anteriores; a marca de estado é do coordenador.
