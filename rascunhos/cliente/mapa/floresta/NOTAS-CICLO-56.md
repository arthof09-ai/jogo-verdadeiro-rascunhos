# Ordem 56 — o ano e as estações no relógio do mundo · notas de medição

Ramo `fable/ciclo-43`, sobre a ponta `0435aa7` (o ESTADO FINAL da Ordem 55). Godot 4.7.2.stable,
Compatibility, RTX 4060, 1920×1080, sem v-sync. Continua a ser **apresentação**: nenhuma regra,
custo ou turno lê a estação.

Era a reserva da Ordem 43 («o dia não tem estações: a declinação do sol é fixa, 9,5°»). Os números
desta nota saem de dois ficheiros, gravados pelas ferramentas (não à mão):

- `capturas/ciclo56/estacoes.json` — `ferramentas/provar_estacoes.gd -- --referencia=… --referencia55=… --gravar` (headless);
- `capturas/ciclo56/medicao_estacoes.json` — `ferramentas/filmar_dia.gd -- --estacoes` (com render).

## A escolha do ano

As NOTAS-CICLO-43 e 55 **não fixam um comprimento de ano**. Fica o que a ordem dá:

- **cada estação dura 28 dias do mundo** (uma volta completa da lua) e **o ano tem 112**
  (`DIAS_ESTACAO = 28`, `DIAS_ANO = 112`);
- os nomes, por ordem: **primavera** (dias 0–28), **verão** (28–56), **outono** (56–84),
  **inverno** (84–112), e dá a volta;
- **o meio de cada estação é o ponto do ano que lhe dá o nome**: o equinócio da primavera (dia 14),
  o dia mais longo (verão, dia 42), o equinócio do outono (dia 70), o dia mais curto (inverno,
  dia 98). Assim o verão tem o dia mais longo e o inverno o mais curto, como a ordem pede. Com as
  estações a começar nos equinócios e solstícios (a convenção astronómica), o meio da primavera e
  o do verão teriam o mesmo dia, e a prova «verão a maior» não se fazia.

**A estação de referência é a primavera, dia 21 do ano** (`DIA_ANO_REFERENCIA = 21`): 7 dias depois
do equinócio, 1/16 de ano. **O mundo abre nesse dia** (`DIA_ANO_INICIAL`). É o dia da Ordem 43:
declinação 9,5°, nasce às 06:00, põe-se às 19:00.

## A regra

- **O que o ano muda é só a declinação do sol.** É uma sinusóide:
  `δ(d) = A · sen(2π (d − 14)/112)`, escrita no código como
  `9,5 + A · (sen φ(d) − sen φ(21))`. É o mesmo número, mas no dia 21 a diferença é **0 exacto** e a
  declinação sai **9,5 bit a bit** (sem caso especial no código).
- **A amplitude** `A = 9,5° / sen(π/8) = 24,82°` é a que faz a sinusóide passar por 9,5° no dia de
  referência. (A Terra tem 23,44°; este mundo não é a Terra.)
- **Daí sai tudo o resto pela trigonometria de sempre**: quando o sol nasce e se põe, a que altura
  passa ao meio-dia, de onde nasce. E **a cor dele sai das mesmas tabelas de cor por elevação** (o
  sol de inverno ao meio-dia está a 27–29°, abaixo da chave dos 30°, e por isso é mais quente).
- **Nenhuma curva de luz muda.** As tabelas por elevação, a luz-chave, o `lua_baixa`, o `CEU_LUZ`,
  o piso `0,46` e as energias ficam iguais. O meio-dia solar fica às 12:30 em todas as estações.
- **O dia do ano anda CONTÍNUO com o relógio**: 1/1440 por minuto do mundo, dentro de
  `avancar_horas`, tal como os `dias`. Por isso não há salto em lado nenhum: a declinação muda no
  máximo 0,00097° por minuto do mundo, e a duração do dia no máximo 8,7 min de um dia para o
  seguinte. **O nome da estação vira quando o dia do ano passa por 28, 56, 84 e 112**. Como o
  mundo abre às 16:15 do dia 21, as viradas caem às 16:15 do relógio. No minuto em que o nome muda,
  nada do que se vê muda (provado, abaixo).
