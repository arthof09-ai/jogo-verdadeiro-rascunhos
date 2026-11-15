# Ordem 55 — as fases da lua no relógio do mundo · notas de medição

Ramo `fable/ciclo-43`, sobre a ponta `d7b9e6c` (o ESTADO FINAL da Ordem 43). Godot 4.7.2.stable,
Compatibility, RTX 4060, 1920×1080, sem v-sync. Continua a ser **apresentação**: nenhuma regra,
custo ou turno lê a fase da lua.

Era a reserva declarada da Ordem 43 («a lua é sempre cheia»). Os números desta nota saem de dois
ficheiros, gravados pelas ferramentas (não à mão):

- `capturas/ciclo55/fases_lua.json` — `ferramentas/provar_fases_lua.gd -- --referencia=… --gravar` (headless);
- `capturas/ciclo55/medicao_fases.json` — `ferramentas/filmar_dia.gd -- --fases` (com render).

## A regra

- **O ciclo:** as fases dão a volta em **28 dias do mundo**. As NOTAS-CICLO-43 não diziam outra
  coisa, por isso fica o número da ordem (`DIAS_FASES_LUA = 28.0`).
- **A idade da lua** (dias desde a lua nova, 0–28) avança **1 dia por dia do mundo**. Muda às
  **12:30** (`LUA_TROCA_HORA`). A essa hora a lua está no ponto mais baixo, a −52°, e o sol a pino
  (61,5°). A luz da lua é 0 e o disco está debaixo do chão, por isso a mudança não se vê. Cada
  noite tem uma lua só.
- **O mundo abre na lua cheia** (`LUA_IDADE_INICIAL = LUA_CHEIA = 14`): o mundo da Ordem 43.
- **A quantidade de lua** é a fracção iluminada do disco, `(1 − cos α)/2`, com
  `α = 360° × idade/28`: nova **0**, quartos **½**, cheia **1**. É a área clara de uma esfera vista
  com o ângulo de fase α. Sai da fase; não é um número escolhido.
- **A luz da lua** = a luz da Ordem 43 × a fracção iluminada:

  `lua_energia = LUA_ENERGIA × lua_baixa × iluminada × (o sol posto) × (a lua acima do chão)`

  O `lua_baixa` (1,35× a 8° → 1× a 35°) e os valores dele ficam como estavam: a fase
  **multiplica-os**, não os substitui. Tudo o que já saía da luz da lua segue-a sem mais regra
  nenhuma: a luz-chave (`cor_luz`), a força das sombras do luar (`sombra_forca`), o ressalto e a
  DirectionalLight «Lua». Na lua nova a DirectionalLight apaga-se (`lua_energia = 0`).
- **O que NÃO muda com a fase:** o céu (as tintas, as estrelas, a luz do céu `ceu_luz`, a sombra
  colorida, a névoa), o sol, as luzes artificiais e o vento. A noite da lua nova fica com a luz do
  céu da Ordem 43 e com o piso da luz-chave (`sombra × 0,46`), que já lá estavam. Não se lhes
  mexeu (ver «a noite escura», abaixo).
- **O disco no céu** (`shaders/ceu_ciclo.gdshader`): o terminador é a elipse da esfera. Um ponto
  do disco é claro onde `s > cos α · √(1 − y²)`, com `s` medido para o lado claro. Na crescente o
  lado claro é o da direita (o poente, oeste) e na minguante o da esquerda (o nascente, leste),
  como se vê no hemisfério norte. A parte escura deixa ver o céu de trás, sem estrelas. O halo e o
  véu de dia seguem a fracção iluminada. **Na cheia o shader não entra no ramo novo**
  (`lua_terminador = −1`) e o halo é multiplicado por 1,0: é o disco da Ordem 43.
