# ESTADO FINAL — ORDEM-PLANO-2-F1-ADENDA-J-F7-J-F8 (fecho do J-F7 e do J-F8)

Linha `fable/integracao-50`, sem fusão. Corrida em 26/11/2026, 21:12–21:19 -03, e retomada a 27/11/2026, 00:14 -03, no
PC. Origem: a conferência ORDEM-PLANO-2-F1-ADENDA-J-F1-J-F6, **APROVADA COM RESSALVAS — 936/1000**. A sentença não está
neste PC (`~/workspace/…` não existe aqui), por isso segui os textos citados na ordem.

**Resumo:** o J-F7 e o J-F8 estão feitos e no remoto, um commit por ponto, mais a sincronização das listas.

- Na ponta `a8f5863`, o Testes (16 jobs), a Sonda de privacidade e o Aparelhos (F2) estão todos verdes.
- O Aparelhos precisou de uma 2.ª tentativa só do job `qr`, por uma falha de infraestrutura (secção 4).
- A primeira corrida parou às 21:19 no limite de 5 h da conta, depois do push do J-F8 e antes deste ESTADO-FINAL. A
  retoma só fez o que faltava: voltou a medir o J-F8 sobre a árvore cometida, tratou o CI e escreveu este ficheiro.

## 0. Base

- **Ponta ao arrancar:** `143c819`, o ESTADO-FINAL da ORDEM-PLANO-2-F1-F7-F8. É o pai do `f841ff5`.
- **Na retoma:** `git fetch` + `git ls-remote origin fable/integracao-50` deram `a8f5863`, igual ao HEAD local, com a
  árvore limpa. Ninguém meteu nada na linha entretanto.

## 1. J-F7 — o `conferir` já não passa `msg` indefinida ao `deepEqual` (`f841ff5`)

- **A mudança:** em `rascunhos/servidor/testes/d-aud-12-snapshot-novo.test.mjs`, l. 23, a chamada
  `assert.deepEqual(porCasa(snap), ESPERADO, msg)` passa a `… msg ?? 'snapshot')`.
- **ANTES**, com a mutação da adenda reposta por `git checkout`: **0 de 7** (`ℹ fail 7`), com **7 AssertionError e
  0 TypeError**. Os 3 testes sem mensagem (entrada-tardia, sala-reaberta-heroina, sala-reaberta-fim-da-espera) falham
  agora com `AssertionError` e o diff. Log: `provas/ordem-plano-2-f1-adenda/j-f/j-f7-conferir-msg/regressao-snapshot-ANTES.log`.
- **DEPOIS:** **7 de 7**, com **12 linhas `PROVA`** (`regressao-snapshot-DEPOIS.log`).
- **Servidor:** `testes/*.test.mjs` passa **459 de 459** (`servidor.log`, Node 26.13.0). O número mudou em relação aos
  453 do J-F5 porque há mais 6 testes: são os do `e2e-canarios.test.mjs`, da F8 da ORDEM-PLANO-2-F1-F7-F8, e não
  deste ponto.
- **Listas da retoma:** o `8fd4cda` correu o `actualizar-listas.py` depois do `f841ff5`. Não entrou nem saiu nenhum
  ficheiro; só mudou o SHA do teste (`9c2d44e7…` → `c7084e7d…`), em `depois.txt` e no MANIFESTO. O `retoma-pc` está verde.
  O J-F8 só toca em `provas/`, por isso não pede outra sincronização, porque o guião só cobre `rascunhos/`.

## 2. J-F8 — o `falhas()` já não devolve 0 em silêncio (`a8f5863`)

- **A mudança** é igual nos dois guiões: `provas/ordem-plano-2-f1-adenda/suites.sh` e `provas/ordem-plano-2-f1/suites.sh`.
  O da F1 ainda está em uso, por isso também foi corrigido.
  - Quando o log tem `ℹ fail N`, é esse número que conta, como antes.
  - Quando não tem, o `falhas()` soma três coisas: as linhas `  FALHA ` (Godot), as `not ok` (TAP) e as linhas `✖ `
    **só antes** do cabeçalho `✖ failing tests:`.
  - Se o log não tiver marca de falha nem de resumo (`ℹ pass N`, `verificações passaram`), o `falhas()` sai com 1. O
    `muta()` pára então com `PARAR: … não registo falhas=0`.
