# Critério de aceitação — a caixa da jogadora com 8 figuras (Ordem CAIXA-HUD-JOGADORA-MEDICAO-8-FIGURAS)

Escrito ANTES da corrida (22/11/2026), na base `fable/integracao-50` @ `5a29112`.

Corrida: `rascunhos/cliente/testes/caixa_jogadora.gd`, §8, Godot 4.7.2 `--headless` (sem GPU), com 8 figuras na
ordem dinâmica (2 da jogadora, 6 criaturas; nomes públicos genéricos, até 10 letras), a caixa ligada, em combate.

Resoluções: **844×390** e **780×360** (baixas) e **1920×1080** (controlo).

Em todos os ecrãs medidos, a caixa **cumpre** o critério se:

1. **não tapa a ⚙/ficha** — o rectângulo da caixa não cruza o da `ColunaEsquerda`;
2. **não tapa a barra inferior** — não cruza o da `Barra` (visível em combate);
3. **não tapa a faixa de cima** — não cruza o rectângulo da `Faixa`, medido com a frase mais comprida que ela mostra
   (`FAIXA_MAIS_LONGA`, a da pausa);
4. **a faixa de cima continua centrada** — as margens esquerda e direita da faixa são iguais (diferença ≤ 1 u), e o
   centro da faixa coincide com o centro do ecrã (≤ 1 u);
5. **nada fica cortado** — a caixa cabe toda no ecrã; os 8 quadradinhos estão todos dentro da caixa; a faixa tem
   largura livre ≥ à que a frase mais comprida precisa (numa linha).

Regista-se por resolução: a **altura da caixa** (unidades da tela e px reais), a **largura restante da faixa** (u) e a
**sobreposição** (sim/não), e o veredicto ponto a ponto.

Se algum ponto falhar, **não se corrige nesta ordem** (a correcção é o EXPANDE, pendente do veredicto do Mestre às
fotos do PADRAO-BUSTO): regista-se o transbordo com os números no ESTADO-FINAL.