- **A posição da lua NÃO anda com a fase.** Fica a da Ordem 43, sempre oposta ao sol: nasce às
  18:30, culmina às 00:30 a 52°, põe-se às 06:30. É uma escolha, e fica dita: no céu verdadeiro a
  lua nova anda com o sol e o quarto crescente põe-se à meia-noite. Fazer a lua andar mudava a luz
  de todas as noites (de onde vem, a que horas há luar) e com ela o equilíbrio da noite, que a
  ordem manda não tocar. Fica como reserva, para o Mestre.

## A API (a mesma convenção do ficheiro: consultas no nó, contas puras estáticas)

| | |
|---|---|
| `relogio.idade_da_lua()` | float 0–28, dias desde a lua nova (14 = cheia) |
| `relogio.fase_da_lua()` | `"nova"` \| `"crescente"` \| `"cheia"` \| `"minguante"` |
| `relogio.lua_iluminada()` | float 0–1, a fracção iluminada do disco |
| `relogio.definir_idade_da_lua(d)` | põe a lua numa idade (dá a volta aos 28); a hora não muda |
| sinal `fase_da_lua_mudou(fase_da_lua)` | quando o nome da fase muda |
| `CicloDia.fase_da_lua_de(d)` · `iluminada_de(d)` · `angulo_de_fase(d)` | puras (estáticas) |
| `CicloDia.calcular(h, idade = LUA_CHEIA)` | a mesma de sempre; a idade é **opcional** e por omissão é a cheia |
| `estado()` | ganha `lua_idade`, `lua_fase`, `lua_iluminada`, `lua_terminador`, `lua_lado` |
| `campo_floresta.fase_da_lua()` | na raiz da cena, como `hora_do_mundo()` e `vento_actual()` |

**Assinaturas:** nenhuma função antiga mudou de forma. `calcular(h)` só ganhou um 2.º argumento
opcional; quem a chama com um só argumento recebe o mesmo dicionário, bit a bit. As chaves novas
juntam-se às antigas, que ficam todas.

Os nomes cobrem 7 dias cada, à volta da sua idade: nova 24,5–3,5 · crescente 3,5–10,5 · cheia
10,5–17,5 · minguante 17,5–24,5. («Crescente» e «minguante» são os quartos, como se diz em
português; os dias entre eles ficam com o nome mais perto.) `definir_hora()` não mexe na lua, tal
como não mexe nos `dias`; só o relógio a andar (`avancar` / `avancar_horas`) a faz avançar.

Na cena: **U** avança 1 dia da lua, **Shift+U** recua 1 dia. O rótulo da medição (tecla M) mostra
a fase e a idade.

### A fracção iluminada, dia a dia (de `fases_lua.json`)

| idade | 0 | 1 | 2 | 3 | 4 | 5 | 6 | **7** | 8 | 9 | 10 | 11 | 12 | 13 | **14** |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| fase | nova | nova | nova | nova | cresc. | cresc. | cresc. | **cresc.** | cresc. | cresc. | cresc. | cheia | cheia | cheia | **cheia** |
| iluminada | 0 | 0,013 | 0,050 | 0,109 | 0,188 | 0,283 | 0,389 | **0,5** | 0,611 | 0,717 | 0,812 | 0,891 | 0,950 | 0,987 | **1** |

Dos 15 aos 27 desce simétrica (minguante 18–24; nova outra vez a partir do 25).

## As provas

### Em números — `provar_fases_lua.gd` (headless; sai com 1 se falhar)

**24 de 24** com `--referencia` (22 de 22 sem ela):

1. **Âncora (a regressão):** o `ciclo_dia.gd` da Ordem 43 (`git show d7b9e6c:…`, sha256
   `4923caea…93d2`) e o novo, na cheia, dão as **40 saídas iguais bit a bit nos 1440 minutos do
   dia**: 0 diferenças. Iguais também `calcular(h)` = `calcular(h, cheia)` = o `estado()` de um
   relógio novo.
