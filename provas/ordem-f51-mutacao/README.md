# Provas — Ordem F51 da sentença da F25 (23/11/2026, Claude conta 1, PC)

Duas provas da F25 que só existiam em testemunho passam a ter artefacto cometido. O relato está em
`ESTADO-FINAL-ORDEM-F51-MUTACAO-FERRAMENTA.md`, na raiz.

- `correr-mutacao-canario.sh <godot> <pasta-tmp>` repete a mutação do §3 da F25: põe `false and` em
  `nomes_relato.gd:59`, só na cópia de trabalho, corre o canário e repõe o ficheiro com `git checkout`. Escreve:
  - `mutacao.diff`: a mutação posta;
  - `teste-nomes-relato.mutacao.log`: o log da corrida, redigido pelo `redigir-nomes.mjs` (a saída crua traz os
    nomes verdadeiros de propósito e fica na pasta tmp);
  - `resumo.txt`: rc=1, 23 de 26, as 3 FALHA.
  - Desde a F68 (sentença da F51), o guião também afirma que o `mutacao.diff` tem exactamente uma linha mudada: uma
    «-» (a linha 59 como estava) e uma «+» (a mutação). As FALHA distintas contam-se com `sort -u`, e não com `uniq`,
    que só junta as repetidas seguidas. Neste log a troca é preventiva (F92): as duas cópias de uma FALHA saem
    seguidas, e o `uniq` também dá 3.
  - Desde a F91 (sentença da F66+F68), contam-se todas as linhas «-» e «+» do diff menos os cabeçalhos «--- » e
    «+++ ». Assim, uma linha só com «-» ou só com «+» também conta. A contagem tem de coincidir com o
    `git diff --numstat` («1 1»), que apanha a linha tirada que começa por «-- » e que a 1.ª conta confundiria com
    um cabeçalho.
- `reproduzir-redaccao-f25.sh <pasta-tmp>` prova que o `redigir-nomes.mjs` reproduz a redacção do §2 da F25. O
  resultado está em `reproducao-f25.log`: os 11 de 11 iguais byte a byte.

- `remendo-ci-testes.yml.patch` é o passo novo do job `cliente`: o auto-teste do `redigir-nomes.mjs` e a comparação da
  saída do canário com o registo limpo. Foi aplicado em `74f5fa9` (F65) e fica aqui como registo.

A ferramenta e o seu uso estão documentados em `provas/ordem-caixa-relato/README.md`, na secção da F51.
