# Provas — Ordem CAIXA-PADRAO-BUSTO (21/11/2026, Claude conta 1, PC)

A caixinha da ordem de turnos com as duas correcções do Mestre (21/11/2026 19:52): os quadradinhos das figuras
seguintes todos do mesmo tamanho, e o retrato em busto (rosto e peitoral). Os mesmos 5 momentos da prova viva da
CAIXA-MANEQUIM e da CAIXA-TESTE-ESTETICA, com o manequim de referência (nunca as cápsulas), na estética do teste.

## cliente/ — 78/78
- As 62 verificações da CAIXA-TESTE-ESTETICA, iguais linha a linha (mesma semente 7, mesmo motor VLAB `a91c021c…`,
  cenário `7703320c…`, fichas `3c498137…`, as mesmas ordens e vezes, as mesmas cores, a mesma privacidade).
- Mais 4 por momento com a caixa à vista (1, 2, 4, 5):
  (a) todos os quadradinhos com o mesmo tamanho ao píxel; esse tamanho é a célula fixa da caixa; o cartão grande da
  figura na vez continua maior;
  (b) todos os retratos em busto: na câmara de cada retrato, o alto da cabeça, o rosto e o peito da figura em pose
  ficam dentro do quadro, a cintura, os joelhos e os pés ficam fora, e a câmara está à frente da figura.
- A lista medida dos tamanhos está no fim de `cliente/relato.txt`: 46×60 px na janela 1028×720 (85×112 unidades do
  HUD) em todos os quadradinhos de todas as capturas; o cartão na vez tem 62×62 px.
- `cliente/retratos/`: o retrato de cada figura no momento 1 (160×160), para o olho.
- Godot 4.7.2, RTX 4060, janela 1028×720 (o mesmo enquadramento).
- Capturas (sha256, 16 primeiros):
  1. `1-entrou-dinamica.png` `81fb4caa067604a7`
  2. `2-iniciativa.png` `eae3031cb331a96c`
  3. `3-desligada.png` `7a990a9f310d468d`
  4. `4-religada-avancou.png` `164bfde4559227d4`
  5. `5-reentrou.png` `47fbf71854b30703`

Correr de novo (Git Bash, na raiz; num clone novo, primeiro `godot --headless --path rascunhos/cliente --import`):
`bash provas/ordem-caixa-padrao-busto/ferramentas/correr-prova-caixa-padrao-busto.sh <Godot_console.exe> <vlab-completo.js> <pasta-tmp>`
