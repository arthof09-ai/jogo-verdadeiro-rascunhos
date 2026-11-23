# ESTADO-FINAL — Ordem F61 da sentença da F28 (a segunda corrida cometida da medição do D1)

**Coordenador:** CM-000009. **Executor:** Claude (opus, esforço médio), PC do cunhado. **Data:** 23/11/2026.
**Linha:** `fable/integracao-50`, trabalho directo, sem ramo e sem fusão.

**Partida.** O `HEAD` do clone à hora do lançamento era `5f92408`, atrás da origem. Antes de começar, avancei por
*fast-forward* até à ponta, que era `74f5fa9` (`74f5fa9f6c550ba63b5615012f58dccba8344f91`, as F65/F69/F70 da F51).
As corridas assentam em `74f5fa9`.
- No `push` da obra, a linha já tinha andado 1 commit, até `01ce39b`. É a nota do CI da F51 e só acrescenta 2 linhas a
  `ESTADO-FINAL-ORDEM-F51-MUTACAO-FERRAMENTA.md`. Não toca em `rascunhos/` nem nesta pasta.
- Pus o commit da obra por cima, e a linha ficou linear. As medidas valem tal e qual.

**Commits:**
1. `c1a1988`: a obra (a ferramenta com a câmara reposta, os dois logs da 2.ª corrida, o `resumo.txt`, o script que o
   escreve e o README da pasta);
2. este ESTADO-FINAL;
3. a nota do CI da ponta do commit 2, acrescentada ao §5 (só documento).

**Esta ordem só mede e não muda nenhum ficheiro do jogo.** Não há nenhum nome verdadeiro inteiro nem valor de PIN neste
ficheiro (§6).

## 0. Antes de começar: o que encontrei na cópia de trabalho
- **A sentença não está neste PC.** O ficheiro `~/workspace/conferencias/f28-custo-d1-hud/SENTENCA-F28-CUSTO-D1-HUD.md`
  não existe, porque não há `~/workspace`, como na F51. Trabalhei com o que a ordem cita e com a emenda F60 do
  `ESTADO-FINAL-ORDEM-F28-CUSTO-D1-HUD.md` (§1, «Repetição»). Ver o ponto 1 do §7.
- **Havia trabalho de uma tentativa anterior, por cometer.** O clone (02:17) trazia 3 coisas, feitas entre as 02:18 e
  as 02:21 e sem ESTADO-FINAL nem commit:
  - a ferramenta mudada (repor a câmara);
  - a secção nova do README;
  - dois logs `…-corrida2.log` e um `resumo.txt`.

  Não os cometi como se fossem desta corrida. Fiz isto:
  1. guardei-os fora do repo, em `tmp/tentativa-anterior/`;
  2. repus a cópia e avancei por *fast-forward*;
  3. revi a alteração da ferramenta contra `camera_mesa.gd` e adoptei-a. Só usa campos públicos da câmara (`modo`,
     `foco`, `zoom`, `rumo`, `inclinacao`) e o `_saltar()` dela, que tira a suavização;
  4. corri as duas medições de raiz (§1).

  As minhas tabelas são iguais byte a byte às da tentativa anterior. Os logs só diferem no tempo de carga da floresta.
- **Biblioteca (GameDev Kit):** vi as 10 pastas da BIB (ambientes, HUD e UX, itens, jogos 2D, sistemas, áudio,
  animações 3D, VFX e magias). Não há nada para resumir ou comparar registos de texto. O único ficheiro novo é um script
  de 31 linhas que escreve o `resumo.txt`, no padrão das ferramentas de `provas/`. (Correcção do coordenador, F72, 23/11/2026: o script tem 31 linhas, não 32.)

