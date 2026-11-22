# ESTADO-FINAL — Ordem CAIXA-RELATO-CORRECOES-10 (as correcções D1–D2 da sentença da CAIXA-RELATO-CORRECOES-9)

**Quem:** Claude, no PC (22/11/2026). **Linha:** `fable/integracao-50`, trabalho directo, sem ramo lateral nem fusão.
**Base:** `1a83738` (a ponta à hora do lançamento: o ESTADO-FINAL da CAIXA-RELATO-B7-CORRECOES-8).
**Sede:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-caixa-relato-correcoes-10\`. Chegou sem clone (só
`ORDEM.md`, `ORDEM.md.b64`, o `.cmd` de arranque e o log vazio). Clonei a linha em `repo\`, como na CORRECOES-9, e
pus a pasta tmp em `tmp\`.
**Commits:** `3e0e089` tem as correcções (B1–B2) e as provas. O commit deste ESTADO-FINAL vem a seguir. O `fetch`
antes de publicar não trouxe nada de novo, por isso o `rebase` não teve nada para fazer e não houve conflitos.

Este ficheiro não leva nomes verdadeiros nem o valor de nenhum PIN. O conferidor estrito dá 0 achados nele (§2).

## 1. Ponto a ponto

### B1 (D1) — `$HOME` que é só a raiz de uma unidade — FEITO, PROVADO (executado, caso a caso)
- **O defeito, executado com a função de `1a83738`:** com `HOME=C:/` ou `HOME=C:\`, `~/x` dava `C://x` em silêncio.
  O `C:` tem um carácter que não é barra, por isso o braço `*[!/\\]*` da B3 da CORRECOES-9 deixava-o passar.
- **A correcção** (`provas/ordem-caixa-relato/ferramentas/absolutizar.sh`, +6/−2): um braço novo no mesmo `case` da
  B3, **antes** do braço `*[!/\\]*`. O braço novo é `[A-Za-z]:[\\/]`: só casa a letra, os dois pontos e uma barra,
  sem mais nada. Falha com a mensagem da raiz: «começa por ~ mas o $HOME («C:/») é a raiz da unidade C:, não uma
  pasta pessoal — dá um caminho absoluto». O comentário do cabeçalho passa a dizer «e não a raiz «/» nem a de uma
  unidade «C:/»». Os outros casos não mudam.
- **Prova — o mecânico** (`provas/ordem-caixa-relato/correcoes-10/b1-mecanico.sh`, com as saídas `-antes.txt` e
  `-depois.txt` ao lado). São os 22 casos M01–M22 e o H01 (`HOME=/`) da CORRECOES-9, todos iguais, mais 3 novos:

  | Caso | HOME | Entrada | Esperado | antes (`1a83738`) | depois |
  |---|---|---|---|---|---|
  | R01 | `C:/` | `~/x` | falha, «é a raiz da unidade C:, não uma pasta pessoal» | ERRO (`C://x`) | **OK** (rc=1) |
  | R02 | `C:\` | `~/x` | idem | ERRO (`C://x`) | **OK** (rc=1) |
  | R03 | `C:` | `~/x` | falha, «não é absoluto» | OK | OK |

  - **antes:** **24 de 26**. Só o R01 e o R02 dão ERRO.
  - **depois:** **26 de 26**.
  - O `diff` antes/depois só tem as linhas do R01, do R02 e do total. As 46 linhas dos 23 casos antigos (M01–M22 e
    H01) são **iguais, byte a byte**, às da saída `b3-mecanico-depois.txt` da CORRECOES-9. Os 22 casos antigos (e o
    H01) não mudam.
- **Extra, com os scripts verdadeiros** (dentro de `b2-privacidade.sh`, contado à parte): com `HOME=C:/` e `~/x` como
  pasta tmp, o `correr-prova-caixa-relato.sh` e o `correr-mutacoes.sh` dão os dois **rc=2** e a mensagem da raiz da
  unidade, e não escrevem nada: **2 de 2**.

