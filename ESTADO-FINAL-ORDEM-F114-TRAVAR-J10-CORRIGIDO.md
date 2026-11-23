# ESTADO-FINAL — Ordem F114 (travar o J10, corrigido — opção 1 da F108)

**Estado: FEITA.** O J10 está travado com o protótipo A da F108. O auto-teste passa de 26/26 para **28/28**. A
reprodução continua **10/11, com a mesma linha 6**. O canário continua **26/26**. As suites estão verdes e o CI da
ponta da obra deu **10/10 + Sonda**.

- **Executor:** Claude (opus, esforço médio), PC do cunhado, conta 1. **Data:** 23/11/2026.
- **Linha:** `fable/integracao-50`, trabalho directo, sem ramos laterais. **`HEAD` de partida:** `5bf8ca1` (o
  ESTADO-FINAL da F108), clone novo e limpo em `ordem-f114-travar-j10-pc/repo`.
- **Biblioteca (GameDev Kit):** não construí nada de raiz. A obra muda uma linha de um padrão do `redigir-nomes.mjs`,
  junta 2 casos ao auto-teste que já existe e acerta o README.

## 1. A decisão, e porquê

É a **opção 1 da F108: a rota 1 com o protótipo A**, lavrada pelo coordenador na ordem F114. A conferência da F108
está a rever esta decisão.

- **Porquê** (da ordem): bate com o exemplo da ordem F108, que pede no máximo um `\n` em qualquer separador. Bate
  também com o J10 como o README o descreve («o espaço à volta da palavra do meio pode ser uma quebra de linha»).
  Mantém o caso das 3 linhas, que o §7, ponto 5, da F88–F96 já confessava. Só tira a linha em branco, que ninguém
  tinha descrito.
- **O item 3 da F108 fica substituído** por: «3 linhas → rc=3; linha em branco → não conta».
- **Reutilizei o protótipo A da F108** (`ordem-f108-travar-j10-pc/tmp/prot-A.mjs`) e não o re-derivei. Antes de o
  usar, confirmei que o `orig.mjs` de lá é igual byte a byte ao ficheiro da ponta `5bf8ca1`. O `prot-A.mjs` difere
  dele só na linha do padrão.

## 2. O padrão, antes e depois

`provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs`, em `reVariantesFora()`.

**Antes** (linha 158, na ponta `5bf8ca1`):

```js
    res.push(new RegExp(`(?<!\\p{L})${antes}\\s+[\\p{L}'’]+(?:-[\\p{L}'’]+)*(?:\\p{P}+\\s*|\\s+)${depois}(?!\\p{L})`, 'giu'));
```

**Depois** (linhas 158–162, na ponta `5554637`; as três primeiras são o comentário):

```js
    // F114 (travar o J10, opção 1 da F108): qualquer separador à volta da palavra do meio casa no máximo um `\n` e nunca
    // `\n\n` — a quebra de linha pode estar antes ou depois da palavra do meio, ou nos dois lados, nunca uma linha em
    // branco.
    const S = '(?=\\s)[^\\S\\n]*\\n?[^\\S\\n]*';
    res.push(new RegExp(`(?<!\\p{L})${antes}${S}[\\p{L}'’]+(?:-[\\p{L}'’]+)*(?:\\p{P}+[^\\S\\n]*\\n?[^\\S\\n]*|${S})${depois}(?!\\p{L})`, 'giu'));
```

O `S` exige pelo menos um espaço (`(?=\s)`). Casa espaços sem quebra de linha, no máximo um `\n` e mais espaços sem
quebra. O `\r` do CRLF é um espaço sem `\n` e por isso passa. A linha em branco precisa de dois `\n` e não passa. A linha
só de espaços também não. O ramo da pontuação (J9) fica com a mesma travagem.

## 3. Os 2 casos novos no auto-teste

Ficam logo a seguir ao caso do J10, e montam-se em memória a partir das fichas, como os outros:

| caso | texto montado (as partes do nome n.º 1) | o que afirma |
|---|---|---|
| **(a) 3 linhas** | `fim: <início>\n<preposição>\n<apelido> segue` | não se redige (fica igual), e a rede apanha-o: `0\|1\|0\|1\|` (0 inteiros, **1 variante, na linha 1**, 0 cortes) e `haSuspeitos` → **saída 3** |
| **(b) linha em branco** | `fim: <início>\n\n<preposição> <apelido> segue` | não se redige, e **0 variantes**: a variante já não atravessa a linha em branco |