- `definir_hora()` não mexe no ano, tal como não mexe na lua nem nos `dias`.

**O que NÃO muda com o ano** (provado): a lua (o sítio, a fase, o disco, a idade, a troca das
12:30), a névoa, o vento, o clima e o mapa. A lua continua na mesma posição da Ordem 43, com
declinação 0 e a culminar às 00:30. Em `calcular()` a luz da lua continua a depender do sol (só há
luar com o sol posto), como sempre. Por isso as horas de luar mudam com a duração da noite; a
curva não muda.

**A névoa continua a seguir a hora do relógio** (a bruma da madrugada às 06:12 em todas as
estações). Foi uma escolha: a névoa é uma curva da hora, não da posição do sol, e a ordem manda
não tocar no clima. Movê-la com o nascer do sol mudava os passos dela por minuto. Fica como reserva.

### O sol nas estações (de `estacoes.json`)

| | dia | δ | nasce | põe-se | horas de sol | sol ao meio-dia | sol às 18:00 | nasce a |
|---|---|---|---|---|---|---|---|---|
| meio da primavera (equinócio) | 14 | 0° | 06:30 | 18:30 | **12,000** | 52,0° | 5,9° | 90,0° (leste) |
| **referência** (primavera) | **21** | **9,5°** | **06:00** | **19:00** | **13,002** | **61,5°** | **11,7°** | **77,9°** |
| meio do verão (o mais longo) | 42 | 24,8° | 05:05 | 19:55 | **14,825** | 76,8° | 20,6° | 57,8° |
| verão, dia 21 da estação | 49 | 22,9° | 05:13 | 19:47 | 14,574 | 74,9° | 19,6° | 60,4° |
| meio do outono (equinócio) | 70 | 0° | 06:30 | 18:30 | **12,000** | 52,0° | 5,9° | 90,0° |
| outono, dia 21 da estação | 77 | −9,5° | 07:00 | 18:00 | 10,998 | 42,5° | 0,0° | 102,1° |
| meio do inverno (o mais curto) | 98 | −24,8° | 07:55 | 17:05 | **9,175** | 27,2° | −9,5° | 122,2° |
| inverno, dia 21 da estação | 105 | −22,9° | 07:47 | 17:13 | 9,426 | 29,1° | −8,3° | 119,6° |

As horas de sol foram contadas também minuto a minuto, com o sol acima de 0°: 720 · 780 · 890 ·
874 · 720 · 660 · 550 · 566 minutos, pela ordem da tabela. Batem com a conta.

**A cor do sol ao meio-dia** (`cor_luz_sol` às 12:30): referência e verão `#fff4de` (o sol acima
dos 60°) · equinócios `#fff2d7` (52°) · outono, dia 77 `#ffebc4` (42,5°) · inverno `#ffe5b2`–`#ffe6b4`
(27–29°). Às 16:15: referência `#ffe6b5`, verão `#ffeac1`, inverno `#ffb66d`–`#ffbe79` (o sol a 8–9°,
cor de fim de tarde).

## A API (a convenção das NOTAS-CICLO-55: consultas no nó, contas puras estáticas)

| | |
|---|---|
| `relogio.dia_do_ano()` | float 0–112, contínuo (21 = o dia de referência) |
| `relogio.estacao()` | `"primavera"` \| `"verão"` \| `"outono"` \| `"inverno"` |
| `relogio.duracao_do_dia()` | float, horas de sol acima do horizonte no dia do ano de agora |
| `relogio.definir_dia_do_ano(d)` | põe o ano num dia (dá a volta aos 112); a hora e a lua não mudam |
| sinal `estacao_mudou(estacao)` | quando o nome da estação muda |
| `CicloDia.estacao_de(d)` · `declinacao_de(d)` · `semiarco_de(d)` · `duracao_do_dia_de(d)` · `nascer_e_por_de(d)` | puras (estáticas) |
| `CicloDia.calcular(h, idade = LUA_CHEIA, dia_do_ano = DIA_ANO_REFERENCIA)` | a mesma de sempre; o dia do ano é **opcional** e por omissão é a referência |
| `CicloDia.sol(h, dia = referência)` · `fase_de(h, dia = referência)` | idem |
| `estado()` | ganha `ano_dia`, `estacao`, `sol_declinacao`, `dia_duracao` |
| `campo_floresta.estacao()` | na raiz da cena, como `fase_da_lua()` |

