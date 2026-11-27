# Provas — ORDEM-D-AUD-01-CORRECCOES-6 (27/11/2026)

Esta ordem aplica três erratas de código e de teste da sentença D-AUD-01-CORRECCOES-5 (820/1000):

- **J8:** a guarda em `_casas_de`.
- **J4:** a mitigação do teste da CORRECCOES-5 já não volta a armar o «Mover».
- **J1:** com o «Mover» armado, o destaque é sempre reposto.

Tudo correu headless, com Godot 4.7.2 `--headless` e Node. **A bancada de rede não correu.** Não há capturas.

## Os guiões

- **`muta.sh`** tem as funções comuns, `muta`, `pecas` e `redigir`. O caminho é o mesmo da CORRECCOES-5:
  - `MESTRE_COMANDOS` e `timeout 300`;
  - o log leva a linha do comando e o diff;
  - o ficheiro é reposto com `git checkout` (há um `trap` que repõe mesmo se algo falhar);
  - o `git diff` é conferido vazio, e o `resumo.txt` regista `reposto=sim`.

  Há uma diferença em relação à CORRECCOES-5: o bloco original e o mutado podem ter várias linhas. A contagem
  («aparece uma só vez») é feita em Python sobre o texto exacto, e não com `grep -x`.
- **`j4.sh`** corre sobre o commit do J4, `2e226c7`, que é **antes** do J1. O J1 junta uma verificação, por isso
  foi aqui que se mediram os números exactos da ordem. As duas mutações têm o texto da CORRECCOES-5. Os logs estão
  em `j4/`.
- **`suites.sh`** corre sobre o código final, `9c831f9`. Faz três mutações e depois as suites da CORRECCOES-5. Os
  logs estão em `suites/`.

```
GODOT=<Godot_v4.7.2-stable_win64_console.exe> PYTHON=<python com jsonschema> L=<pasta> bash provas/ordem-d-aud-01-correccoes-6/j4.sh
GODOT=<...> PYTHON=<...> [MOTOR_MJS=<motor privado>] L=<pasta> bash provas/ordem-d-aud-01-correccoes-6/suites.sh
```

Nos logs, o caminho da máquina sai como `<sede>`.

## J4 (`j4/resumo.txt`, sobre `2e226c7`)

```
pecas_mestre exit=0 falhas=0 scriptErrors=0 fim=«336 de 336 verificações passaram.»
pecas_mestre-SEM-REFRESCO exit=1 falhas=1 ... falhas-correccoes-5=1 ... fim=«335 de 336 verificações passaram.» reposto=sim
pecas_mestre-SEM-B1 exit=1 falhas=3 ... falhas-correccoes-5-B2=1 falhas-correccoes-4=2 ... fim=«333 de 336 verificações passaram.» reposto=sim
```

Na SEM-REFRESCO só falha o teste da CORRECCOES-5. Agora a casa que entrou aparece **engolida**:

```
FALHA D-AUD-01-CORRECCOES-5: … (casas, destaque, «Cancelar» e contagem: false), a casa que saiu não manda nada (["MASTER_ACT"]) e a que entrou manda MASTER_ACT mover ([])
```

Na CORRECCOES-5 a mitigação voltava a armar o «Mover» depois do fantasma. Esse armar lia as casas **novas**, e por
isso a casa que entrou mandava `MASTER_ACT` mesmo sem o refresco. Agora a mitigação só faz o `_responder`.

**A opção do J4 que escolhi: um `_ok` só.** A ordem deixava duas opções:

- separar a metade «a casa que entrou» num `_ok` próprio;
- ou manter um `_ok` só e registar aqui a limitação.

Escolhi a segunda, para não mudar os números exactos que a ordem pede (336, 335/336, 333/336). Com um `_ok`
separado, a SEM-REFRESCO daria duas falhas em 337, e não 335/336. A limitação fica registada assim:

