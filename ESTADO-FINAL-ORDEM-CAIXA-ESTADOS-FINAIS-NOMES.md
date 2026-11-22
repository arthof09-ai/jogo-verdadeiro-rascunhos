# ESTADO FINAL — ORDEM CAIXA-ESTADOS-FINAIS-NOMES (Claude conta 1, PC · 22/11/2026)

A emenda B1 (decisão da bancada de 22/11/2026, O1 da TESTES-14): os dois ESTADO-FINAL da raiz que guardavam os nomes
verdadeiros inteiros passam à redacção «n.º».

- **Linha:** trabalho directo em `fable/integracao-50`, sem ramo lateral nem fusão.
- **Base:** `766060f`, a ponta da linha à hora do lançamento. O `fetch` antes de publicar não trouxe nada novo: a linha
  não avançou durante a ordem, e o `rebase` não teve nada a fazer.
- **Commits:**
  - `18a46bf`: a emenda dos dois ficheiros;
  - o commit deste ESTADO-FINAL, que só acrescenta este ficheiro.
- **Território:** só `ESTADO-FINAL-ORDEM-CAIXA-JANELA-NOMES.md` e `ESTADO-FINAL-ORDEM-CAIXA-JANELA-NOMES-CORRECOES.md`
  (mais este ESTADO-FINAL). Nenhum `.gd`, nenhum `relato.txt`, nenhum `mutacoes.log`, nenhum outro `.md`.
- **A numeração.** «n.º 1» e «n.º 2» seguem a numeração do conferidor estrito (a ordem dos nomes verdadeiros nas fichas
  de teste): o n.º 1 tem 16 caracteres, o n.º 2 tem 15. Bate com a medida da bancada (l. 47 do 1.º ficheiro: o n.º 1;
  l. 48 e 50: o n.º 2).

## 1. B1 — o que mudou

**`ESTADO-FINAL-ORDEM-CAIXA-JANELA-NOMES.md`** (7 linhas):
- l. 9: os dois nomes inteiros passam a «os nomes verdadeiros n.º 2 e n.º 1»;
- l. 47–48: a citação literal da linha suja do §3 e do resultado da asserção passa a descrição (uma linha «bancada:»
  suja com o nome n.º 1 dá um só achado, o n.º 1 na linha 5); o nome n.º 2 dentro de JSON, idem;
- l. 50 e l. 56: o 1.º achado do §4 / da mutação passa a «o nome n.º 2 na linha 7»;
- l. 64: «0 nomes verdadeiros (n.º 1 / n.º 2) no relato»;
- l. 72: os dois nomes públicos das criaturas (pedaços dos verdadeiros) passam a «os nomes públicos das duas criaturas».

**`ESTADO-FINAL-ORDEM-CAIXA-JANELA-NOMES-CORRECOES.md`** (8 linhas):
- l. 36: o canário mudado passa a descrição («o nome n.º 2 com a preposição trocada»);
- l. 48–49: as asserções do §4 citadas como código passam a descrição («que há 22 achados», «que o 1.º achado é o nome
  n.º 2 na linha 7»);
- l. 52: «4 vezes o nome n.º 2 e 4 vezes o nome n.º 1»;
- l. 89–90: o rótulo citado (que trazia o nome público de uma criatura) passa a descrição;
- l. 141: como a l. 64 do outro ficheiro;
- l. 150: como a l. 72 do outro ficheiro.

O número de linhas dos dois ficheiros não mudou (105 e 183); as referências de linha de outros documentos continuam a
bater.

## 2. A prova — conferidor estrito (`provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`)

| Ficheiro | Critério | Inteiros antes → depois | Achados antes → depois |
|---|---|---|---|
| `…-CAIXA-JANELA-NOMES.md` | alargado | **7 → 0** (l. 9 ×2, 47, 48, 50, 56, 64) | 28 → 20 |
| `…-CAIXA-JANELA-NOMES.md` | antigo (`--velho`) | **7 → 0** | 28 → 20 |
| `…-CAIXA-JANELA-NOMES-CORRECOES.md` | alargado | **5 → 0** (l. 36, 49, 52 ×2, 141) | 34 → 29 |
| `…-CAIXA-JANELA-NOMES-CORRECOES.md` | antigo (`--velho`) | **5 → 0** | 32 → 27 |

«Inteiros» = achados que o conferidor marca «(o nome inteiro)». Os achados que restam são todos palavras comuns do
texto que partilham 4 ou mais letras com os nomes: a palavra que designa as fichas e criaturas de teste (sozinha ou
precedida de «de»), um pronome indefinido de 4 letras, o adjectivo que qualifica as ocorrências não agrupadas, no plural e um fim de palavra
seguido de «de». Nenhum é um nome, nem um pedaço de nome cortado a meio; tirá-los obrigava a reescrever o vocabulário
dos relatórios, e não os toquei.

O conferidor também passou sobre este ESTADO-FINAL (§3).

## 3. Corridas (PC; Node 26.13; Python da casa)

| Corrida | Resultado |
|---|---|
| Conferidor nos dois ficheiros, antes (`766060f`) | ver §2 |
| Conferidor nos dois ficheiros, depois (`18a46bf`) | ver §2 |
| Conferidor sobre este ESTADO-FINAL, nos dois critérios | **0 inteiros** nos dois critérios; 12 achados, todos palavras comuns (a palavra que designa a conferência e as fichas de teste, e o pronome indefinido) |
| `retoma-i0004/actualizar-listas.py` | antes.txt 37 · depois.txt 415 · MANIFESTO 459 ficheiros, **0 novos, 0 tirados**; `git status` sem mudanças nas listas |
| CI da ponta | ver §5 |

## 4. Pontos para o coordenador

1. **A sede não era um checkout.** Tinha só a ordem e o lançador. Clonei `fable/integracao-50` para `repo/` dentro da
   sede, como as ordens anteriores (`ordem-caixa-testes-correcoes-14/repo`).
2. **Ainda há nomes verdadeiros inteiros noutros `.md` cometidos**, fora do território desta ordem (não lhes toquei).
   Linhas com um nome inteiro, pelo conferidor estrito: `provas/ordem-caixa-janela/README.md` (3),
   `provas/ordem-caixa-hud-jogadora/README.md` (2), `provas/ordem-autojogo/resumo.md` (2). Se a bancada quer o mesmo
   critério nos READMEs, é uma ordem irmã desta.
3. **Os achados residuais (§2) são falsos positivos do critério de fragmentos** sobre vocabulário corrente. Se a bancada
   quiser «achados → 0» nos relatórios, o conferidor precisa de uma lista de palavras comuns isentas, ou os relatórios
   de deixar de usar essa palavra.
4. Os logs crus (`relato.txt`, `mutacoes.log`) continuam com os nomes, como a ordem manda.
5. Sigo a regra de privacidade: este ficheiro não leva nenhum nome verdadeiro nem PIN; refere-se a eles só pelo n.º.
6. O `ORDEM.md` da sede não foi mexido; termina com a linha exacta «Estado: NOVA».

## 5. CI

A preencher depois do `push` (commit seguinte).
