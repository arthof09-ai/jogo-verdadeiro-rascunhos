# ESTADO-FINAL — Ordem F125 (frase da F89 numa linha + regenerar o log da mutação)

**Ordem:** F125, do coordenador CM-000009, 2026-11-23 10:20 -03 (D-J4 e D-J5 da conferência da F97).
**Conta:** 1 (PC). **Linha:** `fable/integracao-50`. **Partida:** `189e791` (nota do CI da F52, pós-F116).
**Obra:** `307b6e7`. Só dois ficheiros mudaram: `provas/ordem-caixa-relato/README.md` e
`provas/ordem-f51-mutacao/teste-nomes-relato.mutacao.log`.

## 1. A frase da F89 numa só linha (D-J4) — aceitação (a)

Na ponta de partida, a frase estava partida nas linhas **544–545**, e não nas 540–541 que a ordem indica. As linhas
tinham andado com as ordens que vieram depois da F97.

| | linha 544 | linha 545 |
|---|---|---|
| antes | `… da lista é **«uma palavra de letras, com ou sem` | `  hífenes»** («X du-la Y» conta como variante). **Mais de uma palavra** …` |
| depois | `… da lista é **«uma palavra de letras, com ou sem hífenes»**` | `  («X du-la Y» conta como variante). **Mais de uma palavra** …` |

- Agora a frase está **inteira na linha 544**: o `grep -n "uma palavra de letras, com ou sem hífenes"` acha 1 ocorrência, na linha 544.
- O `git diff -U0` mostra um só bloco (`@@ -544,2 +544,2 @@`). Nenhuma outra linha mudou e o ficheiro continua com
  624 linhas. Passar «hífenes»** para a linha de cima obriga a mudar as duas linhas, mas o texto do parágrafo é o
  mesmo.
- O § do «Limite» (F128) e o § do J10 (F116) ficaram como estavam.

## 2. O log da mutação regenerado (D-J5) — aceitação (b)

**O guião:** a ordem nomeia o `provas/ordem-caixa-janela-ci/ferramentas/mutacao-celulas.sh`. Esse guião é a
mutação das células da caixa_janela, escreve `mutacao-celulas.log` e não tem nenhum «caso 1». O log do D-J5 é o
`provas/ordem-f51-mutacao/teste-nomes-relato.mutacao.log`: o ESTADO-FINAL da F97 (§4, ponto 4) aponta-o, e quem o
produz é o `provas/ordem-f51-mutacao/correr-mutacao-canario.sh`. Foi este o guião que corri:

    bash provas/ordem-f51-mutacao/correr-mutacao-canario.sh <godot 4.7.2 win64 console> <tmp fora do repo> <saída fora do repo>

Mandei a saída para fora do repo e copiei para dentro **só o log**. O guião também reescreve o `resumo.txt` e o
`mutacao.diff`, e a ordem limita a obra a dois ficheiros. O `mutacao.diff` novo saiu igual byte a byte ao cometido. O
`resumo.txt` não foi tocado (ver §5).

**Resultado da corrida:** rc=1, «23 de 26 verificações passaram.», as 3 FALHA distintas do §3 da F25, 0 erros de
script, o ficheiro reposto (git diff vazio), o diff com uma linha só, e `esperado: sim`.

**A linha do caso 1 (a 6.ª do ficheiro; só ela muda, e as 39 linhas e os CRLF mantêm-se):**

| | linha 6 |
|---|---|
| antes | `  ok    1: «nome n.º 1» e «nome n.º 2» são canários ["nome n.º 1", "nome n.º 2"]` |
| depois | `  ok    1: «nome n.º 1» e «nome n.º 2» são canários (2)` |

| | bytes | sha256 |
|---|---|---|
| antes | 3861 | `4560e8ceac8d…2747653` |
| depois | 3834 | `975f87d7eb4f…970c9068` |

A redacção diz agora «39 linhas, 0 redigidas»: desde a F97, a saída crua do canário já não traz nenhum nome inteiro.

## 3. Números de aceitação — aceitação (c)

| verificação | partida `189e791` | depois da obra |
|---|---|---|
| auto-teste `redigir-nomes.mjs --auto-teste` (PC) | 29/29 | **29/29** (a ferramenta não mudou) |
| canário `teste_nomes_relato.gd` (PC, Godot 4.7.2 Windows) | — | **26/26**, rc=0, 0 erros de script; a saída redigida é **igual byte a byte** ao registo limpo `cobertura-correcoes-6/teste-nomes-relato.log` (3473 bytes) |
| reprodução `reproduzir-redaccao-f25.sh` (PC) | 10/11, linha 6 | **10/11, a mesma linha 6** (`cobertura-correcoes-6/teste-nomes-relato.log`, 3500 contra 3473 bytes). O alvo da comparação não mudou (é da F122) |
| mutação da F51 (PC) | — | rc=1, 23 de 26, as 3 FALHA, `esperado: sim` |

**Privacidade:**
- Os dois ficheiros cometidos têm **0 nomes verdadeiros inteiros** e **0 PIN**: contei com o `suspeitos().inteiros`
  do `redigir-nomes.mjs`, e as contas ficaram fora do repo. Este ESTADO-FINAL também dá 0 nos dois casos.
- O conferidor `conferir-registo.mjs` (critério alargado / antigo) dá os mesmos números antes e depois: README
  **34/30**, log da mutação **17/17**. São os achados por desenho que a F51 já registava.
- Nos logs do CI desta ponta há **0 + 0** nomes inteiros, no `cliente` e no `godot-cliente`, sem distinguir
  maiúsculas.

## 4. CI da ponta da obra `307b6e7` — aceitação (d)

- **Testes dos rascunhos 45186311395: success, 10/10 jobs.** São eles: ponta-a-ponta, cliente, godot-cliente,
  motor-real, provas-mapa, protocolo, foto-mestre, servidor, retoma-pc e validador-glb.
- **Sonda de privacidade 45186311382: success.**
- No job `cliente`:
  - o passo da F51 dá o auto-teste 29/29, o canário 26/26 e «igual byte a byte ao redigido (3437 bytes, sem os CR)»;
  - a mutação da caixa_janela dá «114 de 123»;
  - as suites dão 321/321, 123/123 e 70/70.
- No job `godot-cliente`, 321/321.

## 5. Pontos abertos (para o coordenador)

1. **O `resumo.txt` da F51 ficou desactualizado.** Diz o sha256 `4560e8ce…` e «7 redigidas — 10 nome(s)
   inteiro(s)», que são do log antigo. Não lhe toquei, porque a ordem limita a obra a dois ficheiros. Se for para o
   pôr em dia, basta copiar o `resumo.txt` desta corrida (guardado fora do repo, no `tmp/mut-saida/` da pasta da
   ordem). Os ESTADO-FINAL da F51, da F66 e da F88 também citam o sha antigo, mas são registos datados e não se
   emendam.
2. **A ordem nomeia o guião errado** (`mutacao-celulas.sh`). Corri o `correr-mutacao-canario.sh` (ver §2).
3. **A ordem dá as linhas 540–541.** Na ponta de partida, a frase estava nas 544–545.
4. **Uma armadilha do guião da F51:** o 3.º argumento (a pasta de saída) é relativo à raiz do repo
   (`S=$PWD/$3`). Com um caminho absoluto no Git Bash, a saída cai dentro do repo, em `c/…`. Foi o que aconteceu na
   1.ª corrida. Movi a pasta para fora antes de qualquer commit e não se cometeu nada dela. Como a saída já vinha
   redigida, não trazia nomes.