2. **Lua nova:** a luz da lua é 0 em todos os minutos.
3. **Quartos:** a luz da lua é exactamente ½ da cheia em todos os minutos (maior erro 0). A razão
   é a mesma em todos os 635 minutos com lua, a qualquer altura dela: o `lua_baixa` compõe-se com
   a fase e não muda.
4. **Só a lua muda:** entre fases, mudam só `lua_energia`, `cor_luz`, `sombra_forca`, `ressalto`
   e as chaves novas da lua. Tudo o resto sai igual: céu, sol, névoa, lume.
5. **O relógio:** 28 dias do mundo a andar minuto a minuto. A idade vira 28 vezes, sempre às 12:30
   (12:31 no texto, pela soma dos minutos), e volta à cheia. O sinal sai 4 vezes, pela ordem
   minguante → nova → crescente → cheia. `definir_hora` não mexe na lua.
6. **A troca não se vê:** às 12:30 a lua está a −52° e a luz dela é 0 em todas as idades. Mudar
   de idade nesse minuto não mexe em nada do que se vê.
7. **Continuidade:** em nenhuma fase o maior passo por minuto do mundo passa o da cheia.
   `cor_luz` 0,0557 (o mesmo das NOTAS-CICLO-43, às 05:57); `lua_energia` 0,0297 na cheia,
   0,0149 nos quartos, 0 na nova.

A Ordem 43 também fica igual por fora: `provar_ciclo_vento.gd` regrava o
`capturas/ciclo43/curvas_ciclo_vento.json` **igual byte a byte** sobre o código novo.

### Por render — as 4 fases (`filmar_dia.gd -- --fases`)

`capturas/ciclo55/c55_22h00_{1-nova,2-crescente,3-cheia,4-minguante}.jpg` e `_folha_fases.jpg`
(as 4 numa folha, 2×2). As 4 têm a mesma hora (**22:00**, lua a sueste a 38,7°, `lua_baixa` = 1×),
o mesmo enquadramento das capturas da Ordem 43 (a orla sul da clareira a olhar para norte) e o
mesmo vento (corre 6 s antes da 1.ª e fica parado). O relógio também fica parado. **A fase é a
única diferença entre elas.** No canto há um encaixe ampliado da lua (uma 3.ª câmara a olhar
para ela, campo de 6°).

| fase | idade | iluminada | luz da lua | luz-chave `cor_luz` | sombra do luar | DirectionalLight «Lua» | luma da cena (0–255) | % quase preto | disco claro no encaixe | FPS | chamadas |
|---|---|---|---|---|---|---|---|---|---|---|---|
| nova | 0 | 0 | 0 | `#081028` | 0 | apagada | **9,7** | 47,9 | 0 % | 1266 | 80 |
| crescente | 7 | ½ | 0,18 | `#4c576f` | 0,62 | acesa | 25,2 | 35,6 | 14,8 % | 1238 | 80 |
| cheia | 14 | 1 | 0,36 | `#6a7999` | 0,62 | acesa | 32,7 | 33,9 | 30,3 % | 1236 | 80 |
| minguante | 21 | ½ | 0,18 | `#4c576f` | 0,62 | acesa | 25,2 | 35,6 | 14,6 % | 1240 | 80 |

(Luma, FPS e chamadas medidos só na cena, sem o painel nem os encaixes; 1 197 363 primitivas em
todas.) As fases não custam nada que se meça: 80 chamadas em todas e FPS dentro do ruído.

**Visto com os olhos:** a crescente tem a metade da direita clara e a minguante a da esquerda, com
o terminador direito (quartos). A cheia é o disco da Ordem 43, com os mares. Na nova não há disco
nem halo, o luar desaparece da relva e a clareira lê-se só pela luz do céu e pelas janelas acesas
da Árvore. Os quartos ficam entre as duas.

