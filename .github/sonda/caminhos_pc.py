#!/usr/bin/env python3
"""Sonda de privacidade — os caminhos reais do PC (ORDEM-SONDA-CAMINHOS-PC, CM-000009, 24/11/2026).

Procura, em todos os ficheiros de texto do repositório (fora do .git, binários saltados como no «grep -I»), as três
formas do caminho do PC:

  forma 1  «C:» + «/Users/»       (também com a barra dobrada)
  forma 2  «C:» + «\\Users\\»     (também com a barra invertida dobrada, como sai escapada em JSON)
  forma 3  «/c/» + «Users/»       (a forma do Git Bash)

sem distinguir maiúsculas. As expressões estão escritas de modo a não se apanharem a si mesmas (a letra da unidade
vai entre parênteses rectos), e este ficheiro, a linha de base e os registos das provas não trazem nenhuma das formas.

A linha de base (`caminhos-pc-base.txt`) congela as ocorrências que já estavam no ramo quando a rede entrou (a
redacção delas é outra errata). Cada entrada é «caminho-relativo<TAB>sha256 da linha» — sem o texto da linha, por
isso a base não repete o caminho do PC. É um multiconjunto: uma linha repetida conta tantas vezes quantas aparece.

Saída 0: todas as ocorrências estão na base. Saída 1: há pelo menos uma ocorrência nova (ficheiro:linha e forma,
sem o texto). As entradas da base que já não existem (ficheiro redigido) são só informadas; para encolher a base,
corre-se com --gerar. Crescer a base exige o sinal --permitir-crescer com a referência da ordem que o autoriza; sem ele, o --gerar recusa com saída 1.

Uso:
  python3 caminhos_pc.py [--raiz .] [--base .github/sonda/caminhos-pc-base.txt]
  python3 caminhos_pc.py --raiz . --gerar .github/sonda/caminhos-pc-base.txt [--permitir-crescer <referência da ordem>]
  python3 caminhos_pc.py --auto-teste
"""
import argparse
import collections
import hashlib
import os
import re
import sys
import tempfile

FORMAS = [
    (1, re.compile(rb"[C]:/+Users/+", re.IGNORECASE)),
    (2, re.compile(rb"[C]:\\+Users\\+", re.IGNORECASE)),
    (3, re.compile(rb"/[c]/Users/", re.IGNORECASE)),
]


def binario(dados: bytes) -> bool:
    return b"\0" in dados[:8192]


def procurar(raiz: str):
    """Devolve a lista de (caminho relativo, n.º da linha, formas, sha256 da linha)."""
    achados = []
    for pasta, subpastas, ficheiros in os.walk(raiz):
        subpastas[:] = sorted(d for d in subpastas if d != ".git")
        for nome in sorted(ficheiros):
            cam = os.path.join(pasta, nome)
            if os.path.islink(cam) or not os.path.isfile(cam):
                continue
            try:
                with open(cam, "rb") as f:
                    dados = f.read()
            except OSError:
                continue
            if binario(dados):
                continue
            rel = os.path.relpath(cam, raiz).replace(os.sep, "/")
            for n, linha in enumerate(dados.split(b"\n"), 1):
                linha = linha.rstrip(b"\r")
                formas = [k for k, rx in FORMAS if rx.search(linha)]
                if formas:
                    achados.append((rel, n, formas, hashlib.sha256(linha).hexdigest()))
    return achados


def ler_base(caminho: str):
    base = collections.Counter()
    try:
        f = open(caminho, "r", encoding="utf-8")
    except OSError:
        print(f"::error::A linha de base não existe ou não se lê: {os.path.basename(caminho)}")
        sys.exit(1)
    with f:
        for n, linha in enumerate(f, 1):
            linha = linha.rstrip("\r\n")
            if not linha or linha.startswith("#"):
                continue
            try:
                rel, h = linha.split("\t")
            except ValueError:
                print(f"::error::Linha de base mal formada na linha {n} de {os.path.basename(caminho)}: esperava caminho<TAB>sha")
                sys.exit(1)
            base[(rel, h)] += 1
    return base