### B2 (D2) — os 3 casos em falta na prova da privacidade — FEITO, PROVADO (executado, caso a caso)
- **A prova** (`provas/ordem-caixa-relato/correcoes-10/b2-privacidade.sh`, com a saída `b2-privacidade.txt`). Corre
  os scripts verdadeiros a partir da sede, com o clone em `repo/`. É a `b3-privacidade.sh` da CORRECOES-9, com os
  mesmos 16 casos (P01–P13 e H01–H03), mais estes 3:

  | Caso | Script e argumento | Entrada (HOME) | rc | Mensagem |
  |---|---|---|---|---|
  | P14 | `correr-prova-caixa-relato.sh`, pasta tmp | `/\x` | 2 | «caminho de rede (UNC) não é suportado» |
  | P15 | `correr-mutacoes.sh`, pasta tmp | `/\x` | 2 | idem |
  | P16 | `correr-mutacoes.sh`, pasta tmp | `~/x` (`HOME=casa-relativa`) | 2 | «o $HOME («casa-relativa») não é absoluto» |

- **Resultado: 19 de 19.** Todos dão rc=2 com a mensagem certa. A saída tem uma linha por caso, com o rc e a
  mensagem por inteiro.
- **Nada escrito:** o harness faz a listagem da sede (sem `repo/.git`, sem a `.godot` do cliente e sem os ficheiros
  do próprio harness) e o `git status --porcelain` do clone, antes e depois. O `diff` entre as duas sai vazio:
  «NADA ESCRITO (listagem da sede e git status do clone iguais)». O `git status` só mostrava a emenda do
  `absolutizar.sh` (e, na segunda corrida, a pasta `correcoes-10/` ainda por cometer), igual antes e depois.
  Depois do commit, o `git status` do clone está limpo.

## 2. As corridas

| Corrida | Resultado |
|---|---|
| mecânico B1 (`b1-mecanico.sh`), antes / depois | 24/26 / **26/26** |
| privacidade B2 (`b2-privacidade.sh`) | **19/19**, nada escrito |
| extra B1 nos scripts verdadeiros | **2/2** |
| teste do relato (`teste_relato_caixa.gd`, Godot 4.7.2 headless, depois do `--import`) | **31/31**, rc=0 |
| `bash -n absolutizar.sh` | sem erros |
| conferidor estrito (`conferir-registo.mjs`) | 0 achados no `absolutizar.sh`, nos dois harnesses, nas saídas `.txt` e neste ESTADO-FINAL |
| `retoma-i0004/actualizar-listas.py`, antes do commit | «MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)» |

## 3. Pontos para o coordenador

1. **`C://` e `C:\\` ficam de fora.** O braço novo segue a ordem à letra: só uma barra depois de `C:`. Com
   `HOME=C://`, `~/x` dá `C:///x`, em silêncio. É um caminho que o Windows aceita, mas é da mesma família. Para o
   rejeitar também, basta trocar o padrão por um que aceite uma ou mais barras depois de `X:`. Não mexi nisso, porque
   a ordem pede «sem mais nada».
2. **As provas ficam agora na linha.** Na CORRECOES-9, os harnesses ficaram só no `tmp/` da sede. Desta vez estão
   cometidos em `provas/ordem-caixa-relato/correcoes-10/`, com as saídas. O `b2-privacidade.sh` corre da pasta da
   sede, com o clone em `repo/`, como na CORRECOES-9.
3. **O `teste-relato.log` cometido dá 4 achados de 4 a 6 caracteres** no conferidor estrito. São palavras correntes
   da saída do teste, as mesmas que o `correcoes-8/teste-relato.log` já cometido também dá (4 achados). Não há nomes
   inteiros. Uma linha da primeira redacção do `b2-privacidade.sh` dava 2 achados de 4 car. (uma palavra corrente).
   Reescrevi-a antes do commit e passou a 0.
4. **Os «22 casos antigos» e os «16 casos antigos»** são as listas que a CORRECOES-9 definiu e escreveu caso a caso no
   seu ESTADO-FINAL. Usei-as sem mudanças.
5. O `ORDEM.md` da sede já termina com `<b>Estado: NOVA</b>`, e não mexi nele.
