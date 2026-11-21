import { readFileSync } from 'node:fs';
const R = process.argv[2];
const { prepararTerreno } = await import('file:///' + R + '/rascunhos/servidor/nucleo/terreno.js');
const P = JSON.parse(readFileSync(R + '/rascunhos/servidor/dados/terreno-floresta.json', 'utf8'));
const T = prepararTerreno(P);
for (const [n, c] of [[75, 1], [50, 1.5], [37, 2]]) {
  const g = T.para(n, n, c); let b = 0;
  for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) if (g.bloqueada(x, y)) b++;
  console.log(`${c} m (${n}x${n}): bloqueadas ${b}, livres ${n * n - b}`);
}
console.log('chaves do pacote:', Object.keys(P).join(', '));