**Os dois casos têm dentes.** Repus o padrão antigo numa cópia fora do repo (`tmp/mutante.mjs`), com os 2 casos novos.
O auto-teste deu **27 de 28**, e a falha é a do caso (b). Com o padrão novo dá 28 de 28.

**A medida dos 8 casos da F108**, refeita com a ferramenta cometida (inteiros/variantes/cortes/sem a preposição, e a
linha da variante). Bate com a coluna A da tabela da F108:

| caso | ponta `5bf8ca1` | ponta `5554637` |
|---|---|---|
| J10 LF | 0/1/0/0 @1 | 0/1/0/0 @1 |
| J10 «du» LF | 0/1/0/0 @1 | 0/1/0/0 @1 |
| J10 CRLF | 0/1/0/0 @2 | 0/1/0/0 @2 |
| 3 linhas | 0/1/0/0 @1 | **0/1/0/0 @1** |
| 3 linhas com «du» | 0/1/0/0 @1 | 0/1/0/0 @1 |
| linha em branco antes da palavra do meio | 0/1/0/0 @1 | **0/0/0/0** |
| linha em branco antes do apelido | 0/0/0/0 | 0/0/0/0 |
| linha só de espaços | 0/1/0/0 @1 | 0/0/0/0 |

Nenhuma outra parte da rede apanha o caso da linha em branco: o pedaço que fica no fim da primeira linha não chega ao mínimo do
corte, e o nome sem a preposição não casa porque a preposição está lá.

## 4. O README

Mudei o `provas/ordem-caixa-relato/README.md` em três sítios:

- **No J10:** ficou «**Travado desde a F114** (opção 1 da F108): qualquer separador à volta da palavra do meio casa no
  máximo uma quebra de linha. A quebra de linha pode estar antes ou depois da palavra do meio, ou nos dois lados (o
  nome partido por 3 linhas continua a contar), **nunca uma linha em branco** (nem uma linha só de espaços)…».
- **Um «Limite (F114, J10)»** a seguir ao «Limite (F97)», com a mesma frase e porque a linha em branco não dá
  suspeito.
- **Nos usos:** «corre 28 verificações». A lista do que o auto-teste cobre ganhou a linha da F114, e a lista das
  dependências das fichas (F96) também: os 2 casos novos precisam de o nome n.º 1 ter uma preposição da lista no meio.

## 5. Os números, antes e depois

| prova | antes (`5bf8ca1`) | depois (`5554637`) |
|---|---|---|
| auto-teste do `redigir-nomes` (PC) | **26/26** (a base da F97, confirmada antes da obra) | **28/28**, rc=0 |
| reprodução da F51 (`reproduzir-redaccao-f25.sh`, PC) | 10/11, a COBERTURA-CORRECOES-6 difere na linha 6 (3500 contra 3473 bytes) — F108 §2 | **10/11, a mesma linha 6** (3500 contra 3473 bytes), rc=1; nos 11, a rede dá 0/0/0/0 |
| canário `teste_nomes_relato.gd` (PC, Godot 4.7.2 Windows) | 26/26 | **26/26**, rc=0, 0 `SCRIPT ERROR`/`Parse Error`/`Compile Error` |
| a saída do canário redigida contra o registo limpo (PC) | igual (3473; 3437 sem os CR) | **igual byte a byte (3473 bytes; 3437 sem os CR)** |
| `rodar_testes` (CI, `cliente` e `godot-cliente`) | 321/321 | **321/321** nos dois |
| `caixa_janela` (CI) | 123/123 | **123/123** |
| `caixa_jogadora` (CI) | 70/70 | **70/70** |
| mutação da CAIXA-JANELA-CI (CI) | 114/123, 9 falhas da B6 | **«114 de 123»**, «MUTACAO APANHADA: 9 falhas, todas do assert B6» |
| CI | Testes 45173473001 + Sonda 45173473055 verdes (ponta `5bf8ca1`) | **Testes 45176723664 + Sonda 45176723680: 10/10 jobs verdes e a Sonda verde** |

**O CI da ponta da obra (`5554637`).** Os 10 jobs verdes são `servidor`, `validador-glb`, `motor-real`, `protocolo`,
`cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`, `foto-mestre` e `retoma-pc`. Li o log do job `cliente`
(job 137699771208, 2164 linhas). O passo da F51 correu:

