# ORDEM PROVAS-MAPA: a tabela grelha a grelha a partir dos JSON de provar_terreno_servidor(_mapa).gd; conta as casas
# de água de cada grelha com o juízo do servidor (juizo-terreno.mjs). Correr dentro de provas-bancada/.
import json,subprocess
for nome in ['terreno-servidor-arena.json','terreno-servidor-arena-adaptada.json']:
  j=json.load(open(nome,encoding='utf-8'))
  print(f"\n### {nome}\n")
  print("| # | pedida | servida | casas (dentro/fora zona livre) | água | bloq. srv | juízo ≠ | motivo ≠ | cob. ≠ | desvio alt. máx (m) | desvio pé máx (m) | figuras (desvio m) | recusas | mover (bloq. no cli) | marcos ok |")
  print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
  for i,g in enumerate(j['grelhas'],1):
    gr=g['grelha']; p=g.get('pedida',gr)
    args=['node','../../../rascunhos/servidor/ferramentas/juizo-terreno.mjs',str(p['largura']),str(p['altura'])]
    if p['casaM']!=1.5: args.append(f"--escala={p['casaM']}")
    sv=json.loads(subprocess.run(args,capture_output=True,text=True).stdout.strip().splitlines()[-1])
    agua=sum(1 for c in sv['juizo']['casas'] if c.get('agua'))
    marcos=sum(1 for m in g['marcos'] if m['servidor']['bloqueada'])
    da=max(g['desvioMaxAlturaM'].values()); dp=max(g['desvioMaxPeM'].values())
    print(f"| {i} | {p['largura']}×{p['altura']} @ {p['casaM']} | {gr['largura']}×{gr['altura']} @ {gr['casaM']} | {g['casasDentroZonaLivre']+g['casasFora']} ({g['casasDentroZonaLivre']}/{g['casasFora']}) | {agua} | {g['casasBloqueadas']} | {g['juizoDiferente']} | {g['motivosDiferentes']} | {g['coberturaAfirmadaDiferente']} | {da:.3g} | {dp:.3g} | {len(g['figuras'])} ({g['desvioMaxFigurasM']:.3g}) | {len(g['recusas'])} | {g['moverOferecidas']} ({g['moverBloqueadas']}) | {marcos}/{len(g['marcos'])} |")
