// N4 (palavra do Mestre, 08/11/2026: «Claro que quero»), como no site (jogo.js terminarBatalha, M-014):
// o Mestre pode «Terminar batalha» a meio e «Recomeçar» a mesma batalha do zero (MASTER_SUPERVISOR terminar/recomecar).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

const recusado = (r) => recibo(r)?.type === 'ROOM_REJECT' || recibo(r)?.estado === 'RECUSADA';
const estado = (m) => m.sala.depuracao.estado();

function emCombate(opcoes) {
  const m = montarMesa({ comEspectador: true, ...opcoes });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }], ['lobo-teste', { x: 9, y: 9 }]]);
  return m;
}

test('terminar: a batalha acaba com o desfecho «terminada»; a Party recebe o fim; depois disso não há vez', () => {
  const m = emCombate();
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' }), 'terminar');
  assert.equal(estado(m).fase, 'fim');
  assert.equal(estado(m).desfecho, 'terminada');
  for (const chave of ['heroina', 'espectador']) {
    const fim = m.clientes[chave].eventos('fim');
    assert.equal(fim.length, 1, `${chave} recebe o fim`);
    assert.deepEqual(fim[0].dados, { desfecho: 'terminada' }, `${chave}: só o desfecho`);
  }
  assert.ok(recusado(m.intencao('heroina', { tipo: 'encerrar' })), 'depois do fim não há vez');
  assert.ok(recusado(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' })), 'não se termina duas vezes');
});

test('terminar: com o cartão de desgraça aberto, fecha o cartão e recusa o recibo que esperava por ele', () => {
  const m = emCombate();
  const orc = m.clientes.heroina.idPorNome('Orc');
  m.motor.cfg.resultado = 'falha_critica';
  assert.equal(recibo(m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'fc-t' })).estado, 'AGUARDANDO_MESTRE');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' }), 'terminar com cartão aberto');
  assert.equal(estado(m).cartoes.filter((c) => c.estado === 'aberto').length, 0, 'nenhum cartão fica aberto');
  const r = m.sala.depuracao.recibo(m.clientes.heroina.seatId, 'fc-t');
  assert.equal(r.estado, 'RECUSADA');
});

test('terminar e recomeçar: só depois de a batalha começar', () => {
  const m = montarMesa();
  m.entrarTodos();
  assert.ok(recusado(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' })), 'no lobby não se termina');
  assert.ok(recusado(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' })), 'no lobby não se recomeça');
});

test('recomeçar: a mesma batalha do zero — casas da colocação, ficha inteira, rodada 1, vez dela; o modo H10 fica', () => {
  const m = emCombate();
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  const lobo = h.idPorNome('Lobo');
  exigirAplicada(m.mestre('MASTER_MODE', { figuraId: lobo, modo: 'semi' }));
  // Mexer na batalha: ela anda e ataca o orc (o motor falso tira 1176).
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }));
  assert.ok(estado(m).figuras[orc].vidaActual < 7777, 'o orc perdeu vida');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar');
  const e = estado(m);
  assert.equal(e.fase, 'combate');
  assert.equal(e.rodada, 1);
  assert.equal(e.vez?.figuraId, h.figuraId, 'começa na vez dela (D-13.3)');
  assert.equal(e.figuras[orc].vidaActual, 7777, 'o orc com a vida inteira');
  assert.deepEqual({ x: e.figuras[orc].x, y: e.figuras[orc].y }, { x: 2, y: 3 }, 'o orc na casa onde foi colocado');
  assert.equal(e.figuras[h.figuraId].paGasto, 0, 'o PA dela volta a zero');
  assert.equal(e.figuras[lobo].modo, 'semi', 'o modo que o Mestre escolheu fica');
  assert.equal(h.eventos('recomeco').length, 1, 'a jogadora recebe o recomeço');
  assert.equal(h.ultimo('ROOM_SNAPSHOT').rodada, 1, 'e um snapshot novo');
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'a batalha segue');
});

test('recomeçar depois do fim (terminar → recomeçar) volta a pôr a batalha em combate', () => {
  const m = emCombate();
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' }));
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar depois do fim');
  assert.equal(estado(m).fase, 'combate');
  assert.equal(estado(m).desfecho, null);
});
