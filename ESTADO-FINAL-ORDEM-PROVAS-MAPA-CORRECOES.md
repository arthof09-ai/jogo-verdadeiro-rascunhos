# ESTADO FINAL — ORDEM PROVAS-MAPA-CORRECOES (Claude do PC · Opus, esforço médio · 20/11/2026)

Ordem: as 6 correcções que a sentença `SENTENCA-CONFERENCIA-PROVAS-MAPA.md` (FUNDE COM CORRECÇÕES, 800/1000) pôs como
condição da fusão. Ficam no ramo, com um commit novo e **sem fusão**.
Marcas: VERIFICADO (corrido e conferido nesta sessão), PROPOSTO, PENDENTE.

**Commit `d21f734`** (`d21f7342adb62356e9dde1950f8d00822ec6d319`), sobre `b62a887`, no ramo `claude2/provas-mapa`.
Foi empurrado e conferido por `git ls-remote`: claude2/provas-mapa = d21f7342adb62356e9dde1950f8d00822ec6d319, e
fable/integracao-50 = c9c176f90a1567a36b00117f7a13613d1d66b05b (intocado). **VERIFICADO.**

## ⚠ Um desvio ao perímetro — leia primeiro
A ordem fecha o perímetro em `provas/…/provas-bancada/` e no ESTADO. Ao mesmo tempo, a correcção 1 pede que **a
ferramenta original deixe de dar as 9 falhas** e que volte a correr. Isso só se consegue mudando a original, e ela
mora em `rascunhos/cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd`, fora do perímetro. A ordem também
chama «original» ao `provar_terreno_servidor_mapa.gd`, mas esse é a cópia, que já passava.

Pesei as duas exigências e segui a correcção 1, que é o que a sentença pede («a única mancha vermelha que o ramo
deixa no repo»). Mudei **só esse ficheiro**: +19 −4 linhas, a mesma mudança que a cópia já tinha.
- É uma **ferramenta de prova**, não código do jogo. Nenhum script do servidor, do cliente do jogo, do protocolo
  nem do workflow mudou.
- Tirando esse ficheiro, o ramo inteiro (`c9c176f..d21f734`) só mexe em `provas/` e no ESTADO-FINAL: 21 ficheiros,
  +105.203 −4, e os 4 apagamentos são todos desse ficheiro.
- **Se o coordenador quiser o perímetro à letra**, basta reverter esse ficheiro. A original volta às 9 falhas, e
  a correcção 1 fica como «documentado»: o §1a/§1b do ESTADO-FINAL já o descreve como «75×75 @ 1 m».

## As 6 correcções

