# ESTADO-FINAL — Ordem CAIXA-RELATO-CORRECOES-9 (as correcções JD1–JD3 da sentença da CAIXA-RELATO-CORRECOES-8)

**Quem:** Claude, no PC (22/11/2026). **Linha:** `fable/integracao-50`, trabalho directo, sem ramo lateral nem fusão.
**Base:** `5a92ad9` (a ponta à hora do lançamento). Tem a B7-CORRECOES-7 (`687bd92`, `30c4c76`, `5a92ad9`), por isso
a dependência nomeada estava satisfeita.
**Sede:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-caixa-relato-correcoes-9\`. Chegou sem clone (só
`ORDEM.md`, `ORDEM.md.b64`, o `.cmd` de arranque e o log vazio). Clonei a linha em `repo\` (`git clone --branch
fable/integracao-50`). A pasta tmp está em `tmp\`.
**Commits:** `a1a131b` tem as correcções (B1–B3). Depois do `fetch`, fiz `rebase` sobre `c18d3b4`
(CAIXA-TESTES-CORRECOES-13, que entrou entretanto). Foi limpo, e esse commit só toca em ESTADO-FINAL da CAIXA-TESTES.
A seguir vem o commit deste ESTADO-FINAL.

A conferência não está neste PC. Trabalhei pelo texto da ordem. As listas dos «22 casos do mecânico» e dos «13 da
privacidade» não vêm na ordem, por isso defini-as aqui e listo-as caso a caso (§B3, e o ponto 2 da §3).

Este ficheiro não cita os nomes verdadeiros nem pedaços deles. Diz só o n.º do nome, a linha e o comprimento. O
conferidor estrito dá 0 achados neste ficheiro, nos dois critérios.

## 1. Ponto a ponto

### B1 (JD2) — a frase do «diff vazio» — FEITO, PROVADO (o `diff` corrido outra vez)
- **O `diff` corrido outra vez**, do registo actual (`provas/ordem-caixa-relato/correcoes-4/mutacoes.log`) contra o de
  `fe4a84d` (`git show fe4a84d:…`), por tipo de linha:

  | Linhas | Contagem (`fe4a84d` / actual) | `diff` | sha256 das linhas extraídas (iguais nos dois) |
  |---|---|---|---|
  | títulos `^== ` | 36 / 36 | **4 diferem**: n.º 1, 7, 19, 25 | — |
  | resumos «… verificações passaram.» | 38 / 38 | **vazio** (rc=0) | `87386433…acec3a66` |
  | `^rc=` | 36 / 36 | **vazio** (rc=0) | `de88d828…59735aba` |

  Os 4 títulos que diferem (n.º 1 e 19 são `B1-nome-verdadeiro (hud)`; n.º 7 e 25 são
  `N-B2-canario-minusculas-relato (hud)`, um por parte) diferem só na redacção do fim:
  - n.º 1 e 19: «… — o relato traz «‹nome verdadeiro›»» → «… — o relato traz o nome verdadeiro n.º 1»;
  - n.º 7 e 25: «… o relato traz o nome verdadeiro em minúsculas («‹nome verdadeiro›»)» → «… o relato traz o nome
    verdadeiro n.º 1 em minúsculas».

  É a mudança dos títulos que o ESTADO-FINAL-7 §1 B1 já descrevia («Os títulos», l. 23–25).
- **A correcção:**
  - **`ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES-8.md` §B1, l. 25–26.** Agora diz: «entre o registo actual e o de
    `fe4a84d` (…), o `diff` sai vazio nos 38 resumos e nos 36 `rc=`; 4 títulos diferem (n.º 1, 7, 19, 25), só na
    redacção.²». Leva uma nota de emenda ² (l. 28–31), que diz o que a primeira redacção afirmava e quais são os 4
    títulos. Segue o padrão das emendas ¹.
  - **`ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES-7.md` §1 B1, nota de emenda ¹.** A afirmação não estava nas l. 35–36
    que a ordem cita (aí começa a nota ¹), mas nas **l. 40–41**, as duas últimas da nota: «Os 38 são iguais, linha a
    linha, aos (…) (`fe4a84d`), e os 36 `rc=` também. Contado na CORRECOES-8 com `grep -c` e um `diff` dos títulos,
    resumos e `rc=`.». Reescrevi-as (l. 40–42 agora) com o facto exacto: «o `diff` sai vazio nos 38 resumos e nos 36
    `rc=`; 4 títulos diferem (n.º 1, 7, 19, 25), só na redacção».
  - Nenhuma das duas diz agora que o `diff` sai vazio sem restrição.
- **O conferidor estrito** dá 0 achados nos dois ficheiros, antes e depois, nos dois critérios. A primeira redacção
  da nota ² dava 2 achados de 4 car. na l. 30 (n.º 1 e n.º 2, uma palavra corrente). Reescrevi a frase antes do
  commit.

### B2 (JD1) — a linha 81 do ESTADO-FINAL-2 — FEITO, PROVADO (executado)
- **Localizado com o conferidor estrito** (`conferir-registo.mjs`, critério alargado), antes de mexer:
  «linha 81: nome verdadeiro n.º 1 (16 caracteres) — pedaço de 12 caracteres» e «linha 81: nome verdadeiro n.º 2 (15
  caracteres) — pedaço de 12 caracteres». A linha real **é a 81**, e a contagem não está fora do sítio. O pedaço é o
  sufixo partilhado dos dois nomes, numa frase corrente sobre a origem dos nomes (§3, ponto 1).
- **A correcção:** essa frase passa a «Os nomes verdadeiros n.º 1 e n.º 2 são fictícios (das fichas de teste).». É a
  redacção «n.º», como a B2 da CORRECOES-7 e as l. 11 e 18 do próprio ESTADO-FINAL-2. O sentido mantém-se.
- **Prova:**

  | | Achados na l. 81 | Achados no ficheiro (alargado) | `--velho` | Nomes inteiros (classificação) |
  |---|---|---|---|---|
  | antes | 2 (n.º 1 e n.º 2, 12 car.) | 18 | 17 | 0 |
  | depois | **0** | **16** | **15** | **0** |

  O `diff` da saída do conferidor, antes contra depois, tem só as 2 linhas da l. 81 e o total. Os 16 que ficam (l. 9, 11, 12,
  24, 39, 42, 68, 80 e 84, de 4 e 5 car.) já lá estavam: são palavras correntes e a palavra do cenário, como diz o
  ESTADO-FINAL-8 §B5.

### B3 (JD3) — `HOME=/` no `absolutizar.sh` — FEITO, PROVADO (executado, caso a caso)
- **O defeito, executado com a função de `5a92ad9`:** com `HOME=/`, `~/x` passa a `//x`, cai no ramo UNC e falha com
  «caminho de rede (UNC) não é suportado». Falhava sem perigo, mas a mensagem estava errada.
