// JV0.3 — os vetores-ouro no CI (job motor-real, com MOTOR_MJS; ORDEM-F4-PARCIAL).
// Aceite (Plano A, JV0.3; Plano 2, F4): pelo menos 500 casos, pelo menos 20 por grupo, 9 grupos; 100 % no CI; duas
// corridas byte-idênticas; só dados fictícios.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import path from 'node:path';
import { jsonCanonico } from '../nucleo/util.js';
import { GRUPOS, FORMATO, gerarFicheiros, executarCaso } from './vetores-ouro.mjs';

const MOTOR_MJS = process.env.MOTOR_MJS;
const PASTA = new URL('./vetores-ouro/', import.meta.url);
const ler = (nome) => readFileSync(new URL(nome, PASTA), 'utf8');
const SALTAR = { skip: !MOTOR_MJS && 'MOTOR_MJS não definido (só corre no job motor-real)' };

async function motorReal() {
  const mod = await import(pathToFileURL(path.resolve(MOTOR_MJS)).href);
  return { Dmg: mod.Dmg, Vlab: mod.Vlab, MOTOR_SHA256: mod.MOTOR_SHA256, DMG_VERSAO: 'real', LEVELUP_SHA: null };
}

test('vetores-ouro: o conjunto gravado tem 9 grupos, ≥ 20 casos por grupo e ≥ 500 no total', () => {
  const man = JSON.parse(ler('MANIFESTO.json'));
  assert.equal(man.formato, FORMATO);
  assert.deepEqual(man.grupos.map((g) => g.grupo), [...GRUPOS]);
  for (const g of man.grupos) {
    const doc = JSON.parse(ler(g.ficheiro));
    assert.equal(doc.casos.length, g.casos, g.grupo);
    assert.equal(doc.total, g.casos, g.grupo);
    assert.equal(doc.motorSha256, man.motorSha256, g.grupo);
    assert.ok(g.casos >= 20, `${g.grupo}: ${g.casos} casos (< 20)`);
  }
  assert.ok(man.total >= 500, `total ${man.total} (< 500)`);
});

test('vetores-ouro: o motor do CI é o dos vetores (SHA-256)', SALTAR, async () => {
  const motor = await motorReal();
  const man = JSON.parse(ler('MANIFESTO.json'));
  assert.equal(motor.MOTOR_SHA256, man.motorSha256,
    'O motor vivo mudou. Regenerar com testes-motor-real/gerar-vetores.mjs e REVER a diferença (é divergência de regras).');
});

test('vetores-ouro: 100 % dos casos reproduzem a saída gravada', SALTAR, async () => {
  const motor = await motorReal();
  let total = 0;
  const falhas = [];
  const porGrupo = {};
  for (const grupo of GRUPOS) {
    const doc = JSON.parse(ler(grupo + '.json'));
    let ok = 0;
    for (const caso of doc.casos) {
      total += 1;
      const saida = executarCaso(motor, caso);
      if (jsonCanonico(saida) === jsonCanonico(caso.saida)) ok += 1;
      else if (falhas.length < 5) falhas.push({ id: caso.id, esperado: caso.saida, veio: saida });
    }
    porGrupo[grupo] = `${ok}/${doc.casos.length}`;
  }
  const passaram = Object.values(porGrupo).reduce((s, x) => s + Number(x.split('/')[0]), 0);
  console.log('VETORES-OURO ' + JSON.stringify({ passaram, total, percentagem: Math.round((passaram / total) * 10000) / 100, porGrupo }));
  assert.deepEqual(falhas, [], 'casos que não reproduzem');
  assert.equal(passaram, total);
});

test('vetores-ouro: duas corridas são byte-idênticas entre si e iguais aos ficheiros gravados', SALTAR, async () => {
  const motor = await motorReal();
  const a = gerarFicheiros(motor);
  const b = gerarFicheiros(motor);
  assert.deepEqual(Object.keys(a), Object.keys(b));
  for (const nome of Object.keys(a)) {
    assert.ok(a[nome] === b[nome], `${nome}: as duas corridas diferem`);
    assert.ok(a[nome] === ler(nome), `${nome}: a corrida difere do ficheiro gravado`);
  }
  console.log('VETORES-OURO-BYTES ' + JSON.stringify(Object.fromEntries(Object.entries(JSON.parse(a['MANIFESTO.json']).grupos).map(([, g]) => [g.grupo, g.sha256]))));
});
