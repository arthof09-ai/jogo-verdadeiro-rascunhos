# ESTADO-FINAL — ORDEM-CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES (22/11/2026)

> **Corrigido pela Ordem CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES-2** (C1 e C4): o cabeçalho, a secção B1 e o ponto 5 levam
> a marca «[GUIAO-FRAGIL-CORRECOES-2 Cn]». Ver `ESTADO-FINAL-ORDEM-CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES-2.md`.

**Executor:** conta 2.
**Ramo:** `claude2/caixa-testes-guiao-fragil-correcoes`, sobre `fable/integracao-50` @ `1b907bc` (a ponta à hora do
lançamento; ~~já contém a CAIXA-TESTES-GUIAO-FRAGIL, `3e096ee`~~ [GUIAO-FRAGIL-CORRECOES-2 C4] já contém a
CAIXA-TESTES-GUIAO-FRAGIL (forma rebaseda sobre a linha; `3e096ee` é a ponta original antes do rebase, não um antepassado)).
**Não fundido** — a fusão é do coordenador.
**Commits:** `b700bf4` (correcções B1–B3) e, por último, o das listas da retoma + este ESTADO-FINAL.

**Território mexido:** `rascunhos/servidor/testes/privacidade.test.mjs` (só um comentário: +3 linhas),
`ESTADO-FINAL-ORDEM-CAIXA-TESTES-GUIAO-FRAGIL.md`, as listas da retoma e este ficheiro. Nenhuma linha de lógica,
nada de código do jogo, nada de HUD, nada de cores.

## B1 (D2) — o relógio parado: o instante sai tarde demais

No ponto 4 dos «Pontos para o coordenador» do ESTADO-FINAL da GUIAO-FRAGIL, a frase «o instante sai cedo demais»
ficou riscada, e logo a seguir vem a correcção com a marca `[GUIAO-FRAGIL-CORRECOES B1]`: o instante sai **tarde
demais**. Com os `ts` todos empatados, `e.ts <= s.ts` é verdade para todos os eventos, e o `Math.max` dá o **último
evento do journal**. A conclusão prática não muda: em geral, a sanidade falha alto.
[GUIAO-FRAGIL-CORRECOES-2 C1] Na forma condicional, por extenso:
A sanidade compara contra uma ordem posterior: falha alto em geral, e só passaria calada se essa ordem posterior coincidisse de novo com a do snapshot.

*Prova:* `journalSeqDoSnapshot` (`privacidade.test.mjs` L127–132) faz
`for (const e of eventos()) if (e.ts <= s.ts) seq = Math.max(seq, e.journalSeq)`. Com um `ts` igual para todos, o
resultado é `journalSeq` máximo, ou seja, o fim. Equivale à mutação M2 da ordem anterior («devolve o fim do
journal»), que fez falhar o controlo B3.

*Nota de localização:* a ordem situa a frase em «L203–205». No ficheiro da ponta `1b907bc`, o ponto 4 está em
L113–114 (o ficheiro tem 121 linhas). A frase é só uma, por isso não há ambiguidade.

## B2 (D3) — o limite da guarda declarado no comentário

`privacidade.test.mjs`: o comentário que antecede a guarda `a ordem reconstruída do journal = a da sala` ganhou 3
linhas:

```js
  // Limite (CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES, B2): só compara o estado FINAL do journal. Um desvio num instante
  // intermédio que reconvirja até ao fim escapava a esta guarda; fica mitigado pelas mutações M1/M2/M5 da
  // CAIXA-TESTES-GUIAO-FRAGIL (o controlo B3 e a M5 mordem nos instantes intermédios).
```

*Prova:* `git diff` deste ficheiro tem 3 inserções e 0 remoções, todas linhas `//`. A suite dá o mesmo total de
antes (421/421; `privacidade` 11/11).

*Nota de localização:* a ordem situa a guarda «a ~L407–409 da ponta». Na ponta `1b907bc` a guarda está em L221–224,
dentro de `conferirCanariosDoMestre` (o ficheiro tem 434 linhas). Só há uma guarda com este nome.

## B3 (D1) — errata: as «duas voltas» são as do caminho da M51b

No ESTADO-FINAL da GUIAO-FRAGIL há duas erratas, ambas com a marca `[GUIAO-FRAGIL-CORRECOES B3]`:

- **No topo da secção B1.** Pela letra da ordem, «duas voltas» são voltas inteiras, e essas (variante B) não
  reproduzem a fragilidade. As «duas voltas» da ordem passam a ler-se como as do **caminho da M51b** (variante A),
  que é a reprodução válida e o único caminho em que a ordem da Party muda depois das escolhas. A variante B é
  informativa e não parte o 1.º teste. O juiz aceitou esta leitura, e a sanidade nova não depende do caminho.
- **No ponto 2** dos pontos para o coordenador: a mesma errata, em resumo, com remissão para a secção B1.

O texto original fica como estava, porque descreve com rigor o que foi corrido. A errata só fixa a leitura.

No topo do ESTADO-FINAL da GUIAO-FRAGIL há também uma nota «Corrigido pela Ordem …», que remete para este ficheiro.
É o padrão da casa (ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7).

## Corridas (PC, Node v26.13.0)

| Corrida | Resultado |
|---|---|
| Suite do servidor no ramo (`npm test` em `rascunhos/servidor`) | **421/421** (0 falham, 0 saltados) |
| `node --test testes/privacidade.test.mjs` | **11/11** |
| Sonda de privacidade (o `grep` de `.github/workflows/privacidade.yml`, corrido no PC) | limpa (grep exit 1: nenhum e-mail pessoal) |
| `python retoma-i0004/actualizar-listas.py` (sobre `b700bf4`) | antes.txt 37, depois.txt 415, MANIFESTO 459 (0 novos, 0 tirados); muda só o hash de `privacidade.test.mjs` nas duas listas |

## Pontos para o coordenador

1. **As linhas citadas na ordem não batem com a ponta.** B1: «L203–205» → L113–114. B2: «~L407–409» → L221–224.
   Corrigi pelo conteúdo, que é único nos dois casos.
2. **Mudou só o registo e um comentário.** A lógica e as asserções são as mesmas, e o total da suite também (421).
3. As decisões já registadas na sentença (421 ≠ 420, a conferência fora do PC, os dois limites, o canário 51, o
   LEVE 1 da M3) não foram tocadas.
4. O CI do último commit não fica registado aqui, porque o commit das listas tem de ser o último. O resultado vai na
   resposta da corrida.
5. ~~O `ORDEM.md` da sede não foi tocado. Já termina com a linha `- O ficheiro da ordem termina com a linha exacta:
   <b>Estado: NOVA</b>`.~~ [GUIAO-FRAGIL-CORRECOES-2 C4] Numa só linha:
   O ficheiro da ordem (`ORDEM.md`, a cópia na sede `ordem-caixa-testes-guiao-fragil-correcoes\`) não foi tocado; a sua última linha é `- O ficheiro da ordem termina com a linha exacta: <b>Estado: NOVA</b>`.
