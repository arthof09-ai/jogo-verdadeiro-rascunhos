# Provas — Ordem CAIXA-EXPANDE (22/11/2026, Claude conta 2, PC)

A regra do Mestre para a caixinha da ordem (21/11/2026 23:10): a caixa compacta mostra o cartão grande (só a figura na
vez, só ela com o nome a ouro) e as 4 caixinhas dos próximos a jogar; o rato por cima (ou um toque) abre a vista
expandida com a ordem completa e os nomes inteiros. Com ela, a recentragem da faixa (F4) e os tectos novos do desvio.

## cliente/ — prova viva, 171/171
Cópia da prova da CAIXA-PADRAO-CORRECOES (os 5 momentos com o manequim de referência, nunca as cápsulas; a mesma
semente 7, o mesmo motor VLAB `a91c021c…`; os casos do retrato passam a ser o passo 10), com:
- **a compacta** nos momentos 1, 2, 4 e 5: as caixinhas são os próximos a jogar a contar de quem vem depois da vez,
  sem a figura na vez; só o cartão grande leva o nome a ouro (a conferência das cores passou a exigir isto);
- **6 (a)** o rato por cima da caixa (eventos do motor, como o rato a sério): a caixa cresce e mostra a ordem inteira,
  a vez primeiro e realçada, todos os nomes completos; tirar o rato volta ao tamanho compacto (`6-rato-expandida.png`);
- **7 (b)** 9 figuras: o Mestre de ensaio põe 5 criaturas a mais na luta (MASTER_PLACE em combate) e escolhe a
  iniciativa; a expandida mostra as 9; o toque abre e fecha a mesma vista, e um toque fora fecha
  (`7-expandida-8-figuras.png`);
- **8 (c)** a expandida com as 9 figuras em 844×390 (cabem as 9) e em 780×360 (cabem 8; a lista rola, e
  `8-expandida-780x360-fim.png` mostra-a rolada até ao fim);
- **9 (d)** a recentragem da faixa nas 3 resoluções, contra os tectos novos: desvio 0,0 / 11,5 / 0,0 u
  (`9-faixa-844x390.png`, `9-faixa-780x360.png`, `9-faixa-1920x1080.png`).

Verificações por passo: 0 → 1 · 1 → 22 · 2 → 20 · 3 → 4 · 4 → 22 · 5 → 20 · 6 → 17 · 7 → 31 · 8 → 18 · 9 → 6 ·
10 → 9 · e 1 da abertura do manequim. Godot 4.7.2, RTX 4060; a janela da prova abre a 1028×720 e muda de tamanho a
sério nos passos 8 e 9.

O PIN do Mestre é fresco por corrida e só passa por `--pin=`; o info e o log do servidor ficam na pasta temporária. O
relato só leva nomes públicos (0 nomes verdadeiros inteiros).

| ficheiro | SHA-256 |
|---|---|
| `cliente/1-entrou-dinamica.png` | `56712693fd3e9089811a27451a1ca82617aa67492027cae058caf9316526b15a` |
| `cliente/2-iniciativa.png` | `efbed26221a0af4c2e718fcb710025872dd5163c1eb15b5ec4a61e66ca753e2d` |
| `cliente/3-desligada.png` | `332f058fbf2687881c511f6b5e608733acbab478665453c3910f28968d41cf6d` |
| `cliente/4-religada-avancou.png` | `f8f29c723ffbd07afad5ee04fea6acdef3d82078f05ba6e4b469cdf87641b0ea` |
| `cliente/5-reentrou.png` | `4a43c883c1ea4f2851dadfc02075787a07f6903f2706571e1f03b91e091f99ef` |
| `cliente/6-rato-expandida.png` | `7cc1f99ccc9aa3762c135660015297e0c8aaccffaf8cb6d7605a5def96d3e755` |
| `cliente/7-expandida-8-figuras.png` | `965692ccf351069ce3cd5a35eb49106a2ae7c042918a72d095f4b6fb30d2c158` |
| `cliente/8-expandida-844x390.png` | `e46c63ee1f5f3e73cb13b27529d32aeb6232fad5455ae29688699fc73c70c687` |
| `cliente/8-expandida-780x360.png` | `b9e422d251f3f724c07fc40920110a3763e1747ce3184c5764ca34ef0a192de4` |
| `cliente/8-expandida-780x360-fim.png` | `f0bf4dc426fc45f06ee60959e0d3627d15329f965a1619c70d8b923d0d818270` |
| `cliente/9-faixa-844x390.png` | `33522e3ac68b79a4ce0718bce5e047d9fead4b958aea371eef9c71e1968fef38` |
| `cliente/9-faixa-780x360.png` | `9b018454743be7a0b50ccd5d4f626af69000dad2f8468bc43cfd4efde02a1f66` |
| `cliente/9-faixa-1920x1080.png` | `2123c8dbebcc13c0b904b9dd8a1f3f129c3582cf4f670561e8ee9e5118eb3afe` |
| `cliente/relato.txt` | `5b6d225aa2b9db8743e931df418df65206168df39402c12be6a7bd68dab8554f` |

## expandida/ — a suite `caixa_janela` (sem ecrã), 123/123
`caixa_janela.log`: 8, 12 e 16 figuras × 1280×720, 844×390 e 780×360. Em todas as medições: a compacta (4 caixinhas,
sem a vez) e a vista expandida aberta pelo rato (as linhas `MEDIDA EXPANDIDA`), com um nome público de 33 letras
na ordem. Só se copia a parte B3; a B1 (6 verificações, todas ok) fica de fora porque as mensagens herdadas dela não
passam no conferidor estrito.

## tecto/ — os tectos novos do desvio (F4)
- `corrida-tecto.log`: `caixa_jogadora` normal (42/42) e `-- --estrita` (41/42: só 780×360, a 11,5 u).
- `sensibilidade.log`: baixar 0,5 u um só tecto por corrida falha exactamente a guarda dessa resolução (41/42, rc 1, as
  três vezes); baixar os três dá 39/42.

## ferramentas/
- `correr-prova-caixa-expande.sh <godot.exe> <vlab-completo.js> <pasta-tmp>`: o lançador (servidor de ensaio + Godot
  com render).
- `prova_caixa_expande.gd`: a prova.