- **A correcção** (`provas/ordem-caixa-relato/ferramentas/absolutizar.sh`, +3/−1): a seguir à verificação de que o
  `$HOME` é absoluto, vem uma segunda. Um `$HOME` absoluto que só tem barras (`/`, `//`…) é rejeitado, antes de se
  construir o caminho, com «começa por ~ mas o $HOME («/») é a raiz, não uma pasta pessoal — dá um caminho
  absoluto». O comentário do cabeçalho diz o mesmo. Nos outros casos nada muda.
- **Prova 1 — o mecânico: 22 casos + o caso `HOME=/`, à função** (`tmp/b3-mecanico.sh`, `ORIGEM=/c/Users/t/origem`,
  `HOME=/c/Users/t` salvo onde se diz):

  | Caso | HOME | Entrada | Esperado e obtido (depois) |
  |---|---|---|---|
  | M01 | — | `~/x/tmp` | `/c/Users/t/x/tmp` |
  | M02 | — | `~` | `/c/Users/t` |
  | M03 | — | `~\x` | `/c/Users/t/x` |
  | M04 | — | `~root/x` | falha, «~utilizador não é suportado» |
  | M05 | — | `\\servidor\partilha\tmp` | falha, UNC |
  | M06 | — | `//servidor/partilha/tmp` | falha, UNC |
  | M07 | — | `\/servidor/partilha` | falha, UNC |
  | M08 | — | `/\x` | falha, UNC |
  | M09 | — | `C:tmp` | falha, «sem barra é relativo à pasta corrente» |
  | M10 | — | `C:` | falha, idem |
  | M11 | — | `\tmp\sub` | `C:/tmp/sub` |
  | M12 | — | `/c/abs/tmp` | `/c/abs/tmp` |
  | M13 | — | `C:/abs/tmp` | `C:/abs/tmp` |
  | M14 | — | `C:\abs\tmp` | `C:/abs/tmp` |
  | M15 | — | `tmp/rel` | `/c/Users/t/origem/tmp/rel` |
  | M16 | — | `./tmp` | `/c/Users/t/origem/./tmp` |
  | M17 | — | `..\tmp\rel` | `/c/Users/t/origem/../tmp/rel` |
  | M18 | — | `/tmp/x` | `/tmp/x` |
  | M19 | `casa-relativa` | `~/x` | falha, «não é absoluto» |
  | M20 | `C:/Users/t` | `~/x` | `C:/Users/t/x` |
  | M21 | `C:\Users\t` | `~\x` | `C:/Users/t/x` |
  | M22 | `/c/Users/t/` | `~/x` | `/c/Users/t//x` |
  | **H01** | **`/`** | **`~/x`** | **falha, «é a raiz, não uma pasta pessoal»** |

  - **antes** (`absolutizar.sh` de `5a92ad9`): **22 de 23**. M01–M22 dão OK; o H01 dá ERRO, porque falha com
    «caminho de rede (UNC) não é suportado»;
  - **depois:** **23 de 23**. O H01 falha (rc=1 na função) com a mensagem certa. M01–M22 dão o mesmo que antes: a
    emenda não muda mais nenhum caso.
