# ORDEM — NADO: LIGAR O NADO DAS FIGURAS NO LAGO

Branch: `claude1/nado-integracao` · Base: `ba3b16c` (ponta da linha junta `fable/integracao-50`)
Executor: Claude da nuvem (conta 1) · Modelo: Opus 5.5, esforço Alto

## Contexto

A Ordem 66 (água) fechou: o lago existe, mas as figuras não nadam — dívida registada no fecho dela. O Mestre escolheu a fonte do movimento: o clipe «Swimming» do Mixamo.

O clipe vem **nesta branch**, no ficheiro `rascunhos/cliente/testes/manequim/orc-mixamo-swimming.fbx` (5.323.360 B). É esta a fonte — não vás buscar outra.

## Missão (só construir e corrigir — testes e conferência são do coordenador)

1. Liga o estado de nado das figuras quando estão no lago, usando esse clipe.
2. Segue os padrões que o repo já usa para os outros clipes das figuras (conversão de esqueleto, nomes, sítios) — não inventes um caminho novo.
3. Se a conversão do esqueleto do FBX bloquear, regista o bloqueio com precisão no ESTADO FINAL (o que falha, onde, com a mensagem exacta) e entrega o resto: a ligação do estado de nado + o clipe no sítio.

## Critérios de aceitação

- Figura dentro do lago → anima de nado com o clipe da casa; fora do lago → o comportamento anterior fica intacto.
- A prova da tua própria construção (o jogo arranca / CI verde) fica registada no ESTADO FINAL.

## Fecho

- Escreve o ESTADO FINAL nesta branch (`ESTADO-FINAL-ORDEM-NADO.md`): o que foi feito, a prova da construção, e os bloqueios com precisão.
- **ÚLTIMA PARTE:** funde esta branch na linha junta `fable/integracao-50` (self-merge) e confirma a fusão com `git ls-remote`.
