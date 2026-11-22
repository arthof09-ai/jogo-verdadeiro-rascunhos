# ESTADO-FINAL — Ordem CAIXA-RELATO-B7-CORRECOES-9

**Dono:** Comestre CM-000009 (Muse). **Data:** 22/11/2026. **Base:** ponta de `fable/integracao-50` à hora do lançamento, `5c6ecf1`.
**Trabalho directo na linha:** sem ramo lateral, sem fusão; `fetch` + `rebase` antes do `push`.

## B1 (D1) — o «82» errado no `corridas.log`

Ficheiro: `provas/ordem-caixa-relato/b7-correcoes-7/corridas.log`, linha 11. Commit `a0cf4d8` (só este ficheiro, 1 linha trocada).

Antes (`sed -n '11p'`):

```
correr-prova-caixa-janela.sh (saída nesta pasta)     rc=0   41 de 41   cliente-janela/relato.txt (82 linhas; B6/O2)
```

Depois (`sed -n '11p'`):

```
correr-prova-caixa-janela.sh (saída nesta pasta)     rc=0   41 de 41   cliente-janela/relato.txt (81 linhas; B6/O2)
```

Contagem do relato (na pasta `provas/ordem-caixa-relato/b7-correcoes-7/`):

```
$ wc -l cliente-janela/relato.txt
81 cliente-janela/relato.txt
$ grep -c '' cliente-janela/relato.txt
81
```

As duas contagens batem (o ficheiro acaba em fim de linha), e a linha 11 agora diz 81. Não há mais nenhum «82 linhas» no `corridas.log`.
O ficheiro continua com fins de linha LF (0 CR antes e depois).

## `retoma-i0004/actualizar-listas.py`

Corrido na raiz do repo depois do commit:

```
antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)
rc=0
```

`git status` limpo depois disto: as listas não mudaram, como se esperava (o território não toca em `rascunhos/`).

## Pontos para o coordenador

1. **A sede não tinha checkout.** A pasta da ordem só trazia `ORDEM.md`, `lanca.cmd` e o log vazio, sem `repo/`. Clonei a linha
   `fable/integracao-50` para `repo/` dentro da sede, como nas sedes da -7 e da -8, e trabalhei aí.
2. **Território:** o commit da correcção toca só no `corridas.log`. Este ESTADO-FINAL vai num commit à parte, como pede a entrega.
3. A prova antes/depois da linha 11 também ficou fora do repo, em `antes.log` e `depois.log` na sede.
4. Privacidade: este ficheiro não leva nomes verdadeiros.
