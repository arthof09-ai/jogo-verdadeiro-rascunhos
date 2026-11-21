# ESTADO FINAL — ORDEM-CAIXA-TESTE-ESTETICA (Claude conta 1, PC · 21/11/2026) — TESTE VISUAL

**Ramo:** `claude1/caixa-teste-estetica` a partir de `fable/integracao-50` @ `2949d16` (a ponta no lançamento, já com a
CAIXA-MANEQUIM fundida). **1 commit**, publicado. **Não fundido**: a fusão é do coordenador, depois da palavra do Mestre.

## As 5 capturas: onde estão
`provas/ordem-caixa-teste-estetica/cliente/`, com os mesmos nomes das da manequim, para se compararem lado a lado:

| # | momento | teste (cores do protótipo) | hoje (paleta C ponto 2) |
|---|---|---|---|
| 1 | dinâmica: a Espadachim entra, ela na vez | `1-entrou-dinamica.png` | `provas/ordem-caixa-manequim/cliente/1-entrou-dinamica.png` |
| 2 | iniciativa: Bruto na vez | `2-iniciativa.png` | `…/2-iniciativa.png` |
| 3 | desligada: a caixa ausente | `3-desligada.png` | `…/3-desligada.png` |
| 4 | religada e avançada: Arqueira na vez | `4-religada-avancou.png` | `…/4-religada-avancou.png` |
| 5 | reentrada: a caixa reconstruída | `5-reentrou.png` | `…/5-reentrou.png` |

Prova viva com o jogo a correr (cliente real pela Rede, servidor de mesa real com o motor VLAB real, Godot 4.7.2,
RTX 4060, janela 1028×720, manequim de referência `andar-v3.glb` com o SHA conferido, 0 cápsulas): **62/62** — as 46
da manequim, iguais linha a linha (mesmas ordens, mesmas vezes), mais 16 das cores (4 por momento com a caixa à vista).
Vi as 5 capturas uma a uma. Suites do cliente: `abrir_scripts` 107 scripts 0 falhas, `rodar_testes` 290/290,
`caixa_jogadora` 18/18, `caixa_janela` 69/69.

## O que mudou face às de hoje
| papel | hoje (PALETA-C ponto 2) | teste (protótipo) |
|---|---|---|
| painel da caixa | sangue C1121F a .78 (vermelho vivo) | rgba(16,12,8,.55) — castanho quase preto, vê-se o cenário através |
| moldura das figuras | ouro FFC93C a .18 (quase invisível) | ouro c9a227 a .85 |
| letras (título, modo, nomes, «na vez») | branco (tema do HUD) | pergaminho f3e9d2 |
| fundo do retrato | raro 4361EE opaco (azul) | rgba(10,8,5,.82) — escuro |
| figura na vez | moldura ffd28b grossa + nome ffd28b | moldura de ouro c9a227 grossa (3 contra 1) + nome a ouro |

Nos ficheiros:
- `dados/apresentacao.gd`: `COR_CAIXA_PAINEL`, `COR_CAIXA_MOLDURA`, `COR_RETRATO_FUNDO` passam a valores próprios
  (já não lêem `COR_SANGUE`/`COR_OURO`/`COR_RARO`) e nasce `COR_CAIXA_TEXTO` (pergaminho). **A tabela da paleta C não
  mudou** (bronze, ouro, sangue, lendário, raro, mágico iguais). A linha das pendências diz «EM TESTE».
- `hud/caixa_ordem.gd`: as letras levam `COR_CAIXA_TEXTO`; o realce da vez passa a ser a moldura de ouro (antes
  `COR_MESTRE_ANEL` ffd28b, que fica na tabela para o Mestre); o fundo da moldura do retrato, que era um preto a .35
  literal, passa a `COR_RETRATO_FUNDO`. Nenhuma cor fora da lista.
- `hud/hud.gd`: só o comentário das cores da caixa (estava desactualizado).
- `hud/retratos.gd` não mudou: lê `COR_RETRATO_FUNDO` da tabela.

## Privacidade
Igual à manequim nos momentos 1, 4 e 5: nenhuma mensagem do Mestre no aparelho dela, a caixa só leva
`ligada/ordemPor/ordemDinamica`, nenhum nome verdadeiro, vida, alma ou PA nos textos da caixa. Não há números na vista
da jogadora.

## Pontos para o coordenador / o Mestre (não mexi)
1. **A figura na vez destaca-se menos do que antes nas miniaturas da fila**: todas as molduras são agora de ouro, e a
   da vez difere pela espessura (3 contra 1) e pelo nome a ouro. O cartão grande à esquerda continua a dizer «na vez».
   Se o Mestre quiser mais contraste sem cor nova, a moldura das outras pode baixar de alfa ou de espessura.
2. O botão «Modo iniciativa» (só no ecrã do Mestre) ficou com o estilo do tema do Mestre: a ordem era a caixinha da
   vista da jogadora.
3. O retrato continua de corpo inteiro com o manequim (ponto 1 da CAIXA-MANEQUIM).
4. `MANIFESTO-SHA256.txt` não foi actualizado (`apresentacao.gd`, `caixa_ordem.gd`, `hud.gd` mudaram): é o passo
   «actualizar-listas» do coordenador depois da fusão, se o Mestre aprovar.