**Âncora por render** (ferramentas descartáveis, fora do repositório, em
`C:\Users\txcga\fable-ciclo\ref55\` e `…\ferr\o55_comparar*.py`): o render desta cena **não é
determinístico**. O mesmo código, duas corridas, com o relógio e o vento parados, dá 30–41 mil
píxeis diferentes por quadro de 1920×1080 (média 0,06–0,12 níveis): é a relva e a água. Por isso
a igualdade não se prova píxel a píxel. O que se mediu foi o código da Ordem 43 contra o novo, às
22:00, 01:00, 19:45 e 05:30. A cena difere em 12–17 mil píxeis (média 0,03–0,05), **menos do que
o ruído de duas corridas do mesmo código**. O disco da lua cheia ampliado às 22:00 e à 01:00 sai
igual: 0–1 píxel diferente, máx. 1 nível.

As 10 capturas da Ordem 43 também foram refeitas (`-- --horas --pasta=…`, fora do repositório).
Esse modo deixa o relógio e o vento correr 2 s em tempo real entre capturas, por isso nem o mesmo
código as repete byte a byte. Diferença média só na cena, por hora (0–255):

- código novo contra as cometidas: 0,02–0,69;
- duas corridas do código novo: 0,00–0,97;
- o código da 43, refeito hoje, contra o novo: 0,23–1,76. O maior valor é às 13:00, com a lua a
  −51° e a fase fora de todas as contas: é o vento.

A mesma ordem de grandeza; a prova forte é a de números (bit a bit) e a do disco parado.

### Para o CI (não entrou: o token desta máquina não tem o âmbito `workflow`)

O passo, para o job `cliente` de `.github/workflows/testes.yml`, a seguir a «Abrir a Clareira de
prova». Corre sem `--referencia`, e por isso faz 22 verificações:

```yaml
      - name: Fases da lua no relógio do mundo (Ordem 55)
        if: always()
        run: |
          set -o pipefail
          timeout 120 "$GODOT" --headless --path . -s res://mapa/floresta/ferramentas/provar_fases_lua.gd 2>&1 | tee "$RUNNER_TEMP/provar_fases_lua.log"
          ! grep -E "SCRIPT ERROR|Parse Error|Compile Error" "$RUNNER_TEMP/provar_fases_lua.log"
          grep -E "^[0-9]+ de [0-9]+ verificações passaram\.$" "$RUNNER_TEMP/provar_fases_lua.log"
```

## A noite escura (os números; a pergunta é do Mestre)

A lua nova às 22:00 dá luma **9,7** contra **32,7** da cheia, e quase metade do quadro (47,9 %)
fica quase preta. A luz-chave desce ao piso que a Ordem 43 já tinha (`sombra × 0,46` =
`#081028`); a luz do céu (`ceu_luz` 0,20 de noite) e as janelas ficam. **Não se mexeu em nada
disto**: a ordem manda deixar a pergunta da noite escura ao olho do Mestre. Os botões, se ele
quiser mexer:

- a luz do céu à noite: `CEU_LUZ[0]` em `ciclo_dia.gd`;
- o piso da luz-chave: o `0,46` de `d["cor_luz"]`;
- a luz da lua: `LUA_ENERGIA` e `lua_baixa`.

Ao luar a sério, os quartos dão bem menos de metade da luz da cheia: cerca de 1/10, pelo efeito
de oposição da superfície da lua. A ordem pede o meio-termo «tirado da fase, não inventado», e a
fracção iluminada (½) é o que a fase dá. Fica dito, para o caso de o Mestre achar os quartos
claros demais.

## O que ficou por fazer

- O olho do Mestre: nenhuma destas notas aprova nada.
- A lua não muda de sítio com a fase (ver «A regra»).
- O lado claro do disco é sempre o da direita na crescente e o da esquerda na minguante, no plano
  do ecrã. Não está inclinado pela eclíptica.
- O halo e o véu de dia da lua seguem a fracção iluminada (linear). Não houve outra afinação.
- Sem «luz cinzenta» (o clarão da Terra na parte escura da lua crescente fina): a parte escura é
  céu.
