# Provas — ORDEM-D-AUD-01-CORRECCOES-4 (26/11/2026)

Esta ordem segue a sentença 930 (secção B). Faz quatro coisas:

- **B1:** o «Mover» armado desarma quando chegam opções novas da **mesma** vez sem `mover`.
- **B2:** uma linha de comentário no ramo `vez != _vez`.
- **B4:** a limitação da prova do B2 da CORRECCOES-3, que fica declarada no ESTADO-FINAL.
- **B3:** a mutação corre pelo mesmo guião das suites.

A prova usa só os testes de unidade, as suites e o CI, tudo headless. **A bancada de rede não correu.** Não há
capturas.

## Os guiões

- `suites.sh`: primeiro a **mutação do B1** e depois as suites da D-AUD-01-CORRECCOES-3. Corre-se assim:

  ```
  GODOT=<Godot_v4.7.2-stable_win64_console.exe> MOTOR_MJS=<motor privado> [PYTHON=<python com jsonschema>] \
    bash provas/ordem-d-aud-01-correccoes-4/suites.sh
  ```

  Os caminhos vêm do ambiente e não estão escritos no guião, por isso o guião commitado é literalmente o que correu.
  A mutação corre pelo **mesmo caminho** das suites: `MESTRE_COMANDOS` + `timeout 300`, o log começa com a linha do
  comando (e com o diff da mutação), e o exit vai para o `resumo.txt`. Isto cumpre o B3.
  - Antes de mutar, o guião confere que o `aba_agir.gd` está limpo e que a linha a mutar aparece uma só vez.
  - O ficheiro é reposto com `git checkout`. Há um `trap` que o repõe mesmo se algo falhar.
  - Depois de repor, o guião confere que o `git diff` ficou vazio.
- `suites-node-lf.sh`: as duas suites de Node que comparam bytes com ficheiros guardados, corridas num worktree em
  LF. Ver «Fim de linha» mais abaixo.

## A mutação (`suites/pecas_mestre-SEM-B1.log`)

A mutação troca `if a_mover and not tem_mover:` por `if false and a_mover and not tem_mover:` em
`rascunhos/cliente/cenas/mestre/aba_agir.gd` (a linha 94 de `07ea9ff`, hoje `bc94aad` depois do rebase). O desarme e o aviso deixam de correr.

Resultado: **exit 1, 332 de 334**. As **duas** FALHA são as duas verificações novas da D-AUD-01-CORRECCOES-4.
Nenhuma outra falhou, e houve 0 erros de script. A linha do `resumo.txt` é esta:

```
pecas_mestre-SEM-B1 exit=1 falhas=2 falhas-correccoes-4=2 scriptErrors=0 reposto=sim
```

O que cada FALHA mostra sem a correcção:

- **(a)** O «Mover» fica armado (casas, destaque e «Cancelar» por desarmar), sem o aviso. O toque na casa velha
  manda um `MASTER_ACT`: é a casa-fantasma.
- **(b)** A guarda sobrevive («orc-teste»). O «Cancelar» repõe o «Colocar», e os dois toques mandam 2 `MASTER_PLACE`.

## Suites (`suites/`, resumo em `suites/resumo.txt`)

Correram com Godot 4.7.2 `--headless` e Node v26.13.1, sobre `a158c31`. O `a158c31` é o `07ea9ff` com as listas
da retoma sincronizadas. Depois do rebase sobre `27b70e5` estes commits passaram a `deb0fd4` e `bc94aad`, com o
mesmo conteúdo em `rascunhos/` (ESTADO-FINAL, §5).

| Suite | Resultado | Na D-AUD-01-CORRECCOES-3 |
|---|---|---|
| servidor (`testes/*.test.mjs`), árvore LF | **446/446** (`servidor-LF.log`) | 435/435 |
| motor real (`testes-motor-real`), árvore LF | **6/6** (`motor-real-LF.log`) | 2/2 |
| prova da caixa | PROVA OK | PROVA OK |
| `abrir_scripts` | 113 scripts, 0 falhas | 111 |
| `rodar_testes` | 333 de 333 | 321 |
| `abrir_mestre` | 67 de 67 | 67 |
| `pecas_mestre` | **334 de 334** | 295 |
| `medir_mestre` | 0 falhas, 0 sem medida | 0, 0 |
| `hud_acoes` | 70 de 70 | 50 |
| `caixa_jogadora` | 70 de 70 | 70 |
| `caixa_janela` | 123 de 123 | 123 |
| canário de privacidade | 10 de 10 | 10 |
| `validar-mensagens.py` | `pecas_mestre` 29 mensagens, 0 falhas; `abrir_mestre` 9, 0 falhas | 29 / 9 |

Todas as suites Godot deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`. Os números subiram desde a
CORRECCOES-3 porque a linha cresceu: entre `4746c9d` e `08beeda` entraram, entre outras, a F3, a F4-PARCIAL, a
D-AUD-06, a D-AUD-07, a D-AUD-14 e a D-AUD-16 com os seus seguimentos. O `pecas_mestre` ganhou as 2 verificações desta ordem. Os testes novos não mandam comandos quando
passam, e o `pecas_mestre` continua com 29 mensagens.

### Fim de linha: `servidor` e `motor-real` no clone do PC

No `resumo.txt` estes dois têm `exit=1`: `servidor` dá 445 de 446 e `motor-real` 5 de 6. Em cada um, a única falha
é uma comparação **byte a byte** com um ficheiro guardado:

- `fixture-mestre.test.mjs`: «mesa-mestre.json desactualizado»;
- `vetores-ouro.test.mjs`: «01-ataque-normal.json: a corrida difere do ficheiro gravado».

O ficheiro lido do disco vinha em CRLF (ver o diff no `servidor.log`), compatível com `core.autocrlf=true` no clone do PC (valor afirmado, sem output de `git config` cometida). O índice está em LF e a cópia de trabalho em CRLF (`git ls-files
--eol`: `i/lf w/crlf`). Por isso o ficheiro lido do disco nunca é igual ao que o teste gera.

O `suites-node-lf.sh` faz um worktree destacado no mesmo código (o `a158c31` pré-rebase já não é endereçável; ver §5) com `core.autocrlf=false` (`i/lf w/lf`), corre
as duas suites lá e tira o worktree. Deu **446/446** e **6/6**, ambos com exit 0 (`resumo-node-lf.txt`,
`servidor-LF.log`, `motor-real-LF.log`). O servidor não foi tocado por esta ordem. O CI corre em LF.

### A 1.ª corrida (`suites/corrida-1/`)

O guião correu duas vezes. Na 1.ª vez o `python` do PC não tinha o `jsonschema`, e os dois `validar-mensagens`
deram exit 1 com `ModuleNotFoundError`. O resto deu igual à 2.ª corrida, incluindo a mutação. Instalei o
`jsonschema` (versão afirmada, sem output de versão cometida) num venv fora do repo (`<sede>/tmp/venv`), juntei ao guião a variável `PYTHON` (por omissão
continua `python`) e corri o guião todo outra vez. Os logs em `suites/` são da 2.ª corrida. Da 1.ª ficaram o
`resumo.txt` e os dois logs do validador.

Os logs completos das outras suites da 1.ª corrida não ficaram guardados; a igualdade com a 2.ª corrida verifica-se só pelos exits do `resumo.txt` da 1.ª.

## Privacidade

- Nos logs, o caminho da máquina passou a `<sede>`.
- O motor real veio da pasta privada de uma bancada anterior (`MOTOR_MJS`, fora do repo). Não foi copiado.
- Nomes: só os fictícios das fichas de teste.