def gerar(raiz: str, destino: str, permitir: str | None = None) -> int:
    achados = procurar(raiz)
    entradas = sorted(f"{rel}\t{h}" for rel, _, _, h in achados)
    if os.path.isfile(destino):
        # A base antiga existe: crescer só com sinal explícito (A.4).
        base_antiga = ler_base(destino)
        resto = base_antiga.copy()
        novos = []
        for rel, _, _, h in achados:
            if resto[(rel, h)] > 0:
                resto[(rel, h)] -= 1
            else:
                novos.append((rel, h))
        if novos:
            if permitir is None:
                print("::error::A base cresceria: há ocorrências novas sem entrada na base antiga — recuso gerar.")
                for rel, h in sorted(novos):
                    print(f"{rel}\t{h}")
                print("  (para crescer é preciso o sinal --permitir-crescer <referência da ordem>)")
                return 1
            print(f"a base cresce com autorização: {permitir}")
    with open(destino, "w", encoding="utf-8", newline="\n") as f:
        f.write("# Linha de base da Sonda dos caminhos do PC (ORDEM-SONDA-CAMINHOS-PC). Gerada por caminhos_pc.py --gerar.\n")
        f.write("# Cada linha: caminho relativo <TAB> sha256 da linha que traz o caminho do PC. Só pode encolher.\n")
        for e in entradas:
            f.write(e + "\n")
    print(f"base gerada: {len(entradas)} ocorrências em {len({a[0] for a in achados})} ficheiros -> {os.path.basename(destino)}")  # só o nome: o caminho inteiro de uma pasta temporária seria o próprio caminho do PC
    return 0


def conferir(raiz: str, base_cam: str | None) -> int:
    achados = procurar(raiz)
    base = ler_base(base_cam) if base_cam else collections.Counter()
    resto = base.copy()
    novos = []
    for rel, n, formas, h in achados:
        if resto[(rel, h)] > 0:
            resto[(rel, h)] -= 1
        else:
            novos.append((rel, n, formas))
    conhecidos = len(achados) - len(novos)
    gastas = sum(v for v in resto.values() if v > 0)
    print(f"caminhos do PC: {len(achados)} ocorrências no total; {conhecidos} na linha de base "
          f"({sum(base.values())} entradas), {len(novos)} novas; {gastas} entradas da base já não existem.")
    if gastas:
        print("  (a base pode encolher: correr com --gerar depois da redacção)")
    if novos:
        for rel, n, formas in novos:
            print(f"::error file={rel},line={n}::Caminho real do PC (forma {'+'.join(map(str, formas))}) — "
                  f"este repositório não admite caminhos do PC.")
            print(f"  NOVO {rel}:{n} forma {'+'.join(map(str, formas))}")
        return 1
    print("Sonda limpa: nenhum caminho do PC novo.")
    return 0


