#!/bin/bash
# ORDEM-SONDA-CAMINHOS-PC: prova local da Sonda, com os passos do privacidade.yml + remendo-privacidade.yml.patch, corrida na cópia de trabalho do ramo.
#   1. sem nenhuma das três formas, a Sonda passa como antes (e-mails + caminhos);
#   2. um ficheiro de teste com cada forma, uma a uma, é apanhado (saída 1); o ficheiro é apagado a seguir;
#   3. o auto-teste do guião (o mesmo passo do CI).
# As formas são montadas aqui em tempo de execução, para que este guião e os registos não as tragam escritas.
# Uso: bash prova-sonda.sh <python> <pasta de saída>     (corre a partir da raiz do repositório)
PY=${1:-python3}; DEST=${2:-provas/ordem-sonda-caminhos-pc/logs}
# Os registos escrevem-se fora da árvore (a Sonda percorre a árvore) e copiam-se para o destino no fim.
O=$(mktemp -d); trap 'rm -rf "$O"' EXIT
PY="$PY -X utf8"   # o -I ignora o PYTHONIOENCODING; o -X utf8 dá os acentos certos na consola do Windows
U="Us""ers"
F1="C"":/$U/ana/jogo/x.log"
F2="C"':\'"$U"'\ana\jogo\x.log'
F3="/c""/$U/ana/jogo/x.log"
T=sonda-teste-caminho.txt

sonda() {  # os passos do privacidade.yml, por ordem; devolve 1 se algum falhar
  local r=0
  if grep -rInE '[a-zA-Z0-9._%+-]+@(gmail|hotmail|outlook|yahoo|icloud)\.com' --exclude-dir=.git . ; then
    echo 'e-mails: FALHA'; r=1
  else
    echo 'e-mails: Sonda limpa: nenhum e-mail pessoal encontrado.'
  fi
  $PY -I .github/sonda/caminhos_pc.py --raiz . --base .github/sonda/caminhos-pc-base.txt || r=1
  return $r
}

cabeca() { echo "# comando: bash provas/ordem-sonda-caminhos-pc/ferramentas/prova-sonda.sh <python> $DEST   (na raiz do repositório)"; echo "# hora: $(date '+%Y-%m-%d %H:%M:%S %z')"; echo "# ponta: $(git rev-parse --short HEAD)$(git diff --quiet HEAD -- .github && echo " (.github igual ao commit)" || echo " (.github MEXIDO, por cometer)")"; }

L=$O/p0-sem-formas.log
{ cabeca; echo "## p0: árvore do ramo, sem ficheiro de teste"; sonda; echo "saída da Sonda: $?"; } > "$L" 2>&1

n=0
for F in "$F1" "$F2" "$F3"; do
  n=$((n+1))
  L=$O/p$n-forma-$n.log
  printf 'linha limpa\nficheiro de teste da forma %s: %s\nfim\n' "$n" "$F" > "$T"
  { cabeca; echo "## p$n: um ficheiro de teste ($T) com a forma $n na linha 2"; sonda; echo "saída da Sonda: $?"; } > "$L" 2>&1
  rm -f "$T"
done

L=$O/p4-depois.log
{ cabeca; echo "## p4: ficheiro de teste apagado — a Sonda volta ao verde"; sonda; echo "saída da Sonda: $?"; } > "$L" 2>&1

L=$O/p5-auto-teste.log
{ cabeca; echo "## p5: o auto-teste (o passo «A rede morde» do CI)"; $PY -I .github/sonda/caminhos_pc.py --auto-teste; echo "saída: $?"; } > "$L" 2>&1

mkdir -p "$DEST"; rm -f "$DEST"/p*.log; cp "$O"/p*.log "$DEST"/
for f in "$O"/p*.log; do echo "$(basename "$f"): $(grep -E '^saída' "$f" | tail -1)"; done
