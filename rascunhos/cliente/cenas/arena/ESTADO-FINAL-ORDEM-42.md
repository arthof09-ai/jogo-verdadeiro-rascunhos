# Ordem 42: integrar o mapa da floresta na arena. ESTADO FINAL

*Fecho da ordem, 2026-11-14, conta 1, Opus, sessão fresca no PCDANASA (RTX 4060, Godot 4.7.2,
Compatibility). Ramo `fable/integracao-42`, a partir de `254188c` (ponta da Ordem 38). As duas partes estão
feitas e commitadas. O juízo é do coordenador e do olho do Mestre: o que está «provado» abaixo foi corrido
ou visto por mim nesta máquina, e o que não foi está dito.*

## Parte 1: a integração do mapa

**O que a arena faz agora.** A cena principal (`cenas/arena/arena.tscn`) cria o mapa da floresta (`Mapa`)
com a zona jogável do snapshot. Tudo assenta no relevo, e há um só céu e uma só luz: os do mapa, montados no
Ambiente e no Sol da arena. A câmara é a da mesa. O método, a prova e os números estão em
`NOTAS-MEDICAO-ORDEM-42.md`.

| Pedido | Feito | Prova |
|---|---|---|
| 1. A grelha assenta no terreno, ao centro da arena do mapa | grelha centrada e encostada às linhas de 1,5 m do mapa; casas, destaques, fogo, cursor e linhas seguem o relevo; figuras no ponto mais baixo da pegada; toque pelo raio contra o relevo | `ferramentas/provar_assentamento.gd`: centro − relevo 0,00000 m; remendos +0,030…0,050 m; nada no ar (0,002 m); toque 70/70 · 400/400 · 361/361; 0 casas bloqueadas pelo mapa |
| 2. Um só fundo, céu e horizonte | os do mapa no Ambiente e no Sol da arena | 1 WorldEnvironment, 1 DirectionalLight3D (prova); vistas 07 e 09–16 |
| 3. A relva mexe e as árvores são as do mapa | relva pisada na zona e alta fora, com o mesmo vento | movimento a 2 s: 4,45/255 (01) e 7,47/255 (07); imagens `_MOVIMENTO-2s` |
| 4. Câmara: Panorama e 360° | Panorama com cantos e meios das bordas à altura real; recorte em ponteado do que fica entre a câmara e o foco | vistas 08 (Panorama) e 03–06 e 09–16 (360°) |
| 5. Perfis Baixo/Médio/Alto | aplicam-se; a densidade da folhagem chega à relva do mapa (0,50/0,75/1,00) | prova; vistas 17 e 18 |
| 6. Figuras como marcadores, assentes | sim | vistas 01, 19 e 20; prova |
| 7. O jogo continua a funcionar | headless e com render, 0 erros; testes do cliente a passar; CI verde | ver «Provas corridas no fecho» |

**O desvio mapa-grelha** era de três ordens: 15 m de desfasamento das coordenadas, 2,44 m de relevo dentro
da zona e 27 casas do jogo bloqueadas pelo mapa (rochas, um tronco, a ponta do tronco tombado). Ficou
resolvido assim: a grelha centrada e encostada às linhas do mapa, o assentamento no relevo, e a zona
jogável livre do que o servidor não conhece (24 pedras, 2 árvores e 5 peças de estrato tiradas; o tronco
tombado acaba à entrada da zona). Medido depois: **0 casas bloqueadas**.

**Desempenho** (Alto, 1920 × 1080, sem v-sync): 96–130 chamadas de desenho e 0,95–1,25 M primitivas por
quadro; **572–663 FPS** em Alto, 1 224 em Médio e 1 663 em Baixo. A cena carrega em 1 870 ms.

**Capturas etiquetadas** (`capturas/`, 20 vistas mais 2 imagens do movimento e o `medicao.json`):

- centro em jogo (Mover e Ataque);
- os 4 cantos;
- a vista da referência 07, de longe;
- o Panorama;
- a volta de 360° rasante (8 rumos);
- os perfis Baixo e Médio;
- dois grandes planos (o pé das figuras e a encosta).

Refiz a corrida na ponta final: as 20 vistas dão exactamente as mesmas chamadas e primitivas.

## Parte 2: o clima forte sobre o mapa integrado

O merge do `fable/clima-41-expansao` (ponta actual `c167f52`, que já traz `e5291b9`, `75850f1`, `e4ba982`
e `aecd44f`) entrou no `ffe60a8`. O conflito no `arena.gd` foi resolvido: o chão do mapa molha e branqueia.

