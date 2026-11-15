# Ordem 57: o relógio do mundo entra na linha juntada. ESTADO FINAL

Claude 2 (conta 2), 2026-11-15, numa sessão. Ramo `fable/integracao-50`, sem ramo novo. `main` (`2383737`)
não foi tocado, e a worktree `fable-servidor-wt` e o clone `fable-ciclo` também não.

- **Ponta do ciclo juntada: `fable/ciclo-43` @ `fd2260b`** (Ordens 43, 55 e 56). A base comum com a linha é
  `254188c` (Ordem 38).
- **A missão nasceu em `ac2676b`, mas a fusão publicada assenta em `74fd8e0`.** A meio da sessão, a Ordem 58
  (`fable/pes-58`) entrou no mesmo ramo e foi publicada. O meu primeiro push foi recusado (sem force).
  - Nada meu estava publicado, por isso refiz a fusão do ciclo sobre a ponta nova, com as mesmas resoluções,
    em vez de fundir uma fusão. A primeira tentativa (`3c12c3e` · `1c4cd81` · `e93d6c8`, sobre `ac2676b`)
    nunca saiu desta máquina.
  - A 58 só se cruzava comigo no `pecas_mestre.gd` (fundiu-se sozinho) e nas listas.
- `mesa-mestre.json` (o «M» do CRLF) não entrou em commit nenhum.

## O que mudou (commits)

| commit | o quê |
|---|---|
| `974e7e2` | **Parte A, a fusão.** Funde `fable/ciclo-43` (`fd2260b`) em `fable/integracao-50` (`74fd8e0`). 4 conflitos resolvidos à mão, 1 fusão automática conferida, a cópia do molde acertada para a Lua, e o pacote do terreno refeito. |
| `1fd2595` | **Parte B.** Prova de que o molde e o relógio convivem: `pecas_mestre` 268 → 272. O retrato deixa de ler a textura de um SubViewport. |
| `62afa51` | Listas da retoma e MANIFESTO refeitos pelo gerador. **Push** `74fd8e0..62afa51`. |
| `1cd6c1c` | **Parte C.** As provas da arena (`provar_mestre_no_relevo`, `provar_assentamento`) com o relógio: a lua conta à parte, e o céu do Mestre e o do jogador comparam-se no mesmo momento do mundo. |
| `48d2cf5` | Listas (parte C). **Push** `62afa51..48d2cf5`. |
| `b057c7a` | **Parte C.** `provar_molde_54.gd` (com janela): o quadro em que o tempo pára já não entra no relógio. |
| *(este)* | Este ESTADO FINAL. |
| *(o seguinte)* | Listas refeitas, porque este documento está dentro de `rascunhos/`. Push do fecho. |

## Os conflitos, um a um, e como foram resolvidos

O ciclo mexeu em 60 ficheiros, quase todos novos. Só 5 tinham sido mexidos também pela linha. As listas
geradas não conflituaram (o ramo do ciclo não as tem) e foram refeitas pelo gerador sobre a árvore fundida.

| ficheiro | linha (Ordens 42/45/48–54) | ciclo (Ordens 43/55/56) | resolução: as duas linhas |
|---|---|---|---|
| `shaders/copa.gdshader` | `#include "recorte_vista.gdshaderinc"` (o recorte da câmara do Mestre) | `#include "vento_floresta.gdshaderinc"` (o vento do mundo) | os dois includes |
| `shaders/haste.gdshader` | a erva pisada na zona jogável: `fica * mix(1, campo_alto, no_campo(raiz.xz))` | o vento do mundo (`vento_dir` unitário, `vento_dobra(vento_local)`, `vento_fase`) | a erva pisada **e** o vento do mundo na mesma linha |
| `shaders/relva.gdshader` (2 blocos) | o include do clima; a dobra × `mix(1, baixa, 0.6)` (a erva afogada/enterrada mexe menos) | o include do vento; a nova lei da dobra (`vento_amplitude · dobra · forma`) e o tremor pela velocidade local | os dois includes; a lei do ciclo **com** o factor `baixa`, que entra também no `v_dobra` (a cor da dobra), como na linha |
| `shaders/marco.gdshader` | o recorte | (só luz) | fusão automática, conferida |
| `campo_floresta.gd` (4 blocos) | o preload do molde; `obstaculos`; o fim do `_ready` partido em `_fim_da_carga` para os dois caminhos (construído/vestido); `_process` com o rótulo nulo guardado | os preloads do ciclo, vento e sombras; as variáveis `ciclo`, `vento`, `sombras`, `lua`; `_ligar_ciclo_e_vento()` no fim do `_ready`; `aplicar_ciclo()` no `_process` | tudo dos dois lados. **O relógio liga-se em `_fim_da_carga`, nos dois caminhos**, e o molde guarda-se **antes** dele (o molde não leva relógio: cada mapa tem o seu). `_process` corre `aplicar_ciclo()` e depois guarda o rótulo nulo |

