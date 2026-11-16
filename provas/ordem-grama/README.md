# Provas da ORDEM GRAMA — a relva que guarda a passagem

A relva da arena (mapa da floresta dentro da arena do jogo) reage a quem a atravessa:
abre/dobra por onde a figura passou e recupera sozinha — cada altura à sua maneira.
Só apresentação: nenhuma regra lê isto (o cliente nunca calcula regra).

## Os vídeos (a prova — movimento prova-se com vídeo)

| Ficheiro | O que mostra |
|---|---|
| `videos/grama-baixa-recta-e-curva.mp4` | A erva BAIXA (0,30 m): o manequim atravessa em linha recta e em curva; reacção curta e rápida, recupera em ~0,9 s com um ressalto de mola. (1280×720, 35,2 s) |
| `videos/grama-media-recta-e-curva.mp4` | A erva MÉDIA (0,95 m): abre já à frente de quem vem e fecha logo atrás; recupera em ~1,6 s. (1280×720, 35,8 s) |
| `videos/grama-alta-recta-e-curva.mp4` | A erva ALTA (1,40 m): abre um corredor que se segura ~3 s e fecha devagar (~12 s no total). (854×480, 46,3 s) |
| `videos/grama-tres-alturas-lado-a-lado.mp4` | As TRÊS lado a lado no mesmo enquadramento, atravessadas em sequência (recta para leste, curva para oeste) e a recuperação de cada uma. (854×480, 58,2 s — ver a nota) |

A figura é o manequim de prova da casa (Mannequin_F do UAL2 com o ANDAR v3,
`testes/manequim/andar-v3.glb`, SHA-256 8413b0395d6b9f161aefe05004999ee5f605d4eb6
8a81f9b56ea3491) — não é personagem do jogo; vive só neste arranjo de prova.

Os .mp4 são convertidos dos .avi do Movie Maker do Godot (H.264, sem cortes nem
mudança de velocidade), emitidos ao tamanho a que cada cena foi rendida: baixa e
média a 1280×720; alta e o combinado a 854×480 (resolução reduzida depois de três
quedas da máquina de render — o Movie Maker escreve sempre contentores 1920×1080;
o tamanho rendido é o que conta). Os .avi mestres da alta (406.108.786 B) e do
combinado (471.361.810 B) ficaram na sede da missão (VM do Plano C). Os mestres da
baixa e da média foram apagados por quota de disco depois de os .mp4 verificarem
(SHA-256 registados no ESTADO da sede: baixa `c79b27ecd19e…`, média `1e67f223c740…`).

**Nota sobre o filme combinado:** a simulação correu 67,1 s e a bancada mediu tudo
(sondas, fases e o fotograma `capturas/tres_t66s_recuperada.jpg`, tirado da cena viva
aos 66 s), mas o Movie Maker perdeu os quadros finais dentro do .avi: só 1.744 dos
2.016 quadros ficaram descodificáveis, por isso o .mp4 tem 58,2 s — chega ao fim da
curva e aos primeiros ~4 s da paragem. A recuperação completa das três ervas lê-se
nos filmes individuais (a alta mostra os seus ~14 s de paragem até ao fim), na
captura dos 66 s e nas medições.

## Medição

- `medicao/` — por modo: `<modo>_medicao.json` (pés no relevo quadro a quadro, a
  abertura da erva nas sondas ao longo do tempo, os tempos de recuperação medidos
  contra os da tabela, chamadas de desenho) e `<modo>_fases.json` (as fases do guião).
- `medicao/medicao_perfis.json` — FPS e chamadas de desenho por perfil gráfico
  (Baixo/Médio/Alto), com e sem as três alturas e o rastro. **Medido nesta VM, com
  render por software (llvmpipe)** — os FPS são os desta máquina fraca; as chamadas
  de desenho são as da cena e valem em qualquer máquina.
  *(A caminho: a medição de perfis corre em separado e entra em commit seguinte
  declarado — ver o ESTADO FINAL.)*
- `capturas/` — fotogramas de apoio etiquetados (não substituem os vídeos).

## A técnica (resumo; a folha completa está em rastro_relva.gd)

Um mapa do chão (256×256 pontos sobre a zona jogável + margem) guarda por ponto a
hora da última passagem, o rumo para onde a erva fugiu e a força. A CPU só escreve
à volta de quem anda (pegada em forma de ovo, comprida para a frente); o shader da
relva lê o ponto debaixo da raiz de cada tufo e dobra-o conforme a altura do tufo,
somando ao vento (contido na erva deitada). Passado o tempo de recuperação da erva
mais lenta, o mapa volta a zero e o shader nem o lê: sem ninguém a andar, custo zero.

Tempos de recuperação (da tabela, rastro_relva.CLASSES): baixa 0,9 s · média 1,55 s ·
alta 12 s (3 s toda aberta + 9 s a fechar).