**Assinaturas:** nenhuma função antiga mudou de forma. `calcular`, `sol` e `fase_de` só ganharam um
argumento opcional no fim: quem as chama como antes recebe o mesmo, bit a bit. As chaves novas do
`estado()` juntam-se às antigas, que ficam todas. São floats constantes ao longo de um dia
congelado, e uma string. Por isso `provar_ciclo_vento.gd` não as mede e o
`curvas_ciclo_vento.json` sai igual byte a byte.

Na cena: **Y** avança 7 dias do ano (¼ de estação), **Shift+Y** recua 7. O rótulo da medição (tecla
M) mostra a estação, o dia do ano e as horas de sol.

## As provas

### Em números — `provar_estacoes.gd` (headless; sai com 1 se falhar)

**27 de 28** com `--referencia` (o `ciclo_dia.gd` da Ordem 43, `d7b9e6c`, sha256 `4923caea…93d2`) e
`--referencia55` (o da Ordem 55, `0435aa7`, sha256 `d08bb5a8…797d`). Sem elas, 22 de 23.

1. **Âncora (a regressão), toda verde:**
   - No dia de referência a declinação é exactamente 9,5 (`9.50000000000000000`), e o mundo abre aí
     (dia 21, primavera).
   - `calcular(h)` = `calcular(h, cheia, 21)` = o `estado()` de um relógio novo, nos 1440 minutos:
     0 diferenças.
   - **Contra a Ordem 43: as 40 saídas iguais bit a bit nos 1440 minutos** (0 diferenças).
   - **Contra a Ordem 55: as 45 saídas iguais bit a bit nos 1440 minutos**, na cheia e também nas
     idades 0, 7, 21, 3,5, 10 e 25 (0 diferenças).
2. **As estações:**
   - Os nomes estão certos.
   - **A duração do dia no meio das estações: verão 14,825 h > primavera 12,000 h = outono
     12,000 h > inverno 9,175 h.**
   - O dia mais longo do ano é o dia 42,0 e o mais curto o 98,0 (procurados de 0,1 em 0,1 dia).
   - No dia de referência nasce às 06:00 e põe-se às 19:00.
3. **Só o sol muda:** de um dia do ano para outro, a lua (sítio, fase, disco), a névoa e o relógio
   não mudam.
4. **As fases da lua intactas em todas as estações:** a nova não dá luz em minuto nenhum, e os
   quartos dão exactamente ½ da cheia (maior erro 0).
5. **O relógio um ano inteiro** (112 × 1440 passos de 1 minuto):
   - O sinal `estacao_mudou` sai 4 vezes, pela ordem verão → outono → inverno → primavera, nos dias
     28, 56, 84 e 112.
   - O relógio volta ao ponto de partida: 112 dias, 16:15, dia do ano 21 (resto 1,6·10⁻¹⁰),
     primavera, lua cheia.
   - **Na viragem do nome, nenhum passo é maior do que no mesmo minuto do dia antes ou do dia
     depois: excesso 0 nas 4 viradas.**
   - `definir_hora` não mexe no ano. `definir_dia_do_ano` dá a volta aos 112 e dá o sinal quando
     muda de estação.
   - **O ano a correr não junta passo que se veja**: em cada minuto, a parte do passo que vem do
     ano (o mesmo minuto, com o dia do ano antes e depois) fica, no máximo, em **0,49 %** do maior
     passo do dia de referência.