**O que a fusão obrigou fora dos conflitos:**

- **`molde_floresta.gd`: a cópia trata a Lua como coisa de fora.**
  - Antes, um nó do próprio mapa guardava-se como referência pelo caminho. A Lua nasce em
    `_montar_ambiente`, pendurada no mapa e fora da Arena e do Fundo. Ao vestir, o estado é reposto
    *antes* de `_montar_ambiente`, e o molde procurava uma Lua que ainda não existia.
  - Conferido com o molde antigo: o `pecas_mestre` dava `Node not found: "Lua"` em cada mapa vestido (4
    no total), e os testes passavam na mesma.
  - Agora só os nós debaixo das raízes guardadas vão como referência. Os outros são «de fora», como o
    Ambiente, o Sol e a Câmara, e o mapa vestido fica com os seus.
- **`molde_floresta.gd` (retrato): a textura do forno das sombras não se lê como imagem.**
  - É o desenho de um SubViewport. Sem GPU, cada retrato dava `Parameter "t" is null`.
  - Entra pelo nome; o nó do forno entra no retrato à parte.
- **`servidor/dados/terreno-floresta.json` refeito com `exportar_terreno.gd`.**
  - O `campo_floresta.gd` é fonte do terreno. O `--conferir` de antes dizia só «a fonte mudou» (nenhuma
    parte do pacote mudou).
  - O pacote refeito difere do antigo **só no SHA da fonte**, no cabeçalho.
  - `conferir-terreno.mjs` dá TERRENO EM DIA, com o pacote refeito pelo Godot e igual byte a byte.

## As presenças do relógio, provadas na linha fundida

As provas correram sobre a árvore fundida, sem mexer numa vírgula delas. A referência da Ordem 43 é
`git show d7b9e6c:…/ciclo_dia.gd` (sha256 `4923caea8e4b7724…`, a mesma da Ordem 55). A da 55 é
`git show 0435aa7:…`.

| presença | prova | resultado |
|---|---|---|
| **o ciclo do dia, com a âncora dos 1440 minutos** | `provar_fases_lua.gd -- --referencia=… --gravar` e `provar_estacoes.gd` | as 40 saídas da Ordem 43 são **iguais bit a bit nos 1440 minutos** (0 diferenças), na cheia e no dia de referência; as 45 da Ordem 55 também |
| **as fases da lua** | `provar_fases_lua.gd` | **24 de 24** |
| **as estações** (a prova numérica da Ordem 56) | `provar_estacoes.gd -- --referencia=… --referencia55=… --gravar` | **27 de 28, a mesma verificação e os mesmos números da Ordem 56**: o critério «nenhum passo por minuto maior que o da referência» falha em 48 dos 112 dias (0–20, 24, 60, 64–86, 110–111); o pior é `cor_luz` no dia 71, +6,9 % (+8,6 % com o ano a correr). Duração do dia: verão 14,825 h > primavera 12,000 = outono 12,000 > inverno 9,175 h; o ano volta ao ponto de partida (resto 1,6·10⁻¹⁰) |
| **o vento do mundo** | `provar_ciclo_vento.gd` | o `curvas_ciclo_vento.json` sai **igual byte a byte** ao do ramo (sha256 `b44bff8a…`) |

`fases_lua.json` e `estacoes.json` saem iguais aos do ramo **excepto numa linha cada**: o caminho do ficheiro
de referência, que agora é `_tmp/o57/ciclo/…` e lá era `fable-ciclo/…`. Repus os do ramo, porque só o
caminho da máquina mudava.

