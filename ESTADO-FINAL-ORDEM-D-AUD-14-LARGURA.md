# ESTADO-FINAL — ORDEM-D-AUD-14-LARGURA (o tabuleiro do Mestre não muda de largura com o tamanho da janela)

**Estado: FEITA** — CI verde (Testes + Sonda) no `93853dd`.

A largura do tabuleiro do Mestre a 1600×900 deixou de depender do caminho até essa janela. **Antes: 880 px** com
abertura directa, **712 px** depois de 800×450 → 1600×900 e 864 px depois de mais um redimensionamento. **Depois: 864 px
nos três percursos.** Medido em píxeis reais, com e sem janela.

- **Executor:** Claude (opus), PC, conta 2. **Data:** 24/11/2026 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. **Ponta de partida:** `afc7e85`. A `main` não foi tocada.
- **Commits:** `7c65fb8` (código + teste), `cac934b` (listas da retoma), `93853dd` (provas + este ESTADO-FINAL) e a
  nota do CI.
- **Não toquei** na posição da caixa (ponto 5), no «na vez» (C-6), na largura da caixa da jogadora, no servidor, nos
  dados, nos workflows, na `main` nem no cliente da jogadora. A regra da largura da folha (45 %, coluna 1, tecto de
  85 %) também ficou como estava: só passou a ser calculada com a letra certa.

## 1. A causa e a correcção

Causa (a da INVESTIGA, confirmada): `_ao_redimensionar` muda a letra do tema (`_tema.default_font_size`) e, **no mesmo
quadro**, lê `_abas.get_tab_bar().get_minimum_size().x` para alargar a folha até caber a barra das abas. A `TabBar`
ainda tem em cache o mínimo da letra anterior. A segunda passagem diferida (`_repassar`) nem sempre o apanha a tempo:
o mínimo novo só chega depois. A folha fica então com a largura da letra anterior até a janela voltar a mudar.

| ficheiro | mudança |
|---|---|
| `rascunhos/cliente/cenas/mestre/mestre.gd:99-102` | `_abas_medidas`: o mínimo da barra com que a folha foi medida da última vez; `_remedir_pendente` |
| `mestre.gd:1241` (`_montar`) | liga `minimum_size_changed` da `TabBar` a `_ao_mudar_barra_abas` |
| `mestre.gd:1436-1437` (`_ao_redimensionar`) | guarda o mínimo lido em `_abas_medidas` (a conta não mudou) |
| `mestre.gd:1474-1486` (1470-1473: comentário) | `_ao_mudar_barra_abas`: se o mínimo actual difere de
`_abas_medidas`, mede a folha outra vez com `call_deferred` (uma só por quadro: `_remedir_pendente`).
`_remedir_folha` chama `_ao_redimensionar` |

Isto é a opção 1 da ordem («recalcular no `minimum_size_changed`»). A medida converge por evento: quando o
mínimo novo chega, a passagem diferida repõe `_abas_medidas` igual ao mínimo da barra, e o sinal seguinte já
não muda nada. Os números de linha da ordem (`:1311-1365`) são os da ponta da INVESTIGA (`96baf99`). Na ponta
de partida desta ordem, a função está em `:1407-1461`.

## 2. A prova (antes/depois, píxeis reais)

Ferramenta: `provas/ordem-d-aud-14-largura/ferramentas/medir_largura.gd`. Pormenor no README das provas.

| percurso | antes (`afc7e85`) | depois (`7c65fb8`) |
|---|---|---|
| A — abertura directa a 1600×900 | **880 px** (MEDIDA VELHA) | **864 px** |
| B — 800×450 → 1600×900 | **712 px** (MEDIDA VELHA) | **864 px** |
| C — … → 1600×898 → 1600×900 | 864 px | 864 px |
| resultado da ferramenta | DIFERENTES, saída 1 | **IGUAIS**, saída 0 |

Os mesmos números na janela real (DisplayServer Windows, com capturas) e em `--headless`. As corridas do PC
(janela, headless e as 13 suites) foram feitas da cópia de trabalho `afc7e85` + correcção; a prova sobre o
código cometido `7c65fb8` é o CI no `93853dd` (Testes 45416808039 + Sonda 45416807952). A prova de que o teste
dispara (4 falhas, `logs/antes/medir-mestre-sem-correccao.log`) é local e não se reproduz a partir de nenhuma
árvore cometida. O «880» directo de antes também vinha (inferência: a folha ficou no termo dos 45 %) da letra
anterior: a folha tinha 864 unidades e a regra pedia 883. **A largura certa é 864 px (±1 px; a INVESTIGA mediu
865 na janela real, `l11`)**, a do percurso C.

