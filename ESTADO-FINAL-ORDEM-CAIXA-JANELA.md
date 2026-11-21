# ESTADO FINAL — ORDEM-CAIXA-JANELA (Claude conta 1, PC · 21/11/2026)

**Ramo:** `claude1/caixa-janela` a partir de `fable/integracao-50` @ `96a9362`. **1 commit**, publicado. **Não fundido** — a fusão é do coordenador.
**Leitura prévia:** a conferência `~/workspace/conferencias/caixa-hud-jogadora/CONFERENCIA-CAIXA-HUD-JOGADORA.md` **não existe neste PC**
(nem `~/workspace`); trabalhei pelo que a ordem cita dela (B1 e B3) e pelo ESTADO FINAL da CAIXA-HUD-JOGADORA.

## O que mudou (só cliente; o servidor não foi tocado)

### B1 — a janela lobby→arena fechada
- `estado/estado.gd`: `eventos_desde_snapshot` — os ROOM_EVENT aplicados depois do último snapshot, pela ordem do `seq`.
  O snapshot esvazia-a (antes do `_drenar`, por isso os eventos em espera drenados depois dele entram). Limite
  `MAX_DESDE_SNAPSHOT` = 4096 (caem os mais velhos). Só guarda o que já chegou ao aparelho — nada novo à vista dela.
- `hud/hud.gd` `_ready`: depois de `_carregar_caixa()` (o snapshot), `_repetir_eventos_antes_do_hud()` repete esses eventos
  no modelo da ordem. O sinal já está ligado antes da repetição e tudo é síncrono: nenhum evento se perde nem conta duas vezes
  (provado: `vezes` = 3 com 2 repetidos + 1 pelo sinal).

### B3 — a caixa com 8+ figuras em ecrãs baixos (defeito real, apanhado pela medida)
Antes da correcção, com 8 figuras em 844×390, a faixa só tinha 569 u para uma frase de 713 u (e com 12 figuras ficava com
largura **negativa**: a faixa passava por baixo da caixa). Correcção, sem cor nova nenhuma:
- `hud/caixa_ordem.gd`: a fila é um `GridContainer`. Sem limite (o ecrã do Mestre) tem uma coluna por figura, ou seja, uma
  linha só, como antes (pecas_mestre 286/286, abrir_mestre 67/67). `limitar_largura(max)` parte-a em linhas.
- `hud/hud.gd` `_posicionar_caixa`: a caixa não pode ocupar a largura que a faixa precisa ao lado da ⚙
  (`largura_faixa_precisa()` = a frase mais comprida, a da pausa `FAIXA_MAIS_LONGA`, ou a de agora). Se a faixa centrada
  couber, fica como antes; se não couber, fica entre a ⚙ e a caixa.
- `hud/hud.gd` `_ao_redimensionar`: **defeito apanhado pela prova viva**: ao mudar o tamanho da janela (rodar o telemóvel), a
  fila não se voltava a desenhar e os retratos e nomes ficavam com a letra antiga (em 844×390 os nomes ficariam com ~6 px
  reais). Agora a caixa redesenha-se a cada mudança de tamanho.

### Testes
- `testes/caixa_jogadora.gd` **§7 novo** «eventos ANTES de o HUD abrir»: snapshot → movimento + ataque → só então o HUD;
  a caixa mostra-os ao abrir, e os eventos de depois seguem pelo sinal. 18/18. Sem a correcção: 16/18 (falha o §7).
- `testes/caixa_janela.gd` **novo** (sem ecrã): B1 (6 verificações) + B3 com 8, 12 e 16 figuras em 1280×720, 844×390 e
  780×360 (7 verificações por caso). 69/69. Sem a correcção B1: 3 falhas. Sem o redesenho ao redimensionar: 6 falhas.
- **Fora do CI** (como o `caixa_jogadora.gd`): o token do PC não tem o âmbito `workflow` e não toquei no passo do CI (é
  outra ordem). Para o juntar, ao lado do passo do `caixa_jogadora.gd`:
  `godot --headless --path rascunhos/cliente -s res://testes/caixa_janela.gd`

## As medidas (B3)

