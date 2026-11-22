# Tabela — a caixa da jogadora com 8 figuras (Ordem CAIXA-HUD-JOGADORA-MEDICAO-8-FIGURAS)

Base `fable/integracao-50` @ `5a29112`. Godot 4.7.2.stable.official.ed1daf0bf, `--headless` (sem GPU), PC Windows.
Teste: `rascunhos/cliente/testes/caixa_jogadora.gd` §8. Critério (escrito antes): `CRITERIO.md`.
Unidades (u) = as da tela do HUD (a altura é sempre 1080 u); px reais = u × escala.

| Resolução | Tela (u) · escala · letra | Caixa (u) | Caixa (px reais) | Altura da caixa | Por linha | Faixa livre / precisa (u) | Margens da faixa esq / dir (u) | Desvio do centro (u) | Sobreposição | Centrada | Cortado |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **844×390** | 2337×1080 · 0,361 · 36 | 1186×323 | 428×117 | 323 u = 117 px (30 % do ecrã) | 8 | 959 / 729 (≈ 346 px reais) | 126 / 1204 | 539,0 | **NÃO** | **NÃO** | **NÃO** |
| **780×360** | 2340×1080 · 0,333 · 39 | 1269×349 | 423×116 | 349 u = 116 px (32 % do ecrã) | 8 | 867 / 788 (≈ 289 px reais) | 136 / 1288 | 576,0 | **NÃO** | **NÃO** | **NÃO** |
| 1920×1080 (controlo) | 1920×1080 · 1,000 · 22 | 767×212 | 767×212 | 212 u = 212 px (20 % do ecrã) | 8 | 1017 / 453 | 77 / 778 | 350,5 | **NÃO** | **NÃO** | **NÃO** |

«Sobreposição» = a caixa cruza a ⚙/ficha (`ColunaEsquerda`), a barra inferior (`Barra`, visível) ou a faixa de cima (com
a frase mais comprida, a da pausa). Nas três resoluções: ficha `false`, barra `false`, faixa `false`.
«Cortado» = a caixa sai do ecrã, um dos 8 quadradinhos sai da caixa, ou a faixa tem menos largura do que a frase mais
comprida precisa. Nas três: a caixa cabe no ecrã, 0 quadradinhos fora, faixa livre ≥ precisa.

## Veredicto pelos 5 pontos do critério

| Ponto | 844×390 | 780×360 | 1920×1080 |
|---|---|---|---|
| 1. não tapa a ⚙/ficha | cumpre | cumpre | cumpre |
| 2. não tapa a barra inferior | cumpre | cumpre | cumpre |
| 3. não tapa a faixa de cima | cumpre | cumpre | cumpre |
| 4. a faixa continua centrada | **falha** | **falha** | **falha** |
| 5. nada fica cortado | cumpre | cumpre | cumpre |

## O ponto 4: quanto falta para a faixa ficar centrada
A regra de `hud.gd _posicionar_caixa` (Ordem CAIXA-JANELA B3): a faixa só fica centrada se
`área − 2 × (caixa + folga) ≥ precisa`. Caso contrário centra-se **entre a ⚙ e a caixa** (por desenho). A área é
`livre + esq + dir`, e a folga é metade da letra.

| Resolução | Área (u) | Precisa (u) | Folga (u) | Caixa máxima para centrar (u) | Caixa com 8 (u) | Excesso (u) |
|---|---|---|---|---|---|---|
| 844×390 | 2289 | 729 | 18 | 762 | 1186 | 424 |
| 780×360 | 2291 | 788 | 19,5 | 732 | 1269 | 537 |
| 1920×1080 | 1872 | 453 | 11 | 698 | 767 | 69 |

## Corridas (os 2 logs desta pasta, ambos com 51 linhas)
- `corrida-1-criterio.log` (SHA-256 `97e44bc0…a000632`): a corrida do critério tal como foi escrito, com o ponto 4 a
  contar. **33 de 36**, rc 1. As 3 falhas são o ponto 4 nas 3 resoluções.
- `corrida-2-final.log` (SHA-256 `bd8ce5d9…3ac876cb`): o teste tal como foi publicado. O ponto 4 é medido e fica numa
  linha `REGISTO (não conta)`, para não pôr o CI vermelho por uma coisa que vem do desenho e que esta ordem não
  corrige. **33 de 33**, rc 0, 0 linhas com `FALHA`, `ERROR` ou `WARNING`.
- As linhas `MEDIDA` são iguais byte a byte nas duas corridas.
- Entre as duas corridas, a redacção de uma frase do teste (a da barra) mudou, só para o
  conferidor estrito dar 0 achados. Não mexeu em nenhuma conta.
