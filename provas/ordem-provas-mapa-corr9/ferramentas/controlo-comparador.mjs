// ORDEM PROVAS-MAPA-CORR9-CORRECOES (B2): os controlos do comparador. Copia a corrida 1 para pastas temporárias,
// muda UMA coisa em cada cópia e corre comparar-corridas.mjs; confere a saída, o veredicto e o número de linhas «NÃO».
//   node controlo-comparador.mjs [pasta-da-corrida-1]
// Sai com 0 se todos os controlos dão o esperado; 1 se não.
import { readFileSync, writeFileSync, mkdtempSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const AQUI = dirname(fileURLToPath(import.meta.url));
const COMPARADOR = join(AQUI, 'comparar-corridas.mjs');
const C1 = process.argv[2] ?? join(AQUI, '../../ordem-mapa-jogavel/provas-bancada');
const FICHEIROS = ['terreno-servidor-arena.json', 'terreno-servidor-arena-adaptada.json', 'bancada-jogadora.json',
  'bancada-mestre.json', 'provar-terreno-servidor.log', 'provar-terreno-servidor-adaptada.log', 'bancada-jogadora.log'];
const base = mkdtempSync(join(tmpdir(), 'controlo-comparador-'));

function copia(nome, muda) {
  const d = join(base, nome);
  mkdirSync(d);
  for (const f of FICHEIROS) copyFileSync(join(C1, f), join(d, f));
  if (muda) muda(d);
  return d;
}
const mudaJson = (f, fn) => (d) => {
  const c = join(d, f); const j = JSON.parse(readFileSync(c, 'utf8')); fn(j); writeFileSync(c, JSON.stringify(j, null, 1));
};
// ORDEM-K2-DINAMICO: o valor de partida lê-se da própria referência (não fica preso ao terreno) e muda-se em +delta.
const mudaFloresta = (f, carga, delta) => (d) => {
  const c = join(d, f); let k = 0;
  const linhas = readFileSync(c, 'utf8').split('\n').map((l) => {
    if (!l.startsWith('[floresta] pronta')) return l;
    k++;
    if (k !== carga) return l;
    const m = l.match(/"casas_bloqueadas":(\d+),/);
    if (!m) throw new Error(`carga ${carga} não tem casas_bloqueadas`);
    return l.replace(m[0], `"casas_bloqueadas":${Number(m[1]) + delta},`);
  });
  writeFileSync(c, linhas.join('\n'));
};

function compara(bits, a, b) {
  const r = spawnSync(process.execPath, [COMPARADOR, ...(bits ? ['--bits'] : []), `ref=${a}`, `teste=${b}`], { encoding: 'utf8' });
  const linhas = r.stdout.split('\n');
  return {
    saida: r.status,
    veredicto: linhas.filter((l) => l.trim()).at(-1),
    nao: linhas.filter((l) => l.endsWith('| **NÃO** |')),
  };
}

const ref = copia('ref');
const controlos = [
  { nome: 'K0 positivo: a corrida 1 contra si própria', bits: true, a: ref, b: copia('k0'), saida: 0, nao: 0 },
  { nome: 'K1 número: grelha 11 (original), casas bloqueadas 156 → 157', bits: true, a: ref,
    b: copia('k1', mudaJson('terreno-servidor-arena.json', (j) => { j.grelhas[10].casasBloqueadas += 1; })), saida: 1, nao: 1 },
  { nome: 'K2 floresta (B1): carga 11 da ferramenta original, casas_bloqueadas 88 → 89 (só no .log)', bits: true, a: ref,
    b: copia('k2', mudaFloresta('provar-terreno-servidor.log', 11, 1)), saida: 1, nao: 1 },
  { nome: 'K3 floresta (B1): uma carga a menos na bancada (a 3.ª linha [floresta] apagada)', bits: true, a: ref,
    b: copia('k3', (d) => { const c = join(d, 'bancada-jogadora.log'); let k = 0;
      writeFileSync(c, readFileSync(c, 'utf8').split('\n').filter((l) => !(l.startsWith('[floresta] pronta') && ++k === 3)).join('\n')); }),
    saida: 1, nao: 2 /* «cargas» 3 → 2 e a carga 03 em falta */ },
  { nome: 'K4 bits: grelha 11 (original), desenhadaY da 1.ª figura + 0,5 m, com --bits', bits: true, a: ref,
    b: copia('k4', mudaJson('terreno-servidor-arena.json', (j) => { j.grelhas[10].figuras[0].desenhadaY += 0.5; })), saida: 1, nao: 1 },
  { nome: 'K5 bits: a mesma mudança SEM --bits (bits só registados, como no CI)', bits: false, a: ref,
    b: join(base, 'k4'), saida: 0, nao: 1 },
  { nome: 'K6 N3: desvio de altura da grelha 11 trocado entre dentro e fora (0,01/0 contra 0/0,01; o max() era igual)', bits: true,
    a: copia('k6a', mudaJson('terreno-servidor-arena.json', (j) => { j.grelhas[10].desvioMaxAlturaM = { dentro: 0.01, fora: 0 }; })),
    b: copia('k6b', mudaJson('terreno-servidor-arena.json', (j) => { j.grelhas[10].desvioMaxAlturaM = { dentro: 0, fora: 0.01 }; })),
    saida: 1, nao: 1 },
  { nome: 'K7 N2: os marcos da grelha 11 por ordem inversa (o hash é ordenado: tem de dar igual)', bits: true, a: ref,
    b: copia('k7', mudaJson('terreno-servidor-arena.json', (j) => { j.grelhas[10].marcos.reverse(); })), saida: 0, nao: 0 },
  { nome: 'K8 N2: altura do servidor do 1.º marco da grelha 11 + 0,5 m (o hash ordenado ainda morde)', bits: true, a: ref,
    b: copia('k8', mudaJson('terreno-servidor-arena.json', (j) => { j.grelhas[10].marcos[0].servidor.alturaM += 0.5; })), saida: 1, nao: 1 },
];

let falhas = 0;
for (const k of controlos) {
  const r = compara(k.bits, k.a, k.b);
  const ok = r.saida === k.saida && r.nao.length === k.nao;
  if (!ok) falhas++;
  console.log(`${ok ? 'OK ' : 'FALHOU'} ${k.nome}`);
  console.log(`     esperado: saída ${k.saida}, ${k.nao} linha(s) «NÃO» · obtido: saída ${r.saida}, ${r.nao.length} linha(s) «NÃO»`);
  console.log(`     ${r.veredicto}`);
  for (const l of r.nao) console.log(`     ${l}`);
}
rmSync(base, { recursive: true, force: true });
console.log(`\n${falhas === 0 ? 'TODOS OS CONTROLOS DÃO O ESPERADO' : `${falhas} CONTROLO(S) FALHARAM`} (${controlos.length} controlos)`);
process.exit(falhas === 0 ? 0 : 1);
