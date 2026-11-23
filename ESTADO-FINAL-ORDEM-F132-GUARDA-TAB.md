# ESTADO-FINAL — Ordem F132 (guarda do tabulador antes da palavra do meio, follow-up da F116)

**Estado: FEITA.** O auto-teste ganhou um caso: a linha só com um tabulador antes da palavra do meio. O caso passa com o
padrão cometido, e o auto-teste vai de 30/30 para **31/31**. O README do J10 diz agora que **o tabulador conta como
espaço em branco**. A ferramenta **não mudou de comportamento**: a reprodução continua **10/11, com a mesma linha 6**,
o canário continua **26/26** e o CI da ponta da obra deu **10/10 + Sonda**.

- **Executor:** Claude (opus), PC, conta 2. **Data:** 23/11/2026.
- **Linha:** `fable/integracao-50`, trabalho directo. **`HEAD` de partida:** `ba9a2a4` (a nota do CI da F109), num clone
  novo em `ordem-f132-guarda-tab-pc/repo`. A F128 (`77ba415`) entrou na linha durante a obra. Fiz o rebase por cima
  dela sem conflitos e voltei a medir tudo depois do rebase.
- **Obra:** `ba165e3`, com 2 ficheiros (8 linhas a mais, 2 a menos).

## 0. Desvio dos números da ordem: 30/30 → 31/31, e não 29/29 → 30/30

A ordem foi escrita com a base 29/29, a da F116. Quando parti, a ponta já tinha a F109 (`8ac126c`), que juntou o caso
do J9-antes. Por isso, a base medida na ponta `ba9a2a4` deu **30 de 30**, rc=0. O caso desta ordem é o único caso
novo, e o auto-teste fica em **31/31**. O critério da ordem, «+1 caso, todos passam», fica cumprido. Só o número
absoluto muda.

## 1. O caso novo e o resultado medido

Em `provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs`, logo a seguir ao caso da F116. Monta-se em memória a
partir das fichas, como os outros:

| caso | texto montado (as partes do nome n.º 1) |
|---|---|
| **F132 (novo)** | `fim: <início>\n\t\n<preposição> <apelido> segue` (só um tabulador na linha do meio) |
| F116, posição 1 (a referência) | `fim: <início>\n  \n<preposição> <apelido> segue` (dois espaços na linha do meio) |

A descrição no auto-teste diz: «F132 (J10 travado): o nome n.º 1 partido por uma linha só com um tabulador antes da
palavra do meio dá o mesmo que a linha só de espaços (não se redige; 0 variantes)».

**O que o caso afirma:**

- o texto não se redige;
- o resultado da rede (`inteiros|variantes|cortes|linhas`) é **igual** ao da linha só de espaços da F116;
- a rede dá **0 variantes**.

**O resultado esperado foi medido, não inventado.** Medi-o com a ferramenta cometida, antes de escrever o caso. O
guião de medida está fora do repo, em `tmp/medir.mjs`, e só imprime contagens:

| linha do meio, antes da palavra do meio | não se redige | inteiros / variantes / cortes |
|---|---|---|
| dois espaços (F116, posição 1) | sim | 0 / **0** / 0 |
| **só um tabulador (F132)** | sim | 0 / **0** / 0 |
| tabulador e espaço | sim | 0 / 0 / 0 |
| linha em branco (F114) | sim | 0 / 0 / 0 |
| controlo: quebra de linha simples (J10) | sim | 0 / 1 (linha 1) / 0 |
| controlo: tabulador na mesma linha, sem quebra | sim | 0 / 1 (linha 1) / 0 |

O tabulador dá exactamente o mesmo que a linha só de espaços. Bate com o facto que a conferência da F116 mediu.

**O caso tem dentes.** Fiz um mutante fora do repo (`tmp/mutante-tab.mjs`, feito por `tmp/fazer-mutante.mjs`): o `S`
da linha 162 com o grupo `(?:\\t\\n)?` inserido depois do `\\n?`. Esse padrão deixa a variante atravessar uma linha só
com um tabulador, mas continua a barrar a linha só de espaços.

- Com o mutante, o auto-teste dá **30 de 31**, rc=1. **Só o caso novo falha.** A F116 continua a passar, porque a sua
  posição 2 é `" \t "` e não um tabulador sozinho. Com o mutante, a medida do tabulador sozinho dá 1 variante.
- Com a ferramenta cometida, o auto-teste dá **31 de 31**, rc=0.

## 2. A frase no README

