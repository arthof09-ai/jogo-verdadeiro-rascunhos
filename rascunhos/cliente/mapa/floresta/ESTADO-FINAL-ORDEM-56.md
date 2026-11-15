# ESTADO FINAL — Ordem 56 (as estações do ano no relógio do mundo)

Ramo `fable/ciclo-43`, trabalhado directamente sobre a ponta `0435aa7` (o ESTADO FINAL da Ordem
55), sem ramo novo. Clone em `C:\Users\txcga\fable-ciclo\repo`. `main` não foi tocado: continua em
`2383737`. Sem merges, sem force.

**Quem fez:** uma sessão só, Claude conta 1 a correr em **Opus 5.5** (`claude-opus-5-5`).

As medidas, os números e as tabelas estão em `NOTAS-CICLO-56.md`.

## A escolha registada

- **O ano: 112 dias do mundo, 4 estações de 28** (uma volta da lua cada). As NOTAS-CICLO-43/55
  não fixavam um ano, por isso fica o da ordem.
- **Os nomes**, por ordem: primavera (0–28), verão (28–56), outono (56–84), inverno (84–112).
  **O meio de cada estação é o ponto que lhe dá o nome**: equinócio, dia mais longo, equinócio,
  dia mais curto. Assim o verão tem o dia mais longo e o inverno o mais curto.
- **A estação de referência é a primavera, dia 21 do ano.** A declinação do sol aí é
  **exactamente 9,5°**: é o dia da Ordem 43 e da 55, bit a bit. **O mundo abre nesse dia**, na lua
  cheia, às 16:15.
- **Só a declinação do sol muda com o ano.** É uma sinusóide de amplitude 24,82° (a que passa por
  9,5° no dia 21), e anda contínua com o relógio (1/1440 por minuto). O nascer, o pôr, a altura e a
  cor do sol saem dela pelas contas e pelas tabelas de sempre. **Nenhuma curva de luz mudou.**
- **Não seguem o ano**: a lua (intacta, como a ordem manda), a névoa (fica por hora do relógio;
  escolha dita nas notas), o vento, o clima e o mapa. O equilíbrio da noite e o `lua_baixa` não
  foram tocados.
- A duração do dia: verão **14,8 h** · primavera e outono **12,0 h** · inverno **9,2 h** (no meio
  de cada estação); a referência tem 13,0 h.

## Prova corrida no fecho

- **`provar_estacoes.gd` (nova, headless): 27 de 28.** Corre com `--referencia`, o `ciclo_dia.gd`
  de `d7b9e6c` (Ordem 43), e com `--referencia55`, o de `0435aa7` (Ordem 55).
  - Âncora: no dia de referência com lua cheia, **as 40 saídas da Ordem 43 e as 45 da Ordem 55
    saem iguais bit a bit nos 1440 minutos**, e nas outras idades da lua também.
  - Duração do dia no meio das estações: verão 14,825 h > primavera 12,000 = outono 12,000 >
    inverno 9,175 h.
  - Com o ano, só o sol muda; as fases da lua ficam intactas em todas as estações.
  - **Um ano a andar minuto a minuto vira a estação 4 vezes, por ordem, e volta ao ponto de
    partida** (dia 21, lua cheia, resto 1,6·10⁻¹⁰).
  - **Na viragem do nome o passo é igual ao do dia antes e ao do dia depois** (excesso 0).
  - O ano a correr junta, no máximo, 0,49 % ao passo de um minuto.
  - **A verificação que falha** é o critério da ordem à letra: «nenhum passo por minuto maior que o
    da referência». Está explicada em «O que falta conferir».
  - Sem referências: 22 de 23.
- **`provar_fases_lua.gd` (a da Ordem 55, sem uma vírgula mudada): 24 de 24.**
- `provar_ciclo_vento.gd` (a da Ordem 43): o `curvas_ciclo_vento.json` sai **igual byte a byte**.
- Render (RTX 4060, Compatibility, 1920×1080): as 4 estações às 18:00.
  - Luma da cena: primavera **72,3** · verão **86,5** · outono **51,8** (o pôr do sol) · inverno
    **12,6** (noite).
  - **80 chamadas em todas**, 1272–1285 FPS sem v-sync.
- O modo `--fases` (reposto, ver abaixo), corrido de novo sobre o código desta ordem, dá os números
  da Ordem 55: luma 9,7 · 25,2 · 32,7 · 25,2.
- As suites, localmente, sobre a ponta:

| suite | resultado |
|---|---|
| `testes/abrir_scripts.gd` | 59 scripts, 0 falhas |
| `testes/rodar_testes.gd` | 138 de 138 |
| `testes/abrir_clareira.gd` | 22 de 22 |
| `testes/medir_painel_config.gd` | 0 falhas |
| `testes/abrir_mestre.gd` | 57 de 57 |
| `testes/pecas_mestre.gd` | 223 de 223 |
| `testes/medir_mestre.gd` | 0 falhas |
| `testes/hud_acoes.gd` | 32 de 32 |
| `testes/canario_privacidade.gd` | 10 de 10 |
| a cena `campo_floresta.tscn` em headless (300 quadros) | erros 0, carga 1425 ms |
| `provar_altura.gd` | maior 0,00002 m (igual sobre `0435aa7`) |
| `provar_costura.gd` | **VERMELHA, 67/255**, igual linha a linha à ponta `0435aa7`. Não se lhe mexeu (decisão do coordenador) |

- CI: corre no push do fecho. O resultado fica no commit seguinte a este. Os workflows não foram
  tocados: o passo da prova nova fica em texto nas notas («Para o CI»).

