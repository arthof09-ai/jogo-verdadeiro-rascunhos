# Ordem 61: juntar a recusa (Ordens 58 e 60) na linha juntada. ESTADO FINAL

*Fecho da ordem, 2026-11-15, Claude conta 2 (Opus 5.5), uma só sessão. Godot 4.7.2 e Node 26, nesta máquina.
Trabalhei no clone `C:\Users\txcga\fable-mapa\repo`, no ramo `fable/integracao-50`. Os registos brutos estão em
`C:\Users\txcga\fable-mapa\_tmp\o61\`, fora do repositório. A `mesa-mestre.json` (o «M» do CRLF) não entrou em
commit nenhum. Não toquei em `main`, em `.github` nem nas outras worktrees.*

## Resumo

**A fusão já estava feita antes desta ordem. Não houve nada para fundir.** `fable/recusa-60` (`91f645d`) entrou
na linha em `fec411d`, a fusão da Ordem 60 (parte B) sobre `9b97066`. A Ordem 59 fundiu-se depois por cima
(`06371c1`), e a ponta publicada ficou em `65d66e9`. A Ordem 58 nunca teve ramo próprio a fundir: o trabalho dela
(`b554ff2` … `ae1e574`) já estava na linha antes da Ordem 57, e `ae1e574` é a base comum entre `fable/recusa-60`
e a linha.

Esta ordem só acrescenta este ESTADO. Não muda código.

## 1. O que medi

Fiz o fetch das duas refs, por refspec explícita, às 2026-11-15, depois das 16:37:

| ref | ponta |
|---|---|
| `origin/fable/integracao-50` | `65d66e9` (igual à medida pelo coordenador) |
| `origin/fable/recusa-60` | `91f645d` (igual à medida pelo coordenador) |

- `git merge-base --is-ancestor 91f645d 65d66e9` → **sim**. `git log 65d66e9..91f645d` → 0 commits. Nada da recusa
  ficou de fora da linha.
- O ramo local `fable/integracao-50` deste clone estava atrasado, em `9b97066`. Avancei-o por avanço rápido para
  `65d66e9`. A seguir, `git merge --no-edit origin/fable/recusa-60` → **«Already up to date.»** Não houve commit de
  fusão nem conflitos.
- Dos 21 ficheiros que a Ordem 60 mudou (`ae1e574..91f645d`), só 4 diferem na linha, e todos de propósito:
  `MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt` são listas refeitas pelo gerador; o `ESTADO-FINAL-ORDEM-60.md`
  ganhou na linha a secção 4 (a fusão); e o `pecas_mestre.gd` tem as guardas da 57 e da 60 juntas (276). Ninguém
  reescreveu trabalho da 58 nem da 60.

## 2. As duas capacidades, provadas na ponta `65d66e9`

**(a) A figura não fica de pé numa casa bloqueada, e a recusa tem nome (Ordem 58).** A regra está em
`CampoDaMesa.recusa_do_pe` (`campo_da_mesa.gd`), e o texto é «FLORESTA-E08-CASA-BLOQUEADA: (x,y) motivo».
`provar_pes_bloqueadas.gd` → TUDO PASSOU (59 ok). Por exemplo:

- «de pé em casas bloqueadas 0 de 43», «0 de 42» e «0 de 5», no Mestre e na jogadora;
- «5 recusas com nome (FLORESTA-E08-CASA-BLOQUEADA), uma por casa bloqueada, com o motivo do servidor»;
- uma figura entra na escarpa (27,24) e outra sai: «A na escarpa (27,24) recusada (FLORESTA-E08-CASA-BLOQUEADA:
  (27,24) escarpa)», nas duas arenas.

**(b) A recusa vê-se no ecrã, nas duas arenas (Ordem 60).** Os pontos do código são `marcar_recusas` e
`aviso_das_recusas`, o sinal `recusas_novas` que chega aos alertas do Mestre, `hud.mostrar_aviso` e
`Textos.NAO_DE_PE`. `provar_recusa_no_ecra.gd` → TUDO PASSOU (62 ok). Por exemplo:

- Mestre: «recusas avisadas NO ECRÃ (os alertas da coluna 1) com o nome e o motivo: 43 de 43» e «5 de 5»;
  «figuras recusadas VISÍVEIS na arena 3D, na casa delas: 5 de 5 com marca, 5 de 5 com o nome e o motivo».
- Jogadora: «recusas avisadas NO ECRÃ (o «Aviso» do HUD) com o nome e o motivo: 43 de 43» e «5 de 5», com a mesma
  marca 5 de 5 na arena 3D.
- Na escarpa (27,24): «Alfa (Heroína Teste)» não fica de pé em (27,24): escarpa — o mapa bloqueia a casa. Fica
  marcada no mapa.» (Mestre). A jogadora vê «Alfa» não fica de pé nesta casa: …», sem a casa.
- Sem casas bloqueadas não aparece nenhum aviso. A mesma vista outra vez não traz nenhum aviso novo.

## 3. As suites na ponta `65d66e9`

Sem janela, Godot 4.7.2, scripts em `_tmp/o61/suites.sh` e `_tmp/o61/servidor.sh`:

| suite | resultado |
|---|---|
| `abrir_scripts` | 83 scripts, 0 falhas |
| `rodar_testes` · `clima_forte` | 177/177 · 119/119 |
| `pecas_mestre` · `hud_acoes` | 276/276 · 50/50 (as guardas da 58 e da 60 estão lá) |
| `abrir_mestre` · `abrir_clareira` · `canario_privacidade` | 67/67 · 22/22 · 10/10 |
| `medir_mestre` · `medir_painel_config` | saída 0 |
| `provar_assentamento` · `provar_terreno_servidor` · `provar_mestre_no_relevo` | TUDO PASSOU |
| `provar_pes_bloqueadas` (58) · `provar_recusa_no_ecra` (60) | TUDO PASSOU |
| `exportar_terreno --conferir` | o terreno do servidor está EM DIA |
| `provar_molde_54` | 0 falhas; o retrato do mapa vestido tem 188 linhas, igual ao construído de raiz |
| arranque `--quit-after 600` | «pronto», 0 erros |
| servidor (`node --permission --allow-net`) | 365 testes: 355 passam, 10 saltados, 0 falham |
| protocolo + `conferir-schemas.py` · `conferir-terreno.mjs` · validador-glb | saída 0 · 0 · 0 |

Nenhum registo tem SCRIPT ERROR, Parse Error ou Compile Error.

## 4. CI

- Na ponta herdada `65d66e9`, o push da Ordem 59 correu o run `43747452346` (Testes dos rascunhos). Os 9 jobs deram
  verde: `servidor`, `cliente`, `ponta-a-ponta`, `retoma-pc`, `foto-mestre`, `validador-glb`, `motor-real`,
  `protocolo` e `godot-cliente`. A sonda de privacidade `43747452438` também deu verde.
- Esta ordem faz dois commits na linha: este ESTADO, e a seguir as listas da retoma e o MANIFESTO refeitos pelo
  gerador. O CI do último commit corre no push do fecho. O resultado fica no relatório da sessão e no log do
  GitHub Actions, porque não cabe neste ficheiro sem um commit a mais.

## 5. O que ficou de fora

1. **A reserva 2 da Ordem 58 continua aberta, fora do âmbito.** Quando a escala muda, o servidor pode deixar figuras
   em casas bloqueadas (eram 7 na sonda `provas/ordem-58-pes/sonda-escala-bloqueadas.mjs`). Falta decidir se a
   mudança se recusa com nome ou se as figuras passam para a casa livre mais próxima. É uma decisão de desenho.
   Hoje, a recusa no ecrã é o que avisa quando isso acontece.
2. **As reservas da Ordem 60 ficam como estavam:** o alerta do Mestre cortado em 2 linhas, um só aviso por vez no
   HUD, o aviso comprido com muitas recusas e a jogadora a ver as recusas de todas as figuras visíveis. Estão no
   `ESTADO-FINAL-ORDEM-60.md`, e esta ordem não lhes toca.
3. **Visto de passagem, sem mexer:** o `ESTADO-FINAL-ORDEM-60.md` tem um CR solto no caminho do clone
   (`fable-mapa` + CR + `epo`, na secção 4). Por isso `git ls-files --eol` mostra-o como `i/-text`. É o mesmo
   defeito que a Ordem 59 corrigiu no ESTADO dela. Não o corrigi, porque é trabalho da Ordem 60 e não desta fusão.
4. A Ordem 58 não tinha ramo próprio por fundir. A ordem fala em «Ordens 58+60», mas o trabalho da 58 já estava na
   linha antes da Ordem 57 (ver o Resumo).
