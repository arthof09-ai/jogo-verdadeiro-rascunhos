# Provas — ORDEM-D-AUD-01-CORRECCOES-3 (24/11/2026)

A conferência da D-AUD-01-CORRECCOES-2 (855, ENTRA COM CORRECÇÕES) deixou dois buracos de prova:

- **B1:** o teste da vez não isolava o ramo `vez != _vez` do `atualizar()`. A guarda já era `""` antes de a vez
  mudar.
- **B2:** em `iniciar_mover()`, com `_casas` vazio, `a_mover` passa a `false` sem `parar_mover()`.

Esta ordem acrescenta o teste isolado do B1, prova que o B2 é inalcançável (a prova está no ESTADO-FINAL, §2) e
aplica a errata A3 ao comentário do duplo armar. O código de produção não mudou.

A prova usa só o teste de unidade, as suites e o CI, tudo headless. **A bancada de rede não correu.** Não há
capturas.

## Duas corridas do `pecas_mestre` (`suites/`)

**Todos os logs começam com a linha do comando**, incluindo o `pecas_mestre.log`. A 1.ª linha do `pecas_mestre-SEM-RAMO-DA-VEZ.log` é um comando anotado (a
mutação descrita entre parênteses,
sem `MESTRE_COMANDOS` nem `timeout 300`); essa corrida não escreveu
`comandos-*.jsonl` e o seu exit não está
no `resumo.txt`.
Tirei o caminho da máquina e
pus `<sede>` no lugar.

1. `pecas_mestre-SEM-RAMO-DA-VEZ.log`: os testes desta ordem com o `aba_agir.gd` **sem** as linhas 63-64
   (`if vez != _vez: parar_mover()`). É uma mutação temporária, não commitada, e foi desfeita com `git checkout`.
   Resultado: **294 de 295**.
   - A única FALHA é o teste novo: `guarda depois «orc-teste», a_colocar «orc-teste», 1 MASTER_PLACE ["orc-teste"]`.
   - O teste da D-AUD-01-CORRECCOES-2 («mover usado → a vez muda») passa **sem** o ramo. Isso confirma o B1.
   - Não há falhas em cascata, porque o teste novo responde ao `MASTER_PLACE` a mais.
2. `pecas_mestre.log`: o código da ponta com os testes desta ordem (`bd3c79b`). Resultado: **295 de 295**.

**Não há corrida ANTES à parte.** O código de produção não mudou, por isso o teste novo sobre o código da ponta
`e671f49` é a própria corrida 2.

## Suites (`suites/`, resumo em `suites/resumo.txt`, guião em `suites.sh`)

Correram neste PC com Godot 4.7.2 `--headless` e Node, sobre `bd3c79b`. São as mesmas da D-AUD-01-CORRECCOES-2.
O guião é o mesmo, com duas diferenças: cada log ganhou a linha do comando, e o `validar-mensagens.py` entrou no
guião.

| Suite | Resultado | Na D-AUD-01-CORRECCOES-2 |
|---|---|---|
| servidor (`testes/*.test.mjs`) | 435/435 | 421/421 (a linha cresceu entre `68ffd3e` e `e671f49`) |
| motor real (`testes-motor-real`) | 2/2 | 2/2 |
| prova da caixa | PROVA OK | PROVA OK |
| `abrir_scripts` | 111 scripts, 0 falhas | 108 (idem) |
| `rodar_testes` | 321 de 321 | 321 |
| `abrir_mestre` | 67 de 67 | 67 |
| `pecas_mestre` | **295 de 295** | 294 |
| `medir_mestre` | 0 falhas, 0 sem medida | 0, 0 |
| `hud_acoes` | 50 de 50 | 50 |
| `caixa_jogadora` | 70 de 70 | 70 |
| `caixa_janela` | 123 de 123 | 123 |
| canário de privacidade | 10 de 10 | 10 |
| `validar-mensagens.py` | `pecas_mestre` 29 mensagens, 0 falhas; `abrir_mestre` 9, 0 falhas | 29 / 9 |

Todas deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`.

O teste novo não manda comandos quando passa, por isso o `pecas_mestre` continua com 29 mensagens.
