# ESTADO-FINAL — Ordem CAIXA-RELATO-B7-CORRECOES

As correcções B1–B4 da sentença da conferência da CAIXA-RELATO-B7. Só registo e teste: **nada do código do jogo
mudou** (`git diff 15eab43 -- rascunhos/` vazio).

- **Executor:** conta 2, no PC do cunhado.
- **Base:** `15eab43`, a ponta de `fable/integracao-50` à hora do lançamento. ~~A linha não avançou durante a
  ordem.~~ **[B7-CORRECOES-2 B3] Falso:** a linha andou `15eab43` → `f049089` dentro da janela da ordem — os três
  commits da CAIXA-TESTES-CORRECOES-3 (`8870275`, `ae62dd9`, `f049089`) entraram em `fable/integracao-50` às
  00:45:29–00:45:30 (−03:00; data de commit 03:45:29–30 UTC), entre o commit das correcções (00:44:25) e o deste
  ESTADO-FINAL (00:48:00). Esta ordem trabalhou e correu tudo sobre `15eab43` e não o viu; o ramo foi depois
  reposto sobre `f049089` na integração (`5ac2253` → `d7ea743`, `b4b51c2` → `f747427`; `git range-diff` dá os dois patches iguais). Os números deste
  ESTADO-FINAL são os da `15eab43` + `5ac2253`.
- **Ramo:** `claude2/caixa-relato-b7-correcoes`, **sem fusão**.
- **Commits:**
  - `5ac2253`: as correcções, o teste e as corridas;
  - o commit deste ESTADO-FINAL, que só acrescenta este ficheiro.
- **A conferência:** não estava neste PC (`~/workspace/conferencias/caixa-relato-b7/` não existe aqui). Trabalhei
  pelo texto da ordem, que traz os pontos e as linhas.

## 1. Ponto a ponto

### B1 — o §4.3 do ESTADO-FINAL da B7 dizia que as provas vivas «não chamam `limpar()`»

**Reescrito** (`ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7.md`, §4 ponto 3, com a marca «[B7-CORRECOES B1]»).

- **A premissa falsa riscada; o caminho verdadeiro escrito.** As provas chamam o `limpar()` indirectamente em cada
  entrada e em cada saída:
  - `_entrar_jogadora` → `Rede.entrar` → `_comecar_entrada` → `est.limpar()` (`rede.gd:362`);
  - `_sair_jogadora` → `Rede.sair` → `est.limpar()` (`rede.gd:152`).
  - **As linhas da ordem são as da base da B7** (`0418d18`): `prova_caixa_jogadora.gd:254/:270`,
    `prova_caixa_manequim.gd:342/:358`. Na `15eab43` estão 10 linhas abaixo (`:264/:280`, `:352/:368`). Conferi as
    duas e registei as duas.
- **A premissa verdadeira:** nenhum leitor observa a lista na janela `limpar()` → snapshot novo. Provas, por
  leitura de código:
  - As provas só lêem `eventos_desde_snapshot` no `_privacidade` (`prova_caixa_jogadora.gd:325`,
    `prova_caixa_manequim.gd:413`). Esse passo corre depois de `_entrar_jogadora` esperar por `_estado.tem_snapshot`
    (`:265` / `:353`), e esse snapshot já esvaziou a lista (`estado.gd:159`).
  - A arena (com o HUD) é libertada antes do `sair()` (`:277`) e só é instanciada depois desse snapshot (`:269`).
- **A decisão de não re-correr as provas vivas mantém-se** (é da B7 e fica escrita como tal). Esta ordem correu-as na
  mesma, porque a sua secção «Prova» o pede: **43/43** e **53/53** (§2).
- **A cobertura real do `limpar()` alterado ficou registada, com um acerto ao texto da ordem.**
  - **No CI:** `pecas_mestre` **286/286** chama `_estado.limpar()` (`pecas_mestre.gd:174`, no passo «Ecrã do Mestre»
    do job cliente), e o teste do relato cobre o caso B7 com o Estado real.
  - **`caixa_janela` 69/69 não é cobertura de CI:** não é um passo do `testes.yml` e não chama o `limpar()`. Cobre a
    lista em si (`caixa_janela.gd:118/:130`). Corri-a à mão: **69/69** (`b7-correcoes/suites/caixa_janela.log`).
    Ficou escrito assim no §4.3, e não como «a suite do CI».

