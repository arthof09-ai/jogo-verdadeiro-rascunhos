#!/usr/bin/env bash
# gravar_videos.sh — Ordem 41: grava os vídeos etiquetados da expansão do clima (AVI do Godot, fora do repo) e
# passa-os a MP4 (H.264, 1280×720, 30 fps) para a pasta de provas do ramo. Uso: gravar_videos.sh [nomes…]
G=/c/Users/txcga/godot-472/Godot_v4.7.2-stable_win64_console.exe
FF=/c/Users/txcga/fable-clima/ferramentas/py/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v9.0.2.exe
P=/c/Users/txcga/fable-clima-expansao/prova41
PW='C:/Users/txcga/fable-clima-expansao/prova41'
D=/c/Users/txcga/fable-clima-expansao/repo/provas/ordem-41-clima/videos
mkdir -p "$P" "$D"
cd /c/Users/txcga/fable-clima-expansao/repo/rascunhos || exit 1
TODOS="nevasca alaga fracos"
for nome in ${@:-$TODOS}; do
  case "$nome" in
    nevasca) ARGS="--modo=nevasca --vento=20,3.0" ;;
    alaga)   ARGS="--modo=alaga --vento=20,2.5" ;;
    fracos)  ARGS="--modo=fracos --vento=20,2.5" ;;
    *) echo "desconhecido: $nome"; exit 1 ;;
  esac
  "$G" --path cliente --resolution 1280x720 --fixed-fps 30 --write-movie "$PW/$nome.avi" \
    -s res://testes/video_clima.gd -- $ARGS --saida="$PW" > "$P/log-$nome.txt" 2>&1
  echo "$nome: godot rc=$? · $(grep -E 'bancada do clima: ' "$P/log-$nome.txt" | tr '\n' ' ')"
  grep -E "SCRIPT ERROR|Parse Error|Compile Error|^ERROR|SHADER ERROR|FALHA" "$P/log-$nome.txt"
  "$FF" -hide_banner -loglevel error -y -i "$P/$nome.avi" -an -vf "scale=1280:720:flags=lanczos" \
    -c:v libx264 -preset slow -crf "${CRF:-24}" -pix_fmt yuv420p -movflags +faststart "$D/$nome.mp4"
  echo "$nome: mp4 rc=$? · $(ls -la "$D/$nome.mp4" | awk '{print $5}') bytes"
done