### Sem ecrã (`caixa_janela.gd`; u = unidades do ecrã 1920×1080 «expand»; px = píxeis reais)
| figuras | janela | caixa (u) | caixa (px reais) | % largura × altura | por linha | retrato | nome | faixa livre / precisa (u) | letra da faixa |
|---|---|---|---|---|---|---|---|---|---|
| 8 | 1280×720 | 767×212 | 511×141 | 40% × 20% | 8 | 41 px | 11,3 px | 1017 / 437 | 14,7 px |
| 8 | 844×390 | 1186×323 | 428×116 | 51% × 30% | 8 | 36 px | 9,8 px | 959 / 713 | 13,0 px |
| 8 | 780×360 | 1269×349 | 423×116 | 54% × 32% | 8 | 37 px | 9,7 px | 867 / 772 | 13,0 px |
| 12 | 844×390 | 1414×358 | 510×129 | 61% × 33% | 10 | 36 px | 9,8 px | 731 / 713 | 13,0 px |
| 12 | 780×360 | 1329×386 | 443×128 | 57% × 36% | 8 | 37 px | 9,7 px | 807 / 772 | 13,0 px |
| 16 | 844×390 | 1414×358 | 510×129 | 61% × 33% | 10 | 36 px | 9,8 px | 731 / 713 | 13,0 px |
| 16 | 780×360 | 1329×386 | 443×128 | 57% × 36% | 8 | 37 px | 9,7 px | 807 / 772 | 13,0 px |

(12 figuras em 1280×720: 1090×212 u, 12 numa linha, faixa 694/437; 16 em 1280×720: 1306×235 u, 15 por linha, faixa 478/437.)

### Captura viva (cliente a sério, servidor de bancada, 10 figuras; `provas/ordem-caixa-janela/cliente/relato.txt`)
| janela | caixa (u) | caixa (px reais) | % largura × altura | por linha | retrato | nome | faixa livre / precisa (u) | letra da faixa |
|---|---|---|---|---|---|---|---|---|
| 1280×720 | 841×212 | 560×141 | 44% × 20% | 10 | 41 px | 11,3 px | 943 / 453 | 14,7 px |
| 844×390 | 1326×323 | 478×116 | 57% × 30% | 10 | 36 px | 9,8 px | 819 / 729 | 13,0 px |
| 780×360 | 1320×386 | 440×128 | 56% × 36% | 9 (+1) | 37 px | 9,7 px | 816 / 788 | 13,0 px |

Em todos os casos: a caixa cabe no ecrã, não tapa a ⚙/ficha nem a barra, fica abaixo de metade da altura, e a faixa tem a
largura da frase mais comprida, numa linha, sem passar por baixo da caixa, com letra ≥ 13 px reais.

## As provas
- Viva (PC, RTX 4060, Godot 4.7.2, motor VLAB real): `provas/ordem-caixa-janela/` — **35/35**. B1 a sério: snapshot seq 33
  sem arena; 3 vezes jogadas na janela (10 eventos, seq 33→43); a arena abre e a caixa é logo a ordem do servidor (10
  figuras, vez Lobo). 3 capturas vistas por mim: `1-janela-1280x720.png`, `2-baixo-844x390.png`, `3-baixo-780x360.png`
  (na última a fila parte em 9 + 1).
- Suites locais todas verdes (`provas/ordem-caixa-janela/suites/`); a prova viva da CAIXA-HUD-JOGADORA corrida de novo:
  36/36.
- Privacidade: nenhuma mensagem do Mestre chega ao aparelho dela; a caixa só leva `ligada/ordemPor/ordemDinamica`; nenhum
  nome verdadeiro, vida, alma ou PA nos textos da caixa, e nenhum dígito (o canário de privacidade continua 10/10).
- Listas da retoma (`retoma-i0004/`) refeitas pelo `actualizar-listas.py` no mesmo commit.

## Pontos para o coordenador / o Mestre (não mexi)
1. **Os nomes na fila da caixa têm 0,75 da letra**: 9,7–11,3 px reais nos ecrãs medidos, abaixo dos 13 px da casa
   (`FONTE_MIN_PX_REAIS`). Lêem-se nas capturas, mas é pequeno. Vem do desenho da Ordem HUD (igual no ecrã do Mestre);
   subir para 1,0 alarga a caixa ~33% e parte a fila mais cedo. Decisão de desenho, não da ordem.
2. Com a caixa larga, a faixa deixa de ficar centrada no ecrã e passa a centrar-se entre a ⚙ e a caixa (vê-se nas 3
   capturas). Com poucas figuras fica centrada, como antes.
3. Passo do CI para `caixa_janela.gd` (e para o `caixa_jogadora.gd`) por juntar, por quem tiver o âmbito `workflow`.
