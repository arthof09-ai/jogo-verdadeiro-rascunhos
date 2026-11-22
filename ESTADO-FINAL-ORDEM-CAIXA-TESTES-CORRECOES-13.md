# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES-13 (Claude conta 1, PC) · 22/11/2026

Esta ordem fecha a correcção **B1** (D1) da sentença da CAIXA-TESTES-CORRECOES-12 (APROVA COM CORRECÇÕES, 970/1000).
Só mudou registo:
- o `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-10.md` (§B2, l. 51);
- este ficheiro.

Nenhuma linha de código mudou. Não toquei em código do jogo, em `provas/` nem em `rascunhos/`.

- **Base:** `origin/fable/integracao-50` @ `5a92ad9` (a ponta à hora do lançamento; contém o `33d9185` da
  CORRECOES-12). Ver «Publicação» abaixo para o `fetch` + `rebase`.
- **Sede:** a sede chegou sem clone (só `ORDEM.md`, `ORDEM.md.b64`, `lanca.cmd` e o log vazio), como na
  CORRECOES-12. Clonei a linha em `repo/` com o mesmo comando da sede da CAIXA-TESTES-CORRECOES-11
  (`git clone --branch fable/integracao-50 --single-branch`); `clone.log` fica na sede, `CLONE_DONE 0`.
- **Trabalho directo na linha** `fable/integracao-50`, sem ramo lateral nem fusão, como manda a ordem.

## Ponto a ponto

### B1 (D1): o prefixo em falta na l. 51 do ESTADO-FINAL-10

**Antes** (`sed -n '51p' ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-10.md`):

```
`dados-exemplo/mesa-mestre.json`:
```

**Depois** (o mesmo comando):

```
`rascunhos/servidor/dados-exemplo/mesa-mestre.json`:
```

A frase «Medido em» acaba na l. 50 e o caminho está sozinho na l. 51 (medido com `sed -n '50,51p'`). Por isso a
troca só toca na l. 51. O diff do commit no ESTADO-FINAL-10 é uma linha: a inserção do prefixo `rascunhos/servidor/`.
Não re-quebrei o parágrafo.

**O caminho novo resolve a partir da raiz:** existe `rascunhos/servidor/dados-exemplo/mesa-mestre.json`; não existe
`dados-exemplo/` na raiz.

**As l. 18–19 já estavam certas** (`sed -n '18,19p'`, antes de tocar no ficheiro):

```
  ordem, que traz os pontos exactos. Conferi cada afirmação no repositório (`rascunhos/servidor/testes/fixture-mestre.test.mjs` e
  `rascunhos/servidor/dados-exemplo/mesa-mestre.json`, só leitura).
```

**Varrimento:** depois da troca, `grep -n "dados-exemplo"` no ESTADO-FINAL-10 dá só as l. 19 e 51, ambas com o prefixo
`rascunhos/servidor/`. Já não há no ficheiro nenhum `dados-exemplo/` sem o prefixo.

**Privacidade:** não houve fuga nem mutação nesta ordem. Nenhum número novo. Este ficheiro não leva nomes verdadeiros.

## Corridas (PC, sobre `5a92ad9` + a correcção)

| Corrida | Resultado |
|---|---|
| `python retoma-i0004/actualizar-listas.py` (raiz), antes do commit | `antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)`; `git status` só mostra o ESTADO-FINAL-10 mudado, nenhuma lista mudou |
| Sonda de privacidade (o `grep` de `.github/workflows/privacidade.yml`, corrido à mão na raiz) | **limpa** |

Não corri a suite do servidor: a ordem só muda registo na raiz e nenhum ficheiro de código ou de teste foi tocado.

## Publicação

Antes do `push`: `git fetch` + `git rebase origin/fable/integracao-50`. O resultado (ponta nova ou não, conflito ou
não) fica no relatório da corrida, porque este ficheiro vai no próprio commit.

## Pontos para o coordenador

1. **B1 é só registo.** Um caminho, uma linha.
2. **A citação da ordem atravessa duas linhas.** «Medido em» está na l. 50 e o caminho na l. 51. Troquei só o caminho
   da l. 51; a l. 50 fica igual.
3. **O commit não traz listas da retoma, e não é omissão.** O `actualizar-listas` deu 0 novos, 0 tirados, como a ordem
   esperava: o script só olha para `rascunhos/`.
4. **A sede veio outra vez sem clone.** Fi-lo eu, igual ao da sede anterior (ver «Sede» acima). Talvez valha a pena a
   sede passar a vir com o clone, ou com o `clone.cmd`.
5. **As l. 68–69 do ESTADO-FINAL-10 não foram tocadas.** Citam `testes/…` dentro de comandos corridos em
   `rascunhos/servidor` (como diz a l. 68), não são caminhos a partir da raiz. A CORRECOES-12 já as tinha deixado
   assim.
6. O CI desta entrega corre sobre o commit na linha; não fica aqui registado, porque este é o último commit.
7. O `ORDEM.md` da sede (fora do repo) não foi tocado.
