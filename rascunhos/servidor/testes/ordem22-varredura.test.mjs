// Ordem 22 do CM-000009 — varredura do servidor (o espírito das V1-V12). Cada teste de correcção falhava antes
// (conferido com o sala.js de 7e36ede) e passa depois; os de controlo passavam antes e continuam.
//
//  V13  MASTER_PLACE com `orientacao: ""` era aceite (o servidor só limitava o comprimento máximo); a figura ficava
//       com orientação vazia e o evento `colocacao` e o snapshot que saíam para a Party violavam o próprio schema
//       (comum.schema.json orientacao: minLength 1). O schema de entrada MASTER_PLACE já a recusava: agora o servidor
//       também (ROOM_REJECT formato, nada gravado).
//  V14  a hora do painel fora do relógio ("25:70", "99:00") dava `luz: 'noite'` à Party (só se olhava para a hora ≥ 18).
//       Uma hora que não existe não diz se é dia ou noite: `luz: null`, como sem hora. As horas válidas não mudam.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { efeitoAmbiente } from '../nucleo/projecao.js';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

// ------------------------------------------------------------------ V13

test('ordem 22 (V13): MASTER_PLACE com orientação vazia é recusado por formato e nada sai para a Party', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  const antes = m.sala.depuracao.journalSeq();
  const n = m.clientes.heroina.msgs.length;
  const r = m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 12, y: 2 }, orientacao: '' });
  const rec = recibo(r);
  assert.equal(rec?.type, 'ROOM_REJECT');
  assert.equal(rec?.motivo, 'formato');
  assert.equal(m.sala.depuracao.journalSeq(), antes, 'nada gravado');
  assert.ok(!m.clientes.heroina.msgs.slice(n).some((x) => x.type === 'ROOM_EVENT' && x.tipo === 'colocacao'));
  assert.ok(Object.values(m.sala.depuracao.estado().figuras).every((f) => typeof f.orientacao === 'string' && f.orientacao.length >= 1));
});

test('ordem 22 (V13, controlo): MASTER_PLACE com orientação, sem ela ou null continua a colocar', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 12, y: 2 }, orientacao: 'N' }), 'com N');
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 12, y: 4 } }), 'sem orientação');
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 12, y: 6 }, orientacao: null }), 'null');
  const ors = Object.values(m.sala.depuracao.estado().figuras).filter((f) => f.fichaId === 'lobo-teste').map((f) => f.orientacao).sort();
  assert.deepEqual(ors, ['N', 'S', 'S']);
});

// ------------------------------------------------------------------ V14

test('ordem 22 (V14): hora fora do relógio não diz dia nem noite à Party', () => {
  for (const hora of ['25:70', '99:00', '24:00', '12:60']) {
    assert.equal(efeitoAmbiente({ hora, clima: null }).luz, null, hora);
  }
  const m = montarMesa();
  m.entrarTodos();
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { hora: '25:70', clima: 'chuva' }));
  const snap = m.enviar('heroina', { type: 'ROOM_RESYNC', lastSeq: -1 }).find((x) => x.type === 'ROOM_SNAPSHOT');
  assert.deepEqual(snap.ambiente, { clima: 'chuva', luz: null });
});

test('ordem 22 (V14, controlo): as horas válidas continuam — 06:00 a 17:59 dia, o resto noite', () => {
  const casos = { '00:00': 'noite', '05:59': 'noite', '06:00': 'dia', '7:30': 'dia', '17:59': 'dia', '18:00': 'noite', '23:59': 'noite' };
  for (const [hora, luz] of Object.entries(casos)) assert.equal(efeitoAmbiente({ hora }).luz, luz, hora);
  assert.equal(efeitoAmbiente({ hora: null }).luz, null);
});
