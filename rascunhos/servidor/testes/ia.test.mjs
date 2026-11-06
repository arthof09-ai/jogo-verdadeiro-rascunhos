// T-IA-07: IA simples + invariante 12 (progresso). A IA só gera intenções a partir do
// ROOM_OPTIONS corrente; na 2.ª recusa no mesmo turno, `auto` encerra; no máximo 20 por turno.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada } from './ajudantes.mjs';
import { MAX_INTENCOES_TURNO } from '../nucleo/sala.js';

function intencoesIAPorTurno(eventos) {
  // Conta eventos internos `ia` e `recusa` (da IA) entre dois `turno`.
  const turnos = [];
  let atual = null;
  for (const e of eventos) {
    if (e.tipo === 'turno') {
      atual = { figuraId: e.dados.figuraId, ia: 0, recusas: 0 };
      turnos.push(atual);
    } else if (atual && e.tipo === 'ia') atual.ia += 1;
    else if (atual && e.tipo === 'recusa' && e.dados.seatId === 'ia') atual.recusas += 1;
  }
  return turnos;
}

test('T-IA-07: em auto, o lobo aproxima-se da jogadora e ataca; a vez volta a ela', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['lobo-teste', { x: 10, y: 2 }]]);
  const h = m.clientes.heroina;
  const lobo = h.idPorNome('Lobo');
  const n0 = h.msgs.length;

  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  const vistos = h.msgs.slice(n0).filter((x) => x.type === 'ROOM_EVENT');
  const turnoLobo = vistos.find((e) => e.tipo === 'turno' && e.dados.figuraId === lobo);
  assert.ok(turnoLobo, 'a Party viu o turno do lobo');
  assert.equal(turnoLobo.dados.narra, true, 'E-P11: a Party vê sempre "o Mestre narra"');
  assert.ok(!('modo' in turnoLobo.dados), 'o modo nunca é projetado');

  const mov = vistos.find((e) => e.tipo === 'movimento' && e.dados.figuraId === lobo);
  assert.ok(mov, 'o lobo andou');
  const dAntes = Math.abs(mov.dados.de.x - 2) + Math.abs(mov.dados.de.y - 2);
  const dDepois = Math.abs(mov.dados.para.x - 2) + Math.abs(mov.dados.para.y - 2);
  assert.ok(dDepois < dAntes, 'aproximou-se');
  assert.equal(dDepois, 1, 'chegou adjacente (reserva de 12 m = 8 casas chega)');
  assert.ok(vistos.some((e) => e.tipo === 'ataque' && e.dados.atacanteId === lobo && e.dados.alvoId === h.figuraId), 'e atacou');
  // A Party não vê o bruto do monstro.
  const atq = vistos.find((e) => e.tipo === 'ataque' && e.dados.atacanteId === lobo);
  assert.ok(!('total' in atq.dados) && !('faces' in atq.dados));

  // A vez voltou à heroína, rodada 2.
  const ultimoTurno = vistos.filter((e) => e.tipo === 'turno').pop();
  assert.equal(ultimoTurno.dados.figuraId, h.figuraId);
  assert.equal(ultimoTurno.dados.rodada, 2);
  assert.equal(h.opcoes.vezId, h.figuraId);

  for (const t of intencoesIAPorTurno(m.sala.depuracao.eventos())) assert.ok(t.ia + t.recusas <= MAX_INTENCOES_TURNO);
});

test('T-IA-07 (invariante 12): com o motor a falhar, a 2.ª recusa encerra o turno da criatura', () => {
  const m = montarMesa();
  m.entrarTodos();
  // Lobo e orc adjacentes à heroína (2,2): a IA vai tentar atacar.
  m.iniciarCombate([['lobo-teste', { x: 2, y: 3 }], ['orc-teste', { x: 3, y: 2 }]]);
  const h = m.clientes.heroina;
  m.motor.cfg.erro = 'FALHA_FALSA';

  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  const turnos = intencoesIAPorTurno(m.sala.depuracao.eventos());
  const daIA = turnos.filter((t) => t.figuraId !== h.figuraId);
  assert.equal(daIA.length, 2, 'lobo e orc tiveram a vez');
  for (const t of daIA) {
    assert.equal(t.recusas, 2, 'exatamente duas recusas');
    assert.ok(t.ia + t.recusas <= MAX_INTENCOES_TURNO);
  }
  assert.equal(h.opcoes.vezId, h.figuraId, 'e a vez voltou à heroína (sem laço infinito, D-REC-01)');
  // Os recibos da IA ficam gravados como RECUSADA, no espaço `ia`.
  const r = m.sala.depuracao.recibo('ia', 'ia-1');
  assert.equal(r.estado, 'RECUSADA');
  // E nenhuma recusa da IA chegou à Party.
  assert.ok(!h.msgs.some((x) => x.type === 'ROOM_REJECT'));
});