## O molde e o relógio convivem (ponto 4)

- **O retrato da Ordem 54 continua a passar.** No `pecas_mestre`, o mapa vestido é igual ao construído de
  raiz em **188 linhas** de retrato (eram 136; entram o relógio, o vento, o forno e a lua, com o estado
  deles). Guardar o molde não muda o mapa, e mexer num vestido não chega ao molde.
- **Verificações novas (`_relogio_no_molde`, +4):**
  1. o vestido tem o seu relógio, vento, forno das sombras e lua, sem nada partilhado com o construído;
  2. o céu do vestido é o dele, e a relva lê as sombras do forno dele;
  3. os dois nascem às **16,25 h**, com lua cheia e na primavera;
  4. em 4 momentos (hora · idade da lua · dia do ano = 22:00 · 0 · 21, 05:45 · 7 · 49, 13:00 · 14 · 77 e
     18:30 · 21 · 105), mudados nos dois, pintam o mesmo céu (todos os parâmetros do `ceu_ciclo`), a mesma luz da
     relva, a mesma névoa e luz ambiente, e o mesmo sol e lua: **0 diferenças**.
- **Com render (RTX 4060, 1920×1080): `provar_molde_54.gd` dá 0 falhas.** Os 3 retratos são iguais e as 3
  fotos (sem molde · construído com molde · vestido) são **iguais byte a byte**.
  - Na árvore fundida dava 4 falhas.
  - Medido quadro a quadro: no quadro em que `Engine.time_scale` passa a 0, o motor ainda dá um passo de
    **1/15 s sem escala** (`vento._t = 0,0667`). O relógio anda com ele, e só a 1.ª abertura o apanha
    (16,2513 h contra 16,25 h).
  - A prova deixa agora passar 2 quadros antes de abrir. Era uma folga do harness, não do molde.

## Provas do fecho (ponta `b057c7a`)

| suite | resultado |
|---|---|
| servidor (`--permission` + `--allow-net`) · protocolo | 345 / 0 / 10 saltados · 355/355 |
| `conferir-schemas` · `validador-glb` · `conferir-terreno` | exit 0 · 31/0/2 · TERRENO EM DIA |
| `abrir_scripts` | **82** scripts, 0 falhas (73 + `provar_pes_bloqueadas` da 58 + os 8 do ciclo) |
| `rodar_testes` | 177/177 |
| `abrir_mestre` | 67/67 |
| `pecas_mestre` | **272/272** (268 da linha com a 58 + 4 da Ordem 57), 0 `ERROR` no registo |
| `abrir_clareira` · `hud_acoes` · `canario_privacidade` · `clima_forte` | 22/22 · 46/46 · 10/10 · 119/119 |
| `medir_mestre` · `medir_painel_config` | 0 falhas, 0 sem medida |
| arranque `--quit-after 600` | «pronto», 0 erros |
| `provar_terreno_servidor -- --json=` · `medir_toque_rasante -- --json=` | TUDO PASSOU · SEM FALHAS; os JSON são **iguais byte a byte** a `provas/ordem-48-terreno/medicao-terreno-qualquer-grelha.json` e a `provas/ordem-51-toque/depois.json` |
| `provar_mestre_no_relevo` · `provar_assentamento` | TUDO PASSOU · TUDO PASSOU (depois da parte C; antes 4 e 1 falhas, explicadas no commit `1cd6c1c`) |
| `medir_perfil_mestre_52 -- --json=` | igual chave a chave ao da Ordem 54 (279 chaves, 0 diferenças) |
| `provar_molde_54` (com janela) | 0 falhas, fotos iguais byte a byte |
| ponta a ponta (motor falso, local) | 17/17 em 2 corridas; jogadora OK, 23 mensagens |

## Reservas, sem rodeios

