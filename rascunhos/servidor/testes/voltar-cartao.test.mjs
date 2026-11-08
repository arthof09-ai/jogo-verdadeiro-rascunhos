// Delta REF_21/REF_24 (I0004, 08/11/2026): o «voltar» do Mestre repõe os cartões do instante.
// REF_21 (site): um restauro não pode deixar uma ordem pendente viva para além do instante.
// REF_24 (site): uma rolagem por resolver nunca se deita fora sem custo.
// No servidor, o cartão de desgraça É a rolagem por resolver (a semente fica gravada nele).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

function heroinaComCartao() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  const antesDoGolpe = m.sala.depuracao.journalSeq();
  m.motor.cfg.resultado = 'falha_critica';
  const r = m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'fc-1' });
  assert.equal(recibo(r).estado, 'AGUARDANDO_MESTRE');
  m.motor.cfg.resultado = 'acerto';
  const comCartao = m.sala.depuracao.journalSeq();
  const cartao = m.clientes.mestre.ultimo('MASTER_CARD');
  assert.equal(cartao.tipo, 'desgraca');
  return { m, h, orc, antesDoGolpe, comCartao, cartao };
}
const abertos = (m) => m.sala.depuracao.estado().cartoes.filter((c) => c.estado === 'aberto');
const ultimoRecibo = (h, id) => h.msgs.filter((x) => x.type === 'ROOM_RECEIPT' && x.intentId === id).pop();

test('voltar para um instante com o cartão aberto: o cartão continua por decidir, com a mesma rolagem', () => {
  const { m, h, orc, comCartao, cartao } = heroinaComCartao();
  const contexto = JSON.stringify(abertos(m)[0].contexto);
  exigirAplicada(m.mestre('MASTER_PAUSE', {}));
  exigirAplicada(m.mestre('MASTER_RESUME', {}));
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: comCartao }));
  const [c] = abertos(m);
  assert.ok(c, 'o cartão do instante continua aberto');
  assert.equal(c.cartaoId, cartao.cartaoId);
  assert.equal(JSON.stringify(c.contexto), contexto, 'a mesma rolagem (semente e contexto)');
  assert.equal(m.sala.depuracao.recibo(h.seatId, 'fc-1').estado, 'AGUARDANDO_MESTRE', 'sem recibo órfão');
  // Sem rolagem nova de graça: enquanto o cartão está aberto, a jogadora não ataca de novo.
  const r2 = m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'fc-2' });
  assert.notEqual(recibo(r2)?.estado, 'APLICADA', 'a rolagem por resolver não se deita fora');
  // O Mestre decide o mesmo cartão e o golpe fecha-se.
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'aprovar' }));
  assert.equal(abertos(m).length, 0);
  assert.equal(ultimoRecibo(h, 'fc-1').estado, 'APLICADA');
});

test('voltar para antes da decisão do Mestre: o cartão reabre, o Mestre volta a recebê-lo e o recibo volta a AGUARDANDO', () => {
  const { m, h, comCartao, cartao } = heroinaComCartao();
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'cai' } }));
  assert.equal(abertos(m).length, 0);
  assert.equal(ultimoRecibo(h, 'fc-1').estado, 'APLICADA');
  const cartoesAntes = m.clientes.mestre.msgs.filter((x) => x.type === 'MASTER_CARD').length;
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: comCartao }));
  assert.equal(abertos(m)[0]?.cartaoId, cartao.cartaoId, 'o cartão reabriu');
  assert.equal(m.clientes.mestre.msgs.filter((x) => x.type === 'MASTER_CARD').length, cartoesAntes + 1, 'o Mestre volta a recebê-lo');
  assert.equal(ultimoRecibo(h, 'fc-1').estado, 'AGUARDANDO_MESTRE');
  const her = m.sala.depuracao.estado().figuras[h.figuraId];
  assert.equal(her.caido, false, 'a desgraça decidida depois do instante foi desfeita');
  assert.equal(her.paGasto, 0, 'o PA do golpe ainda não foi debitado');
});

test('voltar para antes do golpe: o cartão nascido depois fica na história, fechado «revertido», e o recibo é recusado', () => {
  const { m, h, antesDoGolpe, cartao } = heroinaComCartao();
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: antesDoGolpe }));
  assert.equal(abertos(m).length, 0);
  const historia = m.sala.depuracao.estado().cartoes.find((c) => c.cartaoId === cartao.cartaoId);
  assert.equal(historia?.decisao, 'revertido', 'nada se apaga da história');
  const rec = m.sala.depuracao.recibo(h.seatId, 'fc-1');
  assert.equal(rec.estado, 'RECUSADA');
  assert.equal(rec.motivo, 'revertido');
});
