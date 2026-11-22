# Provas — Ordem CAIXA-PADRAO-CORRECOES (22/11/2026, Claude conta 1, PC)

As correcções B1–B9 da conferência da CAIXA-PADRAO-BUSTO. A prova viva corre os mesmos 5 momentos da prova do
padrão-busto, com o manequim de referência (nunca as cápsulas) e na estética do teste, e junta-lhes um 6.º passo: os
casos do retrato.

## cliente/ — 95/95
- **As 78 verificações da prova do padrão-busto** saem iguais e pela mesma ordem: mesma semente 7, mesmo motor VLAB
  `a91c021c…`, as mesmas ordens e vezes, cores, quadradinhos (46×60 px) e bustos.
- **+4 (B7):** a privacidade conferida também no momento 2 (iniciativa).
- **+4 (B5):** nos momentos 1, 2, 4 e 5, a caixa dos retratos contém, um a um, a malha da figura em cena esfolada pelo próprio
  motor (`bake_mesh_from_current_skeleton_pose`). A esfola por CPU, que é a referência da suite sem ecrã, dá o mesmo
  que a do motor.
- **+9 (6.º passo, B1/B2/B4/B5):**
  - o ciclo inteiro do ANDAR, figura sempre de pé;
  - a profundidade máxima do ciclo e a margem ao limiar;
  - a passada longa;
  - a arma rígida levantada;
  - o braço levantado (é um limite);
  - a figura deitada;
  - o quadrúpede esfolado;
  - a caixa zero;
  - a validação em repouso.

  Os retratos destes casos estão em `cliente/retratos/casos/`.
- **B3:** a lista dos quadradinhos mostra os nomes **à vista**, cortados com «…», e não o texto anterior ao corte.
  Está no fim de `cliente/relato.txt`.
- **B8:** o PIN do Mestre é fresco por corrida e só passa por `--pin=`. O info e o log do servidor não se copiam
  para esta pasta, e o relato só leva nomes públicos.
- Godot 4.7.2, RTX 4060, janela 1028×720.
- Capturas (sha256, primeiros 16 caracteres):
  1. `1-entrou-dinamica.png` `39c914cd738b3e49`
  2. `2-iniciativa.png` `1339fc26c83f2bf2`
  3. `3-desligada.png` `bd378e355b2c6ab7`
  4. `4-religada-avancou.png` `cee2ae1a50deb01e`
  5. `5-reentrou.png` `67cad72521b46628`

Para correr de novo (Git Bash, na raiz; num clone novo, corre primeiro
`godot --headless --path rascunhos/cliente --import`):
`bash provas/ordem-caixa-padrao-correcoes/ferramentas/correr-prova-caixa-padrao-correcoes.sh <Godot_console.exe> <vlab-completo.js> <pasta-tmp>`

## tecto/ — B9
- `corrida-tecto.log`: `caixa_jogadora` com os tectos novos (542,5 / 587,5 / 343,5 u) dá **36/36**.
- `sensibilidade.log`: os três tectos baixados 0,5 u, só no ficheiro local, sem commit, e repostos logo a seguir. Dá
  **33/36, rc 1**, e falham exactamente as três guardas: a guarda dispara a +0,5 u.