- **Bacias do relevo real.** Saem de `cenas/arena/bacias_do_relevo.gd` (inundação por prioridade do
  `Relevo.altura`). Foram 8: a cova do charco, uma cova a oeste, a boca da garganta e cinco covas rasas,
  duas delas dentro da zona. O módulo do clima ganhou a **bacia do relevo**, com a água a superfície plana
  e o relevo a dar a forma.
- **Defeito latente do módulo, corrigido.** Num chão com relevo, o chão mais de 1 m abaixo da referência
  saía molhado. Num chão liso dá o mesmo de antes (`clima_forte.gd` 119/119).
- **Abrigos da nevasca.** São os 8 obstáculos reais do mapa mais perto da zona: o tronco tombado, 3
  menires, 3 rochas e o santuário. As malhas reais vestem a neve. A zona deixou de fazer «bordas» de neve.
- **A relva reage ao clima:** enterra-se e branqueia na neve, afoga-se nas bolsas.
- **Entregas** em `provas/ordem-42-clima-no-mapa/`:
  - `videos/nevasca.mp4` (44,1 s) e `videos/alaga.mp4` (50,1 s), etiquetados;
  - capturas em 3 tempos de cada (mais o antes/seco e dois grandes planos);
  - JSON do estado;
  - README com o método e os números. Com as bolsas cheias, a água na zona ocupa 13,5 m² com 4,3 cm de
    fundo; o prado é quase liso e as bolsas grandes ficam fora da zona.

## Provas corridas no fecho (ponta da Parte 2)

**Headless:**

| Teste | Resultado |
|---|---|
| `abrir_scripts` | 60 scripts, 0 falhas |
| `rodar_testes` | 167/167 |
| `clima_forte` | 119/119, sem SCRIPT ERROR |
| `hud_acoes` | 32/32 |
| `abrir_clareira` | 22/22 |
| `abrir_mestre` | 57/57 |
| `canario_privacidade` | 10/10 |
| `pecas_mestre`, `medir_mestre`, `medir_painel_config` | passam |
| `provar_assentamento` | tudo passou |
| arranque `--quit-after 600` | «pronto», 0 erros |

**Com render:** `capturar_arena.gd` (20 vistas, 0 erros) e `clima_no_mapa.gd`, nevasca e alaga (0 erros).

**CI:** os runs do «Testes dos rascunhos» e da «Sonda de privacidade» estão todos verdes desde a `e869df3`:

- ponta da Parte 1, `1330355`: runs 43638127949 e 43638127868;
- `f17ac94`, `2755921` e `fe4912a`, ponta das provas da Parte 2: runs 43640261339 e 43640261332.

Os dois primeiros pushes (`93910dd` e `36357a5`) tiveram só o job `retoma-pc` vermelho, porque as listas da
retoma ainda não tinham sido refeitas. Ficou resolvido na `e869df3`. O run do commit deste documento está
no ESTADO FINAL da mensagem de fecho.

**Com os meus olhos:**

- a relva mexe (imagens do movimento);
- as figuras assentam no chão do relevo (vistas 19 e 20, e a encosta NO);
- os destaques lêem-se sobre a relva (01 e 19);
- o fundo dissolve-se na névoa sem costura à vista (07, 09–16);
- a volta de 360° não mostra cartões a rodar de lado;
- a nevasca junta-se contra o tronco tombado e as rochas;
- a chuva enche as covas reais (a Lia com os pés na água).

## Higiene

Na primeira hora escrevi 4 ficheiros de rascunho em `/tmp` (a pasta temporária do Windows), fora de
`fable-mapa\`, contra a guarda 3. Apaguei-os e o resto foi para `C:\Users\txcga\fable-mapa\_tmp\o42\`. Os AVI
dos vídeos (~900 MB) ficaram lá, fora do repositório. O Godot escreve na sua pasta de dados de utilizador
ao correr, como nas ordens anteriores.

Outros pormenores:

- uma mensagem de commit (`85a9b1e`) perdeu uma palavra por causa de crases na linha de comando; o
  conteúdo do commit está certo;
- não toquei nos ramos `i0004/jv31-decisoes`, `main`, `fable/mapa-37`, `fable/mapa-38-correcoes` nem
  `fable/clima-41-expansao`, nem nos workflows, nem no clone da Ordem 43.
