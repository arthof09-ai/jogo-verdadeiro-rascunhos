# Provas — Ordem F27 da sentença da CAIXA-EXPANDE-INTERACAO (23/11/2026, Claude conta 2, PC do cunhado)

A prova do D1 **com movimento**. Na F14 a prova viva do D1 correu com a arena sem modo (`Modo.NENHUM`): a medida
separava o certo do errado só pelo sinal `toque` da câmara. Aqui a jogadora está na vez dela, com o Mover aberto, e o
toque fora da caixa expandida cai numa casa de destino.

Nenhum ficheiro do jogo mudou. Mudaram a suite `rascunhos/cliente/testes/caixa_jogadora.gd` (§11 novo) e a ferramenta
da prova viva `provas/ordem-caixa-expande/ferramentas/prova_caixa_expande.gd` (passo 13 novo).

## suite/ — `caixa_jogadora` 70/70 (era 58/58: +12 do §11)
O §11 monta a **arena a sério** (`cenas/arena/arena.tscn`: o HUD dela, a câmara dela e o `_ao_toque` que transforma o
toque numa casa e a casa numa intenção), sem servidor. A jogadora está na vez (`vezId` = a figura dela, na casa
(10, 10)), o ROOM_OPTIONS traz as casas a até 3 casas dela e o Mover abre-se **por toque no botão da barra**. Corre com 12
e 16 figuras, em 844×390 e 780×360. Por caso, 3 verificações:
- a vez dela, o Mover aberto (48 casas de destino), a expandida aberta por toque, e um sítio fora dela que cai numa
  casa de destino (o centro da casa projectado pela câmara e confirmado por `casa_em_tela`; deu sempre a casa (7, 11));
- **D1 com o Mover aberto**: o toque fora fecha a expandida e a figura fica no sítio — o nó e a casa do Estado iguais,
  o modo continua Mover, nenhuma intenção na fila da Rede, o `toque` da câmara 0;
- **controlo**: com a caixa fechada, o mesmo toque escolhe a casa e sai `{"tipo": "mover", "destino": {"x": 7, "y": 11}}`.
  Sem servidor, a figura só anda quando o servidor aplica a intenção: isso mede-se na prova viva.

A Rede fica «na mesa» com um `WebSocketPeer` por ligar: a intenção regista-se na fila e o envio do texto falha sem erro.

`caixa_jogadora -- --estrita`: 69/70 (a mesma falha de sempre: 780×360, 11,5 u).

## sem-correcao/ — o §11 apanha o defeito: 54/70
A suite com o `caixa_ordem.gd` de antes da F14 (`0bebd76`; só na cópia de trabalho, depois reposto). As 16 falhas são as
8 do §10 (D1 e D3, como na F14) e as 8 novas do §11. Sem a correcção, o toque fora **envia a intenção de mover**: a fila
passa de 0 para 1 e o modo de 1 (Mover) para 0; o controlo falha porque o Mover já se fechou.

## cliente/ — prova viva, 255/255
A ferramenta da CAIXA-EXPANDE com o passo 13 novo, depois do 11/12. O lançador é
`ferramentas/correr-prova-mover-aberto.sh` (cópia do da CAIXA-EXPANDE-INTERACAO, com a saída aqui). O servidor de mesa é
o real, com o motor VLAB real (`a91c021c…`) e a semente 7. A cena usa o manequim de referência.

Verificações por passo: 0 → 1 · 1 → 22 · 2 → 20 · 3 → 4 · 4 → 22 · 5 → 20 · 6 → 17 · 7 → 31 · 8 → 18 · 9 → 6 ·
10 → 9 · 11 (com o 12) → 70 · **13 → 14** · mais 1 da abertura do manequim. Os passos 0 a 12 dão os mesmos 241 da
CAIXA-EXPANDE-VISTAS.

**Passo 13.** A IA de ensaio joga as vezes das outras figuras até ser a vez da jogadora do ecrã a sério. Ela abre o
Mover pelo botão da barra (por toque). Em 844×390 e 780×360, com as 16 figuras que o passo 11 deixou:
- a expandida abre-se por toque;
- um toque fora, num sítio que cai numa casa de destino, fecha-a e a figura fica no sítio: o nó, a casa do Estado e a
  casa no servidor (vista do Mestre) iguais, o Mover aberto, nenhuma intenção e nenhum `movimento` dela recebido;
- de controlo, o mesmo toque com a caixa fechada escolhe a casa e a figura anda até ela (Estado, servidor e nó).

Antes de medir, espera-se que nenhum nó de figura mexa durante 30 quadros (as figuras que a IA de ensaio acabou de
mover ainda podiam estar a andar).

| capturas | SHA-256 |
|---|---|
| `13-mover-aberta-16-figuras-844x390.png` | `6414041223b0ede0931fcbc0df237e6955626f483e9517a02138d303916eccde` |
| `13-mover-toque-fora-16-figuras-844x390.png` | `01c98d3e0b169dd9be413dd95c612b3df20cf5a64548178efde60f88d4c09c47` |
| `13-mover-controlo-16-figuras-844x390.png` | `adf56f3565c26b5f5057e909766fdccdb504465cc2a603a3649c732f981bbe9e` |
| `13-mover-aberta-16-figuras-780x360.png` | `ade67d9515603fe766503b2d3be79c444786111e92076cb7c69ae997c25dd278` |
| `13-mover-toque-fora-16-figuras-780x360.png` | `fa6d8c68adcfcc246a70c4791c399e1c4548fc06dd05ad9c5c970b235d982c6c` |
| `13-mover-controlo-16-figuras-780x360.png` | `deff54de7f023564ea7543d9e95d483082b3eb78208bcda05a9806310cd21dfe` |

## mutacao/ — o guião da CAIXA-JANELA-CI: 114 de 123
9 falhas, todas da B6, 0 erros de script, ficheiro reposto.

O PIN do Mestre é novo por corrida e só passa por `--pin=`. O info e o log do servidor ficam na pasta temporária.
O relato só leva nomes públicos: 0 nomes verdadeiros inteiros.
