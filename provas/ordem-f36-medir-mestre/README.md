# Ordem F36 — endurecer o `medir_mestre.gd` (sentença da CAIXA-EXPANDE-VISTAS)

Só a prova mudou: `rascunhos/cliente/testes/medir_mestre.gd`. O jogo (`mestre.gd`, `caixa_ordem.gd`) não foi tocado.
Godot 4.7.2, Windows 11, `--headless`, como no CI. Base: `7c4da45`.

| pasta / ficheiro | o que é |
|---|---|
| `suite/medir_mestre.antes.log` | a suite na base `7c4da45`: 130 ok, 0 falhas |
| `suite/medir_mestre.log` | a suite endurecida: 220 ok, 0 falhas |
| `ferramentas/mutacoes-medir-mestre.sh` | quatro mutações do jogo (uma por vez, repostas no fim) — prova de que as guardas novas disparam |
| `mutacoes/resumo.txt`, `mutacoes/M*.log` | o resultado: as quatro disparam e o jogo fica reposto |
| `suites/resumo-alheios.txt` | a linha final das outras suites do cliente e da mutação da `caixa_janela` (os logs inteiros não se cometem: o do `teste_nomes_relato` imprime nomes verdadeiros de propósito) |

Os buracos tapados (D-A, D-B, D-C, D-G) e os números estão no `ESTADO-FINAL-ORDEM-F36-ENDURECER-MEDIR-MESTRE.md`, na raiz.