**A mutação só discrimina o fantasma. A metade da casa que entrou só é provada pela corrida verde.** Na SEM-REFRESCO
o `_ok` já falha por causa da casa que saiu. O `[]` da casa que entrou aparece na mensagem da FALHA, mas não é ele
que a faz falhar.

## Código final (`suites/resumo.txt`, sobre `9c831f9`)

```
pecas_mestre-SEM-REFRESCO exit=1 falhas=1 falhas-correccoes-6=0 falhas-correccoes-5=1 ... fim=«336 de 337 verificações passaram.» reposto=sim
pecas_mestre-SEM-J1       exit=1 falhas=1 falhas-correccoes-6=1 falhas-correccoes-5=0 ... fim=«336 de 337 verificações passaram.» reposto=sim
pecas_mestre-SEM-B1       exit=1 falhas=3 ... falhas-correccoes-5-B2=1 falhas-correccoes-4=2 ... fim=«334 de 337 verificações passaram.» reposto=sim
```

- **SEM-REFRESCO (redefinida).** O J1 tirou a linha `if novas != _casas:`, que a mutação da CORRECCOES-5 mutava.
  No código novo, o equivalente é não trocar as casas: `_casas = novas` passa a `novas = _casas`. O destaque
  continua a ser reposto, mas com as casas velhas. Falha só a CORRECCOES-5, com a casa que entrou em `[]`.
- **SEM-J1 (nova).** Repõe o bloco da CORRECCOES-5, isto é, o `if novas != _casas:` com as duas linhas dentro.
  Falha **só** o teste do J1, com «0 casas destacadas, 33 armadas»: o destaque fica o do esquema, que está vazio.
- **SEM-B1.** A da CORRECCOES-4, com o mesmo texto. Falham as duas da CORRECCOES-4 e a do B2, como na CORRECCOES-5.
  O total é 337 porque o J1 juntou uma verificação.

### O teste do J1 (`pecas_mestre.gd`, «D-AUD-01-CORRECCOES-6 (J1): …»)

1. Arma o «Mover» e confere que o destaque é o das `_casas` (33 casas).
2. Liga o esquema da Mesa (`ligar_esquema(true)`). O `_desenhar_esquema()` desenha as casas do esquema por cima, e
   aqui o esquema está vazio. Confere que o destaque já **não** é o do «Mover».
3. Chegam as **mesmas** opções pela Rede (`ROOM_OPTIONS` na mesma revisão → `opcoes_mudaram` → `atualizar()`).
4. Pede `a_mover`, `_casas` iguais e `casas_destacadas() == _casas`.

No fim desliga o esquema e cancela o «Mover».

## Suites (`suites/`, sobre `9c831f9`)

| Suite | Resultado | Na CORRECCOES-5 |
|---|---|---|
| servidor (`testes/*.test.mjs`) | **459/459**, exit 0 | 446/446 |
| motor real | **não correu neste PC**: não há `MOTOR_MJS`. Corre no CI, job motor-real | 6/6 |
| prova da caixa | PROVA OK | PROVA OK |
| `abrir_scripts` | 113 scripts, 0 falhas | 113 |
| `rodar_testes` | 333 de 333 | 333 |
| `abrir_mestre` | 67 de 67 | 67 |
| `pecas_mestre` | **337 de 337** | 336 |
| `medir_mestre` | 0 falhas, 0 sem medida | 0, 0 |
| `hud_acoes` | 70 de 70 | 70 |
| `caixa_jogadora` | 70 de 70 | 70 |
| `caixa_janela` | 123 de 123 | 123 |
| canário de privacidade | 10 de 10 | 10 |
| `validar-mensagens.py` | `pecas_mestre` 30, 0 falhas; `abrir_mestre` 9, 0 falhas | 30 / 9 |

Todas deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`. O servidor passou de 446 para 459 testes
por causa das ordens da PLANO-2 que entraram entretanto na linha; esta ordem não lhe toca.

**Como se correu.** O clone é novo e tem `core.autocrlf=false`. Antes da primeira corrida fiz o `--import`, como o
CI faz. O `PYTHON` é um venv com `jsonschema`, fora do repo.
