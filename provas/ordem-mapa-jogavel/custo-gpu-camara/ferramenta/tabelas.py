# ORDEM MAPA-JOGÁVEL-CUSTO-CÂMARA: as tabelas (markdown) a partir de medicao.json e de terreno/provar-terreno-servidor.json.
#   python -I provas/ordem-mapa-jogavel/custo-gpu-camara/ferramenta/tabelas.py > provas/ordem-mapa-jogavel/custo-gpu-camara/tabelas.md
import json, sys
sys.stdout.reconfigure(encoding='utf-8', newline='\n')
P = 'provas/ordem-mapa-jogavel/custo-gpu-camara'
m = json.load(open(f'{P}/medicao.json', encoding='utf-8'))
t = json.load(open(f'{P}/terreno/provar-terreno-servidor.json', encoding='utf-8'))
v = lambda x: str(x).replace('.', ',')
print('# Tabelas — ORDEM MAPA-JOGÁVEL-CUSTO-CÂMARA (gerado por `ferramenta/tabelas.py`)\n')
print(f"Render: {m['render']} · base `{m['base']}` · 1920×1080 · sem vsync · perfil «alto» · Panorama · 240 quadros de aquecimento + 1200 medidos por corrida.\n")
print('## A1 — custo GPU por grelha e por corrida\n')
print('| grelha | corrida | FPS médio | ms/quadro (mediana) | ms p95 | chamadas de desenho | primitivas | CPU do lago `avancar` (µs/quadro) |')
print('|---|---|---|---|---|---|---|---|')
for g in ['20', '50', '75', '37']:
    e = m['grelhas'][g]
    for c in e['corridas']:
        print(f"| {e['nome']} | {c['corrida']} | {v(c['fps_medio'])} | {v(c['ms_quadro_mediana'])} | {v(c['ms_quadro_p95'])} | {v(c['chamadas_de_desenho'])} | {c['primitivas']} | {v(c['lago_avancar_us_por_quadro'])} |")
print('\n### Resumo por grelha (média das 3 corridas; banda = maior − menor das 3)\n')
print('| grelha | casa da figura | casa de água | água acima do pé (m) | FPS médio (banda) | ms mediana (banda) | chamadas | primitivas | lago µs (banda) |')
print('|---|---|---|---|---|---|---|---|---|')
for g in ['20', '50', '75', '37']:
    e = m['grelhas'][g]
    f = lambda n: f"{v(round(e[n]['media'], 3))} ({v(e[n]['banda_max_menos_min'])})"
    print(f"| {e['nome']} | ({e['casa_figura'][0]},{e['casa_figura'][1]}) | {'sim' if e['casa_de_agua'] else 'não'} | {v(e['agua_acima_do_pe_m'])} | {f('fps_medio')} | {f('ms_quadro_mediana')} | {v(e['chamadas_de_desenho']['media'])} | {int(e['primitivas']['media'])} | {f('lago_avancar_us_por_quadro')} |")
print('\n### 75×75 − 20×20 contra a banda de ruído da referência\n')
print('| medida | 75×75 − 20×20 | relativa | banda da referência (máx − mín) | intervalos [mín, máx] sobrepõem-se? | fora da banda? |')
print('|---|---|---|---|---|---|')
for n, nome in [('fps_medio', 'FPS médio'), ('ms_quadro_mediana', 'ms/quadro (mediana)'), ('chamadas_de_desenho', 'chamadas de desenho'), ('primitivas', 'primitivas'), ('lago_avancar_us_por_quadro', 'CPU do lago (µs/quadro)')]:
    d = m['diferenca_75_menos_20'][n]
    print(f"| {nome} | {v(d['75_menos_20'])} | {v(d['relativa_pct'])} % | {v(d['banda_ref'])} | {'sim' if d['intervalos_sobrepoem'] else 'não'} | **{'SIM' if d['fora_da_banda'] else 'não'}** |")
print('\n## A2 — a câmara em Panorama (1920×1080), os 16 pontos de `_recalcular_panorama` na câmara real\n')
print('| grelha | pontos no frustum | `_dist_panorama` (m) | distância real câmara–centro (m) | d0 = max/2 (m) | crescimentos ×1,06 | iterações do ciclo | tecto 60 | folga mínima ao bordo (px) | igual nas 6 leituras |')
print('|---|---|---|---|---|---|---|---|---|---|')
for g in ['20', '50', '75', '37']:
    c = m['grelhas'][g]['camera']
    print(f"| {m['grelhas'][g]['nome']} | **{c['dentro']}/{c['total']}** | {v(c['dist_panorama_m'])} | {v(c['dist_real_m'])} | {v(c['d0_m'])} | {c['crescimentos_x1_06']} | {c['iteracoes_do_ciclo']} | {'atingido' if c['tecto_60_atingido'] else 'não'} | {v(c['folga_min_px'])} | {'sim' if c['igual_nas_6_leituras'] else 'NÃO'} |")
print('\n«6 leituras» = antes e depois da medição do custo, nas 3 corridas. A 20×20 é a referência, fora do critério (só as 3 grelhas-mapa contam).\n')
print('## A3 — `provar_terreno_servidor.gd` (original), 18 grelhas: o resíduo de cobertura\n')
print('| # | pedida → servida | bloq. srv | juízo ≠ | motivo ≠ | cob. afirmada ≠ | desvio altura / pé / figuras | cob. não afirmada | … com cliente ≠ referência | recusas | mover (bloq. no cliente) |')
print('|---|---|---|---|---|---|---|---|---|---|---|')
for i, g in enumerate(t['grelhas'], 1):
    p, s = g['pedida'], g['grelha']
    d = lambda x: 0 if (x['dentro'] if isinstance(x, dict) else x) == 0 and (x.get('fora', 0) if isinstance(x, dict) else 0) == 0 else x
    print(f"| {i} | {p['largura']}×{p['altura']} @ {v(p['casaM'])} → {s['largura']}×{s['altura']} | {g['casasBloqueadas']} | {g['juizoDiferente']} | {g['motivosDiferentes']} | {g['coberturaAfirmadaDiferente']} | {d(g['desvioMaxAlturaM'])} / {d(g['desvioMaxPeM'])} / {v(g['desvioMaxFigurasM'])} | {g['coberturaNaoAfirmada']} | **{g['coberturaNaoAfirmadaClienteDifereDaReferencia']}** | {len(g['recusas']) if isinstance(g['recusas'], list) else g['recusas']} | {g['moverOferecidas']} ({g['moverBloqueadas']}) |")
