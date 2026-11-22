# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES-11 (Claude conta 2, PC) · 22/11/2026

Esta ordem fecha as correcções **B1–B2** (O1 e O2) da sentença da CAIXA-TESTES-CORRECOES-10 (FUNDE COM CORRECÇÕES,
940/1000). Só mudou registo:
- o `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-10.md` (duas citações, l. 24 e l. 44);
- este ficheiro.

Nenhuma linha de código mudou. Não toquei em código do jogo, em `provas/` nem em `rascunhos/`.

- **Base:** `origin/fable/integracao-50` @ `e54b76b` (a ponta à hora do trabalho; o clone da sede estava em `880f601`
  e avancei-o por `pull --ff-only`). Clone com `core.autocrlf=false`.
- **Trabalho directo na linha** `fable/integracao-50`, sem ramo lateral, como manda a ordem.
- **Conferência:** `~/workspace/conferencias/caixa-testes-correcoes-10/` não está neste PC. Trabalhei pelo texto da
  ordem, que traz os pontos exactos, e conferi cada linha citada no repositório.

## Ponto a ponto

### B1 (O1): a citação do §B3 do ESTADO-FINAL-8
**Prova:** `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-8.md`, medido com `cat -n`:
- l. 28–31: o «**Corrigido:**» do §B1 (certo, não se tocou);
- l. 46: `### B3`; l. 47–59: a «Prova» do §B3;
- **l. 61–67:** o «**Corrigido**, nos dois sítios:» do §B3 (ESTADO-FINAL-7, B3 + comentário de `historicoVida`);
- l. 69: a nota da CAIXA-TESTES-CORRECOES-10 (B1).

As l. 56–62 caíam a meio da «Prova» do §B3 (a nota da CORRECOES-9 (B2) e o `revertido`), não no bloco «Corrigido».

**Corrigido:** no ESTADO-FINAL-10, l. 24, «do §B3 (l. 56–62)» → «do §B3 (l. 61–67)». O §B1 (l. 28–31) ficou como estava.

### B2 (O2): a citação de `gerar()`
**Prova:** `rascunhos/servidor/testes/fixture-mestre.test.mjs`, medido com `cat -n`:
- l. 80: `function gerar() {`;
- l. 87–95: o `return { origem, canarios, mestre, lobby, agir, jogadora }`;
- **l. 96:** `}` que fecha `gerar()`;
- l. 98: `test('fixture do ecrã do Mestre: …')` — já fora da função.

O caminho `testes/…` era relativo a `rascunhos/servidor/`; a partir da raiz (onde vive o ESTADO-FINAL) não resolve.

**Corrigido:** no ESTADO-FINAL-10, l. 44, «(`testes/fixture-mestre.test.mjs`, l. 80–98)» →
«(`rascunhos/servidor/testes/fixture-mestre.test.mjs`, l. 80–96)».

**Diff do commit no ESTADO-FINAL-10:** só as linhas 24 e 44, cada uma com a troca indicada; mais nada.

**Privacidade:** não houve fuga nem mutação nesta ordem. Nenhum número novo.

## Números das corridas (PC, Node 26.13.0, sobre `e54b76b` + as duas correcções)

| Corrida | Resultado |
|---|---|
| Servidor, `node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"` (em `rascunhos/servidor`) | **421/421**, 0 falhas, 0 cancelados, 0 saltados, 0 todo |
| `node --test --test-isolation=none testes/privacidade.test.mjs` (em `rascunhos/servidor`) | **11/11** |
| Sonda de privacidade (o `grep` de `.github/workflows/privacidade.yml`, corrido à mão na raiz) | **limpa** |
| Prova `node provas/ordem-caixa/ferramentas/prova-servidor.mjs` (da raiz) | **PROVA OK** (não tocada) |
| `python retoma-i0004/actualizar-listas.py` antes do commit | `antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)`; nenhuma lista mudou |

## Pontos para o coordenador

1. **B1–B2 são só registo.** A suite fica 421/421 e a privacidade 11/11, como a ordem esperava.
2. **O commit não traz listas da retoma, e não é omissão.** Corri o `actualizar-listas` antes do commit: 0 novos,
   0 tirados, nenhuma diferença em `antes.txt`, `depois.txt` nem `MANIFESTO-SHA256.txt`. O script só olha para
   `rascunhos/`, e esta ordem não toca em `rascunhos/`.
3. **A ponta mudou entre o clone e o trabalho:** a sede foi clonada em `880f601`; o `fetch` trouxe `e54b76b`
   (GUIAO-FRAGIL-CORRECOES-2), que não toca no ESTADO-FINAL-10. Sem conflito.
4. **Fora do âmbito, não tocado:** a l. 18 do ESTADO-FINAL-10 (secção «Conferência») também escreve
   `testes/fixture-mestre.test.mjs` sem o prefixo `rascunhos/servidor/`. A sentença não a pediu; fica para decisão.
5. O CI desta entrega corre sobre o commit na linha; não fica aqui registado, porque este é o último commit.
6. O `ORDEM.md` da sede (fora do repo) não foi tocado.