### B2 — a varredura de privacidade B6 não cobria o caso novo

**Estendida** (`provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd`).

- **Lista partilhada.** As proibidas passaram a `const PROIBIDAS`, e há um `_proibidas_em(linhas)` usado pelas duas
  varreduras. A lista é a mesma de antes, sem mudanças.
- **As 4 linhas do caso.** Em cada passo, o `_caso_limpar` gera a linha do relato como as provas a escrevem: a caixa
  do Estado, a origem do snapshot e a caixa actual. A caixa actual é o modelo do HUD, carregado da caixa do Estado e
  adiantado pelos eventos desde o snapshot.
  - Os passos são: antes do `limpar()`, `limpar()` sem snapshot, evento à espera, snapshot novo.
  - Duas verificações `_ok` novas: a varredura cobre as 4 linhas, e nenhuma tem palavras proibidas.
- **Teste: 28 → 30.**
- **A varredura nova pega o que deve.** Duas mutações, as duas só locais e não cometidas:
  - **Sem a correcção B7** (tirada a linha `eventos_desde_snapshot = []` do `limpar()`; o `estado.gd` foi reposto
    com `git checkout`): **27/30**. São as mesmas 3 falhas da B7, e a extensão não as tapa
    (`b7-correcoes/mutacao-1-sem-B7.log`).
  - **Canário na caixa do snapshot do caso** (`"nome": "Canario-Bancada"`, numa cópia do teste, depois apagada):
    **29/30**. A varredura nova acusa `["nome", "nome"]`, nas linhas B7-1 e B7-4 (`b7-correcoes/mutacao-2-canario.log`).

### B3 — precisão de linguagem

- **«o snapshot DESTE CASO»:**
  - no teste: o comentário do `_caso_limpar` (o texto «o snapshot não traz `propria` nem nomes» estava na `:194`, não
    na `:169` que a ordem cita; a `:169` era a lista das proibidas) e o cabeçalho;
  - no ESTADO-FINAL da B7, §2: «é uma afirmação sobre a bancada do teste, não sobre o protocolo».
- **A razão 2 da escolha foi retirada** (riscada, com a explicação). O HUD só repete a lista com `Estado.tem_snapshot`
  (`hud.gd:175-180`). O `limpar()` põe `tem_snapshot = false`, e o snapshot novo esvazia a lista antes do sinal
  (`estado.gd:159`). A razão era impossível. O cabeçalho da secção passou de «quatro razões» para «ficam três».
- **«o único campo observável»** (razão 1). O `_tempo_resync` também sobrevive ao `limpar()`, mas fica inerte:
  - o `_process` só o lê com `_resync_pendente`, que o `limpar()` põe a `false` (`estado.gd:93-99`);
  - volta a `0.0` quando um resync novo começa (`:382-383`).
  - **Não lhe toquei.**

### B4 — o fecho do caminho do HUD

**Anotado** (ESTADO-FINAL da B7, §4 ponto 2): o fecho é **por leitura de código, não por teste**. Não há teste
próprio para o caminho do HUD, porque seria um teste de HUD e fica fora da fronteira. O teste prova só que a lista do
Estado fica vazia; que o HUD não a repete na janela lê-se em `hud.gd:175-180`. Nenhuma corrida o mostrou.

## 2. Corridas

Neste PC, sobre `5ac2253` (a `15eab43` + o teste alterado), com o Godot 4.7.2 (`Godot_v4.7.2-stable_win64_console.exe`),
o Node 26.13.0 e o motor VLAB real sha256 `a91c021c…3261`, semente 7.