1. **O relógio não é do mundo, é de cada mapa.**
   - Cada mapa abre às **16:15** e anda sozinho.
   - O ecrã do Mestre, a cada reabertura (mapa vestido do molde ou construído), volta às 16:15.
   - O Mestre e os jogadores não estão sincronizados, e o servidor não sabe a hora. Nas provas, duas arenas
     abertas no mesmo processo ficaram 0,003–0,006 h desencontradas.
   - Era assim no ramo do ciclo («só apresentação; nenhuma regra a lê»). Não inventei um relógio partilhado:
     é decisão de desenho, do coordenador. As provas comparam agora no mesmo momento do mundo, e o
     desencontro fica registado no `--json` do `provar_mestre_no_relevo` («relogio»).
2. **A noite chega à arena depressa.**
   - Um dia do mundo são 1440 s (24 min reais). A arena abre às 16:15, e a noite (19:45) cai ao fim de
     **~3,5 minutos reais**. Uma sessão de 2 horas vê 5 noites.
   - Na lua nova a noite é escura (luma 9,7, medida na Ordem 55).
   - Ninguém mediu ainda a legibilidade da mesa (casas, figuras, destaques) de noite na arena: as capturas do
     ciclo são do mapa sozinho. A vista de cima do Mestre, às 16:15, está na foto da `provar_molde_54`.
3. **Dois ventos.** O vento do clima (`clima.definir_vento`: partículas, nevasca, abrigo) e o vento do mundo
   (relva, hastes, copas) continuam independentes. O Mestre pode pôr a chuva a cair de norte com a relva a
   dobrar para outro lado. Já era assim antes (a relva tinha um vento fixo), mas agora o do mundo muda de
   rumo ao longo do dia. O clima não mexe na névoa, na luz ambiente nem no sol: com o `aplicar_ciclo` não há
   guerra.
4. **`provar_estacoes` continua 27 de 28.** É a régua da continuidade que a Ordem 56 deixou para decisão do
   coordenador. Não lhe mexi.
5. **O CI não corre as provas do ciclo**, só as compila (`abrir_scripts`). O passo ficou por pôr na
   Ordem 55, porque o token desta máquina não tem o âmbito `workflow`, e continua por pôr.
6. **Não corri `provar_costura.gd`** (vermelha desde a Ordem 43, 67/255, decisão do coordenador) nem as
   capturas e filmes do ciclo (`filmar_dia.gd`) sobre a árvore fundida. O mapa sozinho tem agora também o que
   a linha lhe juntou (o recorte, as uniformes do clima, a erva pisada), tudo desligado por omissão fora da
   arena. Que as capturas do ciclo saem iguais está **por confirmar por render**.
7. **FPS do relógio na arena não medido.** O forno vivo das sombras repinta quando o sol anda, e o céu muda
   todos os quadros. Os números do ciclo (80 chamadas, ~1200 FPS) são do mapa sozinho num RTX 4060.
8. **Passo do motor ao parar o tempo.** O quadro em que o `Engine.time_scale` muda ainda corre 1/15 s sem
   escala. Qualquer prova futura que pare o tempo para fotografar o mapa tem de deixar passar esse quadro.

## Nota de retoma

- A linha é agora 48 + 49 + 51 + 52 + molde + 58 + **ciclo (43/55/56)**.
- Quem mexer no `campo_floresta.gd` tem de refazer o pacote do terreno.
- Quem juntar um nó ao mapa fora da Arena e do Fundo tem de o criar nos dois caminhos (`_montar_ambiente`
  ou `_fim_da_carga`). O molde dá-o como «de fora».
- Os scripts de corrida estão em `_tmp/o57/` (cliente.sh, servidor.sh, e2e.sh, presencas.sh), e as
  referências do ciclo em `_tmp/o57/ciclo/`.
- O ramo local `o57-sobre-ac2676b` (a primeira tentativa, nunca publicada) foi apagado no fecho.

## CI

- Push `74fd8e0..62afa51`: «Testes dos rascunhos» run `43730596361` verde; «Sonda de privacidade» run
  `43730596362` verde.
- Push `62afa51..48d2cf5`: «Testes dos rascunhos» run `43730888202`, **9 de 9 jobs verdes** (godot-cliente,
  protocolo, foto-mestre, retoma-pc, ponta-a-ponta, cliente, servidor, validador-glb, motor-real); «Sonda de
  privacidade» run `43730888170` verde.
- Push do fecho: ver o commit seguinte a este.
