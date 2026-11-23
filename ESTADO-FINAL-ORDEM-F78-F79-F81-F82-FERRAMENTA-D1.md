# ESTADO-FINAL — Ordem F78+F79+F81+F82 da sentença da F64 (acabamentos da ferramenta de medição do D1)

**Coordenador:** CM-000009. **Executor:** Claude (opus, esforço médio), PC do cunhado. **Data:** 23/11/2026.
**Linha:** `fable/integracao-50`, trabalho directo, sem ramo e sem fusão.

**Partida.** Clonei a linha às 05:16 e o `HEAD` era `10e21f0` (`10e21f06efba6b80933dd641f743f3ecdf10ff33`, a nota do
CI da F64), igual à origem. As medições assentam em `10e21f0`. No `push` da obra, a linha não tinha andado.

**Commits:**
1. `b4e680f`: a obra (a ferramenta com os quatro acabamentos, os dois logs `-f78`, o `resumo-f78.txt`, o script que o
   escreve e o README da pasta);
2. este ESTADO-FINAL;
3. a nota do CI da ponta do commit 2, acrescentada ao §5 (só documento).

**Esta ordem só mexe na prova e não muda nenhum ficheiro do jogo.** Só mudou `provas/ordem-f28-custo-d1-hud/` e este
ficheiro. Não há nenhum nome verdadeiro inteiro nem valor de PIN neste ficheiro (§6).

## 0. Antes de começar
- **A sentença não está neste PC.** Não há `~/workspace`, por isso não existe
  `~/workspace/conferencias/f64-ferramenta-medicao-d1/SENTENCA-F64-FERRAMENTA-MEDICAO-D1.md`, como já acontecia nas
  ordens anteriores. Trabalhei com os quatro acabamentos tal como a ordem os cita e com as decisões F77/F78/F80/F83 que
  o coordenador lavrou no ESTADO-FINAL da F64 (`99a83a3`). Ver o ponto 1 do §7.
- **A F78 tinha ficado decidida para «a próxima ordem que mexer na ferramenta».** É esta, e fi-la.
- **Biblioteca (GameDev Kit):** voltei a ver o estudo (`analise-biblioteca/ESTUDO-BIBLIOTECA.md`). Não há nada que meça
  gestos nem registe o estado de um HUD, como a F64 já tinha visto. Esta ordem só corrige a ferramenta que existe. O
  único ficheiro novo é o `resumo_f78.sh`, no padrão do `resumo_f64.sh`.

## 1. Os acabamentos e as linhas novas
Ferramenta: `provas/ordem-f28-custo-d1-hud/ferramentas/medir_custo_d1_hud.gd`.

### F78 — o cursor reposto no `_repor`
- **A linha nova**, no `_repor`, antes de `arena.definir_modo(NENHUM)`:
  `arena._cursor = Vector2i(-1, -1)  # F78: o cursor de quando a arena nasce (arena.gd), para a partida ser neutra`
- O (−1, −1) é o valor com que a arena declara o cursor (`arena.gd:94`). É também o que a 1.ª `PARTIDA` da F64
  registava, antes de qualquer caso mexer no cursor.
- **Partida neutra em todos os casos.** As linhas `PARTIDA` dão 84 × (−1, −1) e 16 × (10, 10), nas duas medições.
  - Os 16 são os casos cuja preparação abre o Mover: os três botões da gaveta do Mover e a casa, com a lista aberta e
    de controlo, nos dois ecrãs (4 × 2 × 2).
  - Ao abrir o Mover, a arena põe o cursor na casa dela (`arena.gd:353`). Como a `PARTIDA` é pós-preparação (F80), é
    lá que ele está.
  - O (6, 11) que sobrava de um caso para o seguinte desapareceu: 0 de 100.

### F79 — «do Mover»
- **A linha nova**, no `_estado_agora`:
  `var de := "de nenhum modo" if hud._gaveta_de == M.NENHUM else "do " + str(M.find_key(hud._gaveta_de)).capitalize()`
  e depois `gaveta = "à vista, %s" % de`.
- Os modos possíveis (Mover, Ataque, Consumível) são todos masculinos, e todos levam «do».
- Corri as duas medições outra vez com a ferramenta corrigida. Os logs dão «de o Mover» 0 vezes; na F64 eram 44 na
  ponta e 52 sem o D1. «À vista, do Mover» sai 54 vezes na ponta e 64 sem o D1.