## 1. Como corri a 2.ª corrida
- **A ferramenta:** `provas/ordem-f28-custo-d1-hud/ferramentas/medir_custo_d1_hud.gd`, a mesma da F28, com uma
  mudança: **a câmara repõe-se entre casos**, como a F64 pediu.
  - `_guardar_camara()` guarda o modo, o foco, o zoom, o rumo e a inclinação logo que a arena fica pronta.
  - `_repor_camara()` volta a pô-los no `_repor` (antes de todos os casos) e salta para lá com `_saltar()`.
  - O log diz o estado guardado: modo 0, foco (0.75, −0.085, 0.75), zoom 1,500, rumo 0,0 e inclinação 55,0.
- **Os casos:** os mesmos 62, em 844×390 e em 780×360. Usei o Godot 4.7.2 `_console.exe` com `--headless`, no
  Windows 11, e o mesmo comando do README.
- **Na ponta (com o D1):** `medicao/medir_custo_d1_hud-corrida2.log`.
- **Sem o D1 (o contrafactual):** `medicao/medir_custo_d1_hud-sem-d1-corrida2.log`.
  - Pus o `caixa_ordem.gd` de `0bebd76` só na cópia de trabalho e reponho-o a seguir com `git checkout`.
  - Depois de repor, o `git diff` ficou vazio e o SHA do ficheiro é igual ao do `HEAD` (`cc26f56c…`), nas duas vezes
    que o troquei.
- **Corri as duas medições duas vezes, e as tabelas saíram iguais nas duas.** Entre as duas, troquei a redacção de um
  comentário da ferramenta (§6). Os logs cometidos são os da 2.ª vez, com a ferramenta tal como ficou cometida.
  A 1.ª vez ficou em `tmp/corrida2/`, fora do repo, só para confirmar.

## 2. Os logs e o resumo
| ficheiro | rc | casos | erros de medição | linhas com MEDIDA | linhas TABELA | linhas com `error`/`warning` | sha256 |
|---|---|---|---|---|---|---|---|
| `medicao/medir_custo_d1_hud-corrida2.log` (na ponta) | **0** | **62** | **0** | 62 | 62 | 0 | `8e14444c033b…` |
| `medicao/medir_custo_d1_hud-sem-d1-corrida2.log` (sem o D1) | **0** | **62** | **0** | 62 | 62 | 0 | `0680c217bda4…` |

- `medicao/resumo.txt` (sha256 `743a1d0ca9fa…`) tem:
  - o rc e a contagem dos dois logs;
  - a comparação com a 1.ª corrida;
  - as duas tabelas completas.
- Escreve-o `ferramentas/resumo_corrida2.sh <raiz> <rc-ponta> <rc-sem-d1> <partida>`. Voltar a corrê-lo dá o mesmo
  ficheiro.
- Os nomes distinguem as corridas. A 1.ª continua em `medicao/medir_custo_d1_hud.log` e `sem-d1/medir_custo_d1_hud.log`,
  e não foi mexida. A 2.ª tem o sufixo `-corrida2`.

## 3. Corrida a corrida (1.ª × 2.ª)
**As tabelas são iguais, à excepção do deslocamento da câmara no arrastar, que muda na 4.ª casa decimal.** São 62
linhas TABELA por medição:

| medição | linhas iguais byte a byte | linhas que diferem | quais |
|---|---|---|---|
| na ponta | 61 | 1 | arrastar 1 dedo, 780×360, controlo |
| sem o D1 | 59 | 3 | arrastar 1 dedo: 844×390 controlo, 780×360 lista e 780×360 controlo |

O deslocamento do arrastar, em metros:

| medição | ecrã | caso | 1.ª corrida | 2.ª corrida |
|---|---|---|---|---|
| na ponta | 844×390 | lista | 0.0 | 0.0 |
| na ponta | 844×390 | controlo | 2.26925158500671 | 2.26925158500671 |
| na ponta | 780×360 | lista | 0.0 | 0.0 |
| na ponta | 780×360 | controlo | **2.26987314224243** | **2.26925158500671** |
| sem o D1 | 844×390 | lista | 2.26925158500671 | 2.26925158500671 |
| sem o D1 | 844×390 | controlo | **2.26987314224243** | **2.26925158500671** |
| sem o D1 | 780×360 | lista | **2.26859712600708** | **2.26925158500671** |
| sem o D1 | 780×360 | controlo | **2.26802849769592** | **2.26925158500671** |

