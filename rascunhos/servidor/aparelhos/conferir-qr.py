"""Ordem PLANO-2-F2 (JV3.4): lê com o OpenCV (decodificador independente) os QR gerados por gerar-qr-prova.mjs.

    python -I aparelhos/conferir-qr.py <pasta>

Sai com 0 só se todos os QR se lerem e o texto lido for igual ao esperado.
"""
import json
import os
import sys

import cv2


def main():
    pasta = sys.argv[1]
    casos = json.load(open(os.path.join(pasta, 'casos.json'), encoding='utf-8'))
    det = cv2.QRCodeDetector()
    falhas = 0
    for c in casos:
        img = cv2.imread(os.path.join(pasta, c['ficheiro']), cv2.IMREAD_GRAYSCALE)
        texto, _, _ = det.detectAndDecode(img)
        ok = texto == c['texto']
        falhas += 0 if ok else 1
        print(('  ok    ' if ok else '  FALHA ') + f"v{c['versao']} m{c['mascara']} {c['ficheiro']}: lido {texto!r}")
    print(f'== {len(casos) - falhas} de {len(casos)} QR lidos certos ==')
    sys.exit(1 if falhas else 0)


main()
