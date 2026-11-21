# O desenho da margem do lago (ORDEM LAGO-MAIOR)

Rascunho de trabalho, guardado para se poder refazer: **não é código do jogo**. Corre-se desta pasta (ferramentas/).

1. `dump_relevo.gd` (Godot, no relevo de antes) → `dump.json`: o relevo da Ordem 38 à volta da cova e as árvores/rochas do mapa sem zona.
2. `python -X utf8 desenho_margem.py 15 12 8` → `forma.json`: os 72 raios da margem (centro 21, −21), com
   - o limite duro por rumo: árvores a mais de raio + 1,3 m, rochas a mais de 0,9 × tam + 0,7 m (a árvore seca da cova não conta: muda de sítio), o trilho a mais de 3,2 m, x ≤ 35, z ≥ −35,5, x ≥ 2;
   - o chão: a margem da Ordem 66 (antes.json, `margem_por_rumo_m`) mais 0,35 m — o lago velho fica todo por dentro;
   - um ondulado (3, 5 e 7 lóbulos) e alisamento; argumentos: raio-tecto, passagens de alisamento, passagens de chão.
3. `python perfil.py 1.0 2.55 1.6 6` (fim da faixa de andar, fim do talude, fundura ao pé do talude, fundura plena): as áreas e as casas de 1,5 m do modelo. Os números finais são os medidos pela sonda no Godot (`../medicao/depois.json`).

Os raios de `forma.json` são os de `LAGO_MARGEM_M` em `rascunhos/cliente/mapa/floresta/relevo_floresta.gd`.
