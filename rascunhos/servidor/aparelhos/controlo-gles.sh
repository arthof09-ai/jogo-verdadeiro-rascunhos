#!/usr/bin/env bash
# ORDEM-PLANO-2-F2-ANDROID-SHADER: a medição de CONTROLO dos shaders no emulador.
#
#   bash aparelhos/controlo-gles.sh <controlo-gles.apk> <pasta-de-saída> [android-godot.log do jogo]
#
# Instala o projecto de controlo (aparelhos/controlo-gles/: um Godot 4.7.2 vazio, nenhum shader do jogo), espera o
# «controlo-gles pronto» e conta, no log do Godot, os «Program linking failed» por shader do motor e o tecto que o
# driver declara na mensagem. Se for dado o log do jogo, põe as duas contagens lado a lado. É uma MEDIÇÃO: só falha
# se o controlo não chegar a correr (sem «pronto» em 60 s), não por haver erros de link.
set -u
APK="$1"
SAIDA="$2"
JOGO="${3:-}"
PACOTE=org.assimilacao.controlo
mkdir -p "$SAIDA"
adb wait-for-device
adb install -r "$APK" || exit 1
adb logcat -c
adb shell "am start -W -n $PACOTE/com.godot.game.GodotAppLauncher"
ok=1
for i in $(seq 1 60); do
  if adb logcat -d -s godot:* 2>/dev/null | grep -q "controlo-gles pronto"; then ok=0; break; fi
  sleep 1
done
adb exec-out screencap -p > "$SAIDA/controlo-gles.png" || true
adb logcat -d > "$SAIDA/controlo-gles-logcat.log" 2>&1 || true
adb logcat -d -s godot:* > "$SAIDA/controlo-gles-godot.log" 2>&1 || true
adb shell am force-stop "$PACOTE" || true

contar() {  # <log> -> linhas «<Shader> <n>» e o tecto declarado
  local log="$1"
  for s in SceneShaderGLES3 CanvasShaderGLES3 SkyShaderGLES3 ParticlesShaderGLES3 CopyShaderGLES3; do
    printf '  %-22s link falhado: %s\n' "$s" "$(grep -c "ERROR: $s: Program linking failed" "$log")"
  done
  printf '  %-22s %s\n' "tecto declarado:" "$(grep -oE 'GL_MAX_FRAGMENT_UNIFORM_VECTORS \([0-9]+\)' "$log" | sort -u | tr '\n' ' ')"
  printf '  %-22s %s\n' "driver:" "$(grep -oE 'OpenGL API .*' "$log" | head -1)"
}
{
  echo "== CONTROLO (Godot 4.7.2 vazio, nenhum shader do jogo): $(basename "$APK")"
  contar "$SAIDA/controlo-gles-godot.log"
  grep -E "controlo-gles" "$SAIDA/controlo-gles-godot.log" | sed 's/^/  /'
  if [ -n "$JOGO" ] && [ -s "$JOGO" ]; then
    echo "== JOGO: $JOGO"
    contar "$JOGO"
  fi
} | tee "$SAIDA/controlo-gles-medida.txt"
if [ $ok -ne 0 ]; then echo "FALHA: o controlo não disse «pronto» em 60 s"; exit 1; fi
echo "CONTROLO GLES MEDIDO"
