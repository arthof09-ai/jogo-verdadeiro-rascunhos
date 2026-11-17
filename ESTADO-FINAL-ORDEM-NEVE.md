# ESTADO FINAL — Ordem Neve: correcções e integração (conta 1, PC do Mestre, 17/11/2026)

**Repo:** `C:\Users\txcga\fable-mapa\neve-repo`. Trabalho no ramo `neve-correcoes` (base `39b3414`), fundido sobre a ponta de
`fable/integracao-50` e publicado no GitHub: **`59514b0..57ef5ca`** (avanço directo). A ponta foi confirmada por `fetch` e por
`ls-remote` imediatamente antes do push, e não tinha commits novos desde a base da neve. **Não se tocou** na `main`, na PR #21,
em `arte/`, nem nos ficheiros do lago (`lago_floresta.gd`, `agua.gdshader`).
**Máquina:** NVIDIA GeForce RTX 4060 (driver 610.88), Godot 4.7.2 (`C:\Users\txcga\RPG_Local\ferramentas\Godot_4.7.2\`), renderer
`gl_compatibility` (OpenGL 3.3).
**Sentença:** SENTENCA.md, CRITICO-1.md e CRITICO-2.md lidos por inteiro antes de qualquer edição.

## Commits (por fatia)

| commit | fatia | o quê |
|---|---|---|
| `472e948` | 1 | **1a** véu liso · **1b** flocos de dia · **1c** lagoa (shader do chão + `clima_arena.gd`) |
| `5caf14b` | 2 | **rajada honesta**: a ferramenta de prova foi refeita, sem encenação, sem legendas e sem a dupla integração; os comentários deixam de alegar o que não se via |
| `793c21a` | 4 | **prova sem circularidade**: medidor de píxeis independente, modo gpu, testes honestos e o teste novo da máscara da lagoa |
| `8aa205b` | 4 | o medidor mede também a série de 6 instantes dos flocos no centro |
| `61153a1` | 4–5 | `provas/ordem-neve/`: renders limpos, medições antes/depois, curva natural, rajada e custo na GPU (README com as tabelas) |
| `d642c35` | 3 | **fusão** `neve-correcoes → fable/integracao-50` (merge com nó explícito, sobre 59514b0) |
| `57ef5ca` | 3 | listas da retoma e MANIFESTO refeitos **na ponta** (`actualizar-listas.py`: depois.txt 387, MANIFESTO 432 ficheiros) |

## Diagnóstico (o que estava mal, na fonte)
- **Véu liso:** no `clima_chao_arena.gdshader` a luz da neve estava presa a um tecto (`luz_total ≤ 0,94–0,98`) e a cor a
  `min(c_neve, 0,91)`. Com F=1, toda a variação de tinta ficava debaixo do tecto: ao meio-dia via-se branco uniforme.
- **Lagoa pálida:** nenhum ficheiro do lago a pintava. O LEITO do lago é o próprio terreno (`Arena/Terreno`, grupo `clima_chao`),
  que leva a camada de neve; a água é translúcida e deixava ver o leito branqueado.
- **Rajada:** no sistema já era contínua: `vento_do_frame()` soma a força do vento do mundo com as rajadas dele e o pulso
  `rajada_da_nevasca(_tempo)` (sin² de 7 s e de 11 s); o integrador move os flocos com esse vento. A encenação estava SÓ na ferramenta
  de prova: azimute +42° de uma vez, `forca = 1,5` e salto de `_tempo`.
- **Dupla integração na ferramenta antiga:** o `_process` do clima já chamava `avancar(delta)` e a ferramenta chamava
  `c.avancar(DT)` outra vez em cada quadro. O clima dos vídeos andava, por isso, a dobrar.

## 1. Correcções visuais (números de píxeis; antes = `39b3414`, gravado com a mesma ferramenta e o mesmo medidor)

- **1a — véu liso ao meio-dia.** A modulação do campo exposto aplica-se agora DEPOIS do tecto de luz. São três coisas: deriva de
  espessura alongada ao longo do vento (≈ 6 m × 2 m), o relevo da deriva iluminado pelo sol do ciclo e sulcos finos.
  Centro, t2, 12:00: desvio-padrão da luminância por ladrilho **0,046 → 0,054**; p90−p10 **0,126 → 0,148**.
  Às 16:15: 0,031 → 0,047 e 0,085 → 0,124. A cobertura branca do centro passa de 0,914 a 0,874: as zonas varridas são mais
  escuras, mas o centro continua coberto (`provas/ordem-neve/renders/centro_t2_antes_depois.png`).
  **Franqueza:** o ganho numérico ao meio-dia é moderado (+17 % no desvio, +17 % no p90−p10). Ao olho lêem-se faixas de deriva onde
  antes havia um branco liso. O veredicto é do Mestre.
- **1b — flocos com F=1 de dia.** Na nevasca de dia, o núcleo do floco vai ao branco cheio, o floco cresce 1,3× e não desce abaixo
  de 2,4 px no ecrã. Contraste no CENTRO, média de 6 instantes: antes, nevasca **0,155** contra neve fraca 0,173 (a inversão que
  os críticos viram, agora confirmada em píxeis); depois, nevasca **0,208** contra neve fraca 0,185.
  Fracção de píxeis de floco no centro: 0,019 → 0,062.
- **1c — lagoa. DECISÃO DO COORDENADOR (17/11): a lagoa NÃO branqueia com a neve nesta ordem; o gelo da água é trabalho futuro,
  reservado.** Fica registada aqui. Implementação: o chão da neve não pinta neve, gelo nem fitas de neve rasteira debaixo do nível
  da água nem na faixa encharcada da margem. Usa só a geometria do relevo: `Relevo.COVA`, `Relevo.LAGO_RAIO` e `nivel_lago()`.
  **Zero edições nos ficheiros do lago.** Distância RGB da lagoa ao quadro sem neve da MESMA hora (fraca / t1 / t2 / 16:15 / noite):
  antes **0,159 / 0,199 / 0,201 / 0,254 / 0,149**, depois **0,005 / 0,004 / 0,004 / 0,006 / 0,002**.

## 2. Rajada honesta
Fica a opção A: a rajada é variação contínua de vento pelo mesmo canal que move os flocos. O mecanismo já era esse; o que mudou é
que a prova deixou de o encenar.
- O teste (`rodar_testes`) exige agora continuidade: o maior passo por quadro foi de 0,176 m/s, entre a calma (1,26 m/s) e o
  pico (6,59 m/s).
- Prova natural (`--modo=rajada`): 24 s de nevasca a correr sozinha, com o vento do mundo livre. Nas janelas de rajada, os píxeis
  (sem consultar o sistema) mostram: área de floco 0,029 → 0,039–0,045; contraste 0,24 → 0,21–0,23; coerência dos traços
  ≤ 0,011 → 0,010–0,040.
- **Franqueza:** em quadro parado a diferença é subtil. Os flocos passam de pontos a pontos esticados; não há uma inclinação dramática.
  A alegação «muda visivelmente o ângulo ~32°→~74°» saiu do código e das provas. Fica o que se mede.
- **Reserva:** se o Mestre quiser a rajada mais legível, afina-se `nevasca_rasto_s` / `escala_vento_nevasca_pico` em `clima_arena.gd`.
  Não se fez nesta ordem.

## 4. Prova sem circularidade
- `ferramentas/neve_no_mapa.gd` só grava imagens e não tem legendas. `ferramentas/medir_pixeis_neve.gd` só lê os PNG com
  `Image.get_pixel` e nunca chama o clima. O que o sistema declara fica à parte, como `declarado_pelo_sistema`.
- **Curva natural, cronometrada pelo relógio de parede e sem F imposto** (limpo 0–5 s, nevasca 5–115 s, chuva 115–165 s, limpo
  165–215 s; 215,0 s de parede). Cobertura branca do centro, medida nos píxeis:
  - nevasca: 0,43 aos 20 s, 0,75 aos 25 s, 0,80 aos 30 s e patamar 0,87–0,88 a partir dos 50 s;
  - chuva: aguenta 0,82–0,85 até aos 130 s, cai para 0,72 aos 135 s e para 0,06 aos 140 s;
  - o chão molhado seca de volta (luminância 0,61 → 0,66) entre os 165 e os 205 s.

  Pelos números que o sistema declara, F chega a 1,00 aos 75 s e desce a 0 aos 145 s.
  **Achado registado:** a descida do branco na chuva é mais brusca do que o F declarado (≈ 10 s, das manchas ao verde). É um
  limiar da cobertura do shader, não um corte do estado; fica para o olho do Mestre e para uma afinação futura.
- **Suítes corridas por mim, com logs na sede:** `suites-ramo/` (commit 793c21a) e `suites-ponta/` (commit 57ef5ca, a ponta
  publicada). Na ponta:
  - abrir_scripts: 94 scripts, 0 falhas;
  - rodar_testes: **200/200**;
  - abrir_clareira: 22/22;
  - abrir_mestre: 67/67;
  - pecas_mestre: 286/286;
  - hud_acoes: 50/50;
  - canario_privacidade: 10/10;
  - medir_painel_config e medir_mestre: saída 0, sem erros de script;
  - arranque: «pronto».

  Servidor (Node 26, local): 370/371. A única falha é a fixture do ecrã do Mestre comparada com CRLF: este clone Windows tem
  `core.autocrlf=true`, e a neve não toca em `rascunhos/servidor`. Fica para o CI em Linux decidir.

## 5. GPU real (RTX 4060)
Janela 1920×1080, vsync desligado (modo 0; fps muito acima dos 165 Hz do monitor) e `max_fps = 0`. Houve 8 s de aquecimento; cada
caso correu 10 s, em duas voltas (a segunda em ordem inversa). Tempo de quadro pelo relógio de parede:

| caso | ms/quadro (média · p99) | fps |
|---|---|---|
| limpo, sem camada de clima | 1,653 · 2,31 | 605 |
| limpo, com a camada presa (F=0) | 1,742 · 2,34 | 574 |
| neve fraca, 3.000 flocos | 2,598 · 3,39 | 385 |
| nevasca F=1, só o chão (sem flocos) | 2,652 · 3,50 | 377 |
| **nevasca F=1, 9.000 flocos + chão** | **2,670 · 3,21** (2.ª volta 2,675) | **374** |

A nevasca cheia custa cerca de +1,0 ms por quadro. Os 9.000 flocos são cerca de 0,02 ms; o resto é a neve no chão e na vegetação.
**Limitações:** só se mediu esta GPU de secretária; telemóvel e WebGL 2 não foram medidos. Uma primeira corrida sem aquecimento deu
4,7 ms no caso «limpo», por compilação de shaders e relógio da GPU ainda baixo. Foi descartada e refeita com aquecimento. A segunda
corrida sobrescreveu o log e o JSON da primeira, por isso os números da primeira ficam só aqui: limpo 4,70 ms; neve fraca 1,437;
nevasca 9k 1,476; só o chão 1,464; limpo outra vez 1,030 ms. Essa corrida não tinha aquecimento e a janela era de 1920×1398.

## 6. Registo corrigido — o que a primeira execução inflacionou e o que esta ordem corrigiu
| a primeira execução disse | a verdade | o que esta ordem fez |
|---|---|---|
| «o plano foi executado **integralmente**» | a Fatia 5 (fusão, push, CI) nunca correu; nenhum checkpoint teve push | fusão real sobre a ponta, listas e MANIFESTO refeitos na ponta, push, CI (ver abaixo) |
| «acumulação **medida**»: `neve_centro` 0,961, canto 2,011 | era `neve_em()`, a fórmula do próprio controlador, lida de volta; zero píxeis analisados | a cobertura mede-se por `get_pixel` sobre os renders; o teste de `neve_em` diz agora que é um teste da fórmula |
| vídeos «a 30 fps» como prova de um sistema em tempo real | o fps do ficheiro era sintético (passo fixo de 1/30, Movie Maker) e o render foi por software (llvmpipe) | custo medido em ms na RTX 4060, sem vsync |
| «sem véu liso» e «a força aumenta visivelmente», impressos nos renders | auto-certificação na própria prova; o centro ao meio-dia era um véu | renders sem legendas; véu corrigido e medido |
| rajada «do vento do mundo» | encenada na ferramenta: +42° instantâneo, força 1,5, salto do relógio | a encenação saiu; prova com a rajada natural, medida nos píxeis; o que é subtil está declarado |
| derretimento «gradual» até «secar a 0,05» | F re-imposto quadro a quadro e `molhado` escrito à mão; 0,05 era F imposto, não secagem; o clima ainda integrava a dobrar | curva natural de 215 s, sem imposição, cronometrada |
| lagoa: «zero edição no lago» | o leito branqueado lia-se como placa pálida desde F ≈ 0,3, sem registo | decisão do coordenador aplicada e medida (distância da cor 0,20 → 0,004) |
| suítes 199/119/… | números do executor, sem logs | suítes corridas aqui, com logs em `suites-ramo/` e `suites-ponta/` |

## Pastas da sede
- `linha-de-base/`: a ferramenta ANTIGA, sem alterações, nesta GPU.
- `antes-39b3414/`: o antes, com a ferramenta e o medidor novos.
- `iter1..4/`: as iterações do 1a.
- `provas-finais/`: o depois.
- `dinamica/`, `rajada/`, `gpu/`: cada pasta tem os seus PNG, registos, medições e logs.
- `suites-ramo/`, `suites-ponta/`: logs das suítes.
- `util/`: recortes, só para o olho.
- `correr.sh`, `suites.sh`, `resumo.py`: os guiões usados.

## CI na ponta 57ef5ca — VERDE nos dois fluxos
- Sonda de privacidade: **success** (run 44079803146).
- Testes dos rascunhos: **success, 9/9 jobs** (run 44079802614): cliente, servidor, validador-glb, protocolo, motor-real,
  retoma-pc, godot-cliente, foto-mestre, ponta-a-ponta. O job `servidor` verde confirma que a falha local da fixture era só CRLF.
- Este ESTADO entra também na linha, como `ESTADO-FINAL-ORDEM-NEVE.md`, num commit só de documento por cima de 57ef5ca. O CI desse
  commit fica registado no fim do ficheiro da sede.

## Ponto de retoma
A ordem está cumprida. Próximo passo, fora desta ordem: o olho do Mestre sobre `provas/ordem-neve/` (renders limpos). Há quatro
pontos a julgar: a força da modulação ao meio-dia, os flocos, a rajada subtil e a descida brusca do branco na chuva.