### F81 — a forma da ferramenta
- **Rumo e inclinação na pinça a deslocar.** `_pinca_a_deslocar` guarda `rumo0` e `incl0` antes do gesto. A
  `MEDIDA PINÇA A DESLOCAR` passa a dizer «…, rumo 0.0 → 0.0, inclinação 55.0 → 55.0 · …», como a `MEDIDA PINÇA`.
- **A ordem é a mesma em todos os caminhos: `PARTIDA`, as `DEPOIS` e só então a `MEDIDA`.**
  - Na F64, os botões, o rato, a jogada e a casa já escreviam DEPOIS antes da MEDIDA. O arrastar, as duas pinças e a roda
    escreviam ao contrário.
  - Escolhi a ordem dos botões porque é a única possível para eles: a MEDIDA de um botão junta a lista aberta e o
    controlo, e só pode sair no fim dos dois (ponto 3 do §7).
  - Nos quatro caminhos que mudaram, a linha `_depois(…)` passou para antes do `print` da MEDIDA. As duas só lêem o
    estado, por isso nenhum número muda.
  - Contagem: «uma MEDIDA seguida logo de uma DEPOIS» dá 0 nos logs novos. Nos da F64 dava 18.
- **Os logs passam a LF.** O Godot escreve CRLF no Windows; a saída passa agora por `tr -d '\r'` e o rc tira-se de
  `${PIPESTATUS[0]}`. Os dois logs novos têm 0 bytes CR, e o Git regista-os `i/lf`. O README diz como se faz.
  - Os logs mais antigos (F28, F61, F64) ficam em CRLF, tal como foram cometidos (ponto 2 do §7).
- O cabeçalho da ferramenta e a linha `== F78/F79/F81: …` do log dizem o que mudou.

### F82 — o gesto documentado
- **A linha nova no README da pasta**, no parágrafo da F64:
  «O gesto da `PINÇA A DESLOCAR` é arbitrário (F82): 22 u e 2 u por passo, durante 5 passos, e o meio anda 60 u. Foi
  escolhido só para o controlo dar um número grande e não vem de nenhum aparelho. Os 0,854 m que ele dá provam que a
  medida funciona. Nunca são o que um gesto real da jogadora desloca, nem se citam assim.»
- O cabeçalho da ferramenta diz o mesmo.

## 2. Antes / depois
**As medições:** os 62 casos, em 844×390 e 780×360, com o Godot 4.7.2 `_console.exe --headless` no Windows 11.
- Na ponta, com o D1: `medicao/medir_custo_d1_hud-f78.log`.
- Sem o D1: `medicao/medir_custo_d1_hud-sem-d1-f78.log`.
  - Pus o `caixa_ordem.gd` de `0bebd76` só na cópia de trabalho e repu-lo a seguir com `git checkout`.
  - Depois de o repor, o `git diff` ficou vazio e o SHA do ficheiro é `cc26f56c…`, igual ao do `HEAD`.
- `medicao/resumo-f78.txt` escreve-se com `bash ferramentas/resumo_f78.sh <raiz> 0 0 10e21f0`.

| ficheiro | rc | casos | erros | MEDIDA | TABELA | PARTIDA | DEPOIS | `error`/`warning` | CR | sha256 |
|---|---|---|---|---|---|---|---|---|---|---|
| `-f64.log` (na ponta, antes) | 0 | 62 | 0 | 70 | 62 | 100 | 164 | 0 | 417 | `8e194fe05fe0…` |
| `-sem-d1-f64.log` (antes) | 0 | 62 | 0 | 70 | 62 | 100 | 164 | 0 | 417 | `47f00b7e7ea3…` |
| **`-f78.log` (na ponta, depois)** | **0** | **62** | **0** | 70 | 62 | 100 | 164 | 0 | **0** | `51085cf81855…` |
| **`-sem-d1-f78.log` (depois)** | **0** | **62** | **0** | 70 | 62 | 100 | 164 | 0 | **0** | `59a67a03b820…` |

O log novo tem mais uma linha (418 em vez de 417): a `== F78/F79/F81: …` do cabeçalho. `resumo-f78.txt` tem o sha256
`2a6af04decc2…`.

| o que se mede | F64 (antes) | F78 (depois), nas duas medições |
|---|---|---|
| cursor nas `PARTIDA` | 1 × (−1, −1); 89 × (10, 10); **10 × (6, 11)** | **84 × (−1, −1); 16 × (10, 10)**; 0 × (6, 11) |
| «de o Mover» | 44 (ponta) / 52 (sem o D1) | **0** |
| MEDIDA seguida logo de DEPOIS | 18 | **0** |
| `MEDIDA PINÇA A DESLOCAR` com rumo e inclinação | 0 de 4 | **4 de 4** |
| bytes CR por log | 417 | **0** |

