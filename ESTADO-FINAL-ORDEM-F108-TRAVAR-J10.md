# ESTADO-FINAL — Ordem F108 (travar o J10, da sentença da F88–F96)

**Estado: PARADA ANTES DA OBRA.** A ordem contradiz-se num ponto, e a regra da casa manda parar e escrever o ponto
aberto em vez de inventar a decisão (§3). **Não mudei a ferramenta, nem o README, nem o auto-teste.** O único
ficheiro deste commit é este ESTADO-FINAL.

- **Executor:** Claude (opus, esforço médio), PC do cunhado, conta 1. **Data:** 23/11/2026.
- **Linha:** `fable/integracao-50`. **`HEAD` de partida:** `4ca3812` (a nota do CI da F97, filha de `d602848`), clone
  novo e limpo.

## 1. O que li e o que não encontrei

- **A sentença e o JUIZ não estão neste PC.** `~/workspace/conferencias/f88-f96-redigir-nomes/` não existe, e uma busca
  pelo disco não achou nenhum `SENTENCA-F88*`. Segui o resumo da ordem e o §7, ponto 5, do
  `ESTADO-FINAL-ORDEM-F88-F96-REDIGIR-NOMES.md`. Lá está o caso das 3 linhas: uma linha que acaba no nome
  público, uma linha só com a palavra do meio e uma linha que começa pelo apelido.
- **O padrão em causa** (`provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs`, linha 158, em `reVariantesFora`):

  ```js
  res.push(new RegExp(`(?<!\\p{L})${antes}\\s+[\\p{L}'’]+(?:-[\\p{L}'’]+)*(?:\\p{P}+\\s*|\\s+)${depois}(?!\\p{L})`, 'giu'));
  ```

  O `\s+` antes da palavra do meio e o `\s+` (ou o `\p{P}+\s*`) depois dela casam qualquer número de quebras de linha,
  e por isso também a linha em branco.

## 2. A base, confirmada

| prova | na partida (`4ca3812`) |
|---|---|
| auto-teste do `redigir-nomes` | **26 de 26** (rc=0). A base da F97 confirma-se |
| os 11 registos limpos (`reproduzir-redaccao-f25.sh`) | **10 de 11** iguais byte a byte, rc=1. A COBERTURA-CORRECOES-6 difere na linha 6. É o ponto aberto 2 da F97 (a regeneração), não é coisa desta ordem |
| a rede nos 11 registos de antes, redigidos | inteiros/variantes/cortes/nome sem a preposição = 0/0/0/0 |

Não corri o canário, as suites do Godot nem o CI: sem obra, não há nova ponta de código a provar.

## 3. O ponto que me fez parar

**Os itens 1 e 3 não se podem cumprir os dois no caso da linha em branco.**

- **O item 1** manda restringir a variante para que «não atravesse mais de uma quebra de linha **nem uma linha em
  branco**».
- **O item 3** diz: «Na rota 1, os dois casos [3 linhas e linha em branco] **têm de continuar a ser apanhados
  (rc=3)** com a travagem posta.»

Uma variante que a travagem impede de atravessar a linha em branco deixa, por definição, de ser apanhada nesse caso.
Também nenhuma outra parte da rede a apanha: a linha de cima acaba num pedaço do nome que não chega ao mínimo do corte, que é
a premissa do J10.

**No caso das 3 linhas, o item 1 diz duas coisas diferentes.**

- **O texto** diz «não atravesse mais de uma quebra de linha». Lido assim, a variante toda tem no máximo um `\n`, e o
  caso das 3 linhas (dois `\n`) deixa de ser apanhado.
- **O exemplo** diz «trocar o `\s+` à volta da palavra do meio por um separador que case no máximo um `\n`». Lido
  assim, qualquer um dos separadores tem no máximo um `\n`, e o caso das 3 linhas continua a ser apanhado.

### Medida: dois protótipos, fora do repo

Os protótipos estão no `tmp/` da pasta da ordem e não foram cometidos. Os casos montam-se a partir das fichas e a
medida só imprime contagens. Os números são as variantes contadas e a linha onde a variante começa.

