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
- **A cobertura na faixa da borda** (casas cuja casa do mapa tem o centro a 1,35 m ou menos da borda da zona) pode
  vir de árvores e rochas que o cliente planta fora da zona, e essas mudam com a zona. Aí o servidor só afirma a
  cobertura total (2) e devolve `null` no resto — nunca um número errado. Fora da faixa, a cobertura é a do cliente.

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
