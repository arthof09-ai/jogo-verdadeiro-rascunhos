// Lê o journal MESTRE-ONLY da bancada e imprime eventos (menos «ia»), recibos e figuras. Ids de figura → ficha#n.
import fs from 'node:fs';
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')).registo;
const o = JSON.parse(r.split('\n')[0]);
const nomes = {}; const cont = {};
const fig = (id) => { if (!id) return id; if (!nomes[id]) { const f = o.estado.figuras[id]; const fi = f ? f.fichaId : 'fig'; cont[fi] = (cont[fi] || 0) + 1; nomes[id] = `${fi}#${cont[fi]}`; } return nomes[id]; };
for (const id of Object.keys(o.estado.figuras).sort((a, b) => o.estado.figuras[a].casaColocacao.ordem - o.estado.figuras[b].casaColocacao.ordem)) fig(id);
const limpa = (v) => JSON.stringify(v, (k, x) => (typeof x === 'string' && o.estado.figuras[x]) ? fig(x) : x);
console.log('== eventos (sem «ia») ==');
for (const e of o.eventos) { if (e.tipo === 'ia') continue; console.log(o.eventos.indexOf(e) + 1, e.ts, e.tipo, limpa(e.dados || {}).slice(0, 240)); }
console.log('== recibos ==');
for (const x of o.recibos) console.log(limpa(x).slice(0, 240));
console.log('== figuras no fim ==');
for (const [id, f] of Object.entries(o.estado.figuras)) console.log(fig(id), 'colocacao', JSON.stringify(f.casaColocacao), 'casa', JSON.stringify(f.casa ?? f.pos ?? null), 'andouM', f.andouM ?? f.andou ?? '-');
console.log('== contagem: figuras orc-teste =', Object.values(o.estado.figuras).filter((f) => f.fichaId === 'orc-teste').length, '· eventos colocacao =', o.eventos.filter((e) => e.tipo === 'colocacao').length, '· eventos movimento =', o.eventos.filter((e) => e.tipo === 'movimento').length);