| caso | ponta (`\s+`) | A: qualquer separador com no máximo um `\n` (o exemplo da ordem) | B: a variante toda com no máximo um `\n` (o texto da ordem) |
|---|---|---|---|
| J10, LF (nome partido antes da preposição) | 1 @1 | 1 @1 | 1 @1 |
| J10, variante «du» partida depois dela | 1 @1 | 1 @1 | 1 @1 |
| J10, CRLF | 1 @2 | 1 @2 | 1 @2 |
| **3 linhas** (público / palavra do meio / apelido) | 1 @1 | **1 @1** | **0** |
| 3 linhas, com «du» | 1 @1 | 1 @1 | 0 |
| **linha em branco** antes da palavra do meio | 1 @1 | **0** | **0** |
| linha só de espaços antes da palavra do meio | 1 @1 | 0 | 0 |
| auto-teste actual | 26/26 | 26/26 | 26/26 |
| rede nos 11 registos | 0/0/0/0 | 0/0/0/0 | 0/0/0/0 |

**O padrão do protótipo A**, na mesma linha 158:

```js
const S = '(?=\\s)[^\\S\\n]*\\n?[^\\S\\n]*';
res.push(new RegExp(`(?<!\\p{L})${antes}${S}[\\p{L}'’]+(?:-[\\p{L}'’]+)*(?:\\p{P}+[^\\S\\n]*\\n?[^\\S\\n]*|${S})${depois}(?!\\p{L})`, 'giu'));
```

**O protótipo B** fica com o padrão de antes e salta, em `suspeitos()`, a ocorrência com mais de um `\n`.

**Leitura:** a rota 1 é viável tecnicamente, com A ou com B, e os casos já fechados (J8/J9/J10 principais, rc=3) não
mudam em nenhuma das duas. O que não é possível é a aceitação do item 3 na rota 1. Com A falha um dos dois casos (a
linha em branco), com B falham os dois.

## 4. A decisão que falta (ponto aberto para o coordenador)

Escolher **uma** destas, para a próxima corrida:

1. **Rota 1 com A** (o exemplo da ordem). O caso das 3 linhas fica a afirmar rc=3 e o da linha em branco passa a
   afirmar **0 variantes** (a travagem tem dentes). Corrige-se o item 3 para «3 linhas → rc=3; linha em branco → não
   conta». O README passa a dizer: «a quebra de linha pode estar antes ou depois da palavra do meio, ou nos dois lados,
   nunca uma linha em branco».
2. **Rota 1 com B** (o texto da ordem). Os dois casos passam a afirmar **0 variantes**. Corrige-se o item 3 para
   «nenhum dos dois conta». O §7, ponto 5, da F88–F96 deixa de valer.
3. **Rota 2** (documentar o alargamento). Os dois casos afirmam rc=3, como o item 3 está escrito, e o README diz que a
   variante pode atravessar 3 linhas e uma linha em branco. Mas a ordem só permite a rota 2 «se a rota 1 se provar
   inviável», e a rota 1 não é inviável. Só a aceitação dela é contraditória.

**A minha recomendação:** a opção 1. Bate com o exemplo da ordem e com o J10 como o README o descreve («o espaço à
volta da palavra do meio pode ser uma quebra de linha»). Mantém o caso das 3 linhas, que o §7, ponto 5, da F88–F96 já
confessava, e tira só a linha em branco, que ninguém tinha descrito. Em qualquer das três, o auto-teste passa de
26/26 para 28/28.

**Os outros pontos abertos:**

- **A reprodução já dá 10/11 na partida.** A ordem pede «continua a reproduzir os 11 registos limpos byte a byte».
  Enquanto o ponto aberto 2 da F97 não for decidido, a próxima corrida só pode provar «continua 10/11, com a mesma
  linha 6».
- **A sentença e o JUIZ não estão neste PC** (§1). Se o JUIZ (§3, D-J3) fixar a leitura das 3 linhas, isso decide
  entre a opção 1 e a 2.

## 5. Privacidade e listas

- **Este ficheiro tem 0 nomes verdadeiros inteiros e 0 valores de PIN.** O `sobram()` dá 0 inteiros, e o `conferir-registo.mjs` dá 0 achados no critério alargado e 0 no antigo. Duas frases tinham pedaços de 4 letras em palavras correntes e reescrevi-as. Os
  protótipos e o guião de medida ficaram fora do repo e só imprimem contagens. Os registos de antes, que trazem os nomes,
  ficaram em `tmp/repro/`, também fora do repo.
- **As listas da retoma:** este commit só junta este ficheiro, na raiz, e nenhum SHA de `rascunhos/` muda. Não há nada
  a sincronizar.

## 6. Commits

- Este ESTADO-FINAL, sobre `4ca3812`. Não há commit da obra nem nota do CI, porque não houve obra.
