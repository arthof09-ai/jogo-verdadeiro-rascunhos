# provas/ordem-f3 — o «antes» da bancada lido com os nós quietos

O que está aqui, por ordem de data. O relatório é o `ESTADO-FINAL-ORDEM-F3.md` na raiz da linha.

## 21/11/2026 — a correcção (`73975d6`, fundida na linha em `d6348d5`)

| pasta / ficheiro | o quê |
|---|---|
| `ferramentas/bancada_jogadora_mapa_medida.gd` | Cópia instrumentada da bancada de então (`b481122`): imprime o resto do nó no frame do «assente». |
| `ferramentas/correr-medida.sh`, `ferramentas/cinco-seguidas.sh` | Os guiões dessa corrida. Os caminhos estão fixos para o clone `ordem-f3/repo` de então. |
| `registos/` | A medição de antes e depois (natural, 30 corridas; forçada `--fixed-fps 3001`), os extractos do CI vermelho e o registo das 5 corridas. |
| `cinco-seguidas/r1…r5/` | Os `repeticao.md` e os JSON da jogadora das 5 corridas de 21/11. |

## 24/11/2026 — a mesma correcção, medida e provada outra vez sobre a ponta `3d8c187`

| pasta / ficheiro | o quê |
|---|---|
| `ferramentas/medir-ponta.sh` | N corridas da batalha de bancada com `padrao` (a bancada da linha) ou `sem`. `sem` é a mesma bancada com `QUIETO_FRAMES := 1`, gerada por `sed`: a 1 leitura, a espera sai logo, por isso lê no frame do «assente», como antes do conserto. Os caminhos saem da pasta do guião. |
| `ferramentas/resumir-jogadora.mjs` | Uma linha por JSON da jogadora: o desvio da heroína a 1 m e a 2 m, se os desvios são exactos, e cada resto que o registo `quietos` apanhou. |
| `ferramentas/cinco-seguidas-ponta.sh` | As 5 corridas seguidas: a bancada padrão, o guião do CI (`correr-provas-mapa.sh`) e o comparador, como no passo «Repetição» do CI. |
| `ponta-3d8c187/medicao/forcada-sem.log`, `forcada-padrao.log` (+ JSON e log da c1) | O defeito forçado (`--fixed-fps 2001`), 2 + 2 corridas: sem a espera, 2/2 com resto; com a padrão, 2/2 exactas. |
| `ponta-3d8c187/medicao/natural-sem.log`, `natural-padrao.log` | 30 + 30 corridas naturais. |
| `ponta-3d8c187/medicao/controlo-comparador.log` | A série K do comparador (CORR9): 9 de 9 controlos dão o esperado. |
| `ponta-3d8c187/cinco-seguidas/cinco-seguidas.log` | O registo das 5 corridas: 5/5 `REPETE-SE` 461/461 e 73/73. |
| `ponta-3d8c187/cinco-seguidas/r1…r5/` | Por corrida: `bancada.out`, `ci.out`, `ci-resultado.txt`, `repeticao.md`, e para a bancada padrão e o guião do CI o JSON e o log da jogadora e o log da sonda do fio. |

Para correr de novo (no PC, Git Bash, com o projecto do cliente importado):

```
GODOT=<o caminho do teu Godot 4.7.2 no teu PC>
GARGS="--fixed-fps 2001" bash provas/ordem-f3/ferramentas/medir-ponta.sh sem    <pasta> 2
GARGS="--fixed-fps 2001" bash provas/ordem-f3/ferramentas/medir-ponta.sh padrao <pasta> 2
bash provas/ordem-f3/ferramentas/cinco-seguidas-ponta.sh <pasta>
```

**Porquê 2001 fps e não 3001, como em 21/11.** Com 3001 fps fixos, o passo de 1,5 m esgotava os 10 s de relógio da
espera do «assente». São 750 frames de tween. A tentativa a 3001 fps não chegou ao fim (a 1.ª verificação falhou por tempo esgotado na espera do «assente»); o registo não foi guardado, por isso a afirmação não se pode conferir a partir das provas.
Com 2001 fps:
- o tween de 0,25 s dura 500,25 frames;
- o frame 500 cai 0,125 ms antes do fim, dentro da janela de 1e-3 m dos passos de 1,5 m e de 1 m;
- as 49 verificações passam.
