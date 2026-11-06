// T-IDEM-02 e T-IDEM-03 (protocolo v2, ERRATA E-C1, E-P8, §8.1 ACK perdido).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, recibo, exigirAplicada } from './ajudantes.mjs';

function mesaNaVezDaHeroina() {
  const mesa = montarMesa({ comAliada: true });
  mesa.entrarTodos();
  mesa.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  return mesa;
}

const ID_X = '5b0c2c1e-9d7e-4a43-8f2a-1c6f0e2b9a11';

test('T-IDEM-02: o mesmo intentId reenviado devolve o MESMO recibo e não dá segundo efeito', () => {
  const mesa = mesaNaVezDaHeroina();
  const h = mesa.clientes.heroina;
  const orc = h.idPorNome('Orc');
  assert.ok(orc, 'a heroína vê o orc colocado');
  const msg = { type: 'ROOM_INTENT', intentId: ID_X, revision: h.revision, acao: { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' } };

  const r1 = mesa.enviar('heroina', msg);
  const rec1 = exigirAplicada(r1, 'ataque');
  const chamadas = mesa.motor.chamadas.length;
  const jseq = mesa.sala.depuracao.journalSeq();
  const ataques = mesa.sala.depuracao.eventos().filter((e) => e.tipo === 'ataque').length;
  assert.equal(chamadas, 1);
  assert.equal(ataques, 1);

  // Reenvio (o aparelho não sabe se chegou): mesmo recibo, byte a byte; nada novo no journal.
  const r2 = mesa.enviar('heroina', msg);
  assert.deepEqual(r2, [rec1]);
  assert.equal(JSON.stringify(r2[0]), JSON.stringify(rec1));
  assert.equal(mesa.motor.chamadas.length, chamadas, 'o motor não foi chamado outra vez');
  assert.equal(mesa.sala.depuracao.journalSeq(), jseq, 'nenhum evento novo');

  // E um terceiro, já com a revisão nova a circular: continua o recibo original.
  const r3 = mesa.enviar('heroina', msg);
  assert.deepEqual(r3, [rec1]);
});

test('T-IDEM-02 (§8.1): ACK perdido → RECEIPT_QUERY devolve o recibo original e o RESYNC repõe os eventos', () => {
  const mesa = mesaNaVezDaHeroina();
  const h = mesa.clientes.heroina;
  const orc = h.idPorNome('Orc');
  const seqAntes = h.ultimoSeq;
  const msg = { type: 'ROOM_INTENT', intentId: ID_X, revision: h.revision, acao: { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' } };
  // "A ligação cai antes do recibo chegar": chamamos o núcleo sem entregar nada à heroína.
  const saidas = mesa.sala.receber(h.seatId, { v: 2, roomId: 'sala-teste', ...msg });
  const original = saidas.find((s) => s.seatId === h.seatId && s.msg.type === 'ROOM_RECEIPT').msg;

  const q = mesa.enviar('heroina', { type: 'RECEIPT_QUERY', intentIds: [ID_X] });
  assert.equal(q.length, 1);
  assert.deepEqual(q[0], JSON.parse(JSON.stringify(original)));
  assert.equal(q[0].estado, 'APLICADA');

  const resync = mesa.enviar('heroina', { type: 'ROOM_RESYNC', lastSeq: seqAntes });
  const evs = resync.filter((m) => m.type === 'ROOM_EVENT');
  assert.ok(evs.length > 0);
  evs.forEach((m, i) => assert.equal(m.seq, seqAntes + 1 + i, 'seq do lugar sem buracos'));
  assert.ok(evs.some((m) => m.tipo === 'ataque'));
  assert.equal(original.seq, evs[evs.length - 1].seq, 'o recibo aponta para o último evento do fluxo dela');
});

test('T-IDEM-03: o mesmo intentId com outra ação dá intent_conflito e não grava nada', () => {
  const mesa = mesaNaVezDaHeroina();
  const h = mesa.clientes.heroina;
  const orc = h.idPorNome('Orc');
  const rev = h.revision;
  exigirAplicada(mesa.enviar('heroina', { type: 'ROOM_INTENT', intentId: ID_X, revision: rev, acao: { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' } }));
  const jseq = mesa.sala.depuracao.journalSeq();
  const guardado = mesa.sala.depuracao.recibo(h.seatId, ID_X);
  const estadoAntes = mesa.sala.depuracao.hashEstado();

  // Outra ação, mesmo id.
  const r = mesa.enviar('heroina', { type: 'ROOM_INTENT', intentId: ID_X, revision: rev, acao: { tipo: 'mover', destino: { x: 3, y: 2 } } });
  assert.equal(r.length, 1);
  assert.equal(r[0].type, 'ROOM_REJECT');
  assert.equal(r[0].motivo, 'intent_conflito');
  // Mesma ação mas outra revisão também é outro hashAcao.
  const r2 = mesa.enviar('heroina', { type: 'ROOM_INTENT', intentId: ID_X, revision: rev + 1, acao: { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' } });
  assert.equal(r2[0].motivo, 'intent_conflito');

  assert.equal(mesa.sala.depuracao.journalSeq(), jseq, 'nada gravado');
  assert.deepEqual(mesa.sala.depuracao.recibo(h.seatId, ID_X), guardado, 'o recibo original ficou intacto');
  assert.equal(mesa.sala.depuracao.hashEstado(), estadoAntes, 'o estado não mudou');
});

test('E-P8: deduplicação por (seatId, intentId); RECEIPT_QUERY alheio dá DESCONHECIDA', () => {
  const mesa = mesaNaVezDaHeroina();
  const h = mesa.clientes.heroina;
  const orc = h.idPorNome('Orc');
  exigirAplicada(mesa.enviar('heroina', { type: 'ROOM_INTENT', intentId: ID_X, revision: h.revision, acao: { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' } }));

  // A aliada pergunta pelo id da heroína: não sabe de nada.
  const q = mesa.enviar('aliada', { type: 'RECEIPT_QUERY', intentIds: [ID_X] });
  assert.deepEqual(q, [{ v: 2, type: 'ROOM_RECEIPT', roomId: 'sala-teste', intentId: ID_X, estado: 'DESCONHECIDA' }]);

  // O mesmo id usado pela aliada é OUTRA intenção (outro espaço): é processado (fora da vez).
  const a = mesa.clientes.aliada;
  const r = mesa.enviar('aliada', { type: 'ROOM_INTENT', intentId: ID_X, revision: a.revision, acao: { tipo: 'encerrar' } });
  assert.equal(recibo(r).type, 'ROOM_REJECT');
  assert.equal(recibo(r).motivo, 'fora_da_vez');
  // E a recusa é terminal e gravada: reenviar dá a mesma recusa.
  const r2 = mesa.enviar('aliada', { type: 'ROOM_INTENT', intentId: ID_X, revision: a.revision, acao: { tipo: 'encerrar' } });
  assert.deepEqual(r2, [recibo(r)]);
});

test('formato mal feito não é gravado (o mesmo id pode voltar bem formado)', () => {
  const mesa = mesaNaVezDaHeroina();
  const h = mesa.clientes.heroina;
  const jseq = mesa.sala.depuracao.journalSeq();
  const r = mesa.enviar('heroina', { type: 'ROOM_INTENT', intentId: 'id-1', revision: h.revision, acao: { tipo: 'voar' } });
  assert.equal(r[0].motivo, 'formato');
  assert.equal(mesa.sala.depuracao.recibo(h.seatId, 'id-1'), null);
  assert.equal(mesa.sala.depuracao.journalSeq(), jseq);
  exigirAplicada(mesa.enviar('heroina', { type: 'ROOM_INTENT', intentId: 'id-1', revision: h.revision, acao: { tipo: 'defender' } }));
});