**As tabelas não mudaram.** Comparei as linhas TABELA da 2.ª corrida da F61 com as da F78, byte a byte: diferem
**0 de 62 na ponta e 0 de 62 sem o D1**.
- Os 15 botões continuam a custar +1 toque com o D1 e 1 toque sem ele.
- O arrastar e a pinça continuam perdidos inteiros com a lista aberta: 0,000 m e zoom 1,500 → 1,500.
- A roda, o rato e a jogada típica (4 / 6 / 6 com o D1, 4 / 5 / 5 sem ele) dão o mesmo.

**As outras linhas também não mudaram de valor.** Normalizei os logs da F64 e da F78: tirei os CR, «de o» → «do», o
cursor e o rumo/inclinação novos. Depois comparei-os linha a linha, sem olhar à ordem. Só sobram duas diferenças:
- a linha nova do cabeçalho;
- o tempo de carga do mapa da floresta (1850 → 1845 ms na ponta), que varia de corrida para corrida.
- Com o cursor reposto, abrir o Mover passa a registar no `DEPOIS` também `cursor: (-1, -1) → (10, 10)`. Antes não o
  registava, porque o cursor já vinha em (10, 10) do caso anterior.

**As linhas da casa e das pinças** dão os mesmos números da F64 nos dois ecrãs:
- a casa (7, 11): com o D1 e a lista aberta, o 1.º toque fecha a lista sem mover a figura (2 toques);
- a pinça: 0,000 m com a lista aberta e 0,028 m no controlo;
- a pinça a deslocar: 0,000 m com a lista aberta e 0,854 m no controlo. Rumo 0,0 → 0,0 e inclinação 55,0 → 55,0 em
  todos os casos.
- **Na ponta, nos 32 casos com a lista aberta, a linha «ao 1.º toque» muda uma só coisa**: `caixa: expandida por toque →
  compacta` (32 de 32). Sem o D1, é 0 de 32, porque o 1.º toque também faz a acção.

## 3. Nada se partiu
**Neste PC, sobre a obra** (Godot 4.7.2 Windows, os mesmos comandos do CI):

| suite | resultado | rc | `SCRIPT ERROR` / `Parse Error` / `Compile Error` |
|---|---|---|---|
| o canário (`teste_nomes_relato.gd`) | **26 de 26** | 0 | 0 |
| `rodar_testes` | **321 de 321** | 0 | 0 |
| `caixa_janela` | **123 de 123** | 0 | 0 |
| `caixa_jogadora` | **70 de 70** | 0 | 0 |
| mutação das células (`mutacao-celulas.sh`) | **114 de 123**, 9 falhas, todas do assert B6, «MUTACAO APANHADA» | 0 | 0 |

- A mutação repôs o `caixa_ordem.gd`: o `git diff` ficou vazio.
- As saídas cruas ficaram em `tmp/suites/`, fora do repo, porque o canário imprime nomes inteiros de propósito.
- A obra não muda nenhum ficheiro que as suites leiam: só mexe em `provas/ordem-f28-custo-d1-hud/`.

## 4. O passo da F51 no CI
O passo «A saída do canário, redigida (§2 da F25), é igual byte a byte ao registo limpo (Ordem F51, §7.5 da F25)» está
no `.github/workflows/testes.yml` desde `74f5fa9`. Corre o auto-teste do `redigir-nomes.mjs` e a comparação. Não foi
preciso mexer no workflow. O §5 diz o que ele deu na ponta.

## 5. CI
**CI da ponta `b4e680f` (a obra): verde.**
- **Testes dos rascunhos**, run `45138397945`: passaram os 10 jobs (`servidor`, `validador-glb`, `motor-real`,
  `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`, `foto-mestre` e `retoma-pc`).
- **Sonda de privacidade**, run `45138398098`: verde.
- **Os números do log do run:**
  - o canário deu «26 de 26»;
  - `rodar_testes` 321/321, também no `godot-cliente`;
  - `caixa_janela` 123/123;
  - `caixa_jogadora` 70/70;
  - a mutação das células deu «114 de 123» e «MUTACAO APANHADA: 9 falhas, todas do assert B6».
