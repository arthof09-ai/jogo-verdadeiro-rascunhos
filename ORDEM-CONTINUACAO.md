# ORDEM DE CONTINUAÇÃO — MISSÃO DADOS (tabela de apresentação)

Sessão na nuvem que continua a missão neste ramo `claude1/dados-apresentacao` (ponta 7f5bbdd à data da ordem). Modelo: Opus. Trabalha por fatias com commits frequentes.

## Já feito
- Fatia 1 — `rascunhos/cliente/dados/apresentacao.gd`: tabela única de apresentação (cores dos dois anéis, 5 raridades, 8 escolas de dano, 12 papéis de interface; cores dos papéis SEM hex final ficam PENDÊNCIA registada na tabela, nunca hex inventado; casa = 1.5 m registado como pendência com o número).
- Fatia 2 — rewire dos consumidores para a tabela, com 2 reverts ditados pela CI: grelha/relevo do mapa são fontes de terreno do servidor verificadas por SHA (ficam como estão; pendência registada na tabela) e as listas do retoma-pc refeitas.

## Falta
1. Suite verde nos dois fluxos.
2. ESTADO FINAL commitado no repositório.
3. POR ÚLTIMO, depois de buscar a linha junta: merge para `fable/integracao-50`. Se o ambiente web não conseguir empurrar o merge, deixa o ramo completo e diz isso no ESTADO FINAL.

## Regras duras
- Papéis de interface (bronze, ouro, sangue, lendário, raro, mágico) SEM hex final = PENDÊNCIA registada; nunca inventar hex.
- Casa = 1.5 m (grelha_floresta, relevo_floresta, arena, arena_mestre, clareira_prova) — pendência com o número; não mudar.
