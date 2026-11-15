// Ordem 62 (reserva 2 da Ordem 58): a mudança de escala com figuras colocadas aplica a regra da colocação.
// Antes, as posições ficavam em casas e a grelha nova não se conferia: 1,5 → 2 m deixava 7 figuras em casas
// bloqueadas (provas/ordem-62-escala/medicao-antes.txt). Agora cada figura colocada é conferida contra os bloqueios da
// grelha nova; se alguma cai numa casa bloqueada, a mudança é recusada inteira (a sala fica na escala em que estava),
// com o porquê de cada figura ao Mestre — o mesmo CASA_BLOQUEADA do MASTER_PLACE. O «Recomeçar» depois de uma escala
// que bloqueia uma casa de colocação é recusado da mesma maneira (RECOMECAR_SEM_CASA).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { prepararTerreno } from '../nucleo/terreno.js';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

const PACOTE = JSON.parse(readFileSync(new URL('../dados/terreno-floresta.json', import.meta.url), 'utf8'));
const T = prepararTerreno(PACOTE);

/** O que a recusa não pode mexer: as figuras e o mapa (o journal ganha o evento `recusa`, por isso não o hash). */
const mundo = (m) => { const e = m.sala.depuracao.estado(); return JSON.parse(JSON.stringify({ figuras: e.figuras, mapa: e.mapa })); };
const recusas = (m) => m.sala.depuracao.eventos().filter((e) => e.tipo === 'recusa');
const emBloqueadas = (m) => {
  const j = m.sala.depuracao.juizoTerreno();
  return Object.values(m.sala.depuracao.estado().figuras)
    .filter((f) => f.colocada && !j.casas[f.y * j.largura + f.x].passavel)
    .map((f) => `(${f.x},${f.y}) ${j.casas[f.y * j.largura + f.x].motivo}`);
};
/**
 * A mesa da sonda da Ordem 58 (30 × 30, criaturas de 2 em 2 casas), só com as casas que contam, para o teste caber no
 * tempo do CI: as da grelha de 2 em 2 livres na escala `de` e bloqueadas na escala `para` (as que a medição de antes
 * apanhou), mais 6 livres nas duas. A grelha inteira (215 a 225 figuras) corre na medição: provas/ordem-62-escala/.
 */
const mesaCheia = (de, para) => {
  const gDe = T.para(30, 30, de);
  const gPara = T.para(30, 30, para);
  const casas = [];
  for (let y = 0; y < 30; y += 2) for (let x = 0; x < 30; x += 2) if (!gDe.bloqueada(x, y) && gPara.bloqueada(x, y)) casas.push({ x, y });
  for (let x = 10; x < 22; x += 2) if (!gDe.bloqueada(x, 14) && !gPara.bloqueada(x, 14)) casas.push({ x, y: 14 });
  const m = montarMesa({ terreno: PACOTE, mapa: { largura: 30, altura: 30 }, casas: { heroina: { x: 2, y: 2 } } });
  m.entrarTodos();
  m.iniciarCombate([]);
  if (de !== 1.5) exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: de }), 'escala de partida');
  for (const casa of casas) exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'orc-teste', casa }), `(${casa.x},${casa.y}) com ${de} m`);
  return m;
};

test('a sonda da Ordem 58 (1,5 → 2 m): a escala é recusada, nenhuma figura fica numa casa bloqueada, e cada uma vai nomeada ao Mestre', () => {
  const m = mesaCheia(1.5, 2);
  assert.deepEqual(emBloqueadas(m), [], 'antes: todas em casas livres');
  const antes = mundo(m);
  const r = recibo(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 2 }));
  assert.equal(r.type, 'ROOM_REJECT', 'a mudança é recusada');
  assert.equal(r.motivo, 'acao_invalida');
  assert.equal(m.sala.depuracao.juizoTerreno().casaM, 1.5, 'a escala não mudou');
  assert.deepEqual(mundo(m), antes, 'nada mexeu');
  assert.deepEqual(emBloqueadas(m), [], 'depois: nenhuma figura numa casa bloqueada (antes desta ordem: 7)');
  const rec = recusas(m).at(-1);
  const d = rec.soMestre.detalhe;
  assert.match(d, /^ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS: 7 figuras ficavam em casas que o mapa bloqueia com 2 m por casa — /);
  const sete = ['(6,4) menir', '(22,4) água funda', '(24,4) água funda', '(24,6) água funda', '(22,22) escarpa', '(28,24) escarpa', '(6,28) tronco tombado'];
  for (const c of sete) assert.ok(d.includes(`CASA_BLOQUEADA: ${c}`), `o porquê nomeia ${c} (o texto do MASTER_PLACE)`);
  assert.equal(rec.soMestre.figuras.length, 7);
  const est = m.sala.depuracao.estado();
  for (const f of rec.soMestre.figuras) {
    assert.deepEqual(Object.keys(f).sort(), ['figuraId', 'motivo', 'x', 'y']);
    assert.equal(est.figuras[f.figuraId].x, f.x, 'a lista diz a casa da figura');
    assert.equal(est.figuras[f.figuraId].y, f.y);
    assert.ok(d.includes(`${f.figuraId} CASA_BLOQUEADA: (${f.x},${f.y}) ${f.motivo}`));
  }
});

