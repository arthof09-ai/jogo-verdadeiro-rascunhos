#!/usr/bin/env python3
"""B1 (ORDEM-CAIXA-TESTES-GUIAO-FRAGIL): o guião estendido com DUAS voltas depois das escolhas da caixa, SEM «voltar»,
debaixo do primeiro teste da suite. Gera cópias do privacidade.test.mjs do repo (imports absolutos), corre-as com
node --test e escreve a saída. Uso: python b1-repro.py <repo> <saida.log>

Variante A (a da sentença): as duas voltas do caminho da M51b (volta inteira; volta até o lobo levar a aliada a 51 —
o lobo joga antes do orc e a ordem dinâmica da Party troca-os), sem o «voltar» ao fim do guião, no guião do 1.º teste.
Variante B (informativa): duas voltas INTEIRAS no fim do guião de sempre, sem «voltar» (a ordem não troca)."""
import pathlib, re, subprocess, sys
repo = pathlib.Path(sys.argv[1]).resolve(); saida = pathlib.Path(sys.argv[2])
testes = repo / 'rascunhos/servidor/testes'
base = (testes / 'privacidade.test.mjs').read_text(encoding='utf-8')
base = base.replace("from './ajudantes.mjs'", "from '%s'" % (testes / 'ajudantes.mjs').as_uri())
base = base.replace("from '../nucleo/", "from '%s/" % (repo / 'rascunhos/servidor/nucleo').as_uri())
tmp = pathlib.Path(__file__).resolve().parent

def var_a(s):
    voltar = "exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: fimDoGuiao }), 'voltar ao fim do guião');"
    assert s.count(voltar) == 1; s = s.replace(voltar, "void 0; // B1: SEM «voltar»")
    t = "test('canários: nada do Mestre chega a nenhum papel da Party (jogadoras e espectador)', () => {\n"
    i = s.index(t) + len(t); j = s.index('guiao()', i); assert j - i < 80
    return s[:j] + 'guiao({ m51b: true })' + s[j + len('guiao()'):]

def var_b(s):
    a = "    m.enviar(k, { type: 'RECEIPT_QUERY', intentIds: ['aliada-fc', 'oculto-1'] });\n  }\n"
    assert s.count(a) == 1
    return s.replace(a, a + "  voltaInteira(m); voltaInteira(m); // B1-B: duas voltas inteiras, sem «voltar»\n")

head = subprocess.run(['git', '-C', str(repo), 'rev-parse', '--short', 'HEAD'], capture_output=True, text=True).stdout.strip()
sujo = subprocess.run(['git', '-C', str(repo), 'status', '--porcelain', '--', 'rascunhos/servidor/testes/privacidade.test.mjs'], capture_output=True, text=True).stdout.strip()
out = ['# B1 — o guião duas voltas depois das escolhas da caixa, sem «voltar»',
       '# privacidade.test.mjs de HEAD %s%s' % (head, ' + a correcção por cometer (B2/B3)' if sujo else ' (sem correcção)'),
       '# Nota: as variantes mexem no guião PARTILHADO. O teste da M51b (e, na B depois da correcção, o controlo B3, que',
       '# também segue o caminho da M51b) falham nas sanidades do PRÓPRIO caminho («o «voltar» repôs a aliada no 2403»,',
       '# «o lobo levou a aliada a 51»): esperado, não é a fragilidade. O que a B1 olha é o 1.º teste e a asserção',
       '# «a ordem no snapshot do escolherCaixa».', '']
for nome, f in (('A — as duas voltas da M51b, sem «voltar», no guião do 1.º teste', var_a), ('B — duas voltas inteiras no fim do guião de sempre, sem «voltar»', var_b)):
    alvo = tmp / ('b1-%s.test.mjs' % nome[0]); alvo.write_text(f(base), encoding='utf-8')
    r = subprocess.run(['node', '--test', '--test-reporter=spec', str(alvo)], capture_output=True, text=True, encoding='utf-8')
    corpo = re.sub(r'\n\s+at .*', '', r.stdout + r.stderr)
    corpo = re.sub(r' \(\d+(\.\d+)?ms\)', '', corpo); corpo = re.sub(r'ℹ duration_ms .*\n', '', corpo)
    out += ['## Variante %s' % nome, '# node --test: código de saída %d' % r.returncode, '', corpo.replace(str(tmp), '<tmp>').replace(tmp.as_uri(), 'file:///<tmp>'), '']
saida.write_text('\n'.join(out), encoding='utf-8', newline='\n')
