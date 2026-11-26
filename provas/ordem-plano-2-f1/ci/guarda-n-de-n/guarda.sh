! grep -E "SCRIPT ERROR|Parse Error|Compile Error" "$L"
# N de N: exactamente uma linha final, os dois N iguais e maiores que zero (o tr normaliza o CRLF).
FINAL=$(tr -d '\r' < "$L" | grep -E "^[0-9]+ de [0-9]+ verificações passaram\.$" || true)
echo "linha final: ${FINAL:-(nenhuma)}"
N_LINHAS=$(printf '%s\n' "$FINAL" | grep -c . || true)
[ "$N_LINHAS" = 1 ] || { echo "::error::camera_segue: esperava 1 linha final «N de N», há $N_LINHAS"; exit 1; }
read -r PASSOU _ TOTAL _ <<< "$FINAL"
if [ "$TOTAL" -gt 0 ] && [ "$PASSOU" = "$TOTAL" ]; then echo "camera_segue: $PASSOU de $TOTAL (N de N)"; else echo "::error::camera_segue: $PASSOU de $TOTAL (tem de ser N de N)"; exit 1; fi