test('as 6 mudanças de escala: nenhuma deixa figuras em casas bloqueadas; as que não deixam passam como antes', () => {
  // [de, para, figuras que a grelha nova bloqueava (medição de antes)]
  for (const [de, para, n] of [[1.5, 2, 7], [1.5, 1, 0], [1, 1.5, 10], [1, 2, 8], [2, 1.5, 9], [2, 1, 0]]) {
    const m = mesaCheia(de, para);
    const r = recibo(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: para }));
    assert.deepEqual(emBloqueadas(m), [], `${de} → ${para} m: nenhuma figura numa casa bloqueada`);
    if (n === 0) {
      assert.equal(r.estado, 'APLICADA', `${de} → ${para} m: nada a bloquear, a escala muda`);
      assert.equal(m.sala.depuracao.juizoTerreno().casaM, para);
    } else {
      assert.equal(r.type, 'ROOM_REJECT', `${de} → ${para} m: recusada`);
      assert.equal(m.sala.depuracao.juizoTerreno().casaM, de, `${de} → ${para} m: a escala fica`);
      assert.equal(recusas(m).at(-1).soMestre.figuras.length, n, `${de} → ${para} m: ${n} figuras nomeadas`);
    }
  }
});

test('tirada a figura do caminho, a escala muda (a recusa não prende o Mestre)', () => {
  // só a heroína (2,2) e um orc no menir dos 2 m (6,4): a escala é recusada; o orc anda e a escala passa
  const m = montarMesa({ terreno: PACOTE, mapa: { largura: 30, altura: 30 }, casas: { heroina: { x: 7, y: 4 } } });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 6, y: 4 }]]);
  assert.equal(recibo(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 2 })).type, 'ROOM_REJECT');
  assert.match(recusas(m).at(-1).soMestre.detalhe, /: 1 figura ficava em casas que o mapa bloqueia com 2 m por casa — f\w+ CASA_BLOQUEADA: \(6,4\) menir$/);
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 1 }), 'para 1 m o menir dos 2 m não conta');
  assert.deepEqual(emBloqueadas(m), []);
});

test('a Party não vê o porquê nem a lista (só o recibo fixo de sempre)', () => {
  const m = mesaCheia(1.5, 2);
  m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 2 });
  for (const chave of Object.keys(m.clientes).filter((k) => k !== 'mestre')) {
    const txt = JSON.stringify(m.clientes[chave].msgs);
    assert.equal(txt.includes('ESCALA_DEIXA_FIGURAS'), false, chave + ': sem o detalhe');
    assert.equal(txt.includes('CASA_BLOQUEADA'), false, chave + ': sem as casas');
  }
});

test('«Recomeçar» depois de a escala bloquear uma casa de colocação: recusado com o nome, ninguém volta à casa bloqueada', () => {
  // a heroína é colocada em (6,4) (livre com 1,5 m, menir com 2 m), anda para (7,4) e a escala passa a 2 m
  const m = montarMesa({ terreno: PACOTE, mapa: { largura: 30, altura: 30 }, casas: { heroina: { x: 6, y: 4 } } });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 20, y: 20 }]]);
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 7, y: 4 } }), 'mover');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 2 }), 'escala 2 m: todas em casas livres');
  const antes = mundo(m);
  const r = recibo(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }));
  assert.equal(r.type, 'ROOM_REJECT', 'antes desta ordem: APLICADA, com a heroína no menir');
  assert.deepEqual(mundo(m), antes, 'nada mexeu');
  assert.deepEqual(emBloqueadas(m), []);
  const rec = recusas(m).at(-1).soMestre;
  assert.match(rec.detalhe, /^RECOMECAR_SEM_CASA: 1 figura voltava a uma casa de colocação que o mapa bloqueia com 2 m por casa — f\w+ CASA_BLOQUEADA: \(6,4\) menir$/);
  assert.deepEqual(rec.figuras.map((f) => [f.figuraId, f.x, f.y, f.motivo]), [[m.clientes.heroina.figuraId, 6, 4, 'menir']]);
  // de volta à escala da colocação, o «Recomeçar» passa
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 1.5 }), 'de volta a 1,5 m');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar');
  const h = m.sala.depuracao.estado().figuras[m.clientes.heroina.figuraId];
  assert.deepEqual([h.x, h.y], [6, 4]);
});

test('sem terreno a escala é como sempre (nenhum mapa a respeitar)', () => {
  const m = montarMesa({ mapa: { largura: 30, altura: 30 } });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 6, y: 4 }]]);
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 2 }), 'escala');
});