**Consequência a 800×450 (para o Mestre ver):** com a letra certa (32), a barra das abas mede 703 unidades e a regra
«a barra das abas nunca se corta» alarga a folha. O tabuleiro a 800×450 passa de **407 px para 287 px**. Antes, a
barra saía do ecrã (acabava em 2140 de 1920 unidades) e «Registo» e «Sala» não se viam (`capturas/antes/b1`); agora
vêem-se as seis abas (`capturas/depois/b1`). É a regra que já estava no código, agora aplicada com a medida certa, e
não a mudei. Se o Mestre quiser mais tabuleiro nas janelas pequenas, isso fica com a decisão pendente do D-AUD-14
(«mais tabuleiro: os 55 %, a coluna 1 recolher sem cartão»), fora desta ordem.

## 3. Testes

### 3.1 Novo

`rascunhos/cliente/testes/medir_mestre.gd` → `_medir_historia()` (corre no fim de `_medir_todas`, no passo do CI «Ecrã
do Mestre em ecrãs baixos»). Monta o Mestre directo a 1600×900, depois a 800×450, e passa para 1600×900. Confere:

1. a folha é a que a regra pede com a letra actual, nos três passos;
2. o tabuleiro tem a mesma largura nos dois percursos (±1 px). Imprime
   `MEDIDA MESTRE-LARGURA (1600, 900) directo=864 px depois de (800, 450)=864 px`.

**O teste dispara:** com o `mestre.gd` de `afc7e85` dá **4 falhas**, todas do bloco novo
(`logs/antes/medir-mestre-sem-correccao.log`: `directo=880 px depois de (800, 450)=712 px`, saída 1).

### 3.2 Suites (PC, Godot 4.7.2 `--headless`, com a correcção, em cópia de trabalho)

| suite | resultado |
|---|---|
| `rodar_testes.gd` | 333 de 333 |
| `abrir_scripts.gd` | 112 scripts, 0 falhas |
| `abrir_clareira.gd` | 22 de 22 |
| `medir_painel_config.gd` | 0 falhas, 0 sem medida |
| `abrir_mestre.gd` | 67 de 67 |
| `pecas_mestre.gd` | 329 de 329 |
| `medir_mestre.gd` | 0 falhas, 0 sem medida (com o teste novo) |
| `hud_acoes.gd` | 50 de 50 |
| `caixa_jogadora.gd` | 70 de 70 |
| `caixa_janela.gd` | 123 de 123 |
| `canario_privacidade.gd` | 10 de 10 |
| `teste_relato_caixa.gd` | 31 de 31 |
| `teste_nomes_relato.gd` | 26 de 26; redigido = registo limpo da COBERTURA-CORRECOES-6 byte a byte |

Nenhum `SCRIPT ERROR`/`Parse Error`/`Compile Error` nos logs (`provas/ordem-d-aud-14-largura/logs/suites/`). Não corri
no PC a validação dos comandos contra os schemas (falta o `jsonschema` no Python daqui). O CI faz esse passo. A
correcção não mexe em comandos. As suites do servidor (node) não foram tocadas e ficam com o CI.

## 4. Listas da retoma

`py -3 retoma-i0004/actualizar-listas.py` depois de `7c65fb8`: 0 novos, 0 tirados (só os hashes dos dois ficheiros
mudados) → `cac934b`. Esta ordem não muda mais nada em `rascunhos/`.

## Critérios da ordem

- [x] `_ao_redimensionar` mede a folha com a letra nova (recalcula no `minimum_size_changed` da barra das abas).
- [x] Medição antes/depois nos dois percursos, em píxeis: antes 880 / 712, depois **864 / 864**.
- [x] Suites verdes no PC e CI verde (ver a nota).
- [x] ESTADO-FINAL e provas em `provas/ordem-d-aud-14-largura/` (README + logs + capturas); listas da retoma
  sincronizadas.

## Nota do CI

Ao fazer push, a ponta tinha avançado (`6bbf552`, duas notas da conferência da D-AUD-07, sem `rascunhos/`). Fiz rebase
e os commits mudaram de hash: `672f3c1` → `7c65fb8` e `f3864aa` → `cac934b` (este ficheiro e o README já usam os
novos). Corri o `actualizar-listas` outra vez depois do rebase: nada mudou.

No `93853dd`, os dois workflows deram **success**:
- **Testes dos rascunhos** (run `45416808039`). O passo «Ecrã do Mestre em ecrãs baixos» imprimiu
  `MEDIDA MESTRE-LARGURA (1600, 900) directo=864 px depois de (800, 450)=864 px` e `ecrã do Mestre: 0 falha(s), 0 sem
  medida`;
- **Sonda de privacidade** (run `45416807952`).
