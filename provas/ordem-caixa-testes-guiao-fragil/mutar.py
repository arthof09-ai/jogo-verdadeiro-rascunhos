#!/usr/bin/env python3
"""Mutações da ORDEM-CAIXA-TESTES-GUIAO-FRAGIL. Uso: python mutar.py <repo> <saida.log>"""
import pathlib, re, subprocess, sys
repo = pathlib.Path(sys.argv[1]).resolve(); saida = pathlib.Path(sys.argv[2]); tmp = pathlib.Path(__file__).resolve().parent
testes = repo / 'rascunhos/servidor/testes'; nucleo = repo / 'rascunhos/servidor/nucleo'
base = (testes / 'privacidade.test.mjs').read_text(encoding='utf-8')
def absol(s, nuc=nucleo):
    s = s.replace("from './ajudantes.mjs'", "from '%s'" % (testes / 'ajudantes.mjs').as_uri())
    return s.replace("from '../nucleo/", "from '%s/" % nuc.as_uri())
def troca(s, a, b):
    assert s.count(a) == 1, a[:70]; return s.replace(a, b)
FIRST = 'canários: nada do Mestre chega a nenhum papel da Party'
CTRL = 'canários: nada do Mestre chega à Party com o guião duas voltas'
M51B = 'canários: a Vida baixa de um intermédio'
def correr(nome, src, padrao=None):
    f = tmp / ('mut-%s.test.mjs' % nome); f.write_text(src, encoding='utf-8')
    cmd = ['node', '--test', '--test-reporter=spec'] + (['--test-name-pattern=' + padrao] if padrao else []) + [str(f)]
    r = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8')
    linhas = [l for l in (r.stdout + r.stderr).splitlines() if re.match(r'^(✔|✖|ℹ (tests|pass|fail) )', l) or 'AssertionError' in l]
    linhas = [re.sub(r' \(\d+(\.\d+)?ms\)', '', l) for l in linhas]
    i = next((k for k, l in enumerate(linhas) if l.startswith('ℹ tests')), len(linhas))
    return 'código %d\n' % r.returncode + '\n'.join(linhas[:i + 3] + [l.strip() for l in linhas if 'AssertionError' in l])
out = []
# M0: o ficheiro tal como está
out.append(('M0 — o ficheiro corrigido, sem mutação', correr('M0', absol(base))))
# M1: a sanidade antiga (a ordem do FIM) com a correcção do resto — o controlo B3 tem de falhar
old = """      const registada = ordemPartyRegistada(m, journalSeqDoSnapshot(m, s)).ordem;"""
out.append(('M1 — a sanidade volta à ordem do FIM (estado().ordemDinamicaParty): o controlo B3 falha, o 1.º passa',
            correr('M1', absol(troca(base, old, "      const registada = m.sala.depuracao.estado().ordemDinamicaParty.ordem;")))))
# M2: o instante errado (sempre o fim do journal) — o controlo B3 tem de falhar
out.append(('M2 — journalSeqDoSnapshot devolve o fim do journal: o controlo B3 falha',
            correr('M2', absol(troca(base, "  return seq;\n}", "  return m.sala.depuracao.journalSeq();\n}")))))
# M3: o servidor manda a ordem trocada no snapshot (mutação no repo, revertida com git checkout no fim)
odp = nucleo / 'ordem-dinamica.js'
orig = odp.read_bytes()
try:
    od = troca(orig.decode('utf-8'), "  return { ligada: c.ligada, ordemPor: c.modo, ordemDinamica: ordemParaVista(odParty, figuras) };",
               "  const v = ordemParaVista(odParty, figuras); v.ordem.reverse(); // MUTAÇÃO M3\n  return { ligada: c.ligada, ordemPor: c.modo, ordemDinamica: v };")
    odp.write_bytes(od.encode('utf-8'))
    out.append(('M3 — o servidor manda a ordem INVERTIDA no snapshot da Party: o 1.º e o controlo falham', correr('M3', absol(base))))
finally:
    odp.write_bytes(orig)
    subprocess.run(['git', '-C', str(repo), 'checkout', '--', 'rascunhos/servidor/nucleo/ordem-dinamica.js'], check=True)
# M4: a reconstrução também pelo caminho do «voltar» (M51b com voltar) — a função de reconstrução e o 1.º teste passam
out.append(('M4 — o 1.º teste sobre o guião da M51b COM «voltar» (exercita o `revertido` da reconstrução): passa',
            correr('M4', absol(troca(base, "  conferirCanariosDoMestre(guiao());", "  conferirCanariosDoMestre(guiao({ m51b: true }));")), FIRST)))
# M5: a reconstrução ignora o `revertido` — M4 tem de falhar (a guarda da reconstrução morde)
m5 = troca(base, "  conferirCanariosDoMestre(guiao());", "  conferirCanariosDoMestre(guiao({ m51b: true }));")
m5 = troca(m5, "      if (e.tipo === 'revertido') {", "      if (e.tipo === 'revertido' && false) { // MUTAÇÃO M5")
out.append(('M5 — como a M4, mas a reconstrução ignora o `revertido`: falha', correr('M5', absol(m5), FIRST)))
txt = '# Mutações da ORDEM-CAIXA-TESTES-GUIAO-FRAGIL (todas executadas; a M3 mexe no núcleo e é revertida com git checkout)\n\n' + '\n\n'.join('## %s\n%s' % x for x in out) + '\n'
saida.write_text(txt.replace(str(tmp), '<tmp>'), encoding='utf-8', newline='\n')
