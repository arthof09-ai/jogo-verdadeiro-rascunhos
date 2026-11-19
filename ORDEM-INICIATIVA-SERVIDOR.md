# ORDEM — INICIATIVA NO SERVIDOR

Branch: `claude2/iniciativa-servidor` · Base: `ba3b16c` (ponta da linha junta `fable/integracao-50`)
Executor: Claude da nuvem (conta 2) · Modelo: Opus 5.5, esforço Alto

## Contexto

A Ordem HUD fechou e fundiu na linha junta. Ficaram duas pendências registadas no ESTADO FINAL dela:

1. O servidor não lança a iniciativa: os valores vêm da configuração do Mestre (`rascunhos/servidor/nucleo/sala.js`, função `iniciativaDe`).
3. As formas dinâmicas da ordem vivem só no cliente do Mestre: se ele reentra a meio da batalha, a ordem recomeça vazia.

## Missão (só construir e corrigir — testes e conferência são do coordenador)

1. O servidor passa a ser o dono da ordem de turno.
2. **Lançamento:** ao começar a batalha, o servidor lança a iniciativa de cada figura A PARTIR da base que já existe (`iniciativaDe` em `sala.js`). **NÃO inventes fórmula nem dado.** Se no código e nas notas do repo NÃO existir regra de lançamento (que dado, quantas faces), **PÁRA essa parte**: regista-a no ESTADO FINAL como «PENDÊNCIA DO MESTRE — regra de lançamento da iniciativa não existe nas fontes» e entrega o resto da ordem.
3. **Ordem dinâmica no servidor:** as mudanças à ordem durante a batalha (quem entra, quem sai, atrasos) ficam registadas no servidor, para a caixa de ordem do Mestre se reconstruir igual quando ele reentra a meio da batalha.
4. Mudança mínima no cliente: só o preciso para ler a ordem do servidor.
5. **PROIBIDO:** criar qualquer campo novo com pontos de vida ou de alma, em qualquer mensagem ou estado. A vista da Party nunca recebe vida/alma — regra da casa, sem excepção.

## Critérios de aceitação

- A ordem inicial vem do servidor e é igual para todos os clientes que entram na sala.
- Sair e reentrar a meio da batalha devolve a ordem como ela estava, incluindo as mudanças dinâmicas.
- A prova da tua própria construção (o jogo arranca / CI verde) fica registada no ESTADO FINAL.
- Sem campos novos de vida/alma (ponto 5).

## Fecho

- Escreve o ESTADO FINAL nesta branch (`ESTADO-FINAL-ORDEM-INICIATIVA.md`): o que foi feito, a prova da construção, e as pendências nomeadas (incluindo a do ponto 2, se tiveres parado nela).
- **ÚLTIMA PARTE:** funde esta branch na linha junta `fable/integracao-50` (self-merge) e confirma a fusão com `git ls-remote`.
