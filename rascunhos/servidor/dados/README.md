# O terreno do mapa no servidor (`terreno-floresta.json`)

O servidor conhece o relevo e os obstáculos do mapa da floresta, casa a casa, por este pacote. **Não se edita à
mão**: o cliente gera-o com as mesmas funções com que a arena desenha
(`cliente/cenas/arena/ferramentas/exportar_terreno.gd` → `assentamento.gd`, o `Relevo` e a grelha do mapa).
Ordens 44 (o terreno no servidor) e 48 (qualquer tamanho de grelha).

## O que tem (formato `terreno/2`)

O pacote é o **mapa inteiro**; o servidor (`nucleo/terreno.js`) recorta dele a grelha viva (tamanho e escala).

| parte | o quê |
|---|---|
| `escalas` | para 1, 1,5 e 2 m por casa, a origem no mapa (canto NO) da grelha de 1, 2, 3, … casas de lado — a regra da arena tabelada, até à maior que cabe no mapa de 75 m: **75, 50 e 37 casas de lado** |
| `redes` | as alturas das 9 maiores grelhas que cabem no mapa (uma por escala e «fase» da origem). Por casa, `alturaM` (o relevo no centro) e `peM` (a base de uma figura, a regra do pé da Ordem 44), em base64 dos doubles (IEEE-754, little-endian); por coluna e por linha, a casa do mapa debaixo do centro. Toda a grelha que cabe é um recorte exacto de uma rede: os mesmos bits que o cliente calcula |
| `mapa` | as 50 × 50 casas do mapa (1,5 m): `bloqueadas`, `cobertura` (0/1/2) e `motivos` (menir, santuário, lanterna, água funda, escarpa, tronco…) |
| `cabecalho.fontes` | o SHA-256 de cada ficheiro de que o terreno depende (6: relevo, grelha do mapa, campo, formas, assentamento e o exportador) |

## O que o servidor garante

- **Qualquer tamanho que caiba no mapa** é servido pelo recorte: a altura e o pé de cada casa são os do cliente
  (desvio 0, bit a bit), e as casas bloqueadas não se pisam, não se ocupam e não se atravessam, com o motivo na
  recusa ao Mestre (`CASA_BLOQUEADA: (x,y) motivo`).
- **Um tamanho que não caiba não vira «tudo se pisa»**: a sala não abre (`TERRENO_GRELHA_FORA_DO_MAPA`), a
  mudança para uma escala em que a grelha deixe de caber é recusada ao Mestre com o mesmo nome, e uma sala
  restaurada nessas condições também não abre. As salas nascem com casas de 1,5 m: com terreno, o tamanho tem
  de caber a 1,5 m (até 50 × 50).
- **Ordem 62: a mudança de escala não deixa figuras em casas bloqueadas.** As posições ficam em casas, mas cada
  figura colocada é conferida contra os bloqueios da grelha nova, com a regra da colocação. Se alguma ficava numa
  casa bloqueada, a mudança é recusada inteira e a sala fica na escala em que estava. O porquê vai ao Mestre
  (`ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS: … — <figura> CASA_BLOQUEADA: (x,y) motivo; …`), com a lista em
  `soMestre.figuras` (`figuraId`, `x`, `y`, `motivo`), que o ecrã do Mestre mostra nos alertas. O «Recomeçar» que
  devolvia uma figura a uma casa de colocação bloqueada na escala viva é recusado da mesma maneira
  (`RECOMECAR_SEM_CASA: …`). Ninguém é mudado de casa pelo servidor.
- **A cobertura na faixa da borda** (casas cuja casa do mapa tem o centro a 1,35 m ou menos da borda da zona) pode
  vir de árvores e rochas que o cliente planta fora da zona, e essas mudam com a zona. Aí o servidor só afirma a
  cobertura total (2) e devolve `null` no resto — nunca um número errado. Fora da faixa, a cobertura é a do cliente.
  **Ordem 59:** a faixa é só a dos lados da zona com mapa para lá deles. Um lado a `folgaFonteCoberturaM` (0,70 m)
  ou menos da fronteira do mapa não traz cobertura de fora (as fontes só contam dentro do mapa e só sobrevivem a
  mais de 0,70 m fora da zona): a faixa desse lado é servida com a cobertura do mapa, como o interior.