6. **Continuidade contra a referência:**
   - No verão (dias 28–56) nenhum passo por minuto passa o do dia de referência: ✔.
   - **O critério da ordem à letra («nenhum passo por minuto maior que o da referência») NÃO SE
     CUMPRE: ✘.** Explicação logo abaixo.

### O passo por minuto contra a referência — a verificação que falha

Medido com a régua da Ordem 43 (cores pelo maior canal, direcções pela distância dos vectores,
números pela diferença), com o dia do ano congelado e a lua cheia, em cada um dos 112 dias. Num dia
inteiro, o maior passo **passa o do dia de referência em 48 dos 112 dias**: 0–20, 24, 60, 64–86 e
110–111.

| estação | quantas saídas passam | as maiores |
|---|---|---|
| primavera | 25 | `cor_luz` +6,9 % · `estrelas` +5,8 % · `cor_arrebol`/`cor_baixo`/`cor_horizonte` +4,8 % |
| verão | **0** | — |
| outono | 25 | as mesmas da primavera (o ano é simétrico) |
| inverno | 7 | `estrelas` +1,9 % · `cor_arrebol` +1,4 % · `noite` +0,1 % |

O pior num dia inteiro é `cor_luz` no dia 71: **0,0596 por minuto, contra 0,0557** na referência
(+6,9 %). Com o ano a correr, o máximo cai entre dois dias inteiros e chega a **+8,6 %** (`cor_luz`).

**Porquê, e porque não se corrige sem mudar a regra:**

- A latitude é fixa (38°). O sol atravessa o horizonte a `15° · cos 38° · cos δ · sen H₀` por hora,
  e isto é **máximo com δ = 0** (nos equinócios). Com δ = 0 dá 11,82°/h; no dia de referência
  (δ = 9,5°) dá 11,55°/h.
- No crepúsculo fundo (−18°) o mais rápido é δ ≈ −11° (dentro do inverno).
- O dia de referência tem de ser δ = 9,5° (a âncora bit a bit). Por isso **qualquer ano que passe
  pelos equinócios tem dias com a passagem do crepúsculo mais rápida do que a referência**. As
  curvas de luz são as mesmas; só são percorridas um pouco mais depressa.
- Em `dir_sol` há até um argumento de contagem: num dia com δ = 0 o sol percorre um círculo de
  360°, e no de referência um de 355,1°. Um passo máximo menor ou igual ao da referência em todos os
  minutos é impossível.
- Não é um salto. O maior passo de `cor_luz` passa de 0,0557 a 0,0596 por minuto do mundo. Com o
  dia de 24 min, isso é 1 s real, espalhado por 60 quadros. É uma rampa 7 % mais curta, não um
  degrau.

A verificação **ficou na prova, e falha**. Não lhe mudei a régua para a pôr verde. As saídas para o
coordenador e para o Mestre:

1. **aceitar** e trocar a régua por «nenhum passo maior do que o maior do ano físico» ou «nenhum
   degrau na viragem» (estas duas estão provadas);
2. **uma «hora solar» não uniforme** que atravesse o crepúsculo ao passo da referência e ande mais
   depressa perto do meio-dia e da meia-noite. Deixa de ser a trigonometria simples. Não resolve
   `dir_sol` (pelo argumento de contagem), e a lua, que está fixa no relógio, cruza-se com o sol de
   outra maneira em cada estação;
3. **mudar a âncora** (a referência num equinócio). Viola a ordem: a referência tem de ser o mundo
   de hoje, δ = 9,5°.

Recomendo a 1.

### Ainda as provas de antes, sobre o código novo

- `provar_fases_lua.gd` com `--referencia` (o da Ordem 43): **24 de 24**, a mesma saída da Ordem 55
  (sem uma vírgula mudada na prova).
- `provar_ciclo_vento.gd`: o `capturas/ciclo43/curvas_ciclo_vento.json` sai **igual byte a byte**.

### Por render — as 4 estações (`filmar_dia.gd -- --estacoes`)

`capturas/ciclo56/c56_18h00_{1-primavera,2-verao,3-outono,4-inverno}.jpg` e `_folha_estacoes.jpg`
(as 4 numa folha, 2×2):

