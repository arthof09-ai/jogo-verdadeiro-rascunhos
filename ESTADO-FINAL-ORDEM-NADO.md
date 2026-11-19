# ORDEM NADO — ESTADO FINAL (o nado das figuras no lago) · 19/11/2026

Sessão na nuvem (conta 1) que cumpriu `ORDEM-NADO-INTEGRACAO.md` no ramo `claude1/nado-integracao` (base `ba3b16c`,
ponta à chegada `c94df09`). Godot 4.7.2 oficial descarregado para a sessão; render por software (Mesa llvmpipe) em
Xvfb; sem GPU; sem Blender (não foi preciso).
Etiquetas: **VERIFICADO** = corrido/visto nesta sessão, com evidência no repo ou no CI; **PROPOSTO** = escolha minha,
por conferir; **PENDENTE** = por fazer. Testes e conferência são do coordenador: o que segue é a prova da construção.

## O que foi feito

| Commit | O quê |
| --- | --- |
| `b07e6b1` | `testes/converter_nado.gd` (o conversor), `testes/manequim/nado-v1.glb` (o clipe no sítio), `mapa/floresta/lago_floresta.gd` (`LagoFloresta.a_nadar`), `testes/video_lago.gd` (o estado de nado ligado). |
| `7fe613a` | Listas da retoma e MANIFESTO refeitos com `retoma-i0004/actualizar-listas.py` (3 novos: o conversor, o `.glb` e o FBX da fonte, que o `c94df09` tinha deixado fora). |
| este | Este ESTADO FINAL e as provas em `provas/ordem-nado/`. |

### 1. A conversão do esqueleto — VERIFICADO, não bloqueou
- Fonte: `testes/manequim/orc-mixamo-swimming.fbx` (5 323 360 B, SHA-256 `5a98e1af…aae488`), a da ordem; nenhuma
  outra foi buscada. O FBX abre no Godot 4.7.2 com o `FBXDocument` embutido (ufbx): esqueleto `mixamorig` de 41
  ossos, clipe `mixamo_com` de 4,533 s (137 quadros a 30 qps), 34 pistas.
- Padrão seguido (o do ANDAR v3): o manequim de prova é o Mannequin_F do UAL2 em `.glb`, na pasta
  `testes/manequim/` (com `.gdignore`, carregado tal e qual, sem importação), e as pistas são
  `Armature/Skeleton3D:<osso UE>`. Os ossos que pesam na malha são só os 60 da árvore `root` (convenção UE);
  o rig de controlo (MCH-, ORG-, ik, fk) não deforma e fica em descanso.
- Como (`testes/converter_nado.gd`, corre sem janela):
  - retarget por rotações globais com as poses de descanso alinhadas: o Mixamo descansa em pose A, o manequim em
    pose T; para cada osso, a rotação que leva a direcção de descanso da fonte à do alvo; a mão usa também o polegar
    (referencial inteiro) para a palma não rodar;
  - a anca recebe a translação da fonte à escala das alturas da anca (0,9167 / 0,7947 = 1,1535), **sem o avanço**:
    o clipe fica no lugar, como o `andar_v3` (quem avança é a bancada);
  - médio, anelar e mínimo (que este clipe do Mixamo não tem) seguem o indicador.
- Saída: `testes/manequim/nado-v1.glb` — o manequim com **um** clipe, `nadar_v1` (4,533 s, em ciclo, 69 pistas de
  rotação + a posição da anca), 2 201 832 B, SHA-256 `5b75767967494201768a69a5743e155eda170e5c10d1f1baccb918d4130b5371`.
- Determinista: três corridas, o mesmo SHA. O `.glb` é relido e conferido pelo próprio conversor (clipe, duração,
  382 ossos, 1 malha, coxa a meio do ciclo 0,0° de diferença). Log: `provas/ordem-nado/suites/converter_nado.log`.
- Visto: `provas/ordem-nado/clipe/` — o `nadar_v1` de lado, de frente e de cima em 4 tempos. É bruços, de barriga
  para baixo, a cabeça para a frente da marcha (−Z da cena).

### 2. A ligação do estado de nado — VERIFICADO
- Critério: `LagoFloresta.a_nadar(x, z)` — nada onde **não faz pé** (fundura > `FLUTUA_M` = 1,25 m), a mesma fronteira
  do `pe_na_agua` que já existia. Em seco e na rasa (água pelo joelho) anda, como antes.
