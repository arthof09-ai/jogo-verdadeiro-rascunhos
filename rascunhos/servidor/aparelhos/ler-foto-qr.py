"""Ordem PLANO-2-F2 (JV3.4): lê com o OpenCV o QR grande da foto da página /qr (foto-qr.mjs).

    python -I aparelhos/ler-foto-qr.py <pasta>

Sai com 0 se o QR da foto dá o link esperado (qr-esperado.json).
"""
import json
import os
import sys

import cv2


def main():
    pasta = sys.argv[1]
    esperado = json.load(open(os.path.join(pasta, 'qr-esperado.json'), encoding='utf-8'))['link']
    img = cv2.imread(os.path.join(pasta, 'qr-pagina.png'))
    ok, textos, _, _ = cv2.QRCodeDetector().detectAndDecodeMulti(img)
    lidos = [t for t in (textos if ok else []) if t]
    print(f'QR lidos na foto: {lidos}')
    if esperado in lidos:
        print(f'ok: o QR da página dá {esperado}')
        sys.exit(0)
    print(f'FALHA: esperava {esperado}')
    sys.exit(1)


main()
