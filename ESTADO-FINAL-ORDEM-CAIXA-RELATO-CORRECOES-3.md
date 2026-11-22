# ESTADO-FINAL — Ordem CAIXA-RELATO-CORRECOES-3 (as correcções B1–B7 da sentença da CAIXA-RELATO-CORRECOES-2)

**Quem:** Claude, conta 1, no PC (22/11/2026). **Ramo:** `claude1/caixa-relato-correcoes-3`, a partir de `6a87b9e`
(a ponta de `fable/integracao-50` à hora do lançamento). **Não fundi.**
**Sede:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-caixa-relato-correcoes-3\` (clone em `repo\`, pasta tmp em `tmp\`).

A conferência (`~/workspace/conferencias/caixa-relato-correcoes-2/`) não está neste PC. Trabalhei pelos resumos da
ordem, que trazem o ficheiro e a linha de cada defeito.

## 1. Ponto a ponto

### B1 (Privacidade D2) — a varredura «do relato inteiro» cobre o ficheiro todo — FEITO, PROVADO
- **Defeito:** em `_fim()`, a varredura corria antes das 3 últimas `_linha()`: a própria verificação, a linha em
  branco e o resumo. O relato dizia «65 linhas» e o ficheiro tinha 68; no manequim, 75 e 78.
- **Correcção** (`prova_caixa_jogadora.gd` e `prova_caixa_manequim.gd`, `_fim()`):
  - As 3 linhas finais compõem-se primeiro. A varredura corre sobre o relato mais essas 3, ou seja, sobre o que vai
    ficar no ficheiro.
  - A contagem diz esse tamanho: «o relato inteiro (68 linhas — todas as do ficheiro, contando esta e as 2 finais)».
  - Depois de **todas** as `_linha()`, `_fim()` varre outra vez o relato escrito. Se encontrar um nome, escreve uma
    linha FALHA e um resumo novo, e a prova sai com 1.
- **Prova:**
  - Relatos novos: **68 linhas** varridas e 68 no ficheiro (HUD); **78** e 78 (manequim). Conferido com `wc -l`.
  - Mutação com um canário na última linha, o resumo: HUD **42/43** e manequim **52/53**, rc=1. Na base, as mesmas
    mutações passavam 43/43 e 53/53, rc=0.
  - Mutação com um canário na linha em branco final, uma escrita que a varredura de antes não vê: a re-varredura
    apanha-o, «FALHA fim: a re-varredura do relato escrito (68 linhas) achou … na linha 67», **43/44**, rc=1. Na base
    passava 43/43.

### B2 (Privacidade D4) — o canário não distingue maiúsculas — FEITO, PROVADO
- **Correcção:** `to_lower()` dos dois lados em `_nomes_no_relato`. A comparação está agora num ajudante,
  `_nomes_em(linhas, nomes)`, que o `_fim()` também usa. O mesmo vale para a varredura dos textos da caixa
  (`_privacidade`).
- **Prova:**
  - Mutação com o nome verdadeiro em minúsculas no relato (o nome verdadeiro n.º 1 em minúsculas, via `_nome_publico`): HUD **39/43**,
    rc=1. Na base passava 43/43.
  - Mutação com o nome em minúsculas num texto da caixa: HUD **36/43**, rc=1. Falham as 3 verificações dos textos da
    caixa e, em cascata, as do relato, porque a linha FALHA cita o texto. Na base passava 43/43.

### B3 (Privacidade D6) — o cabeçalho do §1 usa o nome público — FEITO, PROVADO
- **Correcção:** no fim da montagem, `_jogadora["nomePublico"] = _nome(fim, figuraId)`, que passa por
  `_nome_publico` e lê da vista do Mestre que já lá estava. O cabeçalho «== 1. a jogadora (…) ==» usa esse valor e
  não `_jogadora["nome"]`. O `nome` do cenário continua a ser usado só no `_rede.entrar` (o login), que não vai para o
  relato.
- **Prova:** usei um cenário em que a heroína que entra tem `nome` ≠ `nomePublico`. Na `fichas-bancada.json`, a
  espadachim passou a ter `"nomePublico": "Espadachim"`, só durante a corrida; foi reposta no fim, e `rascunhos/` está
  limpo no `git status`.
  - Código novo: «== 1. a jogadora (Espadachim) entra pelo ecrã a sério ==», o canário com 3 nomes, **43/43** e
    **53/53**.
  - Base: **39/43** e **49/53**, porque o cabeçalho trazia «Espadachim de Bancada».
- O fallback de `nomePublicoDe` para jogadoras não mudou (é uma decisão registada).

### B4 (Privacidade D5) — só o comentário — FEITO
- No cabeçalho de `teste_relato_caixa.gd` fica escrito que a eficácia de `"master"`/`"caixaMestre"`/`"pa"` assenta
  nas mutações do executor, com um apontador para `correcoes-3/mutacoes.log`.
- Fica também escrito que o `"pa"` sozinho **nunca** migra para o canário vivo: ocorre 23× como substring no relato
  vivo. Contei-as em `correcoes-2/cliente-hud/relato.txt`, sem distinguir maiúsculas: 13× «Espadachim», 3×
  «aparelho», 3× «PA», e «aparece», «desapareceu», «passaram», «passou».
- O comportamento não mudou.

### B5 (Mecânica D1) — o «1,0 %» do §4.2 — CAMINHO (a), com uma correcção à premissa
- As capturas existiam na pasta tmp da sede anterior, com data das 23:02; o relato dessa corrida bate com o cometido.
  Cometi as **10 capturas da CORRECOES-2** em `provas/ordem-caixa-relato/correcoes-2/cliente-hud/` e
  `…/cliente-manequim/`; os SHA-256 batem um a um com os da pasta tmp.
- Cometi também a comparação `correcoes/` ↔ `correcoes-2/`, em
  `provas/ordem-caixa-relato/correcoes-3/comparacao-correcoes-vs-correcoes-2.log`.
- **Essa comparação não salva o 1,0 %.** No §4 da HUD dá **0,6 %**, e os intervalos são 0,4–32,1 % na HUD e
  0,6–23,8 % no manequim.
- O 1,0 % do §4.2 e da B5 do README é, como o próprio texto diz, a corrida **CAIXA-RELATO (21:02) ↔ `correcoes/`**.
  Para lhe dar prova, cometi também as **5 capturas da HUD da corrida CAIXA-RELATO**, ao lado do relato dela, em
  `provas/ordem-caixa-relato/cliente-hud/*.png`. Vieram da pasta tmp da sede CAIXA-RELATO; o relato dessa corrida bate
  com o cometido, salvo as linhas de carga da cena.
- A comparação `correcoes-3/comparacao-caixa-relato-vs-correcoes.log` dá **4-religada-avancou.png 1,0 %** (7519 de
  740160 píxeis).
- O «1,0 %» fica, nos dois sítios. Não apaguei nada.

### B6 (Mecânica D2) — o teste da hora deixa de ser cego no CI — FEITO pela opção (2), PROVADO
- **Correcção:**
  - `relato_caixa.gd`: `hora_ms(unix := -1.0, bias_min = null)`. Sem argumentos lê o relógio e o fuso do sistema,
    como antes, e as provas continuam assim.
  - O teste ganhou uma verificação com o instante e o fuso injectados: `1795000000.25`, com bias −180 →
    `08:06:40.250` e bias +330 → `16:36:40.250`. Os valores esperados estão escritos à mão; o instante é
    2026-11-18 11:06:40.250 UTC, conferido em Node.
- **Porquê a (2) e não a (1):**
  - A prova fica no próprio teste e morde em qualquer máquina, também no runner UTC. Não depende de o coordenador
    aplicar um remendo ao workflow.
  - Também não depende de o Godot em Linux respeitar a variável `TZ`, que eu não podia provar neste PC (é Windows,
    onde o Godot lê o fuso do sistema e não a `TZ`).
  - Não há remendo ao workflow para aplicar.
- **Prova:**
  - Mutação «`hora_ms()` sem o fuso» com o aparelho simulado em UTC: no teste, a hora «local do sistema» passa a ser
    a UTC, que é o caso do CI. A base dava **23/23** (cego); o novo dá **23/24**, com a verificação injectada a falhar.
  - A mutação só com o fuso a zero, no fuso deste PC (UTC−3): **22/24**.

### B7 (Mecânica D3) — as mutações com registo cometido — FEITO
- `provas/ordem-caixa-relato/correcoes-3/mutacoes.log` (182 linhas) tem duas partes, gerada cada uma por
  `ferramentas/correr-mutacoes.sh`; as mutações estão escritas em `ferramentas/mutacoes.mjs`. Cada substituição
  tem de aparecer exactamente uma vez no ficheiro, e cada ficheiro é reposto depois de cada corrida e no fim.
- **Modo base** (os ficheiros das provas de `6a87b9e`): as 6 mutações da ordem anterior dão exactamente
  **B1 39/43 · B2 22/23 · B3 (caixaMestre/master/PA 3) 22/23 ×3 · B5 22/23 · B6 21/23**.
- **Modo novo:**

| Mutação | Base | Novo |
|---|---|---|
| B1 nome verdadeiro | 39/43 | 39/43 |
| B2 fuga nas linhas da hora | 22/23 | 23/24 |
| B3 ×3 | 22/23 | 23/24 |
| B5 bias 0 | 22/23 | 22/24 |
| B6 `estado` de actor | 21/23 | 22/24 |
| N-B1 resumo (HUD / manequim) | 43/43 / 53/53 | 42/43 / 52/53 |
| N-B1 linha em branco | 43/43 | 43/44 |
| N-B2 minúsculas (relato / caixa) | 43/43 / 43/43 | 39/43 / 36/43 |
| N-B3 heroína com nome ≠ público (HUD / manequim) | 39/43 / 49/53 | 43/43 / 53/53 |
| N-B6 UTC e sem fuso | 23/23 | 23/24 |

  N-B3 é o único caso que deve passar no código novo, e passa.
- O nome do registo é `mutacoes.log` e não `mutações.log`: o repositório não tem nenhum nome de ficheiro fora do
  ASCII (conferi os 1319), e assim ficam iguais aos outros (`correcoes`, `comparacao-capturas`).

## 2. Corridas (PC, Godot 4.7.2 Windows `Godot_v4.7.2-stable_win64.exe`; motor VLAB real sha256 `a91c021c…3261`; semente 7) — VERIFICADO

| Corrida | Resultado | Registo |
|---|---|---|
| Teste do relato | **24/24** (eram 23; +1 do fuso injectado) | `correcoes-3/teste-relato.log` |
| Prova HUD-JOGADORA | **43/43** · 68 linhas varridas = 68 no ficheiro | `correcoes-3/cliente-hud/relato.txt` |
| Prova MANEQUIM | **53/53** · 78 = 78 | `correcoes-3/cliente-manequim/relato.txt` |
| Servidor (`node --test`) | 418/418 | `correcoes-3/suites/servidor.log` |
| Prova da caixa do servidor | PROVA OK | `correcoes-3/suites/prova-caixa-servidor.log` |
| `rodar_testes` | 290/290 | `correcoes-3/suites/rodar_testes.log` |
| caixa_jogadora / caixa_janela / hud_acoes / canario_privacidade | 18/18 · 69/69 · 50/50 · 10/10 | `correcoes-3/suites/` |
| abrir_scripts | 107 scripts, 0 falhas | `correcoes-3/suites/abrir_scripts.log` |
| Mutações | base 15 corridas, novo 15 corridas | `correcoes-3/mutacoes.log` |

Nenhum registo tem «SCRIPT ERROR», «Parse Error» nem «Compile Error».

**Listas da retoma:** corri o `python retoma-i0004/actualizar-listas.py` depois do commit. O ramo não toca em
`rascunhos/`, e as listas ficaram sem diferenças (ver §3).

## 3. CI

Commit `3c88709` (código, provas, capturas, registos e este ficheiro):
- **Testes dos rascunhos: success, 10/10 jobs** (run 44979383503): cliente, motor-real, provas-mapa, servidor,
  protocolo, godot-cliente, foto-mestre, **retoma-pc**, validador-glb e ponta-a-ponta.
- No log do job `cliente`, o passo «Relato da caixa», a correr no runner UTC, dá «a hora soma o fuso INJECTADO …
  08:06:40.250 … 16:36:40.250» e **24 de 24**. A verificação nova corre no CI.
- **Sonda de privacidade: success** (run 44979383448).
- O commit seguinte só muda este ficheiro (este §3).

## 4. Para o coordenador

1. **A premissa da B5 estava trocada.** A comparação `correcoes/` ↔ `correcoes-2/` não dá 1,0 % (no §4 da HUD dá
   0,6 %). O 1,0 % é da comparação CAIXA-RELATO (21:02) ↔ `correcoes/`, e eu salvei-o com as capturas dessa corrida
   (só as 5 da HUD).
   - Repare também que nessa mesma comparação o §1 difere 20,2 % e o §5 13,7 %. «No essencial iguais» vale para o
     §2–§4, não para as 5 capturas.
   - O peso das capturas novas no ramo é de ≈18 MB: 10 da CORRECOES-2 e 5 da CAIXA-RELATO.
2. **B6 pela opção (2):** não há remendo ao workflow para aplicar. O passo «Relato da caixa» do CI passa a correr a
   verificação com o fuso injectado.
3. **Território:**
   - Mexi em `provas/ordem-caixa-relato/` e nas duas ferramentas das provas vivas
     (`provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd` e
     `provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd`). É lá que estão `_fim`, `_nomes_no_relato` e
     o cabeçalho do §1 que a sentença aponta.
   - `rascunhos/` só foi mexido de forma temporária, pela mutação N-B3 na `fichas-bancada.json`, e reposto; não entra
     no commit.
   - Não mexi em HUD, cores, workflow nem na prova da CAIXA-JANELA (a B8 é ordem própria).
4. **Relatos antigos:** não os reescrevi. Juntei-lhes ficheiros ao lado (as capturas), sem mudar nenhum relato.
5. **O `ORDEM.md` da sede** não termina numa linha só com `<b>Estado: NOVA</b>`: a última linha é o ponto da lista
   que a contém. É o ficheiro do coordenador e não lhe mexi.
6. **Ambiente:** neste PC continua a não haver o `_console.exe` do Godot. O servidor correu sem `--permission`, como
   nas ordens anteriores.
