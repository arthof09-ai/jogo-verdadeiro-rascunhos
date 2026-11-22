# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES-12 (Claude conta 2, PC) · 22/11/2026

Esta ordem fecha a correcção **B1** (D1) da sentença da CAIXA-TESTES-CORRECOES-11 (APROVA COM CORRECÇÕES, 950/1000).
Só mudou registo:
- o `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-10.md` (a citação da secção «Conferência», l. 18–19);
- este ficheiro.

Nenhuma linha de código mudou. Não toquei em código do jogo, em `provas/` nem em `rascunhos/`.

- **Base:** `origin/fable/integracao-50` @ `bfe4c3c` (a ponta à hora do lançamento; o `fetch` antes do commit não
  trouxe nada novo). Clone com `core.autocrlf=false`.
- **Sede:** a sede chegou sem clone (só `ORDEM.md`, `lanca.cmd` e o log vazio). Clonei a linha em `repo/` com o
  mesmo comando da sede da CAIXA-TESTES-CORRECOES-11 (`git clone --branch fable/integracao-50 --single-branch`);
  `clone.log` fica na sede, `CLONE_DONE 0`.
- **Trabalho directo na linha** `fable/integracao-50`, sem ramo lateral, como manda a ordem.
- **Conferência:** `~/workspace/conferencias/caixa-testes-correcoes-11/` não está neste PC. Trabalhei pelo texto da
  ordem, que traz o ponto exacto, e conferi a linha citada no repositório.

## Ponto a ponto

### B1 (D1): os dois caminhos da secção «Conferência» do ESTADO-FINAL-10
**Prova:** existência medida na raiz do repo (`test -e` e `git ls-files`):
- **existe** `rascunhos/servidor/testes/fixture-mestre.test.mjs` (no índice do git);
- **existe** `rascunhos/servidor/dados-exemplo/mesa-mestre.json` (no índice do git);
- **não existe** `testes/fixture-mestre.test.mjs` na raiz;
- **não existe** `dados-exemplo/mesa-mestre.json` na raiz.

Os caminhos curtos eram relativos a `rascunhos/servidor/`; a partir da raiz (onde vive o ESTADO-FINAL) não resolvem.
É a mesma imprecisão que a B2 da CAIXA-TESTES-CORRECOES-11 corrigiu na l. 44.

**Corrigido:** no ESTADO-FINAL-10, «(`testes/fixture-mestre.test.mjs` e `dados-exemplo/mesa-mestre.json`, só leitura)»
→ «(`rascunhos/servidor/testes/fixture-mestre.test.mjs` e `rascunhos/servidor/dados-exemplo/mesa-mestre.json`, só
leitura)».

**Diff do commit no ESTADO-FINAL-10:** só a inserção dos dois prefixos `rascunhos/servidor/`; mais nada. A citação
está quebrada em duas linhas no ficheiro (medido com `cat -n`): o primeiro caminho está na l. 18 e o segundo na l. 19.
Por isso o diff mostra as l. 18 e 19, cada uma só com o seu prefixo. Não re-quebrei o parágrafo (a l. 18 fica mais
comprida que as vizinhas), para que nada mais mude no ficheiro.

**Privacidade:** não houve fuga nem mutação nesta ordem. Nenhum número novo.

## Números das corridas (PC, Node 26.13.0, sobre `bfe4c3c` + a correcção)

| Corrida | Resultado |
|---|---|
| Servidor, `node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"` (em `rascunhos/servidor`) | **421/421**, 0 falhas, 0 cancelados, 0 saltados, 0 todo |
| `node --test --test-isolation=none testes/privacidade.test.mjs` (em `rascunhos/servidor`) | **11/11** |
| Sonda de privacidade (o `grep` de `.github/workflows/privacidade.yml`, corrido à mão na raiz) | **limpa** |
| Prova `node provas/ordem-caixa/ferramentas/prova-servidor.mjs` (da raiz) | **PROVA OK** (não tocada) |
| `python retoma-i0004/actualizar-listas.py` antes do commit | `antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)`; nenhuma lista mudou |

## Pontos para o coordenador

1. **B1 é só registo.** A suite fica 421/421 e a privacidade 11/11, como a ordem esperava.
2. **A «linha 18» são duas linhas no ficheiro.** A citação começa na l. 18 e acaba na l. 19; o segundo caminho
   (`dados-exemplo/mesa-mestre.json`) está na l. 19. Corrigi os dois, como pede a ordem; o diff toca nas l. 18–19.
3. **O commit não traz listas da retoma, e não é omissão.** O `actualizar-listas` deu 0 novos, 0 tirados, sem
   diferença em `antes.txt`, `depois.txt` nem `MANIFESTO-SHA256.txt`: o script só olha para `rascunhos/`.
4. **A sede veio sem clone.** Fi-lo eu, igual ao da sede anterior (ver «Sede» acima).
5. **Fora do âmbito, não tocado:** a l. 51 do ESTADO-FINAL-10 (§B2, «Medido em `dados-exemplo/mesa-mestre.json`:»)
   tem a mesma imprecisão: o caminho não leva o prefixo `rascunhos/servidor/`. A ordem só pediu a l. 18 e manda que
   o resto do ficheiro fique como está; fica para decisão. (As l. 68–69 citam `testes/…` dentro de comandos corridos
   em `rascunhos/servidor`, como diz a l. 68; não são citações de ficheiro a partir da raiz.)
6. O CI desta entrega corre sobre o commit na linha; não fica aqui registado, porque este é o último commit.
7. O `ORDEM.md` da sede (fora do repo) não foi tocado.
