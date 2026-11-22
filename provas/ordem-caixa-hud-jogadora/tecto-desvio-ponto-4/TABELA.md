# Tabela — o tecto do desvio do ponto 4 (Ordem CAIXA-HUD-JOGADORA-TECTO-DESVIO-PONTO-4)

Teste: `rascunhos/cliente/testes/caixa_jogadora.gd` §8, no commit `762088f` (o tecto, B1), sem mudanças locais.
Godot 4.7.2.stable.official.ed1daf0bf (`Godot_v4.7.2-stable_win64.exe` do PC), `--headless` (sem GPU), Windows.
Antes: `--import` do cliente, rc 0. Depois: `--path rascunhos/cliente -s res://testes/caixa_jogadora.gd`.
Unidades (u) = as da tela do HUD (a altura é sempre 1080 u).

## Desvio do centro da faixa, por resolução

| Resolução | Desvio medido (u) | Tecto (u) | Tecto: passa? | Fasquia do critério (≤ 1 u): passa? | Margens esq / dir (u) |
|---|---|---|---|---|---|
| 844×390 | 539,0 | 539,0 | **sim** | não | 126 / 1204 |
| 780×360 | 576,0 | 576,0 | **sim** | não | 136 / 1288 |
| 1920×1080 (controlo) | 350,5 | 350,5 | **sim** | não | 77 / 778 |

Os números são os mesmos da MEDICAO-8-FIGURAS: as linhas `MEDIDA` e `REGISTO` das 3 corridas desta pasta são iguais,
byte a byte, às do `medicao-8-figuras/corrida-2-final.log`. Por isso o `medicao-8-figuras/TABELA.md` não muda.

## As corridas (3 logs nesta pasta, todos com 54 linhas)

| Log | Como | Resultado | SHA-256 |
|---|---|---|---|
| `variante-estrita.log` (B2) | `... -s res://testes/caixa_jogadora.gd -- --estrita` | **33 de 36**, rc 1. As 3 `FALHA` são o ponto 4 (`[estrita] a faixa continua centrada`) em 844×390, 780×360 e 1920×1080 | `9ec842a9…214ca35d` |
| `corrida-tecto.log` (B3) | `... -s res://testes/caixa_jogadora.gd` (como o CI) | **36 de 36**, rc 0, 0 linhas com `FALHA`, `ERROR` ou `WARNING` | `d5e6ca12…60d4e795` |
| `sensibilidade.log` (extra) | tecto 1920×1080 posto em 350,0 (era 350,5) só no ficheiro local, sem commit; reposto logo a seguir | **35 de 36**, rc 1: só o tecto 1920×1080 falha (350,5 > 350,0). O tripwire dispara | `9819a7f3…f3b700f0` |

Fora do ponto 4, a variante estrita dá o mesmo resultado que a `medicao-8-figuras/corrida-1-criterio.log`. A única
diferença no texto é a frase da barra (agora «barra inferior»), já mudada na MEDICAO-8-FIGURAS.
