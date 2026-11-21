# Provas — Ordem CAIXA-TESTE-ESTETICA (21/11/2026, Claude conta 1, PC) — TESTE VISUAL

A caixinha da ordem de turnos com a linguagem do protótipo («pergaminho e dourado sobre painéis escuros»), nos
mesmos 5 momentos da prova viva da CAIXA-MANEQUIM, com o manequim de referência (nunca as cápsulas).

## cliente/ — 62/62
- As 46 verificações da CAIXA-MANEQUIM, iguais (mesma semente 7, mesmo motor VLAB `a91c021c…`, cenário `7703320c…`,
  fichas `3c498137…`, as mesmas ordens e vezes), mais 4 por momento com a caixa à vista (1, 2, 4, 5): a tabela tem as
  cores do protótipo; o painel é rgba(16,12,8,.55); todas as letras da caixa a pergaminho f3e9d2 (o nome da figura na
  vez a ouro) e todas as molduras a ouro c9a227 a .85 com o fundo rgba(10,8,5,.82), nenhuma outra cor; a figura na vez
  com a moldura de ouro grossa.
- Godot 4.7.2, RTX 4060, janela 1028×720 (o mesmo enquadramento).
- Capturas (sha256, 16 primeiros):
  1. `1-entrou-dinamica.png` `76facdf81d1ee3d8`
  2. `2-iniciativa.png` `4bff76b37cd87470`
  3. `3-desligada.png` `4e757eba95847ebf`
  4. `4-religada-avancou.png` `eceee46f1d81ec2c`
  5. `5-reentrou.png` `32e8dc2ec3c71faa`

Correr de novo (Git Bash, na raiz; num clone novo, primeiro `godot --headless --path rascunhos/cliente --import`):
`bash provas/ordem-caixa-teste-estetica/ferramentas/correr-prova-caixa-teste-estetica.sh <Godot_console.exe> <vlab-completo.js> <pasta-tmp>`