- **a mesma hora (18:00)**, o mesmo enquadramento das capturas da Ordem 55 (a orla sul da clareira
  a olhar para norte), **a lua cheia** e o mesmo vento (corre 6 s antes da 1.ª e fica parado);
- o relógio parado;
- **só o dia do ano muda: o 21.º de cada estação**. O da primavera é o dia de referência. Os quatro
  dias têm δ = +9,5° · +22,9° · −9,5° · −22,9°, por isso as 4 imagens são diferentes. Nos meios
  das estações, a primavera e o outono tinham o mesmo sol;
- no painel: a estação, o dia do ano, o nascer, o pôr, as horas de sol, a declinação e o sol ao
  meio-dia.

| estação | dia | sol às 18:00 (az, elev) | fase do dia | `cor_luz` | `ceu_luz` | lume | luma da cena (0–255) | % quase preto | FPS | chamadas |
|---|---|---|---|---|---|---|---|---|---|---|
| primavera (referência) | 21 | 273,0°, **11,7°** | tarde | `#eabc80` | 0,92 | 0 | **72,3** | 0,0 | 1272 | 80 |
| verão | 49 | 284,3°, **19,6°** | tarde | `#f3d097` | 0,96 | 0 | **86,5** | 0,0 | 1283 | 80 |
| outono | 77 | 257,9°, **0,0°** | entardecer | `#6e3452` | 0,62 | 0,19 | **51,8** | 1,2 | 1285 | 80 |
| inverno | 105 | 247,3°, **−8,3°** | noite | `#131733` | 0,31 | 1 | **12,6** | 39,4 | 1282 | 80 |

(Luma, FPS e chamadas medidos só na cena, sem o painel nem o encaixe; 1 197 363 primitivas em
todas.) As estações não custam nada que se meça: 80 chamadas em todas.

**Visto com os olhos (as 4 na folha):**

- **Primavera:** a tarde da Ordem 43, com o sol baixo a oeste.
- **Verão:** ainda dia claro, a relva mais amarela de luz.
- **Outono:** o pôr do sol, com o arrebol vermelho atrás da Árvore e a orla em contraluz.
- **Inverno:** noite, as janelas da Árvore acesas, o céu azul-escuro. A lua cheia ainda não nasceu
  (nasce às 18:30) e a cena está escura.

**Âncora por render:** o modo `--fases`, corrido de novo sobre o código desta ordem (no dia de
referência), dá os números da Ordem 55: luma 9,7 · 25,2 · 32,7 · 25,2 e disco claro 0 · 14,78 ·
30,26 · 14,55 %. Diferem só os FPS e 0,01 % do «quase preto» na cheia (o ruído do render, ver
NOTAS-CICLO-55). A captura da primavera às 18:00 é o mundo da Ordem 43 a essa hora.

### As suites (localmente, sobre a ponta)

| suite | resultado |
|---|---|
| `testes/abrir_scripts.gd` | 59 scripts, 0 falhas (os 58 de antes + `provar_estacoes.gd`) |
| `testes/rodar_testes.gd` | 138 de 138 |
| `testes/abrir_clareira.gd` | 22 de 22 |
| `testes/medir_painel_config.gd` | 0 falhas |
| `testes/abrir_mestre.gd` | 57 de 57 |
| `testes/pecas_mestre.gd` | 223 de 223 |
| `testes/medir_mestre.gd` | 0 falhas |
| `testes/hud_acoes.gd` | 32 de 32 |
| `testes/canario_privacidade.gd` | 10 de 10 |
| a cena `campo_floresta.tscn` em headless (300 quadros) | erros 0, carga 1425 ms |
| `provar_altura.gd` | maior 0,00002 m (consulta) · 0,000050 m (malha). Igual sobre `0435aa7` |
| `provar_costura.gd` | **VERMELHA, 67/255**, igual linha a linha à ponta `0435aa7` (corrida numa worktree à parte). Não se lhe mexeu |

