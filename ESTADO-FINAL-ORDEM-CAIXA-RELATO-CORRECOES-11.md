# ESTADO-FINAL — Ordem CAIXA-RELATO-CORRECOES-11 (a correcção D1 da sentença da CAIXA-RELATO-CORRECOES-10)

**Quem:** Claude, no PC (22/11/2026). **Linha:** `fable/integracao-50`, trabalho directo, sem ramo lateral nem fusão.
**Base:** `1100822` (a ponta à hora do lançamento: a Ordem CAIXA-TESTES-CORRECOES-14).
**Sede:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-caixa-relato-correcoes-11\`. Chegou sem clone (só
`ORDEM.md`, os `.b64`, o `.cmd` de arranque e o log vazio). Clonei a linha em `repo\`, como nas ordens anteriores, e
pus a pasta tmp em `tmp\`.
**Commits:** `d1dfe46` tem a correcção (B1) e as provas. O commit deste ESTADO-FINAL vem a seguir.

Este ficheiro não leva nomes verdadeiros nem o valor de nenhum PIN. O conferidor estrito dá 0 achados nele (§2).

## 1. O ponto

### B1 (D1) — raiz de unidade com uma ou mais barras — FEITO, PROVADO (executado, caso a caso)
- **O defeito, executado com a função de `1100822`:** com `HOME=C://`, `HOME=C:\\` ou `HOME=c://`, `~/x` dava
  `C:///x` (ou `c:///x`) em silêncio. O braço da CORRECOES-10, `[A-Za-z]:[\\/]`, só casava uma barra.
- **A correcção** (`provas/ordem-caixa-relato/ferramentas/absolutizar.sh`, +8/−2): o braço passa a casar
  `[A-Za-z]:[\\/]*` (letra, dois pontos, uma barra e o que vier) e, dentro dele, um `case` sobre `${HOME:2}` (o que vem
  depois de «C:»). Se aí houver um carácter que não seja barra, é uma pasta e passa. Se só houver barras, falha com a
  mesma mensagem da raiz da unidade: «começa por ~ mas o $HOME («C://») é a raiz da unidade C:, não uma pasta pessoal —
  dá um caminho absoluto». O comentário do cabeçalho passa a dizer «nem a de uma unidade «C:/», «C://», «C:\\»…».
  Os outros braços não mudam, e o script continua sem `extglob`.
- **Porque não usei o padrão do exemplo da ordem tal como está.** Num `case` do bash, `[A-Za-z]:[\\/][\\/]*` é um
  glob, não uma expressão regular: o `*` final quer dizer «qualquer coisa», e não «zero ou mais barras». Pus esse
  padrão à letra numa cópia da função de `1100822` (em `tmp\` da sede, sem cometer) e corri o mecânico. Deu **28 de
  31**: perde o `C:/` e o `C:\` (R01, R02), porque exige duas barras, e rejeita `HOME=C://Users/t` (X02), que é uma
  pasta. O `case` aninhado faz o que a ordem descreve: `[A-Za-z]:[\\/]` seguido de zero ou mais barras e nada mais.
- **Prova — o mecânico** (`provas/ordem-caixa-relato/correcoes-11/b1-mecanico.sh`, com as saídas `-antes.txt` e
  `-depois.txt` ao lado). São os 26 casos da CORRECOES-10 (M01–M22, H01, R01–R03), sem mudanças, mais 3 novos da ordem
  e 2 guardas:

  | Caso | HOME | Entrada | Esperado | antes (`1100822`) | depois |
  |---|---|---|---|---|---|
  | R01 | `C:/` | `~/x` | falha, «é a raiz da unidade C:, não uma pasta pessoal» | OK | OK |
  | R02 | `C:\` | `~/x` | idem | OK | OK |
  | R03 | `C:` | `~/x` | falha, «não é absoluto» | OK | OK |
  | R04 | `C://` | `~/x` | falha, «é a raiz da unidade C:, …» | ERRO (`C:///x`) | **OK** (rc=1) |
  | R05 | `C:\\` | `~/x` | idem | ERRO (`C:///x`) | **OK** (rc=1) |
  | R06 | `c://` | `~/x` | falha, «é a raiz da unidade c:, …» | ERRO (`c:///x`) | **OK** (rc=1) |
  | X01 (guarda) | `C:///` | `~/x` | falha, «é a raiz da unidade C:, …» | ERRO (`C:////x`) | **OK** (rc=1) |
  | X02 (guarda) | `C://Users/t` | `~/x` | `C://Users/t/x` (é uma pasta, passa) | OK | OK |

  - **antes:** **27 de 31**. Só o R04, o R05, o R06 e o X01 dão ERRO.
  - **depois:** **31 de 31**.
  - O `diff` antes/depois só tem as linhas do R04, do R05, do R06, do X01 e do total. As 52 primeiras linhas da saída
    (os 26 casos da CORRECOES-10) são **iguais, byte a byte**, ao `correcoes-10/b1-mecanico-depois.txt` (`cmp` sem
    diferenças). Os 26 casos antigos não mudam.
- **Re-execução da privacidade da CORRECOES-10** (os scripts verdadeiros que lêem o `absolutizar.sh`): corri o
  `correcoes-10/b2-privacidade.sh` sem mudanças, da sede, com a função nova. Deu **19 de 19**, o extra B1 deu **2 de
  2**, e saiu «NADA ESCRITO (listagem da sede e git status do clone iguais)». A saída está cometida em
  `correcoes-11/b2-privacidade-reexecucao.txt`.

## 2. As corridas

| Corrida | Resultado |
|---|---|
| mecânico B1 (`correcoes-11/b1-mecanico.sh`), antes / depois | 27/31 / **31/31** |
| os 26 casos da CORRECOES-10 dentro dele | iguais byte a byte |
| o padrão literal do exemplo da ordem (cópia na sede, não cometida) | 28/31 (R01, R02, X02 falham) |
| privacidade da CORRECOES-10 (`b2-privacidade.sh`), re-executada | **19/19**, extra **2/2**, nada escrito |
| teste do relato (`teste_relato_caixa.gd`, Godot 4.7.2 headless, depois do `--import`) | **31/31**, rc=0 |
| `bash -n` nos `.sh` de `ferramentas/` | sem erros |
| conferidor estrito (`conferir-registo.mjs`) | 0 achados no `absolutizar.sh`, nos 4 ficheiros de `correcoes-11/` e neste ESTADO-FINAL |
| `retoma-i0004/actualizar-listas.py`, antes do commit | «MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)» |

## 3. Pontos para o coordenador

1. **O exemplo da ordem não foi usado à letra** (§1): como glob, `[A-Za-z]:[\\/][\\/]*` partiria o R01 e o R02 e
   rejeitaria `C://Users/t`. Usei um `case` aninhado, que faz o que a ordem descreve, sem ligar o `extglob`.
2. **Juntei 2 guardas ao mecânico (X01, X02)**, contados no total de 31. O X01 (`C:///`) mostra que «uma ou mais
   barras» vai além de duas. O X02 (`C://Users/t`) mostra que uma pasta depois de várias barras continua aceite, como
   antes.
3. **O teste do relato corri-o só como verificação de rotina.** É GDScript e não lê o `absolutizar.sh`, e esta ordem
   não o pede. A saída ficou no `tmp\` da sede e não foi cometida. Os scripts que lêem a função foram exercidos pela
   re-execução da privacidade.
4. O `ORDEM.md` da sede já termina com `<b>Estado: NOVA</b>`, e não mexi nele. Nenhum valor de PIN foi escrito.
