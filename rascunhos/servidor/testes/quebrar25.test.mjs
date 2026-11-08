// REF_19 (T-QUEBRAR25, palavra do Mestre 07/11/2026): quebrar o corpo perde NA HORA floor(vida/4), tecto vida−1, ≥0.
// Só depois da autorização do Mestre (o cartão H10 não cobra). Uma vez por desgraça. A perda só vai à própria.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada, recibo, listaDeFichas } from './ajudantes.mjs';
import { carregarFichas } from '../nucleo/carregar-fichas.js';

function falhaCriticaDaAliada({ vidaAntes } = {}) {
  let fichas = null;
  if (vidaAntes !== undefined) {
    // O estado de depuração é uma cópia: a Vida pequena entra pela ficha da aliada.
    const lista = listaDeFichas({ comAliada: true });
    lista.find((f) => f.id === 'aliada-teste').vidaTotal = vidaAntes;
    const r = carregarFichas(lista);
    if (!r.ok) throw new Error('fixture inválida: ' + JSON.stringify(r.erros));
    fichas = r.fichas;
  }
  const m = montarMesa({ comAliada: true, comEspectador: true, fichas });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  const aliadaId = m.clientes.aliada.figuraId;
  const fig = () => m.sala.depuracao.estado().figuras[aliadaId];
  m.motor.cfg.resultado = 'falha_critica';
  const r = m.intencao('aliada', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'aliada-quebra' });
  assert.equal(recibo(r).estado, 'AGUARDANDO_MESTRE');
  const vidaNoCartao = fig().vidaActual;
  const cartao = m.clientes.mestre.ultimo('MASTER_CARD');
  assert.equal(cartao.tipo, 'desgraca');
  return { m, fig, aliadaId, cartao, vidaNoCartao };
}

test('REF_19: o cartão (proposta H10) não cobra; aprovado com quebra-corpo, perde floor(vida/4) uma vez', () => {
  const { m, fig, cartao, vidaNoCartao } = falhaCriticaDaAliada();
  assert.equal(vidaNoCartao, 3579, 'antes da autorização do Mestre nada se perde');
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'quebra-corpo' } }));
  assert.equal(fig().corpoPartido, true);
  assert.equal(fig().vidaActual, 3579 - Math.floor(3579 / 4), '3579 → 2685');
  const evMestre = m.clientes.mestre.eventos('desgraca');
  assert.equal(evMestre.length, 1, 'uma desgraça, uma perda');
  assert.equal(evMestre[0].dados.soMestre.perdaVida, 894);
});

test('REF_19: só a própria vê que perdeu; a outra jogadora e o espectador veem só o efeito', () => {
  const { m, cartao } = falhaCriticaDaAliada();
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'quebra-corpo' } }));
  const [daAliada] = m.clientes.aliada.eventos('desgraca');
  assert.equal(daAliada.dados.efeito, 'quebra-corpo');
  assert.equal(daAliada.dados.perdeQuarto, true);
  for (const k of ['heroina', 'espectador']) {
    const [e] = m.clientes[k].eventos('desgraca');
    assert.deepEqual(Object.keys(e.dados).sort(), ['efeito', 'figuraId'], `${k} não vê a perda`);
    const tudo = JSON.stringify(m.clientes[k].msgs);
    for (const n of ['894', '2685', '3579']) assert.ok(!tudo.includes(n), `${k} não vê ${n}`);
  }
});

test('REF_19: com Vida 1 a 3 a perda é 0 e a frase da perda não sai; com Vida 4 perde 1', () => {
  for (const [antes, depois] of [[1, 1], [3, 3], [4, 3], [7, 6]]) {
    const { m, fig, cartao } = falhaCriticaDaAliada({ vidaAntes: antes });
    exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'quebra-corpo' } }));
    assert.equal(fig().vidaActual, depois, `${antes} → ${depois}`);
    assert.ok(fig().vivo !== false, 'a regra sozinha nunca mata');
    const [e] = m.clientes.aliada.eventos('desgraca');
    assert.equal('perdeQuarto' in e.dados, antes - depois > 0);
  }
});

test('REF_19: outra desgraça (cai) não mexe na Vida', () => {
  const { m, fig, cartao, vidaNoCartao } = falhaCriticaDaAliada();
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'cai' } }));
  assert.equal(fig().vidaActual, vidaNoCartao);
  const [e] = m.clientes.aliada.eventos('desgraca');
  assert.ok(!('perdeQuarto' in e.dados));
});