| # | correcção | o que foi feito | estado |
|---|---|---|---|
| 1 | O caso `[50, 50, 1.0]` na ferramenta original | A original abre a arena com a grelha que o servidor devolve (`juizo.largura/altura`) e guarda `pedida` e `grelha` no relatório. O caso leva o comentário «pedida 50×50 @ 1 m → servida 75×75 @ 1 m». **Re-corrida nas 18 grelhas: TUDO PASSOU, código de saída 0.** A grelha 11 dá 75×75, 5.625 casas, 0 juízo/motivo/cobertura ≠, desvio 0 bit a bit, marcos 14/14 e mover 110 (0). A cópia também foi re-corrida: TUDO PASSOU, e o JSON dela tem os **mesmos dados**, só com o cabeçalho de proveniência mudado (diff de 2 linhas). A corrida antiga, com as 9 falhas, fica em `provar-terreno-servidor-b62a887.log`. | VERIFICADO |
| 2 | Resíduo nulo | O ESTADO-FINAL §1a define que «cobertura ≠» conta só a cobertura afirmada e regista a não afirmada grelha a grelha: 0–184 casas `null` e, dessas, **0–4 por grelha** em que o cliente difere da referência (as grelhas-mapa 10–12 têm 0). `tabela-grelhas.md` ganhou a coluna «cob. não afirmada (cli ≠ ref)» e um cabeçalho com as regras. | VERIFICADO |
| 3 | Condição da obsolescência | ESTADO-FINAL §1b: a obsolescência assenta na regra §0 da MAPA-JOGÁVEL, **ainda PROPOSTA ao Mestre**. Se ele a rejeitar, o caso reabre; a fusão não a abençoa como incondicional. | feito |
| 4 | Proveniência | O `terreno-servidor-arena-adaptada.json` diz agora `"ordem": "PROVAS-MAPA (cópia adaptada da Ordem 59)"` e `"prova": "provas/…/provar_terreno_servidor_mapa.gd (cópia adaptada de …)"`: a ferramenta mudou e voltou a correr. O ESTADO-FINAL do commit é **o mesmo ficheiro da sede, byte a byte** (`cmp` contra `git show d21f734:…`: iguais, 21.129 B), com a linha de verificação do push de `b62a887`. | VERIFICADO |
| 5 | O que não se re-deriva | Tirei as durações «~70 s / ~40 s», que não tinham carimbo. Os registos novos têm `# início` / `# fim`: a original levou **84 s** (20:42:25 → 20:43:49) e a cópia **80 s** (20:43:56 → 20:45:16). A bancada não foi re-corrida e fica sem duração. As regras da água (recalculada pelo gerador com `juizo-terreno.mjs`) e dos marcos estão escritas no `tabela_grelhas.py` e no cabeçalho da tabela. As **15 figuras da grelha 1** são 17 pedidas − 3 recusadas (menir (1,0), menir (3,2) e santuário (28,28)) + a heroína; nas grelhas «auto» são 9 + a heroína = 10. | VERIFICADO |
| 6 | Variância da floresta | ESTADO-FINAL §2 (o relatório): o `casas_bloqueadas` dos resumos `[floresta]` é a grelha própria da floresta (50×50 @ 1,5 m), depois de ela tirar árvores, rochas e estrato da zona da grelha que a arena abriu (`zona_tirados_*`). Por isso varia com a grelha (173/146/128/…; a grelha-mapa dá 88) e **repete-se de corrida para corrida**: a re-corrida deu a mesma sequência, grelha a grelha. A prova não lê esse número. | VERIFICADO |

**Mais uma coisa.** O `tabela_grelhas.py` partia na consola do Windows (cp1252 com o «≠»). Agora escreve em UTF-8 e
corre-se com `python -I ferramentas/tabela_grelhas.py > tabela-grelhas.md`. A sonda do CI (e-mails pessoais) está
limpa nos ficheiros mudados.

## O que ficou no commit `d21f734` (10 ficheiros)
- `rascunhos/cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd`: a correcção 1 (ver o desvio acima).
- `provas/ordem-mapa-jogavel/provas-bancada/`:
  - `provar-terreno-servidor.log` e `terreno-servidor-arena.json`: a original, re-corrida, TUDO PASSOU;
  - `provar-terreno-servidor-b62a887.log` (novo): a corrida antiga, com as 9 falhas;
  - `provar-terreno-servidor-adaptada.log` e `terreno-servidor-arena-adaptada.json`: a cópia, re-corrida, com a
    proveniência certa;
  - `ferramentas/provar_terreno_servidor_mapa.gd`: a proveniência no JSON;
  - `ferramentas/tabela_grelhas.py` e `tabela-grelhas.md`: as regras e a cobertura não afirmada.
- `ESTADO-FINAL-ORDEM-PROVAS-MAPA.md`: os §1a, §1b, §2 e §3 e a Passagem anotados, e um §5 novo com as correcções.
  É igual à cópia da sede.

Os `.uid` que o Godot gerou ficaram fora do commit, como antes.

## Passagem
- **Onde parou:** as 6 correcções estão feitas e empurradas (`d21f734`), **sem fusão**. A fusão em
  `fable/integracao-50` fica para o coordenador, depois de conferir.
- **A conferir pelo coordenador:** o desvio ao perímetro (aceitar a mudança na ferramenta original, ou reverter esse
  ficheiro e ficar com o «documentado»).
- **Continua PROPOSTO ao Mestre:** a regra §0 (a mudança de escala na grelha-mapa guarda o sítio). A correcção 1 vale
  enquanto essa regra valer.
- **PENDENTE (as correcções 7–10 da sentença, ordens próprias na FILA):**
  - a volta 2 → 1,5 m e as recusas de escala;
  - um controlo positivo na sonda de privacidade;
  - o CI, ou uma segunda corrida da bancada;
  - uma bancada de rede com o ecrã do Mestre em Godot.

  Nenhuma foi tocada nesta ordem.