| Corrida | Resultado | Registo |
|---|---|---|
| Teste do relato (`teste_relato_caixa.gd`) | **30/30** (eram 28) | `provas/ordem-caixa-relato/b7-correcoes/teste-relato.log` |
| Prova viva HUD-JOGADORA (`prova_caixa_jogadora.gd`) | **43/43** | `b7-correcoes/cliente-hud/relato.txt` |
| Prova viva MANEQUIM (`prova_caixa_manequim.gd`) | **53/53** | `b7-correcoes/cliente-manequim/relato.txt` |
| `caixa_janela` | 69/69 | `b7-correcoes/suites/caixa_janela.log` |
| `caixa_jogadora` | 18/18 | `b7-correcoes/suites/caixa_jogadora.log` |
| Mutação «sem a B7» | 27/30 (falha como deve) | `b7-correcoes/mutacao-1-sem-B7.log` |
| Mutação «canário no caso» | 29/30 (falha como deve) | `b7-correcoes/mutacao-2-canario.log` |

- As duas provas vivas acabam com a varredura do relato inteiro sem nomes verdadeiros (65 e 75 linhas).
- As capturas das provas não entram no ramo: ficaram na pasta tmp da sede.
- **`actualizar-listas`:** corri-o depois do `5ac2253`: `antes.txt` 37, `depois.txt` 415, MANIFESTO 459, **0 novos,
  0 tirados**. As listas não mudaram, porque nada em `rascunhos/` mudou, e por isso não houve commit de listas.

## 3. CI

**Verde em `5ac2253`** (runs 44982015685 e 44982015650):

- **Sonda de privacidade:** success.
- **Testes dos rascunhos:** **10/10 jobs** — ponta-a-ponta, motor-real, servidor, protocolo, **retoma-pc**,
  godot-cliente, foto-mestre, validador-glb, cliente e provas-mapa.
- **No registo do CI:** o teste do relato deu `teste do relato da caixa: 30 de 30 verificações passaram.`, com as duas
  verificações B7-CORRECOES, e o `pecas_mestre` deu `286 de 286`.

## 4. Pontos para o coordenador

1. **Os números do teste do relato na B7 são os da base dela, não os da linha.** A B7 correu sobre `0418d18`, sem a
   CORRECOES-2, e deu 21 + 5 = **26** (o CI dela mostra «26 de 26» e «varre as 4 linhas»). Depois do rebase sobre a
   CORRECOES-2, que tinha 23, a linha integrada tem **28** (CI da `15eab43`: «28 de 28»). Pela mesma razão, o «antes
   da correcção 23/26» do §2 da B7 é **25/28** na linha. Anotei o 28 na tabela da §3 da B7; o §2 dela não o reescrevi.
2. **«`caixa_janela` 69/69» não é cobertura de CI do `limpar()`** (ver B1). Registei-o com a cobertura verdadeira:
   `pecas_mestre` no CI, `caixa_janela` à mão e só sobre a lista.
3. **As linhas das provas citadas pela ordem** (`:254/:270`, `:342/:358`) são as da `0418d18`; na `15eab43` estão
   +10. Registei as duas.
4. **O lançador das provas grava fora do sítio se o 4.º argumento for relativo.** O `--saida` é resolvido pelo Godot
   a partir de `rascunhos/cliente/`, e foi o que aconteceu nesta corrida. Movi os `relato.txt` para `b7-correcoes/` e
   as capturas para a pasta tmp, antes do commit. Nada ficou em `rascunhos/` (o `git status` estava limpo). Ficou
   escrito no README das provas; o lançador não mudou.
5. **O1 (o `limpar()` repõe `fase = ""` sem emitir `fase_mudou`) não foi tocado**, como a ordem manda. O
   `_tempo_resync` também não.
6. **A fronteira:** os ficheiros mudados foram o teste e o README de `provas/ordem-caixa-relato/`, as corridas novas
   em `provas/ordem-caixa-relato/b7-correcoes/` e o ESTADO-FINAL da B7 (é registo, e é o que o B1/B3/B4 corrigem).
   Nada de `rascunhos/`, HUD ou cores. Nas provas não há vida, alma, PA nem dados do Mestre; o nome do canário da
   mutação é de bancada e só aparece no registo dessa mutação.
7. **Não mexi no `ORDEM.md` da sede**, como nas ordens anteriores.
