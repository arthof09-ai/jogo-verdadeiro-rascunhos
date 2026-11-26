# A guarda N de N do passo `camera_segue` (F3 da ORDEM-PLANO-2-F1-FECHO-VIDEO)

`guarda.sh` são as linhas do passo do `testes.yml`, tal como saem do `passo-camera-segue.patch` (sem o `timeout ... | tee`).
Corrida no PC, 26/11/2026, `bash -eo pipefail` (como o `run:` do GitHub), contra 5 logs:

| caso | log | esperado |
|---|---|---|
| `ok` | `provas/ordem-plano-2-f1-fecho/suites/camera_segue.log` tal como está (CRLF, «22 de 22») | exit 0 |
| `falha` | o mesmo, com a linha final trocada para «21 de 22» | exit 1 |
| `sem` | o mesmo, sem a linha final (a suite não chegou ao fim) | exit 1 |
| `duas` | o mesmo, com uma segunda linha final | exit 1 |
| `zero` | só «0 de 0 verificações passaram.» | exit 1 |

O resultado está em `resultado.txt` (os 5 deram o esperado).