- **O passo da F51 correu** no job `cliente`: o auto-teste do `redigir-nomes` deu 16 de 16, e a saída redigida do
  canário ficou «igual byte a byte» ao registo limpo (3464 bytes).
- O `retoma-pc` ficou verde, o que confirma que as listas da retoma batem certo sem mudar.

**CI da ponta `fc04d26` (a obra mais este ESTADO-FINAL): verde.**
- Testes dos rascunhos, run `45138841851`: passaram os 10 jobs.
- Sonda de privacidade, run `45138842030`: verde.
- Os números são os mesmos: canário 26/26, `rodar_testes` 321/321 (também no `godot-cliente`), `caixa_janela` 123/123,
  `caixa_jogadora` 70/70 e mutação das células «114 de 123». O passo da F51 deu 16/16 e «igual byte a byte».
- O commit desta nota só acrescenta este parágrafo a este ficheiro.

## 6. Privacidade re-derivada
Conferidor: `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`, nos dois critérios (alargado e `--velho`), sobre
os ficheiros cometidos por esta ordem. Na coluna dos nomes inteiros conta-se um achado cujo pedaço tem o comprimento do
nome inteiro.

| ficheiro | alargado / antigo | nomes inteiros |
|---|---|---|
| este ESTADO-FINAL | **0 / 0** | 0 |
| `provas/ordem-f28-custo-d1-hud/README.md` | **0 / 0** | 0 |
| `ferramentas/medir_custo_d1_hud.gd` | **0 / 0** | 0 |
| `ferramentas/resumo_f78.sh` | **0 / 0** | 0 |
| `medicao/resumo-f78.txt` | **0 / 0** | 0 |
| `medicao/medir_custo_d1_hud-f78.log`, `medicao/medir_custo_d1_hud-sem-d1-f78.log` | 2 / 2 por log | **0** |

- **O README** chegou a dar 1 / 0 no rascunho: um pedaço de 6 letras, a cavalo de duas palavras da frase da F82.
  Reformulei a frase antes de cometer, e ficou 0 / 0.
- **Os dois logs** têm 2 / 2 numa só linha que eu não escrevi: a 3.ª, o relatório de carga do mapa da floresta
  (`[floresta] pronta em … ms | {…}`). São pedaços de 5 letras de nomes de 16 e de 15. São os mesmos achados, na mesma
  linha, dos logs da F28, da F61 e da F64, que foram aceites: palavras correntes, não nomes.
- **Nomes verdadeiros inteiros: 0** em todos os ficheiros da obra e neste ESTADO-FINAL.
- **PIN: 0.** Esta ordem não arrancou o servidor, por isso não houve PIN nem `--pin=`. Procurei números de 20
  algarismos (a forma do PIN) nos ficheiros desta ordem e não há nenhum.
- **As listas da retoma:** corri `python retoma-i0004/actualizar-listas.py` e deu «0 novos, 0 tirados», sem mudar
  nenhum ficheiro. As listas só cobrem `rascunhos/`, e nenhum ficheiro de `rascunhos/` mudou. Nenhum SHA mudou, por isso
  não houve nada a sincronizar.

## 7. Pontos abertos para o coordenador
1. **A sentença da F64 não está neste PC.** Se ela disser os quatro acabamentos de outra maneira, é preciso conferir.
   Por exemplo, pode querer outra ordem para MEDIDA/DEPOIS ou outro valor neutro do cursor.
2. **«Os logs passam a LF».** Fi-lo nos logs que esta ordem escreve (os dois `-f78`). Não converti os logs já cometidos
   da F28, da F61 e da F64: são registos de corridas passadas e ficam como foram cometidos. As comparações das tabelas
   tiram os CR (`tr -d '\r'`), por isso a diferença não pesa. Se a sentença quiser também os antigos em LF, é uma
   conversão só de fins de linha, e decide o coordenador.
3. **O sentido da ordem uniforme.** A ordem pede a ordem MEDIDA/DEPOIS uniformizada, mas não diz qual. Escolhi
   «PARTIDA, DEPOIS, MEDIDA», porque é a única que os botões podem ter (§1, F81).
4. **O valor neutro do cursor.** Repus o (−1, −1) com que a arena nasce, e não um valor guardado quando a arena fica
   pronta, como a F61 faz com a câmara. Aqui os dois são o mesmo, e a 1.ª `PARTIDA` da F64 já dava (−1, −1).
5. **Este PC não tem ecrã de toque.** Como na F28, os toques são os que o motor recebe de um aparelho.