test('T-IA-07 (semi): a IA propõe por cartão ao Mestre; a razão só o Mestre a vê', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['lobo-teste', { x: 10, y: 2 }]]);
  const h = m.clientes.heroina;
  const mestre = m.clientes.mestre;
  const lobo = h.idPorNome('Lobo');
  exigirAplicada(m.mestre('MASTER_MODE', { figuraId: lobo, modo: 'semi' }));

  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  const cartao = mestre.ultimo('MASTER_CARD');
  assert.ok(cartao, 'o Mestre recebeu o cartão');
  assert.equal(cartao.tipo, 'ia');
  assert.match(cartao.razao, /CANARIO-RAZAO-IA/);
  assert.equal(cartao.proposta.tipo, 'mover');
  assert.ok(!JSON.stringify(h.msgs).includes('CANARIO-RAZAO-IA'));

  // Enquanto o cartão está aberto, a heroína não tem opções (opções honestas) e nada se aprova sozinho.
  const fora = m.intencao('heroina', { tipo: 'encerrar' });
  assert.equal(fora.find((x) => x.type === 'ROOM_REJECT').motivo, 'aguardando_mestre');

  // O Mestre aprova; a IA propõe a seguir (atacar, se chegou), até encerrar.
  for (let i = 0; i < 6; i++) {
    const c = mestre.ultimo('MASTER_CARD');
    const est = m.sala.depuracao.estado();
    if (!est.cartoes.some((x) => x.cartaoId === c.cartaoId && x.estado === 'aberto')) break;
    exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: c.cartaoId, decisao: 'aprovar' }), 'aprovar ' + c.cartaoId);
  }
  assert.equal(h.opcoes.vezId, h.figuraId, 'a vez voltou à heroína');
  const tipos = m.sala.depuracao.eventos().filter((e) => e.tipo === 'cartao_fechado').map((e) => e.dados.decisao);
  assert.ok(tipos.length >= 2 && tipos.every((d) => d === 'aprovar'));
});

test('cartões em FIFO e decisão idempotente: a primeira decisão ganha', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['lobo-teste', { x: 10, y: 2 }]]);
  const h = m.clientes.heroina;
  const lobo = h.idPorNome('Lobo');
  exigirAplicada(m.mestre('MASTER_MODE', { figuraId: lobo, modo: 'semi' }));
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  const c = m.clientes.mestre.ultimo('MASTER_CARD');
  // Com o cartão aberto, outros comandos de estado dão cartao_aberto.
  const bloq = m.mestre('MASTER_AMBIENTE', { hora: '12:00' });
  assert.equal(bloq.find((x) => x.type === 'ROOM_REJECT').motivo, 'cartao_aberto');
  // Recusar: o Mestre passa a jogar esta vez à mão.
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: c.cartaoId, decisao: 'recusar' }));
  const segunda = m.mestre('MASTER_APPROVE', { cartaoId: c.cartaoId, decisao: 'aprovar' });
  assert.equal(segunda.find((x) => x.type === 'ROOM_REJECT').motivo, 'acao_invalida', 'o cartão já foi decidido');
  // Agora o Mestre joga o lobo pelo mesmo caminho do motor.
  const ops = m.clientes.mestre.opcoes;
  assert.equal(ops.vezId, lobo);
  exigirAplicada(m.enviar('mestre', {
    type: 'MASTER_ACT', intentId: 'act-1', revision: m.clientes.mestre.revision, figuraId: lobo, acao: { tipo: 'encerrar' },
  }));
  assert.equal(h.opcoes.vezId, h.figuraId);
});
