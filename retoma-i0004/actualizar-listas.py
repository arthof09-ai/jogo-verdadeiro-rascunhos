#!/usr/bin/env python3
"""Refaz antes.txt, depois.txt e as linhas de rascunhos/ do MANIFESTO-SHA256.txt (I0004, 08/11/2026).

Correr na raiz do repositório, depois de cada commit que mude ficheiros em rascunhos/:
    python3 retoma-i0004/actualizar-listas.py

- depois.txt: SHA-256 dos ficheiros de rascunhos/ que o ramo muda ou cria em relação ao 9cbaca8 (bytes do repo).
- antes.txt:  SHA-256 no 9cbaca8 dos que já existiam lá (os que o script do PC substitui, com cópia de segurança).
- MANIFESTO:  as linhas rascunhos/ ficam com os SHA de agora; as novas entram por ordem; o resto não se toca.
O job retoma-pc do CI confere que tudo bate (e falha se alguém se esquecer de correr isto).
"""
import hashlib
import subprocess
import sys

BASE = '9cbaca88b6e4951d41e518579afd3b32d846fee6'


def git(*args, binario=False):
    r = subprocess.run(['git', *args], check=True, capture_output=True)
    return r.stdout if binario else r.stdout.decode('utf-8')


def sha(dados):
    return hashlib.sha256(dados).hexdigest()


def main():
    mudados = [l for l in git('diff', '--name-only', '--diff-filter=AM', BASE, 'HEAD', '--', 'rascunhos').splitlines() if l]
    apagados = [l for l in git('diff', '--name-only', '--diff-filter=D', BASE, 'HEAD', '--', 'rascunhos').splitlines() if l]
    if apagados:
        sys.exit('PARAR: o ramo apaga ficheiros de rascunhos/ (%s); o script do PC não sabe apagar.' % ', '.join(apagados))
    na_base = set(git('ls-tree', '-r', '--name-only', BASE, 'rascunhos').splitlines())
    depois = {p: sha(git('show', 'HEAD:' + p, binario=True)) for p in sorted(mudados)}
    antes = {p: sha(git('show', BASE + ':' + p, binario=True)) for p in sorted(mudados) if p in na_base}

    with open('retoma-i0004/antes.txt', 'w', encoding='utf-8', newline='\n') as f:
        f.write('# SHA-256 no 9cbaca8 (antes) dos %d ficheiros que o ramo muda. Formato do MANIFESTO.\n' % len(antes))
        for p, h in antes.items():
            f.write('%s  %s\n' % (h, p))
    with open('retoma-i0004/depois.txt', 'w', encoding='utf-8', newline='\n') as f:
        f.write('# SHA-256 no ramo i0004/ci4-protocolo (depois) dos %d ficheiros mudados ou novos em rascunhos/.\n' % len(depois))
        for p, h in depois.items():
            f.write('%s  %s\n' % (h, p))

    linhas = open('MANIFESTO-SHA256.txt', encoding='utf-8').read().split('\n')
    em_head = set(git('ls-tree', '-r', '--name-only', 'HEAD', 'rascunhos').splitlines())
    vistos = set()
    saida = []
    tirados = 0
    for l in linhas:
        partes = l.split('  ', 1)
        if len(partes) == 2 and not l.startswith('#') and partes[1].startswith('rascunhos/') and partes[1] not in em_head:
            tirados += 1  # ficheiro que já não existe no ramo (ex.: criado e depois apagado pelo ramo)
            continue
        if len(partes) == 2 and not l.startswith('#') and partes[1] in depois:
            saida.append('%s  %s' % (depois[partes[1]], partes[1]))
            vistos.add(partes[1])
        else:
            saida.append(l)
    novos = [p for p in depois if p not in vistos]
    if novos:
        # Entram a seguir à última linha de ficheiro, por ordem alfabética com as outras de rascunhos/.
        corpo = [l for l in saida if l and not l.startswith('#')]
        comentarios_fim = []
        while saida and (saida[-1] == '' or saida[-1].startswith('#')):
            comentarios_fim.insert(0, saida.pop())
        topo = []
        while saida and (saida[0] == '' or saida[0].startswith('#')):
            topo.append(saida.pop(0))
        corpo = saida + ['%s  %s' % (depois[p], p) for p in novos]
        corpo.sort(key=lambda l: l.split('  ', 1)[1] if '  ' in l else l)
        saida = topo + corpo + comentarios_fim
    total = sum(1 for l in saida if l and not l.startswith('#'))
    open('MANIFESTO-SHA256.txt', 'w', encoding='utf-8', newline='\n').write('\n'.join(saida))
    print('antes.txt: %d · depois.txt: %d · MANIFESTO: %d ficheiros (%d novos, %d tirados nesta passagem)' % (
        len(antes), len(depois), total, len(novos), tirados))


if __name__ == '__main__':
    main()