def auto_teste() -> int:
    """Prova que a rede morde: uma árvore limpa passa; cada forma, sozinha, num ficheiro novo, é apanhada;
    uma linha nova num ficheiro já listado na base também é apanhada; a base repõe o verde."""
    u = "Us" + "ers"
    casos = {
        "forma 1": "C" + ":/" + u + "/ana/jogo/x.log",
        "forma 1 com barra dobrada": "C" + "://" + u + "//ana/x",
        "forma 2":"C" + ":\\" + u + "\\ana\\jogo\\x.log",
        "forma 2 escapada em JSON": "\"C" + ":\\\\" + u + "\\\\ana\"",
        "forma 3": "/c" + "/" + u + "/ana/jogo/x.log",
        "forma 1 em minúsculas": "c" + ":/" + u.lower() + "/ana",
    }
    limpos = ["C:/Programas/x", "/c/Programas/x", "D:\\" + u + "\\x", "Users/ana sem unidade", "caminho <sede>/repo"]
    falhas = 0

    def correr(rot, arvore, esperado, base=None):
        nonlocal falhas
        with tempfile.TemporaryDirectory() as t:
            for rel, txt in arvore.items():
                p = os.path.join(t, rel)
                os.makedirs(os.path.dirname(p), exist_ok=True)
                with open(p, "w", encoding="utf-8", newline="") as f:
                    f.write(txt)
            bcam = None
            if base is not None:
                bcam = os.path.join(t, ".base")
                gerar_em = os.path.join(t, ".base")
                # a base é gerada a partir da árvore «base», noutro directório
                with tempfile.TemporaryDirectory() as t2:
                    for rel, txt in base.items():
                        p = os.path.join(t2, rel)
                        os.makedirs(os.path.dirname(p), exist_ok=True)
                        with open(p, "w", encoding="utf-8", newline="") as f:
                            f.write(txt)
                    gerar(t2, gerar_em)
            print(f"--- {rot} (esperado: saída {esperado})")
            r = conferir(t, bcam)
            ok = r == esperado
            print(f"=== {rot}: saída {r} -> {'OK' if ok else 'FALHOU'}")
            if not ok:
                falhas += 1

    correr("árvore limpa (sem nenhuma das formas)", {"a.txt": "\n".join(limpos) + "\n", "b/c.md": "nada\n"}, 0)
    for rot, txt in casos.items():
        correr(f"apanha {rot}", {"a.txt": "\n".join(limpos) + "\n", "b/novo.log": "antes\r\n" + txt + "\r\ndepois\r\n"}, 1)
    velho = "linha velha " + casos["forma 1"] + "\n"
    correr("linha de base: a ocorrência conhecida passa", {"v.log": velho}, 0, base={"v.log": velho})
    correr("linha de base: uma linha nova no mesmo ficheiro é apanhada",
           {"v.log": velho + "linha nova " + casos["forma 3"] + "\n"}, 1, base={"v.log": velho})
    correr("linha de base: a mesma linha copiada para outro ficheiro é apanhada",
           {"v.log": velho, "outro.log": velho}, 1, base={"v.log": velho})
    correr("linha de base: a mesma linha repetida no mesmo ficheiro é apanhada",
           {"v.log": velho + velho}, 1, base={"v.log": velho})
    def correr_gerar(rot, arvore, base, permitir, esperado):
        nonlocal falhas
        with tempfile.TemporaryDirectory() as t:
            for rel, txt in arvore.items():
                p = os.path.join(t, rel)
                os.makedirs(os.path.dirname(p), exist_ok=True)
                with open(p, "w", encoding="utf-8", newline="") as f:
                    f.write(txt)
            bcam = os.path.join(t, ".base")
            if base is not None:
                with tempfile.TemporaryDirectory() as t2:
                    for rel, txt in base.items():
                        p = os.path.join(t2, rel)
                        os.makedirs(os.path.dirname(p), exist_ok=True)
                        with open(p, "w", encoding="utf-8", newline="") as f:
                            f.write(txt)
                    gerar(t2, bcam)
            antes = None
            if os.path.isfile(bcam):
                with open(bcam, "rb") as f:
                    antes = f.read()
            print(f"--- {rot} (esperado: saída {esperado})")
            r = gerar(t, bcam, permitir)
            depois = None
            if os.path.isfile(bcam):
                with open(bcam, "rb") as f:
                    depois = f.read()
            ok = r == esperado
            if esperado == 1 and antes is not None and depois != antes:
                print("=== a base foi reescrita apesar da recusa")
                ok = False
            print(f"=== {rot}: saída {r} -> {'OK' if ok else 'FALHOU'}")
            if not ok:
                falhas += 1

    # A guarda do --gerar: crescer sem sinal recusa (e não reescreve a base); com sinal passa; encolher passa.
    correr_gerar("gerar: sem base antiga, passa", {"v.log": velho}, None, None, 0)
    correr_gerar("gerar: encolher passa", {"v.log": ""}, {"v.log": velho}, None, 0)
    correr_gerar("gerar: crescer sem sinal recusa",
                 {"v.log": velho + "linha nova " + casos["forma 3"] + "\n"}, {"v.log": velho}, None, 1)
    correr_gerar("gerar: crescer com sinal passa",
                 {"v.log": velho + "linha nova " + casos["forma 3"] + "\n"}, {"v.log": velho}, "ORDEM-TESTE", 0)
    print(f"AUTO-TESTE: {falhas} falha(s)")
    return 1 if falhas else 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--raiz", default=".")
    ap.add_argument("--base")
    ap.add_argument("--gerar")
    ap.add_argument("--permitir-crescer", default=None, metavar="REFERÊNCIA")
    ap.add_argument("--auto-teste", action="store_true")
    a = ap.parse_args()
    if a.auto_teste:
        return auto_teste()
    if a.gerar:
        return gerar(a.raiz, a.gerar, a.permitir_crescer)
    return conferir(a.raiz, a.base)


if __name__ == "__main__":
    sys.exit(main())
