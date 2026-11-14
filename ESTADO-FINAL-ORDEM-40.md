# ESTADO FINAL — Ordem 40 (clima na arena: chuva e neve)

Ramo `fable/clima-40` (nasce da PONTA-BASE `548d66c`). Fecho escrito a 2026-11-14 pela sessão de sucessão da
conta 1 (as duas sessões anteriores morreram no limite de 5 h; a segunda deixou a nota 2 commitada em `46e77ee`).
Nenhum ficheiro deste ramo aprova nada: o veredicto é do coordenador e do olho do Mestre, sobre os vídeos.

## O que foi entregue

1. **O sistema de clima** — módulo transplantável em `rascunhos/cliente/arte/clima/` (ver o `README.md` de lá):
   chuva e neve com um só vento integrado frame a frame (a lição da REF_85), o chão e as figuras a responderem
   por `material_overlay` (nenhum material da cena é trocado), intensidades fraca/forte comutáveis sem
   reiniciar a cena, contagens por perfil gráfico (Baixo/Médio/Alto). Ligado às duas arenas de hoje
   (`cenas/arena/arena.gd` e `cenas/mestre/arena_mestre.gd`). Só apresentação: não lê `Estado` nem `Rede`.
2. **Testes**: `testes/rodar_testes.gd` (167 verificações, 29 do clima) e `testes/pecas_mestre.gd` (234, 11 do
   clima). Bancada com render: `testes/video_clima.gd` (modos `video`, `troca`, `jogadora`, `fotos`, `medir`).
3. **Provas** em `provas/ordem-40-clima/` — as notas completas estão em `NOTAS.md` (notas 1, 2 e 3).

## Os 5 vídeos etiquetados (a prova principal)

Todos em `provas/ordem-40-clima/videos/` — MP4 H.264, 1280×720, 30 fps, perfil Alto, gravados quadro a quadro
com render de verdade (RTX 4060), com a etiqueta no ecrã (clima, intensidade, contagem, vento do frame) e a
seta laranja do vento:

| Vídeo | Duração | O que mostra |
| --- | --- | --- |
| `chuva-fraca.mp4` | 24 s | chuva fraca, vento 4,0 m/s; antes → liga → o vento muda (+75°, ×1,7) → de perto → Panorama |
| `chuva-forte.mp4` | 24 s | chuva forte, o mesmo guião |
| `neve-fraca.mp4` | 24 s | neve fraca, vento 2,2 m/s, o mesmo guião |
| `neve-forte.mp4` | 24 s | neve forte, o mesmo guião |
| `comutacao.mp4` | 25 s | chuva fraca → forte → neve fraca → forte → desligado, na mesma cena, sem reiniciar |

Extra (6.º, nota 3): `arena-jogadora.mp4` (32 s) — a arena da jogadora com HUD e casas do «Mover», chuva forte
e neve forte pela preferência `"clima"`. Fechou o ponto 3 do «por fazer» da nota 2.

Apoio: `capturas/` (acumulação da neve em 3 tempos, chão molhado antes/depois, 4 da arena da jogadora),
`folhas/` (6 quadros de cada vídeo), `rastos/` (três quadros seguidos em R → G → B: o sentido do movimento),
`medicao.md` / `medicao.json` (custo por perfil e a medição da REF_85: 0 de 1 793 075 deslocamentos contra o
vento, salto máximo 0,117 m), `ferramentas/` (os scripts que gravaram).

## ESTADO FINAL — Passagem

- **O que mudou** (neste fecho, sobre `46e77ee`):
  - `e983c02` — `rascunhos/cliente/testes/video_clima.gd`: modo `--modo=jogadora` da bancada. Era o ficheiro
    modificado por commitar. **Decisão: faz parte da entrega** — a sessão anterior escreveu-o e correu-o
    (0 falhas, log em `fable-clima\prova2\log-arena-jogadora.txt`) para fechar o ponto 3 do «por fazer», e
    morreu antes de o commitar. Conferi: os 37 scripts abrem, 167 de 167 testes; corrigi uma linha do
    cabeçalho (a quebra de linha do comando de exemplo tinha-se perdido).
  - `4aa459f` — listas da retoma e MANIFESTO refeitos (`actualizar-listas.py`).
  - `faeff25` — nota 3 em `NOTAS.md`, `videos/arena-jogadora.mp4`, 4 capturas e a folha.
  - este commit — `ESTADO-FINAL-ORDEM-40.md`.
- **Onde parou**: a ordem está fechada do lado do executor. A ponta `46e77ee` já estava no remoto
  (`origin/fable/clima-40`, CI verde: runs 43561853223 e 43561853245); os commits do fecho foram empurrados
  sem force. CI na ponta `faeff25`: Sonda de privacidade verde; Testes dos rascunhos com 8 de 9 jobs verdes à
  hora desta escrita (faltava acabar o `foto-mestre`) — o resultado final vem na mensagem de fecho da sessão.
  A `main` e os outros ramos não foram tocados.
- **Próximo passo**: (1) conferência do coordenador sobre os 5 vídeos; (2) o olho do Mestre; (3) a expansão
  (nevasca e chuva que alaga) nasce desta ponta, no ramo `fable/clima-41-expansao`, no clone
  `C:\Users\txcga\fable-clima-expansao\repo`.
- **O que falta conferir** (por natureza não é do executor, ou não foi provado):
  - a conferência do coordenador e o veredicto do Mestre sobre os vídeos — não são meus;
  - não medido no telemóvel nem no export web (só PC, RTX 4060; o custo que conta lá é o enchimento de
    píxeis das camadas transparentes);
  - não há interruptor na interface (liga-se pela API, pela preferência `"clima"` e por `-- --clima=`);
  - figuras GLB, chão com relevo (salpicos num plano; poças inclinam num declive), ordem de desenho com a
    água e a erva do mapa, câmara livre do Mestre dentro da coluna de clima — pontos 4 a 9 da lista do
    `NOTAS.md`, todos passos da integração com o mapa da cadeia;
  - a etiqueta do vídeo `arena-jogadora.mp4` fica por cima do botão «FICHA» (defeito da bancada, não do clima).
