#!/bin/bash
# F2: as vezes 3..20 (a 1 e a 2 foram à mão, com os mesmos passos). Vez da Arqueira: medir, Mover uma casa
# (alterna os dois lados), medir, Encerrar → Sim. Vez de um monstro (modo manual): MestreVez = medir, Agir → Correr,
# medir, Encerrar a vez. As funções (Medir, EncerrarSim, MestreVez, SimDoDialogo) estão em ligar4.ps1 e v.ps1.
J=fb1005a9cc5081b31; lado=596; for n in $(seq 3 20); do NN=$(printf %02d $n)
vez=$(bash ferr/journal.sh 1 | head -1 | awk '{print $6}')
if [ "$vez" = "$J" ]; then
cat > tmp/v.ps1 <<EOT
Guarda
Medir 'f2-v$NN-inicio'
Clicar \$J 580 683; Start-Sleep -Milliseconds 1000
Mover \$J $lado 343; Start-Sleep -Milliseconds 300; Clicar \$J $lado 343; Start-Sleep -Milliseconds 2500
Medir 'f2-v$NN-depois'
EncerrarSim
EOT
[ $lado = 596 ] && lado=684 || lado=596
else printf "Guarda\nMestreVez 'f2-v$NN'\n" > tmp/v.ps1; fi
out=$(bash ferr/c.sh v$NN 40 < tmp/v.ps1); echo "v$NN vez=$vez | $out"; echo "$out" | grep -q 'OCUPADO\|DIALOGO?\|SEM RESPOSTA' && break; sleep 1
done
