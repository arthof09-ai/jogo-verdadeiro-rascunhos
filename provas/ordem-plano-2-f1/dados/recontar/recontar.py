"""ORDEM-PLANO-2-F1-FECHO, F5 — recontagem do D-AUD-15 a partir do pacote, sem a ferramenta original e sem o motor.

    python -I provas/ordem-plano-2-f1/dados/recontar/recontar.py

Só biblioteca padrão. Lê os ficheiros desta pasta (pares-serie-1-N.csv, faces-serie-1-N.csv) e recalcula:
  1. o χ² das faces (19 g.l.) e o χ² dos pares seguidos (399 g.l.) da série 1..N, com os valores de p;
  2. a corrida4em6 — P(4 ou mais faces iguais seguidas em 6 d20 justos) — de duas maneiras:
     (a) EXACTA, por programação dinâmica em fracções (não precisa de semente nenhuma);
     (b) Monte Carlo com semente PUBLICADA (SEMENTE_MC abaixo; random.Random de Python, M = 2 000 000).
O Monte Carlo da ferramenta original (dados-justos.mjs) usou rngNode() — o CSPRNG do servidor — sem semente; esse número
(0,03525 % em 26/11, 0,037 % em 24/11) não se reproduz por construção. Fica substituído pelo valor exacto.
"""
import csv
import math
import os
import random
from fractions import Fraction

AQUI = os.path.dirname(os.path.abspath(__file__))
SEMENTE_MC = 20261126
M_MC = 2_000_000


def p_qui(x, k):
    """P(X² ≥ x), k graus de liberdade: gama incompleta regularizada superior Q(k/2, x/2)."""
    a, z = k / 2.0, x / 2.0
    if z <= 0:
        return 1.0
    lg = math.lgamma(a)
    if z < a + 1:  # série da inferior P, Q = 1 - P
        termo = soma = 1.0 / a
        n = 0
        while True:
            n += 1
            termo *= z / (a + n)
            soma += termo
            if abs(termo) < abs(soma) * 1e-16 or n > 100000:
                break
        return 1.0 - soma * math.exp(-z + a * math.log(z) - lg)
    # fracção contínua de Q (Lentz modificado)
    tiny = 1e-300
    b = z + 1 - a
    c = 1 / tiny
    d = 1 / b
    h = d
    for i in range(1, 100000):
        an = -i * (i - a)
        b += 2
        d = an * d + b
        d = tiny if abs(d) < tiny else d
        c = b + an / c
        c = tiny if abs(c) < tiny else c
        d = 1 / d
        delta = d * c
        h *= delta
        if abs(delta - 1) < 1e-16:
            break
    return h * math.exp(-z + a * math.log(z) - lg)


def ler_pares():
    with open(os.path.join(AQUI, 'pares-serie-1-N.csv'), newline='', encoding='utf-8') as f:
        linhas = list(csv.reader(f))[1:]
    t = [[int(v) for v in l[1:]] for l in linhas]
    assert len(t) == 20 and all(len(l) == 20 for l in t), 'a tabela tem de ser 20×20'
    return t


def ler_faces():
    with open(os.path.join(AQUI, 'faces-serie-1-N.csv'), newline='', encoding='utf-8') as f:
        return [int(l[1]) for l in list(csv.reader(f))[1:]]


def corrida_exacta(lancamentos=6, lados=20, minimo=4):
    """P(haver ≥ `minimo` faces iguais seguidas em `lancamentos` dados justos), exacta."""
    q = Fraction(1, lados)
    # estado: comprimento da corrida actual (1..minimo-1); 'feito' absorve
    est = {1: Fraction(1)}
    feito = Fraction(0)
    for _ in range(lancamentos - 1):
        novo = {}
        for r, p in est.items():
            novo[1] = novo.get(1, 0) + p * (1 - q)
            if r + 1 >= minimo:
                feito += p * q
            else:
                novo[r + 1] = novo.get(r + 1, 0) + p * q
        est = novo
    return feito


def corrida_mc(semente=SEMENTE_MC, m=M_MC):
    r = random.Random(semente)
    com = 0
    for _ in range(m):
        maior = cur = 1
        ant = -1
        for _ in range(6):
            f = r.randrange(20)
            if f == ant:
                cur += 1
                if cur > maior:
                    maior = cur
            else:
                cur = 1
            ant = f
        if maior >= 4:
            com += 1
    return com


def main():
    import sys
    sys.stdout.reconfigure(encoding='utf-8')
    faces = ler_faces()
    n = sum(faces)
    esp = n / 20
    qui = sum((c - esp) ** 2 / esp for c in faces)
    print(f'série 1..N: N = {n}; faces de {min(faces)} a {max(faces)}; maior desvio '
          f'{max(abs(100 * c / n - 5) for c in faces):.4f} pp')
    print(f'  χ² das faces = {qui:.4f} (19 g.l.), p = {p_qui(qui, 19):.4f}')

    t = ler_pares()
    tot = sum(map(sum, t))
    espp = tot / 400
    quip = sum((c - espp) ** 2 / espp for l in t for c in l)
    print(f'  pares seguidos: {tot} pares (= N-1: {tot == n - 1}); χ² = {quip:.4f} (399 g.l.), p = {p_qui(quip, 399):.4f}')
    # conferência interna: a soma de cada linha é a contagem da face anterior (a última semente não abre par)
    linhas_ok = all(sum(t[a]) == faces[a] - (1 if a == t_ultima(t, faces) else 0) for a in range(20))
    print(f'  somas das linhas = contagens das faces (menos a última semente): {linhas_ok}')

    ex = corrida_exacta()
    print(f'corrida4em6 exacta = {ex} = {float(ex) * 100:.5f} %')
    com = corrida_mc()
    print(f'corrida4em6 Monte Carlo (random.Random({SEMENTE_MC}), M = {M_MC}): {com} → {100 * com / M_MC:.5f} %')


def t_ultima(t, faces):
    """A face da semente N é a única cuja linha soma uma unidade menos do que a contagem."""
    dif = [faces[a] - sum(t[a]) for a in range(20)]
    assert sorted(dif) == [0] * 19 + [1], f'somas das linhas incoerentes: {dif}'
    return dif.index(1)


if __name__ == '__main__':
    main()