### Para o CI (não entrou: o token desta máquina não tem o âmbito `workflow`)

O passo, para o job `cliente` de `.github/workflows/testes.yml`, a seguir ao das fases da lua
(NOTAS-CICLO-55). Corre sem as referências, e por isso faz 23 verificações. **Hoje sai VERMELHO**
(22 de 23), pela verificação do critério à letra. Não se deve juntar antes de o coordenador decidir
a régua (ver acima). Dura ~1 min 25 s nesta máquina.

```yaml
      - name: O ano e as estações no relógio do mundo (Ordem 56)
        if: always()
        run: |
          set -o pipefail
          timeout 300 "$GODOT" --headless --path . -s res://mapa/floresta/ferramentas/provar_estacoes.gd 2>&1 | tee "$RUNNER_TEMP/provar_estacoes.log"
          ! grep -E "SCRIPT ERROR|Parse Error|Compile Error" "$RUNNER_TEMP/provar_estacoes.log"
          grep -E "^[0-9]+ de [0-9]+ verificações passaram\.$" "$RUNNER_TEMP/provar_estacoes.log"
```

## Achados (encontrados pelo caminho; ditos, não escondidos)

- **O modo `--fases` da Ordem 55 nunca chegou ao repositório.**
  - O ESTADO-FINAL-ORDEM-55 dá-o como entregue em `356a89f`, mas esse commit só trouxe as capturas.
    O `filmar_dia.gd` estava como na Ordem 43 (`4a0219a`).
  - Foi reposto em `d194876` com o próprio script de edição da Ordem 55
    (`fable-ciclo/ferr/o55_editar_filmar.py`, fora do repositório).
  - Corrido de novo, dá os números das capturas cometidas (acima).
  - Juntou-se uma guarda: o painel desenhava antes de existir a câmara da lua (um `SCRIPT ERROR`
    no arranque).
- **A meia-noite tem um degrau, que é da Ordem 43.**
  - O peso `manha` vale `_suave(−0,5; 1,5; h)`, mas `h` vem de `fposmod(h, 24)` e nunca é negativo.
    Às 00:00 o peso salta de 0 para 0,156.
  - Mexe só nas tintas da tabela da manhã/tarde que de noite diferem: `cor_luz_sol`, `cor_disco` e
    `cor_clarao`, as do sol. Com o sol abaixo de −18° nada disso se vê, e o sol à meia-noite está a
    −27° ou mais baixo em todas as estações.
  - Está no `curvas_ciclo_vento.json` desde a Ordem 43 (`manha` 0,156; `cor_luz_sol` 0,0196 às
    00:00). Não se lhe mexeu.
- **A lua cheia já não está sempre oposta ao sol.** A lua ficou onde estava (a ordem manda deixá-la
  intacta). Nasce sempre às 18:30, e o sol põe-se às 17:05 no inverno e às 19:55 no verão.
  - No inverno fica uma ponta de noite sem lua: com a cheia, das 17:13 às 18:30 no dia 105. É a
    captura de inverno, luma 12,6.
  - No verão a lua nasce com o sol ainda no céu.
  - É a mesma reserva da Ordem 55 («a lua não anda com a fase»), agora também com a estação.
- **As tabelas da manhã e da tarde só coincidem acima dos 30°.** No inverno o sol do meio-dia fica a
  27–29°, por isso a troca manhã→tarde (11:30–13:30) passa-se com o sol abaixo da chave dos 30°. A
  diferença entre as duas tabelas aí é de ~1/255 na cor do sol: é uma rampa de 2 h, e não se vê.

## O que ficou por fazer

- O olho do Mestre: nenhuma destas notas aprova nada. Ver a folha `_folha_estacoes.jpg`.
- A régua da continuidade (acima): a decisão é do coordenador.
- A névoa não segue o nascer do sol (é por hora do relógio).
- A lua não anda com a estação nem com a fase.
- Só o sol muda com o ano: as árvores, a relva e o céu não têm cores de estação (não foi pedido; as
  curvas de luz não mudam).
- O passo do CI (acima) não entrou.
