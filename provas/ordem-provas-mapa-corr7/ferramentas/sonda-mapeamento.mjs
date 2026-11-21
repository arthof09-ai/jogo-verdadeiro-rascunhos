import { readFileSync } from 'node:fs';
const R = process.argv[2];
const { prepararTerreno } = await import('file:///' + R + '/rascunhos/servidor/nucleo/terreno.js');
const T = prepararTerreno(JSON.parse(readFileSync(R + '/rascunhos/servidor/dados/terreno-floresta.json', 'utf8')));
const g = { 1: T.para(75, 75, 1), 1.5: T.para(50, 50, 1.5), 2: T.para(37, 37, 2) };
const L = { 1: 75, 1.5: 50, 2: 37 };
console.log('origens', Object.fromEntries(Object.entries(g).map(([k, v]) => [k, v.origemM])));
const lugar = (c, de, para) => {
  const e = (v, i) => Math.min(L[para] - 1, Math.max(0, Math.floor((g[de].origemM[i] + (v + 0.5) * de - g[para].origemM[i]) / para + 1e-9)));
  return { x: e(c.x, 0), y: e(c.y, 1) };
};
for (const [de, para] of [[2, 1.5], [1.5, 2], [1, 2], [2, 1], [1, 1.5], [1.5, 1]]) {
  const vistas = new Map(); let livresBloq = []; let col = 0;
  for (let y = 0; y < L[de]; y++) for (let x = 0; x < L[de]; x++) {
    const n = lugar({ x, y }, de, para); const k = n.x + ',' + n.y;
    if (vistas.has(k)) col++; else vistas.set(k, 1);
    if (!g[de].bloqueada(x, y) && g[para].bloqueada(n.x, n.y)) livresBloq.push(`(${x},${y})->(${n.x},${n.y})`);
  }
  console.log(`${de} -> ${para}: casas de origem que colidem ${col}; livres que caem em bloqueadas ${livresBloq.length}`, livresBloq.slice(0, 4).join(' '));
}
// os casos que o teste CORR7 escolhe (mesmo algoritmo)
let par = null;
for (let y = 10; y < 40 && !par; y++) for (let x = 10; x < 40 && !par; x++) {
  const a = lugar({ x, y }, 1.5, 2), b = lugar({ x: x + 1, y }, 1.5, 2);
  if (a.x === b.x && a.y === b.y && !g[1.5].bloqueada(x, y) && !g[1.5].bloqueada(x + 1, y) && !g[2].bloqueada(a.x, a.y)) par = { h: { x, y }, o: { x: x + 1, y }, em2: a };
}
console.log('(b) par juntas a 1,5 m:', JSON.stringify(par));
let alvo = null;
for (let y = 0; y < 50 && !alvo; y++) for (let x = 0; x < 50 && !alvo; x++) {
  const c = lugar({ x, y }, 1.5, 2);
  if (!g[1.5].bloqueada(x, y) && g[2].bloqueada(c.x, c.y) && Math.abs(x - 25) + Math.abs(y - 25) > 4) alvo = { x, y, em2: c };
}
console.log('(c) alvo bloqueada a 2 m:', JSON.stringify(alvo));
const livres2 = []; for (let y = 0; y < 37; y++) for (let x = 0; x < 37; x++) if (!g[2].bloqueada(x, y)) livres2.push({ x, y });
const enc = (n) => [-1, 0, 1].some((dy) => [-1, 0, 1].some((dx) => { const x = n.x + dx, y = n.y + dy; return x >= 0 && y >= 0 && x < 50 && y < 50 && g[1.5].bloqueada(x, y); }));
const risco = livres2.filter((c) => enc(lugar(c, 2, 1.5)) && !(c.x === 15 && c.y === 15));
const passo = Math.max(1, Math.ceil(risco.length / 60));
console.log(`(c) descer: livres a 2 m ${livres2.length}; de risco ${risco.length}; postas no servidor ${risco.filter((_, i) => i % passo === 0).length} (1 em ${passo})`);
