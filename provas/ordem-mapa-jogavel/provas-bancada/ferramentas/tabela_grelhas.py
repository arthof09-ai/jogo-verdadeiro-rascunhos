# ORDEM PROVAS-MAPA: a tabela grelha a grelha a partir dos JSON de provar_terreno_servidor(_mapa).gd; conta as casas
# de água de cada grelha com o juízo do servidor (juizo-terreno.mjs). Correr dentro de provas-bancada/:
#   python -I ferramentas/tabela_grelhas.py > tabela-grelhas.md
# ORDEM PROVAS-MAPA-CORRECÕES: saída em UTF-8 (a consola do Windows é cp1252), a cobertura não afirmada e as regras de
# contagem escritas no cabeçalho da tabela (o que não está nos JSON re-deriva-se daqui).
import json, subprocess, sys
sys.stdout.reconfigure(encoding='utf-8', newline='\n')
print("""# As grelhas servidor × arena (gerado por `ferramentas/tabela_grelhas.py`)

Regras de contagem (o que cada coluna conta):
- **água**: casas do juízo do servidor com `agua` verdadeiro. O gerador recalcula-as: corre `juizo-terreno.mjs` com a
  grelha **pedida** e a escala, sem figuras (a água é do terreno, não depende das figuras). Não estão nos JSON.
- **bloq. srv**: casas com `passavel` falso no juízo (`casasBloqueadas` do JSON). A água pisa-se e não conta.
- **juízo ≠ / motivo ≠**: casas em que o cliente diz bloqueada e o servidor não, ou o contrário; e casas bloqueadas
  com outro motivo (`juizoDiferente`, `motivosDiferentes`).
- **cob. afirmada ≠**: conta **só** as casas em que o servidor **afirma** a cobertura (≠ null) e o cliente tem outra
  (`coberturaAfirmadaDiferente`). É este o portão da ferramenta.
- **cob. não afirmada (cli ≠ ref)**: casas da faixa da borda em que o servidor diz `null` (`coberturaNaoAfirmada`) e,
  entre parênteses, quantas delas o cliente tem com outra cobertura que a do mapa de referência do pacote
  (`coberturaNaoAfirmadaClienteDifereDaReferencia`). É um campo **registado, não julgado**: a ferramenta não falha
  por ele.
- **figuras**: as figuras que o servidor colocou e a arena desenhou, contando a heroína. Nos casos «auto» são as 9
  casas livres mais a heroína (as bloqueadas são todas recusadas). Na grelha 1 foram pedidas 17 casas e recusadas 3
  (dois menires e um santuário): 14 + a heroína = 15.
- **marcos ok**: marcos do mapa dentro da grelha que o mapa do cliente bloqueia com o próprio nome e que caem no centro
  de uma casa do jogo (entrada em `marcos` do JSON). O gerador conta os que têm a casa bloqueada no servidor; a
  ferramenta exige também o mesmo nome (e passa).
""")
for nome in ['terreno-servidor-arena.json', 'terreno-servidor-arena-adaptada.json']:
  j = json.load(open(nome, encoding='utf-8'))
  print(f"\n### {nome}\n\nprova: `{j['prova']}`\n")
  print("| # | pedida | servida | casas (dentro/fora zona livre) | água | bloq. srv | juízo ≠ | motivo ≠ | cob. afirmada ≠ | cob. não afirmada (cli ≠ ref) | desvio alt. máx (m) | desvio pé máx (m) | figuras (desvio m) | recusas | mover (bloq. no cli) | marcos ok |")
  print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
  for i, g in enumerate(j['grelhas'], 1):
    gr = g['grelha']; p = g.get('pedida', gr)
    args = ['node', '../../../rascunhos/servidor/ferramentas/juizo-terreno.mjs', str(p['largura']), str(p['altura'])]
    if p['casaM'] != 1.5: args.append(f"--escala={p['casaM']}")
    sv = json.loads(subprocess.run(args, capture_output=True, text=True, encoding='utf-8').stdout.strip().splitlines()[-1])
    agua = sum(1 for c in sv['juizo']['casas'] if c.get('agua'))
    marcos = sum(1 for m in g['marcos'] if m['servidor']['bloqueada'])
    da = max(g['desvioMaxAlturaM'].values()); dp = max(g['desvioMaxPeM'].values())
    print(f"| {i} | {p['largura']}×{p['altura']} @ {p['casaM']} | {gr['largura']}×{gr['altura']} @ {gr['casaM']} | {g['casasDentroZonaLivre']+g['casasFora']} ({g['casasDentroZonaLivre']}/{g['casasFora']}) | {agua} | {g['casasBloqueadas']} | {g['juizoDiferente']} | {g['motivosDiferentes']} | {g['coberturaAfirmadaDiferente']} | {g['coberturaNaoAfirmada']} ({g['coberturaNaoAfirmadaClienteDifereDaReferencia']}) | {da:.3g} | {dp:.3g} | {len(g['figuras'])} ({g['desvioMaxFigurasM']:.3g}) | {len(g['recusas'])} | {g['moverOferecidas']} ({g['moverBloqueadas']}) | {marcos}/{len(g['marcos'])} |")