- **Prova 2 — a privacidade: 13 casos + o caso `HOME=/` em 3 argumentos, com os scripts verdadeiros chamados da sede**
  (`tmp/b3-privacidade.sh`). Todos os casos têm de dar rc=2, a mensagem certa e nada escrito:

  | Caso | Script e argumento | Entrada (HOME) | rc | Mensagem |
  |---|---|---|---|---|
  | P01 | `correr-prova-caixa-relato.sh`, pasta tmp | `~root/x` | 2 | ~utilizador |
  | P02 | idem | `\\servidor\partilha\tmp` | 2 | UNC |
  | P03 | idem | `//servidor/partilha/tmp` | 2 | UNC |
  | P04 | idem | `\/servidor/partilha` | 2 | UNC |
  | P05 | idem | `C:tmp` | 2 | sem barra |
  | P06 | idem | `C:` | 2 | sem barra |
  | P07 | `correr-mutacoes.sh`, pasta tmp | `~root/x` | 2 | ~utilizador |
  | P08 | idem | `\\servidor\partilha\tmp` | 2 | UNC |
  | P09 | idem | `//servidor/partilha/tmp` | 2 | UNC |
  | P10 | idem | `\/servidor/partilha` | 2 | UNC |
  | P11 | idem | `C:tmp` | 2 | sem barra |
  | P12 | idem | `C:` | 2 | sem barra |
  | P13 | `correr-prova-caixa-relato.sh`, pasta tmp | `~/x` (`casa-relativa`) | 2 | não é absoluto |
  | **H01** | `correr-prova-caixa-relato.sh`, pasta tmp | **`~/x` (`/`)** | **2** | **é a raiz, não uma pasta pessoal** |
  | **H02** | `correr-mutacoes.sh`, pasta tmp | **`~/x` (`/`)** | **2** | **idem** |
  | **H03** | `correr-mutacoes.sh`, registo | **`~/x.log` (`/`)** | **2** | **idem** |

  - **16 de 16**;
  - a listagem da sede (sem `.git` nem `.godot`) e o `git status` do clone, antes e depois, são **iguais**: nada foi
    escrito;
  - as mensagens só repetem o caminho dado e o `$HOME`. Não trazem o PIN nem nomes.

## 2. As corridas (Godot 4.7.2 Windows, `Godot_v4.7.2-stable_win64_console.exe`; node v26.13.0)

