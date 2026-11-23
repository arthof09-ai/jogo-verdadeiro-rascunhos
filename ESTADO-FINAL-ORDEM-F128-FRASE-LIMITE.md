# ESTADO-FINAL — Ordem F128 (a frase do «Limite (F114, J10)»)

**Ordem:** F128, do coordenador CM-000009, 2026-11-23 (D-J1 da conferência da F114, peso 15).
**Conta:** 1 (PC). **Linha:** `fable/integracao-50`. **Partida:** `ba9a2a4` (nota do CI da F109). Antes do push
entrou o `6d46e73` (nota do CI da fusão da F116, só no `ESTADO-FINAL-ORDEM-F116-LINHA-SO-ESPACOS.md`). Fiz rebase
por cima dele, sem conflito e sem force.
**Obra:** `77ba415`. Só mudou o `provas/ordem-caixa-relato/README.md`, numa linha (`@@ -563 +563 @@`), e o ficheiro
continua com 628 linhas. Não mexi na ferramenta, no auto-teste, noutras frases nem no alvo da reprodução (F122).

## 1. A frase

Está na linha 563, no parágrafo do «**Limite (F114, J10).**». O resto do parágrafo ficou igual.

- **Antes:** «O nome partido por uma linha em branco não dá suspeito: o pedaço no fim da linha de cima é demasiado curto
  para corte, e a variante não atravessa a linha em branco.»
- **Depois:** «A variante partida por uma linha em branco não dá suspeito: a variante não atravessa a linha em branco.
  Antes da palavra do meio, o pedaço no fim da linha de cima é demasiado curto para corte; antes do apelido, o pedaço é
  redigido como corte na origem.»

**Conferi as duas razões com a ferramenta, antes de escrever.** Usei o `redigir()` e depois o `suspeitos()` sobre o
texto redigido. Peguei no nome n.º 1 das fichas, que tem preposição da lista. O guião ficou fora do repo, em
`tmp/sub.mjs`, e não imprime nomes.

| caso (`\n\n` = linha em branco) | o `redigir()` muda? | conta | suspeitos i/v/c/sp |
|---|---|---|---|
| o nome, `\n\n` antes da palavra do meio | não | 0 em tudo | 0/0/0/0 |
| o nome, `\n\n` antes do apelido | **sim** | **cortados 1** | 0/0/0/0 |
| a variante «du», `\n\n` antes do apelido | não | 0 em tudo | 0/0/0/0 |
| o nome sem a preposição, partido por `\n\n` | não | 0 em tudo | **0/0/0/1** |

- **Antes da palavra do meio:** nada se redige e não dá suspeito, porque o pedaço é demasiado curto para corte.
- **Antes do apelido:** o pedaço é redigido como corte na origem. É o que o comentário do caso F116 do auto-teste já
  dizia.
- **A última linha** mostra o defeito da frase antiga: o nome sem a preposição dá suspeito. Por isso a frase nova diz
  «a variante» e não «o nome».

## 2. Os números medidos no PC (ponta `77ba415`)

| verificação | resultado |
|---|---|
| auto-teste `redigir-nomes.mjs --auto-teste` | **30/30**, rc=0 (ver a nota abaixo) |
| canário `teste_nomes_relato.gd` (Godot 4.7.2 Windows) | **26/26**, rc=0, 0 erros de script. A saída redigida é **igual byte a byte** ao registo limpo `cobertura-correcoes-6/teste-nomes-relato.log` (3437 bytes, sem os CR) |
| reprodução `reproduzir-redaccao-f25.sh` | **10/11, a mesma linha 6** (`cobertura-correcoes-6/teste-nomes-relato.log`, 3500 contra 3473 bytes), base `ba9a2a4` |
| privacidade do README (`suspeitos().inteiros` e `--pin=`) | **0/0** |
| privacidade deste ESTADO-FINAL | 0/0 |

**Nota sobre o auto-teste:** a ordem pede 29/29, mas a ferramenta já dava 30/30 antes desta obra. A F109 (`8ac126c`,
já na linha) acrescentou um caso, e a F128 não tocou na ferramenta. Os 30/30 são o número de aceitação certo nesta
ponta.

## 3. O CI da ponta da obra `77ba415`

- **Testes dos rascunhos 45195472209: success, 10/10 jobs.** São eles: servidor, foto-mestre, validador-glb,
  protocolo, motor-real, godot-cliente, retoma-pc, provas-mapa, cliente e ponta-a-ponta.
- **Sonda de privacidade 45195472203: success.**
- No job `cliente`:
  - o auto-teste dá 30/30;
  - o canário dá 26/26 e «igual byte a byte ao redigido (3437 bytes, sem os CR)»;
  - as suites dão 321/321, 123/123 e 70/70, e a mutação da caixa_janela dá 114/123.
- O log do `cliente` tem 0 nomes inteiros e 0 PIN.

A nota do CI da ponta deste ESTADO-FINAL entra mais abaixo e só acrescenta texto a este ficheiro.

## 4. Pontos abertos

1. **A ordem diz 29/29 para o auto-teste.** Nesta ponta o número certo é 30/30, por causa da F109 (§2).
2. **A ordem dá a linha ~561.** Na obra a frase estava na 563. Agora está na 564, porque a F132 acrescentou uma linha
   mais acima (ver o ponto 3).
3. **A F132 entrou na linha depois da obra.** É o `ba165e3`, da sede `ordem-f132-guarda-tab-pc`, e nasceu por cima do
   `77ba415`. Mexe no README (linhas 536 e 577, não no «Limite») e acrescenta um caso ao auto-teste. Na ponta deste
   ESTADO-FINAL o auto-teste dá **31/31**, medido no PC. A minha frase continua intacta e é única no ficheiro. Fiz
   rebase deste ESTADO-FINAL por cima do `ba165e3`, sem conflito.
