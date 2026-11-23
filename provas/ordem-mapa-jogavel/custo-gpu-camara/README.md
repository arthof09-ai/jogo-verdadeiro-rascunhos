# Provas — ORDEM MAPA-JOGÁVEL-CUSTO-CÂMARA (Claude conta 1, PC · 23/11/2026)

Esta pasta guarda a medição do custo GPU da grelha-mapa (A1), o enquadramento da câmara em Panorama (A2), o resíduo
de cobertura (A3), a ponta-a-ponta na grelha-mapa (A4) e as suites (A5). O veredicto está em
`ESTADO-FINAL-ORDEM-MAPA-JOGAVEL-CUSTO-CAMARA.md`, na raiz do repo. A base é `fable/integracao-50` @ `5ab2aea`.
**Nenhum ficheiro do jogo mudou.** A câmara passou a A2 (16/16 nas 3 grelhas), por isso não houve correcção e não
existe `capturas/`.

| Pasta / ficheiro | O que é |
|---|---|
| `ferramenta/medir_custo_camara.gd` | Cópia de trabalho da `capturas/ferramenta/foto_mapa_jogavel.gd` (a arena da jogadora: o mesmo snapshot, a figura «No lago», perfil «alto», Panorama), mais a leitura de `_dist_panorama` e do frustum. Só lê; vive só aqui. |
| `ferramenta/tabelas.py` | Gera `tabelas.md` a partir de `medicao.json` e de `terreno/provar-terreno-servidor.json`. |
| `corridas/<g>-c<n>.json`, `.log` | As 12 corridas da A1/A2 (4 grelhas × 3), com o JSON completo e o registo do Godot. `estado-do-pc.txt` guarda a hora e o sensor de cada uma. |
| `medicao.json` | As 12 corridas agregadas: médias, bandas (máx − mín), a diferença 75×75 − 20×20 e a câmara por grelha, com os 16 pontos. |
| `tabelas.md` | As tabelas da A1, A2 e A3. |
| `controlo-panorama/` | 3 fotos de controlo do Panorama na ponta `5ab2aea`, uma por grelha-mapa (ver abaixo). **Não são as 9 refeitas.** |
| `terreno/` | A3: o registo e o JSON de `provar_terreno_servidor.gd` (o original, corrido como está). |
| `e2e/` | A4: a cópia adaptada `servidor-e2e-mapa.mjs` (sem `sala.mapa`), o guião `correr-e2e-mapa.sh` (o do CI com essa única troca), a `sonda-grelha.mjs` e os `registos/`. |
| `suites/antes/` | A5: as suites na ponta antes das medições, com `resumo.txt`. |

## Como se correu

- **A1/A2.** Godot 4.7.2 (o renderizador do projecto, `gl_compatibility`), NVIDIA GeForce RTX 4060, 1920×1080, `--disable-vsync`
  e `Engine.max_fps = 0` (no JSON: `vsync 0`, `max_fps 0`). Houve um processo por grelha e por corrida, por esta ordem:
  c1 (20, 50, 75, 37), c2, c3. Os comandos estão no cabeçalho da ferramenta. Cada processo segue estes passos:
  1. faz o snapshot e abre a arena;
  2. põe a câmara em Panorama e espera 60 quadros;
  3. faz a leitura A2;
  4. aquece 240 quadros;
  5. mede 1200 quadros: FPS médio = quadros ÷ tempo de parede, ms/quadro = mediana dos intervalos, chamadas de desenho
     e primitivas = média por quadro, e a CPU do lago = `LagoFloresta.custo_medio_us()` (o `avancar()` em µs por
     quadro, nesse intervalo);
  6. repete a leitura A2.

  O Godot correu na sessão 0 do Windows, como a CAPTURAS-MAPA, e com o PC em LIVRE (`corridas/estado-do-pc.txt`).
- **A figura.** Está nas casas das provas: (36,9) @ 1,5 m, (54,14) @ 1 m e (27,6) @ 2 m. A referência 20×20 (canto NO
  em −15 m) **não chega ao lago**: o sítio de (36,9) fica em x ≈ 17,25 m. Por isso, na referência, a figura está na
  casa da 20×20 mais perto desse sítio, (19,0), que é **seca**. O valor «água acima do pé» dessa linha é só o nível do
  lago menos a altura do pé, numa casa fora do lago, e não quer dizer nada.
- **A2.** São os 16 pontos de `_recalcular_panorama`: 4 cantos e 4 meios de borda, a 0 m e a 1,8 m acima do relevo. Mediram-se com
  `is_position_in_frustum` **na câmara real**, depois de `_saltar()` e de 60 quadros de suavização. A distância real
  câmara–centro é igual a `_dist_panorama` (ver a tabela). As iterações deduzem-se de `_dist_panorama = d0 × 1,06ⁿ × 1,03`,
  com resíduo 0.
- **A3.** `godot --headless --path rascunhos/cliente -s res://cenas/arena/ferramentas/provar_terreno_servidor.gd -- --json=<…>/terreno/provar-terreno-servidor.json`.
- **A4.** Na raiz do repo: `GODOT=<godot> MOTORES=<motores.mjs> SAIDA=<pasta> bash provas/ordem-mapa-jogavel/custo-gpu-camara/e2e/correr-e2e-mapa.sh`.
  O `motores.mjs` sai do `vlab-completo.js` vivo por `motores/embrulhar.mjs`, como no CI. Para conferir a grelha servida,
  `node e2e/servidor-e2e-mapa.mjs <porta>` e depois `node e2e/sonda-grelha.mjs <porta>`.

## As fotos de controlo (`controlo-panorama/`)

As 9 fotos das CAPTURAS-MAPA foram tiradas em `62dfa61`, **antes** da LAGO-MAIOR (`ded3272`), que mudou o relevo
(`relevo_floresta.gd`) e o lago. A câmara e a arena não mudaram desde então. A ordem pede que a prova independente da
A2 sejam as fotos mais os números. Por isso tirei uma foto do Panorama por grelha-mapa na ponta, com a mesma
ferramenta (`--foto`). São só controlo: o guião das 9 fica intacto e a pasta `capturas/` só existiria se a câmara
fosse corrigida.

Nas três fotos a grelha inteira e o lago ficam dentro do ecrã. Perto das bordas, as copas da orla tapam partes da
grelha. Isto é oclusão e não frustum: os pontos estão no ecrã, por baixo das copas. Fica registado como observação
para o Mestre e não foi corrigido, porque está fora dos limites da correcção da câmara. A figura não se vê no lago:
está submersa, com a água 1,8–2,0 m acima do pé (ver o PENDENTE (b) no ESTADO-FINAL).

## Privacidade

Os caminhos com o nome de utilizador do Windows foram trocados por `<utilizador>` nos registos desta pasta. A Sonda
(`grep` dos e-mails pessoais) dá limpa e o canário dá 10/10 (`suites/antes/canario_privacidade.log`). As fichas são as
fictícias dos testes.
