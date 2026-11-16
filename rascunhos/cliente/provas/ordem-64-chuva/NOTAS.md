# Ordem 64 — a chuva na arena integrada (notas)

Linha `fable/integracao-50`, no clone principal `C:\Users\txcga\fable-mapa\repo`. Só apresentação.

## Nota 1 — a base e o ponto de partida (2026-11-15)

- **Base conferida:** `HEAD` = `8e530b7` (`8e530b7cb5aed0cc1e8c1a154eda7cc99d6792ce`), igual a
  `origin/fable/integracao-50` depois do fetch. A árvore só mostra o `mesa-mestre.json` modificado, que é o
  artefacto CRLF conhecido. Não é trabalho desta ordem e não entra em commit.
- **Modelo:** a ordem pede `claude-fable-5-2`, mas esta sessão corre em **Claude Opus 5.5**
  (`claude-opus-5-5`). Fica escrito aqui para o coordenador decidir se o trabalho conta.
- **Disco:** C: com 1,4 GB livres ao começar. Por isso os vídeos são curtos e leves.
- **A Ordem 40 já está na linha.** `fable/clima-40` (`cd94361`) e `fable/clima-41-expansao` (`c167f52`) são
  ancestrais da linha. O módulo `arte/clima/` (chuva, salpicos, chão molhado, figuras molhadas, contagens
  por perfil, intensidades sem reiniciar) já existe. A Ordem 42 (parte 2) já o ligou ao mapa integrado
  (`CampoDaMesa.ligar_clima`, nas duas arenas). Não houve nada a transplantar à mão: o transplante já estava
  feito, e a falta era outra.
- **O que faltava (a frente desta ordem):** o ponto 3 do `ESTADO-FINAL-ORDEM-57.md`, «Dois ventos». O clima
  caía com um vento seu (`definir_vento`, 20° e 2,5 m/s, com rajadas sintéticas). Ao mesmo tempo, o vento do
  mundo da Ordem 43 (`vento_mundo.gd`) dobrava a relva e as copas para outro lado e rodava com o dia.
