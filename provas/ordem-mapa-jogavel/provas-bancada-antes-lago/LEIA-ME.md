# provas-bancada-antes-lago — a «primeira corrida» das provas do mapa, no terreno de ANTES do LAGO-MAIOR (arquivo)

**Arquivada em 21/11/2026 pela ORDEM-LAGO-SEG-CORRECOES** (ramo `claude1/lago-seg-correcoes`). Nada foi apagado: os
ficheiros foram movidos com `git mv` de `provas/ordem-mapa-jogavel/provas-bancada/` para aqui, sem mudar um byte.

## O que é
- É a referência com que o passo «Repetição» do job `provas-mapa` comparava cada corrida até esta ordem
  (`comparar-corridas.mjs primeira=provas/ordem-mapa-jogavel/provas-bancada ci=…`).
- Foi gravada pela ORDEM-PROVAS-MAPA (`b62a887`, 20/11/2026) e refeita pela ORDEM-PROVAS-MAPA-CORRECÕES (`d21f734`,
  20/11/2026), no PC (Windows, Godot 4.7.2).
- **O terreno é o de antes do lago crescer:** o `rascunhos/servidor/dados/terreno-floresta.json` anterior à fusão do
  `claude2/lago-maior` (`ed395bb`), o mesmo que está em `42c5eba`. Nele, por exemplo, a grelha-mapa (50 × 50 a 1,5 m)
  tem 67 casas bloqueadas no servidor e a carga 11 da floresta tem `casas_bloqueadas` 88.

## Porque foi arquivada
- Com o terreno novo (pós-LAGO), 177 dos 461 números do comparador mudam (bloqueadas por grelha, recusas, casas de
  água nos caminhos, o passo da bancada a 2 m…). O job ficava vermelho (`NÃO SE REPETE`, 284/461) com todas as provas
  a passar. A referência estava velha, e o comparador estava certo (ORDEM-LAGO-SEG §5; conferência da LAGO-SEG, 920/1000).
- A referência nova, gravada no terreno pós-LAGO, está de novo em `../provas-bancada/`.

## O que está aqui e o que não está
- Estão aqui todos os registos e JSON que estavam na raiz de `provas-bancada/`, incluindo os que o guião de hoje não
  volta a gerar: `provar-terreno-servidor-b62a887.log`, `canario-privacidade.log`, `sonda-ci.txt` e a
  `tabela-grelhas.md` velha.
- **As ferramentas não vieram.** `provas-bancada/ferramentas/` ficou no lugar porque o CI e o guião as usam a partir
  dali. A versão delas no momento em que esta referência foi gravada é a do commit `d21f734` (antes da F2 e da F3).
- Para comparar com isto: `node provas/ordem-provas-mapa-corr9/ferramentas/comparar-corridas.mjs
  antes-lago=provas/ordem-mapa-jogavel/provas-bancada-antes-lago nova=provas/ordem-mapa-jogavel/provas-bancada`
  dá `NÃO SE REPETE — 284/461`, a mesma contagem que o CI deu em `e810fbd`.