A frase está em `provas/ordem-caixa-relato/README.md`, na entrada **J10** da lista da rede, a seguir a «…partido por
uma linha em branco, deixa de contar»:

> Desde a F132, **o tabulador conta como espaço em branco** (não é quebra de linha): uma linha só com um tabulador é
> uma linha só de espaços;

Além da frase, mudei um número para o README continuar certo: nos usos, «corre **31** verificações» (antes dizia 30).
**Não mexi:**

- na frase do «Limite (F114, J10)», que é da F128 (o rebase confirma que as duas obras não se tocam);
- no alvo da comparação da reprodução, que é da F122.

Também não juntei linhas à lista do que o auto-teste cobre nem à das dependências das fichas, porque a ordem pede uma
frase só. Ver o ponto aberto 1.

## 3. Os números, antes e depois

| prova | antes (`ba9a2a4`) | depois (`ba165e3`) |
|---|---|---|
| auto-teste do `redigir-nomes` (PC) | **30/30**, rc=0 | **31/31**, rc=0 (o mutante dá 30/31) |
| reprodução da F51 (`reproduzir-redaccao-f25.sh`, PC) | 10/11, linha 6 | **10/11, a mesma linha 6** (3500 contra 3473 bytes), rc=1; nos 11 registos a rede dá 0/0/0/0 |
| canário `teste_nomes_relato.gd` (PC, Godot 4.7.2 Windows) | 26/26 | **26/26**, rc=0, 0 `SCRIPT ERROR`/`Parse Error`/`Compile Error` |
| saída do canário, redigida, contra `cobertura-correcoes-6/teste-nomes-relato.log` | igual | **igual byte a byte** (3473 bytes; 3437 sem os CR) |
| `rodar_testes` (CI, `cliente` e `godot-cliente`) | 321/321 | **321/321** nos dois |
| `caixa_janela` / `caixa_jogadora` (CI) | 123/123 / 70/70 | **123/123 / 70/70** |
| mutação da CAIXA-JANELA-CI (CI) | 114/123 | **«114 de 123»**, «MUTACAO APANHADA: 9 falhas, todas do assert B6» |
| CI | — | **Testes 45195587170 + Sonda 45195587003: 10/10 jobs verdes e a Sonda verde** |

**A nota do CI (ponta `ba165e3`).** Os 10 jobs verdes foram `servidor`, `validador-glb`, `motor-real`, `protocolo`,
`cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`, `foto-mestre` e `retoma-pc`. Li o log do job `cliente`
(job 137765042180, 2150 linhas). O passo da F51 correu:

- «auto-teste do redigir-nomes: **31 de 31** verificações passaram»;
- o registo da COBERTURA-CORRECOES-6 deu «**igual byte a byte** ao redigido (3437 bytes, sem os CR)»;
- o canário deu «26 de 26».

**Nomes inteiros nos logs do CI:** 0 + 0 no `cliente` e 0 + 0 no `godot-cliente` (sem distinguir maiúsculas). Os logs
estão fora do repo, em `tmp/`.

## 4. A privacidade

- **0 nomes verdadeiros inteiros** nos dois ficheiros da obra, no diff e neste ESTADO-FINAL. Contei com o
  `suspeitos()` da ferramenta e também sem distinguir maiúsculas: 0/0/0/0.
- **O conferidor** (`conferir-registo.mjs`, critério alargado) dá **2** achados na ferramenta e **34** no README. São os
  mesmos números da ponta de partida: a obra não juntou nada.
- **0 valores de PIN.** Esta ordem não usa PIN.
- **Fora do repo**, em `tmp/` da pasta da ordem: os guiões de medida, o mutante, a reprodução com os registos de antes
  (que trazem os nomes), o log do canário e os logs do CI.
- **SHAs e listas da retoma:** o `MANIFESTO-SHA256.txt` e `retoma-i0004/` não citam nada de
  `provas/ordem-caixa-relato/`, tal como a F116 já tinha verificado. Não havia nada a sincronizar.

## 5. Pontos abertos

1. **O README só tem a frase pedida.** A lista do que o auto-teste cobre e a lista das dependências das fichas (F96)
   não falam do caso F132. O caso depende da mesma condição que a F116: o nome n.º 1 tem de ter uma preposição da
   lista no meio. Se o coordenador quiser as duas linhas, juntam-se numa ordem à parte.
2. **A reprodução continua 10/11.** A decisão sobre o alvo é da F122.

## 6. Commits

1. `ba165e3` — a obra: o caso novo e a frase no README (sobre `77ba415`, a F128).
2. Este ESTADO-FINAL.
