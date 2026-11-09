// Ordem 6 do CM-000009 (decisões do Mestre ao ecrã do Mestre, JV3.1), no servidor:
//  - decisão 1: os monstros também têm cartão de desgraça (aprovar ou editar, como o das heroínas);
//  - decisão 7: monstro caído = MORTO (sem testes de morte nem levantar).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

/** O orc (manual) adjacente à heroína; o Mestre joga-o. */
function orcDoMestre() {
  const m = montarMesa({ modoPadrao: 'manual' });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar');
  assert.equal(m.sala.depuracao.estado().vez?.figuraId, orc, 'a vez é do orc');
  return { m, h, orc };
}

function atacarComOrc(m, h, orc, intentId) {
  return m.enviar('mestre', {
    type: 'MASTER_ACT', intentId, revision: m.clientes.mestre.revision, figuraId: orc,
    acao: { tipo: 'atacar', alvoId: h.figuraId, arma: 'machado-teste' },
  });
}

function cartaoDoOrc() {
  const { m, h, orc } = orcDoMestre();
  m.motor.cfg.resultado = 'falha_critica';
  const r = recibo(atacarComOrc(m, h, orc, 'act-fc'));
  assert.equal(r?.estado, 'AGUARDANDO_MESTRE', 'a desgraça do monstro espera pelo Mestre: ' + JSON.stringify(r));
  const cartao = m.clientes.mestre.ultimo('MASTER_CARD');
  return { m, h, orc, cartao };
}

test('decisão 1: a falha crítica do monstro abre o cartão de desgraça ao Mestre (proposta), e não se aplica sozinha', () => {
  const { m, h, orc, cartao } = cartaoDoOrc();
  assert.equal(cartao.tipo, 'desgraca');
  assert.equal(cartao.figuraId, orc, 'o cartão é do monstro');
  assert.ok(Array.isArray(cartao.desgracas) && cartao.desgracas.length > 0, 'leva a lista do «Escolher outra»');
  const ultima = m.motor.chamadas[m.motor.chamadas.length - 1];
  assert.equal(ultima.contexto.modoDesgraca, 'proposta', 'o monstro já não vai em «sorte»');
  assert.equal(h.eventos('desgraca').length, 0, 'nada aplicado antes do Mestre');
  assert.equal(JSON.stringify(h.msgs).includes('MASTER_CARD'), false, 'o cartão é só do Mestre');
});

test('decisão 1: o Mestre aprova a desgraça do monstro e ela aplica-se com a mesma semente', () => {
  const { m, h, orc, cartao } = cartaoDoOrc();
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'aprovar' }), 'aprovar');
  const n = m.motor.chamadas.length;
  assert.equal(m.motor.chamadas[n - 1].contexto.modoDesgraca, 'escolha');
  assert.equal(m.motor.chamadas[n - 1].contexto.semente, m.motor.chamadas[n - 2].contexto.semente, 'a mesma semente');
  const [ev] = h.eventos('desgraca');
  assert.equal(ev?.dados?.figuraId, orc, 'a Party vê a desgraça do orc');
  assert.equal(ev?.dados?.efeito, 'arma-cai', 'a proposta aprovada');
});

test('decisão 1: o Mestre edita a desgraça do monstro para outra da lista', () => {
  const { m, h, cartao } = cartaoDoOrc();
  assert.ok(cartao.desgracas.includes('cai'));
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'cai' } }), 'editar');
  const [ev] = h.eventos('desgraca');
  assert.equal(ev?.dados?.efeito, 'cai');
});

test('decisão 7: monstro a 0 de Vida = morto — sai da ordem, sem testes de morte nem levantar', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }], ['lobo-teste', { x: 15, y: 15 }]]);
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  let testesDeMorte = 0;
  const base = m.motor.Vlab.resolverTesteDeMorte;
  m.motor.Vlab.resolverTesteDeMorte = (e) => { testesDeMorte += 1; return base(e); };
  m.motor.cfg.dano = 999999;
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }), 'atacar');
  m.motor.cfg.dano = 1;
  const est = m.sala.depuracao.estado();
  assert.equal(est.figuras[orc].vivo, false, 'o orc a 0 morre');
  assert.equal(testesDeMorte, 0, 'monstro não faz teste de morte');
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar');
  const depois = m.sala.depuracao.estado();
  assert.notEqual(depois.vez?.figuraId, orc, 'o morto não volta a ter vez');
  assert.equal(depois.figuras[orc].vivo, false, 'não se levanta');
  assert.equal(testesDeMorte, 0);
});