- **Log sintético** (`j-f/j-f8-falhas-sem-resumo/conferir-falhas.sh`/`.log`): corre o `muta()` de cada guião a sério,
  num repo git temporário. Os resultados são iguais nos dois guiões:

  | log sintético | `falhas()` antigo | agora |
  |---|---|---|
  | node, 7 falhados, sem `ℹ fail N` | 0 | **falhas=7** |
  | node morto na lista (sem nenhum `ℹ`) | 0 | **falhas=7** |
  | node completo (controlo) | 7 | 7 |
  | godot, 3 `FALHA` | 3 | 3 |
  | godot verde | 0 | 0 |
  | sem marcas | 0 | **PARAR**, exit 1, sem linha no resumo |

- **Corrida focada** (`SO_MUTACAO=1 bash provas/ordem-plano-2-f1-adenda/suites.sh`): dá
  `d-aud-12-snapshot-SEM-SUFIXO-NA-FIGURA-PUBLICA exit=1 falhas=7 fim=«ℹ pass 0 ℹ fail 7 » reposto=sim`.
- **A nova medição na retoma, sobre a árvore cometida:** o log cometido da corrida focada foi medido com os guiões ainda
  por cometer (o `resumo.txt` diz que a árvore testada não é a do commit). Por isso voltei a correr as duas provas no
  `a8f5863` limpo.
  - O `conferir-falhas.sh` deu as mesmas 12 linhas.
  - A corrida focada deu `árvore testada: af1e17b… (limpa: a árvore do commit)` e a mesma linha `falhas=7`, com
    `git status` limpo depois. Esta corrida foi só para confirmar e não ficou cometida, porque é igual à que está no
    commit.
- **O que não foi corrido:** o `provas/ordem-plano-2-f1/suites.sh` não correu por inteiro, porque pede `GODOT` e
  `MOTOR_MJS` e as suas três mutações. Só o `muta()`/`falhas()` dele passou pelo `conferir-falhas.sh`.
- **Uma limitação, dita no comentário do guião:** num `describe` com subtestes, o `✖` do pai também conta como falha. Os
  testes destas provas não têm subtestes.

## 3. Commits (push a cada passo)

| commit | o quê |
|---|---|
| `f841ff551030ed6ef59e839d733831a756e478dc` | J-F7: teste + logs ANTES/DEPOIS/servidor |
| `8fd4cda9051718ecbf4a9657629cedc0d657d527` | listas da retoma sincronizadas depois do `f841ff5` |
| `a8f5863ef8fed6db6d94000ee2041ad5db313e46` | J-F8: os dois `suites.sh` + log sintético + corrida focada |
| (este) | ESTADO-FINAL |

## 4. Nota do CI

| commit | Testes | Sonda | Aparelhos (F2) |
|---|---|---|---|
| `8fd4cda` | 45915795871 success | 45915795852 success | 45915795762 success |
| `a8f5863` | 45915982796 success, 16/16 jobs | 45915982863 success | 45915982758 success na 2.ª tentativa |

- **A 1.ª tentativa do Aparelhos no `a8f5863` falhou:** foi o job `qr`, no passo «A página /qr fotografada no Chromium»,
  com `Error: o navegador não abriu o DevTools`.
- **Porque não tem a ver com este ponto:** o `a8f5863` só mexe em `provas/`, e o mesmo job passou no `8fd4cda`, dois
  minutos antes.
- **O que fiz:** voltei a correr só o job falhado (`gh run rerun --failed`) e ele passou. Os outros 5 jobs (rede-3-bots,
  exportar, android, windows e web-chromium) passaram logo à 1.ª.