## Ordem MAPA-JOGÁVEL — o mapa inteiro é campo de batalha (20/11/2026)

- **A grelha é o mapa inteiro.** Uma sala com terreno e sem tamanho na config nasce com a grelha = o maior quadrado
  que cabe no mapa na escala viva: **50 × 50 de 1,5 m** (a malha, casa a casa). Quando o Mestre muda a escala, a
  grelha continua a ser o mapa inteiro — **75 × 75 de 1 m**, **37 × 37 de 2 m** (74 m: sobra uma faixa de 0,5 m em
  cada borda, menos do que uma casa) — e **ninguém muda de sítio no mapa**: cada figura, casa inicial, casa de
  colocação e casa a arder passa para a casa nova que contém o centro da de antes. Recusas nomeadas ao Mestre:
  `ESCALA_JUNTA_FIGURAS` (duas figuras na mesma casa) e `ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS`. Um tamanho dado
  na config continua a valer como antes (bancadas, provas das Ordens 44/48/62).
- **A água pisa-se.** O pacote continua a marcar o lago como casas bloqueadas por «água funda» (não muda: está preso
  por SHA às fontes do cliente). O servidor lê esse motivo como **casa de água** (`MOTIVOS_DE_AGUA` em
  `nucleo/terreno.js`): entra-se, ocupa-se e atravessa-se, com o **mesmo custo** de uma casa seca (o cânone diz
  «terreno difícil, não parede», sem número: [FALTA] o custo). `agua(x, y)` e `casasDeAgua()` na grelha recortada;
  `agua` no juízo do terreno. A 1,5 m são as 21 casas de água funda; 50 a 1 m; 13 a 2 m.
- Prova: `testes/ordem-mapa-jogavel.test.mjs`.

## Refazer o pacote

Sempre que o relevo, o mapa, a regra do assentamento ou o exportador mudarem. Em `rascunhos/`:

```
godot --headless --path cliente -s res://cenas/arena/ferramentas/exportar_terreno.gd
```

(~40 s: abre a arena do jogo 10 vezes, sem janela.)

## Conferir (o comando)

Na raiz do repositório:

```
node rascunhos/servidor/ferramentas/conferir-terreno.mjs [--godot=<caminho do Godot 4.7>]
```

Confere as fontes (o SHA de cada uma contra o cabeçalho, só Node) e depois refaz o pacote inteiro com o Godot e
compara-o, byte a byte, com o do repositório (não escreve nada). O Godot procura-se em `--godot=…`, na variável
`GODOT`, no `PATH` (`godot`) e por fim em `~/godot-*/Godot_v4.7*.exe`.

- Numa árvore limpa: sai com 0 e **`TERRENO EM DIA`**.
- Uma fonte mexida sem reexportar: sai com 1 e **`TERRENO_DESACTUALIZADO`**, com a fonte que mudou e a parte do
  pacote que difere (por exemplo «a fonte cenas/arena/assentamento.gd mudou desde a exportação» e «a parte
  «redes» do pacote difere do que o cliente gera hoje»).
- Sem Godot: sai com 1 e `GODOT_NAO_ENCONTRADO` (a conferência das fontes corre na mesma).

O **CI** não corre a conferência completa; corre a das fontes, no `rodar_testes` do cliente (o teste
«o terreno do servidor está em dia com as fontes do cliente»): uma fonte mudada sem reexportar põe o CI
vermelho, com o nome da fonte. O `rodar_testes` confere também a tabela das origens contra a regra da arena.

## As provas

- `cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd`: o servidor de verdade
  (`ferramentas/juizo-terreno.mjs`) contra a arena do jogo, casa a casa, em 12 grelhas (entre elas a 25 × 25 nas
  três escalas): altura e pé pelos bits do double, bloqueio, motivo, cobertura onde afirmada, recusas, mover.
- `testes/ordem44-terreno.test.mjs` e `testes/ordem48-terreno-qualquer-grelha.test.mjs`.
