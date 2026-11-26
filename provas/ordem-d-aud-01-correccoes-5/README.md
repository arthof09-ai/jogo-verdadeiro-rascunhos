# Provas — ORDEM-D-AUD-01-CORRECCOES-5 (26/11/2026)

A ordem segue a sentença 785 (a conferência da CORRECCOES-4). Faz quatro coisas:

- **Passo 1, o caso vizinho (a):** o «Mover» armado refresca as casas quando chegam opções da **mesma** vez **com**
  `mover`, mas com outras casas.
- **Passo 2:** um teste novo para esse caso.
- **Passo 4, a E1:** o teste (b) da CORRECCOES-4 passa a provar sozinho o desarme completo.
- **Passo 5, o B2:** o aviso «sem casas» fica enquanto as opções desta vez não trouxerem `mover`.

Tudo correu headless (testes de unidade, suites e CI). **A bancada de rede não correu.** Não há capturas.

## Os guiões

- **`e1.sh` (passo 4).** Corre sobre o commit da E1 (`3b6bf7b`), **antes** de qualquer mudança de código desta
  ordem. Faz o `pecas_mestre` e depois a mutação do B1 da CORRECCOES-4, com o mesmo `sed` e a mesma reposição do
  guião dela. Os logs estão em `e1/`.
- **`suites.sh` (passos 3 e 6).** Corre sobre `fa82f20` (o código final). Primeiro faz **duas mutações** pelo mesmo
  caminho (padrão B3 da CORRECCOES-4), depois as suites da CORRECCOES-4. Os logs estão em `suites/`. Corre-se
  assim:

  ```
  GODOT=<Godot_v4.7.2-stable_win64_console.exe> MOTOR_MJS=<motor privado> PYTHON=<python com jsonschema> \
    bash provas/ordem-d-aud-01-correccoes-5/suites.sh
  ```

  Em cada mutação, o guião:
  - confere que o `aba_agir.gd` está limpo e que a linha a mutar aparece uma só vez;
  - muta essa linha exacta (com Python, sem `sed`, por causa dos tabs);
  - corre com `MESTRE_COMANDOS` e `timeout 300`;
  - repõe com `git checkout` (há um `trap` que repõe mesmo se algo falhar);
  - confere o `git diff` vazio e escreve `reposto=sim` no `resumo.txt`.

Os caminhos vêm do ambiente. Nos logs, o caminho da máquina sai como `<sede>`, tanto na forma `/c/...` como na forma
`C:/...`.

## E1 (`e1/resumo.txt`, sobre `3b6bf7b`)

```
pecas_mestre exit=0 ok=334 falhas=0 ... fim=«334 de 334 verificações passaram.»
pecas_mestre-SEM-B1 exit=1 ok=332 falhas=2 falhas-correccoes-4=2 scriptErrors=0 fim=«332 de 334 verificações passaram.»
reposto=sim
```

Com a E1, o teste (b) continua verde. Sem o B1, só as duas da CORRECCOES-4 falham. Na (b) a FALHA continua a
mostrar a guarda viva e os dois `MASTER_PLACE`, e agora a condição exige também `desarmado_b`, `aviso_b` e os botões.

## As mutações (`suites/resumo.txt`, sobre `fa82f20`)

```
pecas_mestre-SEM-REFRESCO exit=1 falhas=1 falhas-correccoes-5=1 falhas-correccoes-5-B2=0 falhas-correccoes-4=0 scriptErrors=0 fim=«335 de 336 verificações passaram.» reposto=sim
pecas_mestre-SEM-B1 exit=1 falhas=3 falhas-correccoes-5=0 falhas-correccoes-5-B2=1 falhas-correccoes-4=2 scriptErrors=0 fim=«333 de 336 verificações passaram.» reposto=sim
```

- **SEM-REFRESCO** troca `if novas != _casas:` por `if false and novas != _casas:`. Falha **só** o teste novo:
  o refresco dá `false`, e a casa que saiu manda `["MASTER_ACT"]` (a casa-fantasma).
- **SEM-B1** (a da CORRECCOES-4, corrida outra vez sobre o código final) dá 333 de 336. Falham as duas da
  CORRECCOES-4 e a asserção do B2: sem o desarme, o aviso nunca liga (`false`). Nenhuma outra falhou.

## Suites (`suites/`, sobre `fa82f20`)

| Suite | Resultado | Na CORRECCOES-4 |
|---|---|---|
| servidor (`testes/*.test.mjs`) | **446/446**, exit 0 | 446/446 (só em LF) |
| motor real | **6/6**, exit 0 | 6/6 (só em LF) |
| prova da caixa | PROVA OK | PROVA OK |
| `abrir_scripts` | 113 scripts, 0 falhas | 113 |
| `rodar_testes` | 333 de 333 | 333 |
| `abrir_mestre` | 67 de 67 | 67 |
| `pecas_mestre` | **336 de 336** | 334 |
| `medir_mestre` | 0 falhas, 0 sem medida | 0, 0 |
| `hud_acoes` | 70 de 70 | 70 |
| `caixa_jogadora` | 70 de 70 | 70 |
| `caixa_janela` | 123 de 123 | 123 |
| canário de privacidade | 10 de 10 | 10 |
| `validar-mensagens.py` | `pecas_mestre` 30, 0 falhas; `abrir_mestre` 9, 0 falhas | 29 / 9 |

Todas as suites deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`. O `pecas_mestre` sobe de 334 para
336 porque há duas verificações novas. O validador sobe de 29 para 30 mensagens: é o `MASTER_ACT` da casa que entrou.

**Fim de linha.** Este clone foi feito com `core.autocrlf=false`, por isso o servidor e o motor real passam
directamente, sem o worktree LF de que a CORRECCOES-4 precisou.

**Primeira corrida do `e1.sh`.** Num clone novo, o `pecas_mestre` dá `Parse Error` (`AplicadorPerfil` não declarado)
enquanto não se corre o `--import`, porque as classes globais ainda não estão registadas. Corri
`--headless --path . --import`, como o CI faz, e corri o `e1.sh` outra vez. Os logs cometidos são da 2.ª corrida.

**Python e motor.** O `PYTHON` é o venv com `jsonschema` da CORRECCOES-4, fora do repo. O motor real veio da pasta
privada da bancada da D-AUD-06 e não foi copiado para o repo.
