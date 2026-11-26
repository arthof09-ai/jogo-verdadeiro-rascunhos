#!/bin/bash
# F1, corrida das 19:29: depois do Arco (t2b.ps1), «Encerrar → Sim» rodada a rodada até a fase ser «fim».
for r in $(seq 2 14); do
cat > tmp/r.ps1 <<EOT
Guarda
Clicar \$J 819 683; Start-Sleep -Milliseconds 1100
Captura \$J "\$CAP\c-r$r-encerrar-jog.png" | Out-Null
SimDoDialogo
Start-Sleep -Milliseconds 5000
Cap 'c-r$r-depois-monstros' | Out-Null
"r$r feito"
EOT
out=$(bash ferr/c.sh rr$r 40 < tmp/r.ps1); echo "$out" | grep -q 'OCUPADO\|DIALOGO?\|SEM RESPOSTA' && break
bash ferr/journal.sh 1 | grep -q 'fase fim' && break
done