- **Nenhuma conclusão da F28 muda.**
  - Os 15 botões continuam a custar +1 toque com o D1, e 1 toque sem ele.
  - Com a lista aberta, o arrastar continua a dar 0,000 m e a pinça 1,500 → 1,500.
  - A roda, o rato e a jogada típica (4 / 6 / 6 com o D1, 4 / 5 / 5 sem ele) dão o mesmo.
  - A 2,27 m do §3 da F28 fica 2,27 m.
- **O que a reposição da câmara mudou.** Com a câmara reposta, os 6 arrastares que deslocam a câmara dão todos o mesmo
  valor, `2.26925158500671`. Na 1.ª corrida variavam entre 2,2680 e 2,2699. A reposição tira a variação, o que aponta
  para o estado que a câmara levava de um caso para o seguinte. A ordem pedia que a reposição se fizesse se não mudasse
  os números: só muda essa 4.ª casa decimal, que é a variação que a ordem já admite.
- **Fora das linhas TABELA e MEDIDA,** os logs só diferem em duas coisas:
  - o tempo de carga da floresta (`pronta em … ms`), que muda de corrida para corrida;
  - a linha nova `== F61: a câmara repõe-se entre casos (…) ==`, a 6.ª linha dos logs novos.

## 4. Nada se partiu
**Neste PC, sobre a obra** (Godot 4.7.2 Windows, os mesmos comandos do CI):

| suite | resultado | rc | `SCRIPT ERROR` / `Parse Error` / `Compile Error` |
|---|---|---|---|
| o canário (`teste_nomes_relato.gd`) | **26 de 26** | 0 | 0 |
| `rodar_testes` | **321 de 321** | 0 | 0 |
| `caixa_janela` | **123 de 123** | 0 | 0 |
| `caixa_jogadora` | **70 de 70** | 0 | 0 |
| mutação das células (`mutacao-celulas.sh`) | **114 de 123**, 9 falhas, todas do assert B6, «MUTACAO APANHADA» | 0 | 0 |

- A mutação repôs o `caixa_ordem.gd`: o `git diff` ficou vazio.
- As saídas cruas ficaram em `tmp/suites/`, fora do repo, porque o canário imprime nomes inteiros de propósito.
- A obra não muda nenhum ficheiro que as suites leiam: só mexe em `provas/ordem-f28-custo-d1-hud/`.
- O CI da ponta está no §5.

## 5. CI
**CI da ponta `c1a1988` (a obra): verde.**
- **Testes dos rascunhos**, run `45125654264`: passaram os 10 jobs (`servidor`, `validador-glb`, `motor-real`,
  `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`, `foto-mestre` e `retoma-pc`).
- **Sonda de privacidade**, run `45125654337`: verde.
- **Os números do log do run:**
  - o canário deu «26 de 26», e o passo novo da F65 deu o auto-teste da redacção 12 de 12 e a comparação «igual»;
  - `rodar_testes` 321/321, também no `godot-cliente`;
  - `caixa_janela` 123/123;
  - `caixa_jogadora` 70/70;
  - a mutação das células deu «114 de 123» e «MUTACAO APANHADA: 9 falhas, todas do assert B6».
- O `retoma-pc` ficou verde, o que confirma que as listas da retoma batem certo sem mudar.

**CI da ponta `53ae12a` (a obra mais este ESTADO-FINAL): verde.**
- Testes dos rascunhos, run `45125978651`: passaram os 10 jobs.
- Sonda de privacidade, run `45125978637`: verde.
- Os números são os mesmos: canário 26/26 (redacção 12/12), `rodar_testes` 321/321 (também no `godot-cliente`),
  `caixa_janela` 123/123, `caixa_jogadora` 70/70 e mutação das células «114 de 123».