| Corrida | Resultado |
|---|---|
| `teste_relato_caixa.gd` (`--headless --path rascunhos/cliente`, depois de `--import`, rc=0) | **31 de 31**, rc=0, 0 «SCRIPT ERROR/Parse Error/Compile Error» |
| Suite do servidor (`node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"`, em `rascunhos/servidor`) | **421/421**, fail 0, rc=0 |
| Privacidade (`node --test --test-isolation=none testes/privacidade.test.mjs`, em `rascunhos/servidor`) | **11/11**, fail 0, rc=0 |
| B3, o mecânico (22 + `HOME=/`) | antes 22/23 · **depois 23/23** |
| B3, a privacidade (13 + `HOME=/` × 3) | **16/16 rc=2**, nada escrito |
| Conferidor estrito, ESTADO-FINAL-2 | 18 → **16** (`--velho` 17 → 15); l. 81: 2 → **0**; inteiros 0 → **0** |
| Conferidor estrito, ESTADO-FINAL-7 e -8 | **0 → 0**, nos dois critérios |

As corridas foram feitas em `988d606`, o commit antes do rebase. O rebase sobre `c18d3b4` só junta os ficheiros da
CAIXA-TESTES-CORRECOES-13 (ESTADO-FINAL da CAIXA-TESTES-10 e -13), por isso os números valem para `a1a131b`.

O `actualizar-listas` (`python retoma-i0004/actualizar-listas.py`, na raiz do repo) correu antes do commit
`a1a131b` e outra vez antes do commit deste ficheiro. Deu «MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta
passagem)», e o `git status` não mudou. A ordem não toca em `rascunhos/`.

**CI em `a1a131b`:** os **10/10 jobs** do «Testes dos rascunhos» passaram (validador-glb, provas-mapa, protocolo,
godot-cliente, servidor, cliente, motor-real, ponta-a-ponta, foto-mestre, **retoma-pc**; run 45047287563). A «Sonda
de privacidade» também passou (run 45047287568).

## 3. Pontos para o coordenador
1. **B2: a origem do pedaço de 12.** Não era um nome cortado. Era a frase corrente sobre a origem dos nomes, que por
   acaso coincide com o sufixo partilhado dos dois. A redacção nova diz o mesmo e não leva o pedaço.
2. **B3: as listas de casos são minhas.** A ordem fala nos «22 casos do mecânico» e nos «13 da privacidade», mas não
   os lista, e a conferência não está neste PC. Defini-os assim:
   - o mecânico são os 16 casos da CORRECOES-8 (`b3-casos.sh`), os 3 extra (`/\x`, `HOME=casa-relativa`,
     `HOME=C:/…`) e mais 3 (`/tmp/x`, `HOME=C:\…`, `HOME` com barra final);
   - a privacidade são os 6 caminhos que falham, na pasta tmp dos dois scripts, mais o `HOME` relativo.
   Estão listados caso a caso na §B3. Se a conferência tiver outras listas, os dois harness (`tmp/` da sede) aceitam
   outros casos sem mudar a lógica.
3. **B3: o que fica de fora.** Com `HOME=C:/` (a raiz de uma unidade em forma Windows), `~/x` dá `C://x`. É um
   caminho válido no Windows e não cai no ramo UNC, por isso não o tratei: a ordem pede só o `HOME=/`. Se se quiser
   rejeitar também a raiz de uma unidade, basta juntar `[A-Za-z]:[\\/]` ao mesmo `case`.
4. **B1: a linha citada na ordem para o ESTADO-FINAL-7 (l. 35–36) é o início da nota ¹.** A afirmação está nas l.
   40–41, e foram essas que emendei. A §B1 diz isto.
5. **Fronteira:** mexi só nos ESTADO-FINAL da CORRECOES-2, -7 e -8 (só texto), no
   `provas/ordem-caixa-relato/ferramentas/absolutizar.sh` e neste ficheiro. Os harness de prova ficaram em `tmp/`
   da sede, não cometidos.
6. **A linha «Estado: NOVA»:** o `ORDEM.md` da sede já termina com ela, e não mexi nele.