## ESTADO FINAL — Passagem

**O que mudou** (commits, do mais antigo ao mais novo):

- `d194876`: **o modo `--fases` da Ordem 55 reposto** em `filmar_dia.gd`. Nunca tinha chegado ao
  repositório (ver «O que falta conferir»). Mais uma guarda para um `SCRIPT ERROR` no arranque.
- `c7ef7dc`: **a construção.**
  - `ciclo_dia.gd`: o dia do ano contínuo, a declinação do sol por estação e a API
    `dia_do_ano()`, `estacao()`, `duracao_do_dia()`, `definir_dia_do_ano()`, mais o sinal
    `estacao_mudou`.
  - As puras `estacao_de`, `declinacao_de`, `semiarco_de`, `duracao_do_dia_de` e
    `nascer_e_por_de`.
  - `calcular`, `sol` e `fase_de` ganham o dia do ano como argumento opcional; por omissão é a
    referência.
  - `campo_floresta.gd`: repinta quando o dia do ano muda; tecla Y / Shift+Y (±7 dias);
    `estacao()` na raiz; a estação no rótulo.
- `f96fade`: `provar_estacoes.gd` e `capturas/ciclo56/estacoes.json`.
  **Push do fim da 1.ª parte: `0435aa7..f96fade`, sem force.**
- `2958f5f`: o modo `--estacoes` em `filmar_dia.gd` e as capturas `c56_18h00_1-primavera`,
  `2-verao`, `3-outono` e `4-inverno`, mais `_folha_estacoes.jpg` e `medicao_estacoes.json`.
- `9cad015`: `NOTAS-CICLO-56.md`. Em `NOTAS-CICLO-43.md`, a linha da API e a reserva das estações
  dada por feita.
- (este commit): `ESTADO-FINAL-ORDEM-56.md`.

**Onde parou:** tudo o que a ordem pede está construído e commitado. Push no fecho. A prova nova
tem uma verificação vermelha, de propósito e explicada (abaixo).

**Próximo passo:** a conferência do coordenador e do Mestre:

1. ver `capturas/ciclo56/_folha_estacoes.jpg` (as 4 estações às 18:00, só o dia do ano muda), e
   depois as 4 em tamanho real;
2. na cena, **Y** anda ¼ de estação e Shift+Y recua; com **P** e **,** **.** escolhe-se a hora;
3. **decidir a régua da continuidade** (abaixo, e em NOTAS-CICLO-56 «a verificação que falha»).
   Só depois juntar ao CI o passo da prova nova.

**O que falta conferir:**

- **O critério «nenhum passo por minuto maior que o da referência» não se cumpre, e a prova diz
  isso (27 de 28).**
  - Num dia inteiro, o maior passo passa o do dia de referência em **48 dos 112 dias**: perto dos
    dois equinócios (dias 0–20, 24, 60, 64–86) e no fundo do inverno (110–111).
  - O pior é `cor_luz` no dia 71: 0,0596 contra 0,0557 por minuto do mundo, **+6,9 %**. Com o ano
    a correr, entre dias inteiros, chega a **+8,6 %**. No verão nada passa.
  - Não é um salto. É a geometria: com a latitude fixa, o sol atravessa o crepúsculo mais depressa
    nos equinócios (δ = 0) do que com δ = 9,5°. O dia de referência tem de ter 9,5° (a âncora), por
    isso nenhum ano que passe pelos equinócios cumpre a régua à letra.
  - Não mudei a régua para pôr a prova verde. As saídas estão nas notas: aceitar e trocar a régua
    («nenhum degrau na viragem», que está provado), uma «hora solar» não uniforme, ou mudar a
    âncora (viola a ordem). **Recomendo aceitar.**
- **O modo `--fases` da Ordem 55 nunca tinha chegado ao repositório.**
  - O ESTADO-FINAL-ORDEM-55 dá-o como entregue em `356a89f`, mas esse commit só trouxe as capturas.
  - Foi reposto com o script de edição da própria Ordem 55 (`fable-ciclo/ferr/o55_editar_filmar.py`),
    e corrido de novo dá os números das capturas cometidas.
  - Vale a pena conferir se mais alguma coisa da 55 ficou só na máquina. Conferi `ciclo_dia.gd`,
    `campo_floresta.gd`, `ceu_ciclo.gdshader` e `provar_fases_lua.gd`: estão todos no
    repositório e batem com o que a 55 descreve.
- **A lua cheia já não está oposta ao sol fora da referência** (a lua ficou intacta, como a ordem
  manda). No inverno fica uma ponta de noite sem lua: na captura de inverno ela ainda não nasceu
  (luma 12,6). No verão a lua nasce com o sol no céu. É a mesma reserva da 55 («a lua não anda»),
  agora também com a estação.
- **A névoa não segue o nascer do sol.** É por hora do relógio, por escolha (é clima, e mexer-lhe
  mudava os passos dela). A bruma da madrugada fica às 06:12 em todas as estações.
- **A meia-noite tem um degrau, que já vinha da Ordem 43.** O peso `manha` salta de 0 para 0,156 às
  00:00, mas só nas tintas do sol, que de noite não se vêem. Está nas notas e não se lhe mexeu.
- **`provar_costura.gd` continua vermelha (67/255)**, igual linha a linha à ponta da 55. A decisão é
  do coordenador.
- **O olho do Mestre:** nenhuma prova aprova as cores das estações. Só o sol muda: as árvores e a
  relva não têm cores de estação (não foi pedido).
