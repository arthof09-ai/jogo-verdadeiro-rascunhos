// Ordem 23 do CM-000009 — varredura do servidor (o espírito das V1-V14). Cada teste de correcção falhava antes
// (conferido com o sala.js de 2ae92d1) e passa depois; os de controlo passavam antes e continuam.
//
//  V15  MASTER_APPROVE com `rodada: true` num cartão que não é de IA (desgraça, progresso) era aceite em silêncio: o
//       `rodada` ficava ignorado e a decisão aplicava-se. O schema (MASTER_APPROVE.rodada) diz: «Só com decisao
//       'aprovar' num cartão de IA cuja proposta é uma marcha pura […]. Noutro caso o servidor recusa (acao_invalida).»
//       Agora recusa, e o cartão fica aberto — como no cartão de IA (L6).
//  V16  MASTER_APPROVE `editar` num cartão de progresso («Duas recusas nesta vez») encerrava a vez como o `aprovar`
//       e o registo dizia «trocado». O cartão de progresso não tem edição (o schema só a define nos cartões de
//       desgraça e de IA; o cliente nunca a manda): `editar` sem edição possível é recusado (acao_invalida), o cartão
//       fica aberto — como o `editar` sem edição válida nos outros cartões.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

const abertos = (m) => m.sala.depuracao.estado().cartoes.filter((c) => c.estado === 'aberto');
function exigirRecusa(r, motivo = 'acao_invalida') {
  const rec = recibo(r);
  assert.ok(rec?.type === 'ROOM_REJECT' || rec?.estado === 'RECUSADA', 'recusado: ' + JSON.stringify(rec));
  assert.equal(rec.motivo, motivo);
}

function cartaoDeDesgraca() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  m.motor.cfg.resultado = 'falha_critica';
  const r = m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'fc-1' });
  assert.equal(recibo(r).estado, 'AGUARDANDO_MESTRE');
  m.motor.cfg.resultado = 'acerto';
  const cartao = m.clientes.mestre.ultimo('MASTER_CARD');
  assert.equal(cartao.tipo, 'desgraca');
  return { m, cartao };
}

/** Lobo em semi; o Mestre recusa o cartão de IA e joga à mão; duas acções recusadas → cartão de progresso. */
function cartaoDeProgresso() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['lobo-teste', { x: 10, y: 2 }]]);
  const lobo = m.clientes.heroina.idPorNome('Lobo');
  exigirAplicada(m.mestre('MASTER_MODE', { figuraId: lobo, modo: 'semi' }));
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  const ia = m.clientes.mestre.ultimo('MASTER_CARD');
  assert.equal(ia?.tipo, 'ia');
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: ia.cartaoId, decisao: 'recusar' }));
  for (const id of ['act-x1', 'act-x2']) {
    const r = m.enviar('mestre', {
      type: 'MASTER_ACT', intentId: id, revision: m.clientes.mestre.revision, figuraId: lobo,
      acao: { tipo: 'mover', destino: { x: 0, y: 19 } }, // longe demais: fora das opções
    });
    exigirRecusa(r);
  }
  const cartao = m.clientes.mestre.ultimo('MASTER_CARD');
  assert.equal(cartao?.tipo, 'progresso');
  return { m, lobo, cartao };
}

// ------------------------------------------------------------------ V15

test('ordem 23 (V15): «Continuar a rodada» (rodada: true) num cartão de desgraça é recusado e o cartão fica aberto', () => {
  const { m, cartao } = cartaoDeDesgraca();
  exigirRecusa(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'aprovar', rodada: true }));
  assert.ok(abertos(m).some((c) => c.cartaoId === cartao.cartaoId), 'o cartão continua por decidir');
  assert.equal(m.sala.depuracao.estado().marchaLivre ?? null, null);
});

test('ordem 23 (V15): «Continuar a rodada» num cartão de progresso é recusado e a vez não acaba', () => {
  const { m, lobo, cartao } = cartaoDeProgresso();
  exigirRecusa(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'aprovar', rodada: true }));
  assert.ok(abertos(m).some((c) => c.cartaoId === cartao.cartaoId));
  assert.equal(m.sala.depuracao.estado().vez?.figuraId, lobo);
});

test('ordem 23 (V15, controlo): sem rodada (ou rodada: false), aprovar a desgraça e o progresso funciona como antes', () => {
  const d = cartaoDeDesgraca();
  exigirAplicada(d.m.mestre('MASTER_APPROVE', { cartaoId: d.cartao.cartaoId, decisao: 'aprovar', rodada: false }), 'desgraça');
  assert.equal(abertos(d.m).length, 0);
  const p = cartaoDeProgresso();
  exigirAplicada(p.m.mestre('MASTER_APPROVE', { cartaoId: p.cartao.cartaoId, decisao: 'aprovar' }), 'progresso');
  assert.notEqual(p.m.sala.depuracao.estado().vez?.figuraId, p.lobo, 'aprovar = encerrar o turno');
});

// ------------------------------------------------------------------ V16

test('ordem 23 (V16): «editar» num cartão de progresso é recusado — o cartão fica aberto e a vez não acaba', () => {
  const { m, lobo, cartao } = cartaoDeProgresso();
  exigirRecusa(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar' }));
  exigirRecusa(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { acao: { tipo: 'encerrar' } } }));
  assert.ok(abertos(m).some((c) => c.cartaoId === cartao.cartaoId), 'o cartão continua por decidir');
  assert.equal(m.sala.depuracao.estado().vez?.figuraId, lobo, 'a vez continua a ser do lobo');
});

test('ordem 23 (V16, controlo): «recusar» o cartão de progresso continua a devolver a vez ao Mestre', () => {
  const { m, lobo, cartao } = cartaoDeProgresso();
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'recusar' }));
  assert.equal(abertos(m).length, 0);
  const vez = m.sala.depuracao.estado().vez;
  assert.equal(vez?.figuraId, lobo);
  assert.equal(vez.recusas, 0);
  assert.equal(vez.iaPausada, true);
});
