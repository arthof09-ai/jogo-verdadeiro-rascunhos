# Ordem 37 — o campo de batalha da floresta: notas de medição

> **Nota da Ordem 38 (2026-11-14):** este documento é o fecho da Ordem 37 e fica como estava. A Ordem 38
> refez a fundação, o fundo e a vegetação: os tamanhos e os números abaixo estão ultrapassados pelos de
> `ESTADO-FINAL-ORDEM-38.md`. Os comandos para abrir a cena e repetir as provas continuam certos.

*Fecho da missão, 2026-11-13. Ramo `fable/mapa-37`. Tudo o que aqui está foi medido nesta máquina
(PCDANASA, NVIDIA GeForce RTX 4060, Godot 4.7.2, Compatibility) — os números vêm de
`capturas/medicao.json`, gravado pela própria ferramenta de capturas. O que NÃO foi medido está
dito no fim, sem rodeios.*

## Como abrir e como repetir a prova

```
# a cena (WASD anda, rato olha, 1–9 e 0 saltam para as vistas, F deixa só o fundo, M esconde a medição)
godot --path rascunhos/cliente res://mapa/floresta/campo_floresta.tscn

# as capturas etiquetadas + medicao.json (precisa de janela/GPU; --jpg é o que está no repositório)
godot --path rascunhos/cliente --resolution 1280x720 -s res://mapa/floresta/ferramentas/capturar_floresta.gd -- --jpg

# a prova da cor única, em números (sai com 0 se não houver costura)
godot --path rascunhos/cliente --resolution 1280x720 -s res://mapa/floresta/ferramentas/provar_costura.gd

# folhas de contacto 2×2 das capturas
godot --path rascunhos/cliente --headless -s res://mapa/floresta/ferramentas/folha_contacto.gd -- --pasta=capturas
```

As capturas do repositório são JPEG a 95 % (14 MB no total; em PNG eram 37 MB). Para as ver sem
perdas, corre a captura sem `--jpg` e com `--pasta=capturas/_ensaio` (pasta ignorada pelo git).

## Tamanho real do mapa

| Camada | Medida |
|---|---|
| Arena jogável | **60 × 60 m** (40 × 40 casas de 1,5 m), centrada na origem. Não cresceu: o relevo coube. |
| Relevo dentro da arena | de −1,87 m a +3,88 m (**desnível 5,75 m**); o centro está a −0,27 m. Declive máximo 46,5° (a escarpa do terraço de rocha, a sueste); o resto são rampas suaves. |
| Terreno 3D real (arena + orla de floresta) | até 20,5 m para lá da arena: um quadrado arredondado de **≈101 m de lado** |
| Anel próximo (uma malha) | dos 15 aos 62 m para lá da arena (≈45–92 m do centro): **≈184 m de lado a lado** (216 m com a contra-encosta que derrete na cor do horizonte) |
| Anel longe (uma malha, 3 capas fechadas) | raios de **135, 185 e 245 m** |
| Árvore-âncora | a **215 m**, azimute −7° (norte), **96 m** de altura |
| Névoa de profundidade | começa aos **40 m** da câmara, satura aos **125 m** (tecto 0,78, curva 1,25) |

Conteúdo: 128 árvores reais, 111 pedras, 230 arbustos, 20 945 tufos de relva (36 blocos),
760 árvores pobres no anel próximo. Carga da cena: ≈0,95 s.

## Chamadas de desenho (draw calls)

| O quê | Medido |
|---|---|
| **Fundo inteiro** (anel próximo 1 + anel longe 1 + âncora 1 quando está no campo de visão + céu 1 passagem) | **3 a 4** — alvo do estudo: 4–8 |
| Cena inteira, do centro (8 rumos) | 27–29 + céu |
| Cena inteira, dos cantos a olhar para o centro | 38–39 + céu |
| Cena inteira, dos cantos a olhar para fora | 11–12 + céu |
| Cena inteira, vista da referência 07 | 39 + céu |
| Cena inteira, do alto (mapa inteiro) | 44 + céu |

Os números são do contador do viewport da prova, que conta os objectos 3D: com a arena escondida
dá 2 ou 3 (os dois anéis, mais a âncora quando se vê). O céu é uma passagem de ecrã inteiro que
esse contador não conta — somei-a à mão no total do fundo.

