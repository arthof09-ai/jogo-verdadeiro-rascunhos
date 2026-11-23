# ESTADO-FINAL — Ordem F116 (linha só de espaços — caso de guarda + frase no README, da sentença da F108)

**Estado: FEITA.** O auto-teste ganhou o caso de guarda da linha só de espaços e passa de 28/28 para **29/29**. O
README diz agora «uma linha só com espaços conta como linha em branco». A ferramenta **não mudou de comportamento**: a
reprodução continua **10/11, com a mesma linha 6**, o canário continua **26/26** e o CI da ponta da obra deu **10/10 +
Sonda**.

- **Executor:** Claude (opus, esforço médio), PC do cunhado, conta 1. **Data:** 23/11/2026.
- **Linha:** `fable/integracao-50`, trabalho directo, sem ramos laterais. **`HEAD` de partida:** `49d6fbe` (a nota do
  CI da F114), clone novo e limpo em `ordem-f116-linha-espacos-pc/repo`. A ponta traz a F114 (`5554637`).
- **Base confirmada antes da obra:** o auto-teste da ponta `49d6fbe` deu **28 de 28**, rc=0.
- **Biblioteca (GameDev Kit):** não construí nada de raiz. A obra junta 1 caso ao auto-teste que já existe e uma frase
  ao README.
- **A sentença** (`~/workspace/conferencias/f108-travar-j10/SENTENCA.md`) **não está neste PC**: não há `~/workspace`
  (como já a F108 §1 registou). Segui o resumo da ordem. Ver o ponto aberto 1.

## 1. O caso novo e o que afirma

Em `provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs`, logo a seguir ao caso (b) da F114 (linha em branco).
Monta-se em memória a partir das fichas, como os outros:

| posição | texto montado (as partes do nome n.º 1) |
|---|---|
| antes da palavra do meio | `fim: <início>\n  \n<preposição> <apelido> segue` (dois espaços na linha do meio) |
| antes do apelido | `fim: <início> du\n \t \n<apelido> segue` (espaço, tabulador, espaço na linha do meio) |

**O que afirma**, nas duas posições: o texto **não se redige** (fica igual) e a rede dá **0 variantes**. Ou seja, a
linha só de espaços conta como linha em branco, e a variante não a atravessa.

A descrição no auto-teste: «F116 (J10 travado): o nome n.º 1 partido por uma linha só de espaços (antes da palavra do
meio, ou a variante «du» antes do apelido) não se redige e NÃO conta como variante (0 variantes nas duas posições; a
travagem tem dentes)».

**Porquê a variante «du» antes do apelido.** Com a preposição verdadeira, a linha de cima acaba em «início +
preposição», e a redacção já a redige como corte na origem. A rede ficaria calada com qualquer padrão, e o caso não
teria dentes nessa posição. Com «du», o texto não se redige e só a travagem decide. Medi as duas formas, com o padrão
antigo (ponta `5bf8ca1`) e com o da F114:

| caso | padrão antigo (`\s+`) | padrão da F114 |
|---|---|---|
| linha só de espaços antes da palavra do meio | igual, **1 variante** | igual, **0** |
| idem, com um tabulador | igual, 1 | igual, 0 |
| linha só de espaços antes do apelido, preposição verdadeira | redige-se (corte), 0 | redige-se (corte), 0 |
| linha só de espaços antes do apelido, variante «du» | igual, **1 variante** | igual, **0** |

A 1.ª linha bate com a tabela da F108 (linha só de espaços: 1 @1 na ponta antiga, 0 no protótipo A).

**O caso tem dentes.** Corri o auto-teste com dois mutantes, ambos fora do repo (`tmp/` da pasta da ordem):

- **o padrão antigo** (a linha 158 da `5bf8ca1`): **27 de 29**. Falham o caso (b) da F114 e o caso novo;
- **um padrão que barra a linha em branco mas deixa passar a linha só de espaços** (o `S` com o grupo `(?:\n[^\S\n]+)?` inserido antes do `\n?`): **28 de 29**. O caso da F114 passa, e só o caso novo falha. É exactamente o buraco que
  esta guarda tapa.

Com a ferramenta cometida: **29 de 29**, rc=0.

## 2. A frase no README

`provas/ordem-caixa-relato/README.md`, no «**Limite (F114, J10)**» (linha 561), logo a seguir à frase da F114 sobre a
quebra de linha («…ou nos dois lados, **nunca uma linha em branco**.»). A linha exacta passa a começar assim:

> **Limite (F114, J10).** A variante partida por quebra de linha só conta se a quebra de linha estiver antes ou depois
> da palavra do meio, ou nos dois lados, **nunca uma linha em branco**. Desde a F116 (sentença da F108), **uma linha só
> com espaços conta como linha em branco**, antes da palavra do meio ou antes do apelido. …

e acaba em «O auto-teste afirma-o (0 variantes), e desde a F116 também para a linha só de espaços (0 variantes nas duas
posições).».

Mudei mais três sítios, para o README não mentir:

- nos usos, «corre **29** verificações» (era 28);
- na lista do que o auto-teste cobre, uma linha «desde a F116»;
- na lista das dependências das fichas (F96), o caso novo também precisa de o nome n.º 1 ter uma preposição da lista no
  meio.

O J10 já dizia «(nem uma linha só de espaços)» desde a F114. Não lhe toquei.

## 3. Os números, antes e depois