- O commit desta nota só acrescenta este parágrafo a este ficheiro.

## 6. Privacidade re-derivada
Conferidor: `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`, nos dois critérios (alargado e `--velho`).
Na coluna dos nomes inteiros conta-se um achado cujo pedaço tem o comprimento do nome inteiro.

| ficheiro | alargado / antigo | nomes inteiros |
|---|---|---|
| este ESTADO-FINAL | **0 / 0** | 0 |
| `provas/ordem-f28-custo-d1-hud/README.md` | **0 / 0** | 0 |
| `ferramentas/medir_custo_d1_hud.gd` | **0 / 0** | 0 |
| `ferramentas/resumo_corrida2.sh` | **0 / 0** | 0 |
| `medicao/resumo.txt` | **0 / 0** | 0 |
| `medicao/medir_custo_d1_hud-corrida2.log`, `medicao/medir_custo_d1_hud-sem-d1-corrida2.log` | 2 / 2 por log | **0** |

- **A ferramenta** teve 2 / 2 achados com a alteração da câmara, na linha 126. Eram um pedaço de 4 letras: o pronome
  distributivo de quatro letras, o mesmo que a F51 já evitava. Testei as substitutas no conferidor antes de trocar,
  e o comentário passou a «antes de todos os casos». Ficou 0 / 0, como na F28. As medições voltaram a correr depois da
  troca (§1).
- **Os dois logs** têm 2 / 2 numa só linha que eu não escrevi: a 3.ª, o relatório de carga do mapa da floresta
  (`[floresta] pronta em … ms | {…}`). São pedaços de 5 letras, os mesmos achados e na mesma linha dos dois logs da
  1.ª corrida, que a F28 aceitou: palavras correntes, não nomes.
- **Nomes verdadeiros inteiros: 0** em todos os ficheiros da obra e neste ESTADO-FINAL. Os nomes que a ferramenta e os
  logs mostram são públicos e genéricos, os mesmos da suite.
- **PIN: 0.** Esta ordem não arrancou o servidor, por isso não houve PIN nem `--pin=`. Procurei números de 20
  algarismos (a forma do PIN) em todos os ficheiros desta ordem e não há nenhum.
- **As listas da retoma:** corri `python retoma-i0004/actualizar-listas.py` e deu «0 novos, 0 tirados». As listas só
  cobrem `rascunhos/`, e nenhum ficheiro de `rascunhos/` mudou. Nenhum SHA mudou, por isso não houve nada a
  sincronizar.

## 7. Pontos abertos para o coordenador
1. **A sentença da F28 não está neste PC** (não há `~/workspace/conferencias/`). Segui a ordem e a emenda F60 do
   ESTADO-FINAL da F28. Se a sentença pedir mais alguma coisa sobre a 2.ª corrida, como outros nomes de ficheiro ou
   outra pasta, é preciso conferir.
2. **A F64 também não está neste PC.** A ordem diz que a F64 pede a reposição da câmara, e foi isso que fiz: o modo, o
   foco, o zoom, o rumo e a inclinação de quando a arena ficou pronta, com o salto sem suavização.
   - Não repus o estado interno dos gestos da câmara (`_toques`, `_arrastando` e os outros). Os casos já acabam com os
     dedos levantados.
   - Se a F64 pedir mais do que isto, é preciso conferir.
3. **A 1.ª corrida fica como estava.** Os logs da 1.ª corrida foram feitos sem a reposição da câmara, e a 2.ª com ela.
   Por isso, a diferença da 4.ª casa decimal do arrastar já não é a mesma variação da 1.ª corrida:
   - na 2.ª corrida, o arrastar sai igual em todos os casos;
   - na 1.ª, variava.

   Não voltei a correr a 1.ª sem a reposição para a cometer: a ordem pede só a 2.ª corrida.
4. **A tentativa anterior** (§0): os restos dela ficaram em `tmp/tentativa-anterior/`, fora do repo. Não sei quem a
   correu nem porque parou.