Triângulos por quadro: **244 mil a 743 mil** conforme a vista (relva 377 mil no total, árvores
201 mil, arbustos 55 mil, pedras 21 mil, terreno 20 mil). O fundo sozinho: **83 mil** (anel próximo
74,6 mil, anel longe 6,9 mil, âncora 1,6 mil) — acima da estimativa do estudo («centenas a poucos
milhares»), porque as filas da frente do anel levam forma de árvore para casarem com a orla real.

## FPS

Medido SEM v-sync, a 1920 × 1080, 2 s por vista, nesta máquina (RTX 4060):
**1657 a 3631 FPS** (mínimo na vista do alto; do centro ≈2300–2440; cantos para o centro ≈1840–1930).

**Isto NÃO prova a porta da casa (≥45 FPS no Redmi).** Ver «O que ficou por fazer».

## O que os olhos conferiram no fecho (regra da prova)

| Pergunta | Veredicto dos olhos | Onde ver |
|---|---|---|
| A relva mexe? | Sim. Na imagem do movimento a relva e as copas acendem; céu, pedras, troncos, anéis e âncora ficam pretos (parados). Diferença média de luma entre quadros a 2 s: 2,3–16,9/255 conforme a vista. | `capturas/01_…_MOVIMENTO-2s.png`, `capturas/13_…_MOVIMENTO-2s.png` |
| Há fogueira ou disco de terra? | Não. O centro é relva; a única terra é um trilho estreito que passa longe do centro e o pé das árvores. | `capturas/14_alto_mapa-inteiro…`, as 8 vistas do centro |
| O fundo dissolve-se na névoa sem costura? | Sim. Em números: maior desvio à cor do horizonte 0/255, maior degrau entre amostras 1/255, nos 4 rumos. | `provar_costura.gd`; `capturas/01_…_SO-FUNDO.jpg`, `capturas/13_…` |
| A câmara 360° denuncia cartões planos? | Não vi nenhum. Os anéis são malhas fechadas à volta da arena; a volta está capturada de 45 em 45 graus a partir do centro. | vistas 01–04 e 15–18 |

Corrigido neste fecho, porque os olhos o encontraram: os troncos do anel próximo estavam ao sol
pleno (paus cor de areia atrás dos troncos escuros da orla); as copas e o chão do anel não levavam
oclusão; o ar do anel entrava cedo demais (as primeiras filas saíam pálidas a 20–30 m dos cantos);
a base do tronco da âncora acabava num corte recto por cima das capas; a escarpa do terraço lia-se
como chuvisco cinzento.

## O que ficou por fazer / por decidir

1. **FPS no Redmi (≥45): NÃO MEDIDO.** Não houve exportação para Android nem telemóvel à mão. Com
   545–745 mil triângulos por quadro nas vistas cheias, é o maior risco em aberto. Há um botão
   pronto (`densidade_relva`: 1,0 alto · 0,7 médio · 0,45 baixo) mas os perfis médio e baixo não
   foram medidos nem vistos. As árvores reais (201 mil triângulos) não têm nível de detalhe.
2. **A lua** lê-se como um disco cinzento-escuro contra o azul do céu (vistas 05 e 16). O brilho
   é o aprovado da paleta v2 (0,410) e não lhe toquei — é decisão do olho do Mestre.
3. **Os cantos a olhar para fora** (vistas 09–12) são onde o fundo fica mais perto (≈17 m): as
   copas do anel são lisas, sem a pincelada das reais, e alguns troncos do anel ficam com o pé
   escondido atrás de uma lomba. Lê-se como floresta a continuar; fica ao juízo do Mestre.
4. **Os dentes da primeira capa do anel longe** (135 m) são blocos angulosos quando se vêem no
   vale a norte (vistas 01 e 15). Assumidos como silhueta; podem ser arredondados.
5. **A escarpa do terraço (46,5°)** — falta a regra do jogo dizer se essas casas são jogáveis.
6. **Colisão:** só o chão tem (HeightMapShape3D de 1 m). Árvores e pedras não têm corpo.
7. **Sombras em tempo real:** desligadas (as do cenário estão cozidas no mapa do chão). As figuras
   do jogo não projectam sombra enquanto o sol do grupo «sol» não a ligar.
8. **Integração com a arena do jogo** (`cenas/arena`): não feita — a ordem era só o mapa.
   `altura_em(x, z)` e `Relevo.centro_casa(i, j)` dão o chão de cada casa.
9. **Clone fresco:** os `.uid` e os `.import` não estão no repositório (ignorados); o Godot gera-os
   ao abrir. Sem importação, o céu é lido directamente do PNG (há esse caminho no código).