| prova | antes (`49d6fbe`) | depois (`209bbf8`) |
|---|---|---|
| auto-teste do `redigir-nomes` (PC) | **28/28** (a base da F114, confirmada antes da obra) | **29/29**, rc=0 |
| reprodução da F51 (`reproduzir-redaccao-f25.sh`, PC) | 10/11, linha 6 (F114) | **10/11, a mesma linha 6** (3500 contra 3473 bytes), rc=1; nos 11, a rede dá 0/0/0/0 |
| canário `teste_nomes_relato.gd` (PC, Godot 4.7.2 Windows) | 26/26 | **26/26**, rc=0, 0 `SCRIPT ERROR`/`Parse Error`/`Compile Error` |
| a saída do canário redigida contra o registo limpo (PC) | igual (3473; 3437 sem os CR) | **igual byte a byte (3473 bytes; 3437 sem os CR)** |
| `rodar_testes` (CI, `cliente` e `godot-cliente`) | 321/321 | **321/321** nos dois |
| `caixa_janela` (CI) | 123/123 | **123/123** |
| `caixa_jogadora` (CI) | 70/70 | **70/70** |
| mutação da CAIXA-JANELA-CI (CI) | 114/123 | **«114 de 123»**, «MUTACAO APANHADA: 9 falhas, todas do assert B6» |
| CI | Testes 45177537605 + Sonda 45177537526 (ponta `90ac1a0`) | **Testes 45179766279 + Sonda 45179766283: 10/10 jobs verdes e a Sonda verde** |

**Não exigi 11/11 nem mudei o alvo da comparação**, como a ordem manda: o ponto aberto 2 da F97 é do coordenador
(F122).

**O CI da ponta da obra (`209bbf8`).** Os 10 jobs verdes são `servidor`, `validador-glb`, `motor-real`, `protocolo`,
`cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`, `foto-mestre` e `retoma-pc`. Li o log do job `cliente`
(job 137710231365, 2148 linhas). O passo da F51 correu:

- «auto-teste do redigir-nomes: **29 de 29** verificações passaram»;
- o registo da COBERTURA-CORRECOES-6 «**igual byte a byte** ao redigido (3437 bytes, sem os CR)»;
- canário «26 de 26».

**Nomes inteiros nos logs do CI:** 0 + 0 no log do `cliente` e 0 + 0 no do `godot-cliente` (os dois nomes das fichas,
sem distinguir maiúsculas, nos logs descarregados para `tmp/`, fora do repo).

## 4. A privacidade, re-derivada

- **0 nomes verdadeiros inteiros** nos ficheiros cometidos por esta ordem (a ferramenta, o README e este
  ESTADO-FINAL). Contei com o `suspeitos()` da ferramenta.
- **0 valores de PIN.** Esta ordem não usa PIN e não há nenhum `--pin=` com valor nestes ficheiros.
- **O conferidor** (`conferir-registo.mjs`, critério alargado / antigo): a ferramenta dá **2/2** e o README **34/30**,
  os mesmos números da ponta de partida. Este ESTADO-FINAL dá **0/0**.
- **Ficou fora do repo**, no `tmp/` da pasta da ordem: os guiões de medida, os dois mutantes, os registos de antes
  (com os nomes), os logs do canário e os do CI.

**SHAs e listas da retoma.** Mudaram dois ficheiros: `redigir-nomes.mjs` e o README do `ordem-caixa-relato`. Procurei
no repo os sha256 e os blobs antigos dos dois e não os encontrei. O `MANIFESTO-SHA256.txt` e as listas da retoma
(`retoma-i0004/`) não citam nada de `provas/ordem-caixa-relato/`. **Não havia nada a sincronizar.**

## 5. Pontos abertos

1. **A sentença da F108 não está neste PC.** Li «as duas posições» como antes da palavra do meio e antes do apelido. A
   tabela da F108 só mediu a linha só de espaços antes da palavra do meio, e lá «0» aparece nas duas colunas dos
   protótipos (A e B). Se a sentença queria dizer as duas colunas, o caso continua certo (a posição antes da palavra do
   meio é a medida), e a posição antes do apelido é uma guarda a mais. Se a sentença disser outra coisa, o coordenador
   confirma.
2. **A reprodução continua 10/11** (o ponto aberto 2 da F97; a decisão do alvo é da F122).
3. **Ficam por aplicar** o remendo da guarda do CI e a regeneração do log da mutação da F51 (pontos abertos 1 e 4 da
   F97). Não são desta ordem e não lhes toquei.

## 6. Commits

1. `209bbf8` — a obra: o caso novo e o README (sobre `49d6fbe`).
2. Este ESTADO-FINAL (sobre `209bbf8`).
3. A nota do CI da ponta do commit 2, acrescentada no fim deste ficheiro.

## 7. Nota do CI — ponta `0c721cf` (este ESTADO-FINAL)

Testes **45180476469** + Sonda **45180476063**: **10/10 jobs verdes e a Sonda verde**, com o passo da F51 a correr.
No log do job `cliente` (job 137712666092, 2152 linhas):

- canário 26/26;
- «auto-teste do redigir-nomes: **29 de 29** verificações passaram»;
- o registo da COBERTURA-CORRECOES-6 «**igual byte a byte** ao redigido (3437 bytes, sem os CR)»;
- `rodar_testes` 321/321 (também no `godot-cliente`), `caixa_janela` 123/123, `caixa_jogadora` 70/70;
- a mutação deu «114 de 123» e «MUTACAO APANHADA: 9 falhas, todas do assert B6».

**Nomes inteiros nos logs:** 0 + 0 no log do `cliente` e 0 + 0 no do `godot-cliente` (sem distinguir maiúsculas).
A procura da `SENTENCA.md` no disco deste PC também não a encontrou (a busca foi parada pelo limite de tempo, sem
resultado). O commit desta nota só acrescenta esta secção a este ficheiro.


## Nota do CI (fusão C-J1)

Fusão C-J1 (commit 8124dce): Testes dos rascunhos 45188835973 — SUCCESS; Sonda de privacidade 45188835851 — SUCCESS. 11/11.
