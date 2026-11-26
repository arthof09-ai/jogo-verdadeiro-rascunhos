// ORDEM-PLANO-2-F1-FECHO, F5 — a tabela 20×20 dos pares seguidos da série 1..N, gerada SEM a ferramenta original
// (`ferramentas/dados-justos.mjs`) e SEM o motor privado.
//
//   node provas/ordem-plano-2-f1/dados/recontar/gerar-pares.mjs [--n=2000000]
//
// O que reproduz: a série «sementes 1..N (repetível)» do D-AUD-15. Para a semente s = 1, 2, …, N, a face do d20 do
// ataque é 1 + ⌊mulberry32(s)()·20⌋ — a 1.ª saída do gerador, sem sorteios antes (o motor, vlab-completo.js:788-801,
// lido em 26/11; a função mulberry32 é a de vlab-completo.js:691-699, aqui copiada à letra — é o algoritmo público de
// Tommy Ettinger, não é código privado). Um par é (face da semente s, face da semente s+1), para s = 1..N-1.
//
// Escreve, ao lado deste ficheiro:
//   pares-serie-1-N.csv   — 20 linhas × 20 colunas (linha = face anterior, coluna = face seguinte), N-1 pares
//   faces-serie-1-N.csv   — a contagem de cada face (para conferir contra dados-justos.json)
//   sementes-registadas.txt — as faces das 6 sementes registadas pela auditoria, pelo mesmo cálculo
import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const arg = process.argv.find((a) => a.startsWith('--n='));
const N = arg ? Number(arg.slice(4)) : 2000000;

function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const face = (s) => 1 + Math.floor(mulberry32(s)() * 20);

const faces = new Array(21).fill(0);
const pares = Array.from({ length: 21 }, () => new Array(21).fill(0));
let ant = 0;
for (let s = 1; s <= N; s++) {
  const f = face(s);
  faces[f]++;
  if (ant) pares[ant][f]++;
  ant = f;
}

const cab = 'anterior\\seguinte,' + Array.from({ length: 20 }, (_, i) => i + 1).join(',');
const linhas = [cab];
for (let a = 1; a <= 20; a++) linhas.push(a + ',' + pares[a].slice(1).join(','));
writeFileSync(path.join(AQUI, 'pares-serie-1-N.csv'), linhas.join('\n') + '\n');
writeFileSync(path.join(AQUI, 'faces-serie-1-N.csv'), 'face,n\n' + faces.slice(1).map((n, i) => `${i + 1},${n}`).join('\n') + '\n');

const registadas = [[30, 2599056525], [45, 1430019558], [56, 1985287769], [67, 1655933658], [78, 2212477532], [89, 3445070651]];
writeFileSync(path.join(AQUI, 'sementes-registadas.txt'),
  'seq,semente,face (1.ª saída de mulberry32)\n' + registadas.map(([q, s]) => `${q},${s},${face(s)}`).join('\n') + '\n');

const total = pares.flat().reduce((x, y) => x + y, 0);
console.log(`N = ${N}; pares = ${total}; faces = ${faces.slice(1).join(' ')}`);
console.log('registadas: ' + registadas.map(([, s]) => face(s)).join(', '));
