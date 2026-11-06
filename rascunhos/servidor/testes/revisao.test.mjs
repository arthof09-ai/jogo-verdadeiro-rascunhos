// T-REV-04 e T-REV-05 (invariante 5; ERRATA E-P5, E-C5; testes de oráculo da JV1.2).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, recibo, exigirAplicada } from './ajudantes.mjs';

function mesa() {
  const m = montarMesa({ comAliada: true });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  return m;
}

test('T-REV-04: intenção com revision velha é recusada, nunca aplicada, e chega um ROOM_OPTIONS novo', () => {
  const m = mesa();
  const h = m.clientes.heroina;
  const revVelha = h.revision;
  const opcoesVelhas = h.opcoes;
  assert.equal(opcoesVelhas.revision, revVelha);

  // Algo VISÍVEL muda: o Mestre põe um lobo no tabuleiro.
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 9, y: 9 } }));
  assert.ok(h.revision > revVelha, 'a revisão dela subiu');
  assert.ok(h.opcoes.revision > revVelha, 'e recebeu opções novas');

  const jseq = m.sala.depuracao.journalSeq();
  const posAntes = m.sala.depuracao.estado().figuras[h.figuraId];
  const destino = opcoesVelhas.mover[0];
  const r = m.intencao('heroina', { tipo: 'mover', destino: { x: destino.x, y: destino.y } }, { intentId: 'rev-velha-1', revision: revVelha });
  const rej = recibo(r);
  assert.equal(rej.type, 'ROOM_REJECT');
  assert.equal(rej.motivo, 'revisao_antiga');
  assert.ok(!/\d/.test(rej.texto), 'o texto não leva números');
  const novas = r.find((x) => x.type === 'ROOM_OPTIONS');
  assert.ok(novas, '§4: o servidor manda logo um ROOM_OPTIONS novo');
  assert.equal(novas.revision, h.revision);
  assert.ok(r.indexOf(rej) < r.indexOf(novas), 'recusa primeiro, opções depois');

  const posDepois = m.sala.depuracao.estado().figuras[h.figuraId];
  assert.deepEqual([posDepois.x, posDepois.y], [posAntes.x, posAntes.y], 'não andou');
  assert.equal(m.sala.depuracao.eventos().slice(jseq).filter((e) => e.tipo === 'movimento').length, 0);

  // Terminal (E-C5): o mesmo id volta a dar a mesma recusa; para tentar de novo, id novo.
  const r2 = m.intencao('heroina', { tipo: 'mover', destino: { x: destino.x, y: destino.y } }, { intentId: 'rev-velha-1', revision: revVelha });
  assert.deepEqual(recibo(r2), rej);
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: destino.x, y: destino.y } }));
});

test('T-REV-05: mudança oculta (MASTER_MODE, painel do ambiente) não mexe no revision nem no seq da Party', () => {
  const m = mesa();
  const h = m.clientes.heroina;
  const a = m.clientes.aliada;
  const orc = h.idPorNome('Orc');
  const antes = { hRev: h.revision, hSeq: h.ultimoSeq, hN: h.msgs.length, aRev: a.revision, aSeq: a.ultimoSeq, aN: a.msgs.length };
  const revMestre = m.clientes.mestre.revision;

  exigirAplicada(m.mestre('MASTER_MODE', { figuraId: orc, modo: 'semi' }));
  // Só muda o que vem no futuro do ambiente (o efeito presente não muda: não há hora nem clima).
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { futuro: 'raio 23:59 CANARIO' }));

  assert.ok(m.clientes.mestre.revision > revMestre, 'o Mestre vê a mudança');
  assert.equal(h.revision, antes.hRev);
  assert.equal(h.ultimoSeq, antes.hSeq);
  assert.equal(h.msgs.length, antes.hN, 'a heroína não recebeu NADA');
  assert.equal(a.revision, antes.aRev);
  assert.equal(a.ultimoSeq, antes.aSeq);
  assert.equal(a.msgs.length, antes.aN, 'a aliada não recebeu NADA');

  // E a intenção feita na revisão que ela tem continua válida.
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }));
});

test('T-REV-05 b: a revisão só sobe para quem vê a mudança (o movimento dela muda a vista de todos)', () => {
  const m = mesa();
  const h = m.clientes.heroina;
  const a = m.clientes.aliada;
  const aRev = a.revision;
  const destino = h.opcoes.mover.find((o) => o.custoM === 1.5);
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: destino.x, y: destino.y } }));
  assert.ok(a.revision > aRev, 'a posição dela é visível para a aliada');
  // Cada seq do fluxo da aliada é contíguo.
  const seqs = a.msgs.filter((x) => x.type === 'ROOM_EVENT').map((x) => x.seq);
  seqs.forEach((s, i) => assert.equal(s, seqs[0] + i));
});