- «auto-teste do redigir-nomes: **28 de 28** verificações passaram.»;
- o registo da COBERTURA-CORRECOES-6 «**igual byte a byte** ao redigido (3437 bytes, sem os CR)»;
- canário «26 de 26».

**Nomes inteiros nos logs do CI:** 0 + 0 no log do job `cliente` e 0 + 0 no do `godot-cliente`. Contei os dois
nomes das fichas sem distinguir maiúsculas, nos logs descarregados para `tmp/`, fora do repo.

**Não reproduzi 11/11, como a ordem manda.** O ponto aberto 2 da F97 continua por decidir.

## 6. A privacidade, re-derivada

- **0 nomes verdadeiros inteiros** nos ficheiros cometidos por esta ordem (a ferramenta, o README e este
  ESTADO-FINAL). Contei com o `suspeitos()` da ferramenta.
- **0 valores de PIN.** Esta ordem não usa PIN e não há nenhum `--pin=` com valor nestes ficheiros.
- **O conferidor** (`conferir-registo.mjs`, critério alargado / antigo):
  - a ferramenta deu **2/2** e o README **34/30**, os mesmos números da ponta de partida;
  - na primeira redacção deram 6 e 36/32. Os achados a mais eram uma palavra corrente de 4 letras que eu tinha
    escrito, e que coincide com 4 letras seguidas de um nome das fichas. Troquei-a por «qualquer», e os números voltaram
    aos de partida;
  - este ESTADO-FINAL deu **0/0**, depois de reescrever duas frases que tinham pedaços de palavras correntes.
- **Ficou fora do repo**, no `tmp/` da pasta da ordem: os casos montados, os registos de antes (com os nomes), o
  mutante, os logs do canário e os do CI.

**SHAs e listas da retoma.** Mudaram dois ficheiros: `redigir-nomes.mjs` e o README do `ordem-caixa-relato`. Procurei
no repo os sha256 e os blobs antigos dos dois e não os encontrei em lado nenhum. O `MANIFESTO-SHA256.txt` e as listas
da retoma (`retoma-i0004/antes.txt`, `depois.txt`) não citam nada de `provas/ordem-caixa-relato/`. **Não havia
nada a sincronizar.**

## 7. Pontos abertos

1. **A conferência da F108 está a rever a decisão** (opção 1). Se a sentença mandar a opção 2 ou a 3, o padrão e os
   2 casos mudam numa ordem nova:
   - na opção 2, o caso (a) passa a afirmar 0;
   - na opção 3, o caso (b) passa a afirmar rc=3 e volta o `\s+`.
2. **A reprodução continua 10/11** (o ponto aberto 2 da F97), como a ordem já previa.
3. **Ficam por aplicar** o remendo da guarda do CI e a regeneração do log da mutação da F51 (pontos abertos 1 e 4 da
   F97). Não são desta ordem e não lhes toquei.
4. **A sentença e o JUIZ da F88–F96 continuam sem estar neste PC** (F108 §1).

## 8. Commits

1. `5554637` — a obra: o padrão, os 2 casos e o README (sobre `5bf8ca1`).
2. Este ESTADO-FINAL (sobre `5554637`).
3. A nota do CI da ponta do commit 2, acrescentada no fim deste ficheiro.

## 9. Nota do CI — ponta `90ac1a0` (este ESTADO-FINAL)

Testes **45177537605** + Sonda **45177537526**: **10/10 jobs verdes e a Sonda verde**, com o passo da F51 a correr.
No log do job `cliente` (job 137702565444, 2179 linhas):

- canário 26/26;
- «auto-teste do redigir-nomes: **28 de 28** verificações passaram.»;
- o registo da COBERTURA-CORRECOES-6 «**igual byte a byte** ao redigido (3437 bytes, sem os CR)»;
- `rodar_testes` 321/321 (também no `godot-cliente`), `caixa_janela` 123/123, `caixa_jogadora` 70/70;
- a mutação deu «114 de 123» e «MUTACAO APANHADA: 9 falhas, todas do assert B6».

**Nomes inteiros nos logs:** 0 + 0 no log do `cliente` e 0 + 0 no do `godot-cliente` (contagem refeita sem distinguir
maiúsculas). O commit desta nota só acrescenta esta secção a este ficheiro.
