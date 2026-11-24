// Ordem PLANO-2-F2 (JV3.4): gera os QR de prova em PGM (versões 1 a 10, URLs da mesa e textos de enchimento) e um
// casos.json com o texto esperado de cada um. Quem os lê é um decodificador independente (conferir-qr.py, OpenCV).
//   node aparelhos/gerar-qr-prova.mjs <pasta-de-saída>
import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { qrEmPgm, codificarQR, capacidade, VERSAO_MAX } from '../adaptadores/node/qr.js';

const pasta = process.argv[2];
if (!pasta) {
  console.error('uso: node aparelhos/gerar-qr-prova.mjs <pasta>');
  process.exit(2);
}
mkdirSync(pasta, { recursive: true });
const casos = [
  'http://192.168.1.20:8080/',
  'http://192.168.1.20:8080/?medir=1',
  'http://10.0.0.5:8080/',
  'http://192.168.100.200:65535/?medir=1',
  'Mesa fictícia — ção',
];
for (let v = 1; v <= VERSAO_MAX; v++) {
  const n = capacidade(v);
  casos.push(('http://mesa.local/' + 'x'.repeat(n)).slice(0, n)); // enche a versão v até ao último byte
}
const saida = [];
casos.forEach((t, i) => {
  const q = codificarQR(t);
  const f = `qr-${String(i).padStart(2, '0')}-v${q.versao}-m${q.mascara}.pgm`;
  writeFileSync(path.join(pasta, f), qrEmPgm(t));
  saida.push({ ficheiro: f, texto: t, versao: q.versao, mascara: q.mascara });
});
writeFileSync(path.join(pasta, 'casos.json'), JSON.stringify(saida, null, 1));
console.log(`${saida.length} QR gerados (versões ${[...new Set(saida.map((s) => s.versao))].join(', ')}; `
  + `máscaras ${[...new Set(saida.map((s) => s.mascara))].sort().join(', ')})`);
