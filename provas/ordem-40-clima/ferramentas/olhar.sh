#!/usr/bin/env bash
# olhar.sh <video> <quadro> <passo> <saida.png> [crop=w:h:x:y]
# Composto com o tempo em cores: o quadro N vai para o VERMELHO, N+passo para o VERDE, N+2·passo para o AZUL.
# O que está parado fica cinzento; o que se mexe deixa três pontos R → G → B no sentido do movimento.
set -e
FF=/c/Users/txcga/fable-clima/ferramentas/py/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v9.0.2.exe
V="$1"; N="$2"; P="$3"; S="$4"; C="${5:-}"
T=$(mktemp -d /c/Users/txcga/fable-clima/olhar/tmp.XXXX)
for i in 0 1 2; do
  Q=$((N + i * P))
  "$FF" -hide_banner -loglevel error -y -i "$V" -vf "select='eq(n\,$Q)'" -frames:v 1 "$T/$i.png"
done
F="[1:v]format=gray[g];[2:v]format=gray[b];[0:v]format=gray[r];[g][b][r]mergeplanes=0x001020:gbrp,format=rgb24"
if [ -n "$C" ]; then F="$F,crop=$C"; fi
"$FF" -hide_banner -loglevel error -y -i "$T/0.png" -i "$T/1.png" -i "$T/2.png" -filter_complex "$F" -frames:v 1 "$S"
rm -rf "$T"
echo "ok $S"
