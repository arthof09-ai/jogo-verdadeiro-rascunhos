#!/usr/bin/env python3
"""Ordem ÁGUA-REAÇÃO — folhas ANTES/DEPOIS a partir dos dois vídeos da bancada do lago (testes/video_lago.gd).

    python3 folha.py <antes.ogv> <depois.ogv> <saida.jpg> "<título>" t1:legenda t2:legenda ...

Para cada instante t (s do vídeo, 30 q/s fixos: o mesmo quadro do guião nos dois), tira o quadro dos dois vídeos com
o ffmpeg e põe-nos lado a lado (ANTES = a reacção da Ordem 66/NADO; DEPOIS = esta ordem), uma linha por instante.
Só lê os vídeos; não mexe no projecto.
"""
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

LARG = 960  # cada quadro na folha


def quadro(video, t, destino):
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', '%.3f' % t, '-i', video, '-frames:v', '1', destino], check=True)
    img = Image.open(destino).convert('RGB')
    return img.resize((LARG, int(img.height * LARG / img.width)))


def fonte(tam):
    for f in ['/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf']:
        if Path(f).exists():
            return ImageFont.truetype(f, tam)
    return ImageFont.load_default()


def main():
    antes, depois, saida, titulo = sys.argv[1:5]
    instantes = []
    for a in sys.argv[5:]:
        t, _, leg = a.partition(':')
        instantes.append((float(t), leg))
    with tempfile.TemporaryDirectory() as tmp:
        linhas = []
        for i, (t, leg) in enumerate(instantes):
            a = quadro(antes, t, '%s/a%d.png' % (tmp, i))
            d = quadro(depois, t, '%s/d%d.png' % (tmp, i))
            linhas.append((t, leg, a, d))
    alt = linhas[0][2].height
    cab = 70
    faixa = 44
    folha = Image.new('RGB', (2 * LARG + 12, cab + len(linhas) * (alt + faixa)), (24, 24, 24))
    dr = ImageDraw.Draw(folha)
    dr.text((12, 10), titulo, fill=(255, 255, 255), font=fonte(26))
    dr.text((12, 42), 'ESQUERDA = ANTES (Ordem 66 + NADO)  ·  DIREITA = DEPOIS (Ordem ÁGUA-REAÇÃO)  ·  mesmo quadro do guião',
            fill=(200, 200, 200), font=fonte(18))
    y = cab
    for t, leg, a, d in linhas:
        dr.text((12, y + 10), 't = %.1f s · %s' % (t, leg), fill=(255, 230, 120), font=fonte(22))
        folha.paste(a, (0, y + faixa))
        folha.paste(d, (LARG + 12, y + faixa))
        y += alt + faixa
    folha.save(saida, quality=85)
    print('folha', saida, folha.size)


if __name__ == '__main__':
    main()