- `testes/video_lago.gd` (a única figura articulada que entra no lago):
  - junta o `nadar_v1` à biblioteca do AnimationPlayer do manequim (confere o SHA do `.glb`);
  - ao passar a fronteira, mistura para o nado em 0,6 s e o corpo deita-se à tona (anca 0,08 m abaixo do nível);
    ao voltar a fazer pé, volta ao `andar_v3`;
  - a velocidade do clipe acompanha a da peça (0,62 m/s ÷ 0,483 m/s do clipe): as braçadas não patinam;
  - a nado, o tronco fura a água a meio (anca–peito), para os anéis e a esteira;
  - a etiqueta do vídeo diz o clipe em uso; a medição ganha `nado.quadros_a_nadar`.
- Prova (corrida `--modo=funda`, render por software, 45,1 s):
  - 601 quadros a nadar; fases: rasa → a água sobe → **a NADAR na funda** (t = 5,5 s) → sai → anda na rasa;
  - quadros em `provas/ordem-nado/quadros/` (nado-1, nado-3, nado-4 a nadar com esteira; a-sair já de pé com o
    `andar_v3`); medição e fases em `provas/ordem-nado/funda_*.json`.
- **Fora do lago, o comportamento anterior intacto** — prova numérica: `--modo=rasa` corrido com a árvore de antes
  (`c94df09`) e com a de agora: as 742 linhas da série da medição são **iguais uma a uma** (0 diferenças), as fases e
  a duração iguais, os pés no leito iguais, 0 quadros a nadar. Em `provas/ordem-nado/rasa-antes-depois/`.

### 3. A prova da construção — VERIFICADO
- Local, Godot 4.7.2 headless em `b07e6b1` (logs em `provas/ordem-nado/suites/`):
  - abrir_scripts: 104 scripts, 0 falhas;
  - rodar_testes: **226/226**, 0 erros de script;
  - arranque da cena principal: «pronto», 0 erros de script.
- CI: ver «CI» no fim deste ficheiro.

## Riscos e pontos para o coordenador
1. **PROPOSTO — o que é «dentro do lago».** Nada só onde não faz pé. Na rasa continua a andar (é o que a Ordem 66
   filmou). Se o Mestre quiser nado em todo o lago, basta mudar o limiar em `a_nadar`.
2. **PENDENTE — as figuras do jogo.** As figuras da arena são marcadores (cápsulas), sem esqueleto, e o lago fica
   fora da grelha de 20 × 20. No jogo não há hoje clipe para trocar. A ligação vive no manequim de prova; o critério
   (`LagoFloresta.a_nadar`) fica pronto para quando as figuras tiverem rig.
3. **Transição de saída.** Nos 0,6 s da mistura, ao voltar a fazer pé, o corpo ainda está a levantar-se. A medição
   regista a planta do pé até 1,11 m acima do leito (t 25,5–26,1 s). É a mistura, não um erro de altura. Se ficar
   feio, antecipa-se a mistura antes da fronteira.
4. A folga negativa dos pés no talude (−0,24 m a t ≈ 4,8 s, na entrada) acontece antes do nado e com o `andar_v3`.
   Não vem desta ordem.
5. Mãos: no meio da braçada os pulsos dobram para cima (ver `clipe/nadar_v1_zoom_t1.13.png`). Vem do clipe ou da
   palma do retarget; fica para o olho do Mestre.
6. O `.glb` exportado pelo Godot tira as pistas constantes (53 pistas na releitura, contra 70 no clipe). Os ossos
   sem pista ficam no descanso, que é o mesmo valor.

## CI
- Base `c94df09`: Testes dos rascunhos **success** (run 44540268193); Sonda **success** (run 44540268169).
- `7fe613a` (código + listas): Sonda **success** (run 44548166974); Testes dos rascunhos: corrida 44548166920 (9 jobs; os
  da conversão e do cliente — `cliente` abrir/testes, `godot-cliente`, `retoma-pc` — já verdes quando a vi).
- `112a8e5` (ESTADO FINAL e provas): Sonda **success** (run 44548400110); Testes dos rascunhos **success** (run 44548400209).

## Fecho
- Fusão na linha junta `fable/integracao-50`: **fast-forward** (a ponta da linha, `ba3b16c`, já estava contida neste ramo;
  nada a resolver). Feita depois deste commit, que fica a ponta das duas; confirmada com `git ls-remote`.
- Próximo passo: conferência do coordenador (vídeos `--modo=funda`/`rasa` com GPU; o olho do Mestre sobre o nado).
