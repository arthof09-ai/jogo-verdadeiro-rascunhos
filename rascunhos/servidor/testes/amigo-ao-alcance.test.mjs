// Q12 «amigo ao alcance» (julgamento da casa de 2026-11-03; Musa 08/11/2026 16:31). Aliado ADJACENTE ao atacante ou
// NA LINHA até ao alvo vai em contexto.aliadosAoAlcance, por proximidade. O dano pendente da desgraça (acerta-amigo e
// acerta-se) = metade com piso, nunca crítico, − RD de quem recebe → Vida, nunca abaixo de 1, sem testes de morte.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada, recibo, listaDeFichas } from './ajudantes.mjs';
import { carregarFichas } from '../nucleo/carregar-fichas.js';

function fichasCom(mudar) {
  const lista = listaDeFichas({ comAliada: true });
  mudar(lista);
  const r = carregarFichas(lista);
  if (!r.ok) throw new Error('fixture inválida: ' + JSON.stringify(r.erros));
  return r.fichas;
}

/** A aliada (2,4) ataca o orc com o chicote (9 m); a heroína fica onde o teste mandar. */
function falhaDaAliada({ heroina = { x: 2, y: 3 }, orc = { x: 2, y: 6 }, fichas = null, danoDerivado = 300 } = {}) {
  const m = montarMesa({ comAliada: true, comEspectador: true, casas: { heroina }, fichas });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', orc]]);
  const h = m.clientes.heroina;
  const orcId = h.idPorNome('Orc');
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  m.motor.cfg.resultado = 'falha_critica';
  m.motor.cfg.danoDerivado = danoDerivado;
  const r = m.intencao('aliada', { tipo: 'atacar', alvoId: orcId, arma: 'chicote-teste' }, { intentId: 'aliada-falha' });
  assert.equal(recibo(r).estado, 'AGUARDANDO_MESTRE');
  const ctx = m.motor.chamadas.at(-1).contexto;
  const cartao = m.clientes.mestre.ultimo('MASTER_CARD');
  const fig = (id) => m.sala.depuracao.estado().figuras[id];
  return { m, ctx, cartao, fig, heroinaId: h.figuraId, aliadaId: m.clientes.aliada.figuraId, orcId };
}

test('Q12: aliada adjacente ao atacante vai em aliadosAoAlcance como «adjacente»', () => {
  const { ctx, heroinaId } = falhaDaAliada({ heroina: { x: 2, y: 3 } });
  assert.deepEqual(ctx.aliadosAoAlcance, [{ id: heroinaId, posicao: 'adjacente' }]);
});

test('Q12: aliada na linha até ao alvo (sem ser adjacente) vai como «naLinha»; fora da linha não vai', () => {
  assert.deepEqual(falhaDaAliada({ heroina: { x: 2, y: 6 }, orc: { x: 2, y: 8 } }).ctx.aliadosAoAlcance.map((a) => a.posicao), ['naLinha']);
  assert.deepEqual(falhaDaAliada({ heroina: { x: 5, y: 5 } }).ctx.aliadosAoAlcance, []);
  // Supercover: de (2,4) a (4,6) a linha passa no canto de (3,5) — (3,4)/(2,5) são adjacentes, (3,5) está na linha.
  const diag = falhaDaAliada({ heroina: { x: 3, y: 5 }, orc: { x: 4, y: 6 } });
  assert.deepEqual(diag.ctx.aliadosAoAlcance.map((a) => a.posicao), ['naLinha']);
});

test('Q12: inimigos nunca contam como amigos — a heroína ataca, o lobo ao lado dela fica fora, a aliada na linha entra', () => {
  const m = montarMesa({ comAliada: true });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 3, y: 2 }]]);
  m.motor.cfg.resultado = 'falha_critica';
  m.intencao('heroina', { tipo: 'atacar', alvoId: m.clientes.heroina.idPorNome('Orc'), arma: 'chicote-teste' });
  // A heroína (2,2) e a aliada (2,4) não estão adjacentes; a aliada está na linha até ao orc (2,6).
  assert.deepEqual(m.motor.chamadas.at(-1).contexto.aliadosAoAlcance, [{ id: m.clientes.aliada.figuraId, posicao: 'naLinha' }]);
});

test('Q12: «acerta-amigo» aprovado — metade com piso, sem RD, Vida da amiga desce; o mesmo contexto na 2.ª corrida', () => {
  const { m, cartao, fig, heroinaId } = falhaDaAliada({ danoDerivado: 301 });
  const antes = fig(heroinaId).vidaActual;
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'acerta-amigo' } }));
  assert.equal(fig(heroinaId).vidaActual, antes - 150, 'floor(301/2) = 150');
  assert.deepEqual(m.motor.chamadas.at(-1).contexto.aliadosAoAlcance, [{ id: heroinaId, posicao: 'adjacente' }]);
  const [d] = m.clientes.mestre.eventos('desgraca');
  assert.equal(d.dados.soMestre.pendente.aplicada, true);
  assert.equal(d.dados.soMestre.pendente.danoSofrido, 150);
  // A amiga atingida sabe quanto sofreu (é a própria); o espectador vê o dano sem o número.
  const danoH = m.clientes.heroina.eventos('dano').at(-1);
  assert.equal(danoH.dados.alvoId, heroinaId);
  assert.equal(danoH.dados.valor, 150);
  const danoE = m.clientes.espectador.eventos('dano').at(-1);
  assert.ok(!('valor' in danoE.dados));
  // Ordem 32 (V32): o `estado` da aliada (o PA que ela gastou) também sai agora; conta o da heroína.
  assert.equal(m.clientes.heroina.eventos('estado').filter((x) => x.dados.figuraId === heroinaId).at(-1).dados.vidaActual, antes - 150);
});

test('Q12: tecto de letalidade — nunca abaixo de 1 de Vida, nunca abre testes de morte', () => {
  const { m, cartao, fig, heroinaId } = falhaDaAliada({ danoDerivado: 999999 });
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'acerta-amigo' } }));
  const h = fig(heroinaId);
  assert.equal(h.vidaActual, 1);
  assert.ok(!h.estadoMorte, 'sem testes de morte');
  assert.notEqual(h.vivo, false);
  const [d] = m.clientes.mestre.eventos('desgraca');
  assert.equal(d.dados.soMestre.pendente.tetoAplicado, true);
});

test('Q12: a RD de quem recebe desconta antes do tecto (RD geral 41)', () => {
  const fichas = fichasCom((l) => { l.find((f) => f.id === 'heroina-teste').rd = { geral: 41, porTipo: {} }; });
  const { m, cartao, fig, heroinaId } = falhaDaAliada({ fichas, danoDerivado: 100 });
  const antes = fig(heroinaId).vidaActual;
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'acerta-amigo' } }));
  assert.equal(fig(heroinaId).vidaActual, antes - (50 - 41));
  const [d] = m.clientes.mestre.eventos('desgraca');
  assert.equal(d.dados.soMestre.pendente.rdAplicada, 41);
});

test('Q12: dano de dois tipos contra RD — como o VLAB, não se decide: não aplica e fica para o Mestre', () => {
  const fichas = fichasCom((l) => {
    l.find((f) => f.id === 'heroina-teste').rd = { geral: 5, porTipo: {} };
    const t = l.find((f) => f.id === 'aliada-teste').tecnicas[0];
    delete t.tipo;
    t.tipos = ['cortante', 'perfurante'];
  });
  const { m, cartao, fig, heroinaId } = falhaDaAliada({ fichas });
  const antes = fig(heroinaId).vidaActual;
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'acerta-amigo' } }));
  assert.equal(fig(heroinaId).vidaActual, antes);
  const [d] = m.clientes.mestre.eventos('desgraca');
  assert.equal(d.dados.soMestre.pendente.aplicada, false);
  assert.equal(d.dados.soMestre.pendente.motivo, 'RD_SEM_DISTRIBUICAO_POR_TIPO');
});

test('Q12: «acerta-se» pendente (motor sem a Vida) — a mesma regra no próprio atacante', () => {
  const { m, cartao, fig, aliadaId } = falhaDaAliada({ danoDerivado: 999999 });
  m.motor.cfg.acertaSePendente = true;
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'acerta-se' } }));
  assert.equal(fig(aliadaId).vidaActual, 1);
  assert.ok(!fig(aliadaId).estadoMorte);
  assert.equal(m.clientes.aliada.eventos('estado').at(-1).dados.vidaActual, 1);
});

test('Q12: o registo da desgraça pendente (RD, Vida antes/depois) nunca chega à Party', () => {
  const fichas = fichasCom((l) => { l.find((f) => f.id === 'heroina-teste').rd = { geral: 41, porTipo: {} }; });
  const { m, cartao } = falhaDaAliada({ fichas, danoDerivado: 100 });
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'acerta-amigo' } }));
  for (const k of ['heroina', 'aliada', 'espectador']) {
    const tudo = JSON.stringify(m.clientes[k].msgs);
    assert.ok(!tudo.includes('rdAplicada') && !tudo.includes('aliadosAoAlcance') && !tudo.includes('acertaAmigo'), k);
  }
});

// Q8 (do mesmo julgamento; Musa 08/11/2026 16:31) e o site (jogo.js: «fica inutilizável até ser consertada»; sem
// conserto em combate): a arma quebrada não volta nesta batalha; a arma caída apanha-se com a Acção de Movimento.
function vezDaAliadaOutraVez(m) {
  m.motor.cfg.resultado = 'erro'; // o orc (auto) falha e a ronda segue
  exigirAplicada(m.intencao('aliada', { tipo: 'encerrar' }));
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  return m.clientes.aliada.opcoes;
}

test('Q8: arma quebrada — a técnica com arma desaparece das opções e o ataque com ela é recusado', () => {
  const { m, cartao, orcId } = falhaDaAliada();
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'arma-quebra' } }));
  const op = vezDaAliadaOutraVez(m);
  assert.equal(op.vezId, m.clientes.aliada.figuraId);
  assert.deepEqual(op.ataques, []);
  assert.ok(!op.acoes.includes('apanhar_arma'), 'quebrada não se apanha nem se conserta');
  const r = m.intencao('aliada', { tipo: 'atacar', alvoId: orcId, arma: 'chicote-teste' });
  assert.notEqual(recibo(r).estado, 'APLICADA');
});

test('Q8: arma caída — só «apanhar_arma» (gasta a Acção de Movimento: a reserva toda); depois volta a atacar', () => {
  const { m, cartao, fig, aliadaId } = falhaDaAliada();
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'arma-cai' } }));
  let op = vezDaAliadaOutraVez(m);
  assert.deepEqual(op.ataques, []);
  assert.ok(op.acoes.includes('apanhar_arma'));
  exigirAplicada(m.intencao('aliada', { tipo: 'apanhar_arma' }));
  assert.equal(fig(aliadaId).armaCaida, false);
  op = m.clientes.aliada.opcoes;
  assert.equal(op.orcamentoM, 0, 'a reserva foi toda');
  assert.ok(op.ataques.some((a) => a.arma === 'chicote-teste'));
});

test('Q8: a própria recebe logo o `estado` com a arma caída, e outra vez ao apanhá-la', () => {
  const { m, cartao } = falhaDaAliada();
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'arma-cai' } }));
  assert.equal(m.clientes.aliada.eventos('estado').at(-1).dados.armaCaida, true);
  vezDaAliadaOutraVez(m);
  exigirAplicada(m.intencao('aliada', { tipo: 'apanhar_arma' }));
  assert.equal(m.clientes.aliada.eventos('estado').at(-1).dados.armaCaida, false);
  for (const k of ['heroina', 'espectador']) {
    assert.ok(m.clientes[k].eventos('estado').every((e) => !('armaCaida' in e.dados)), `${k} não sabe da arma dela`);
  }
});

// Q12 — escolha do amigo no cartão (BANCADA-DESGRACA-JULGAMENTO.md; Musa 08/11 17:03): o cartão leva os amigos
// elegíveis; o Mestre declara qual é atingido (edicao.aliadoAtingidoId); fora da lista, recusa.
test('Q12: o cartão de desgraça leva os amigos elegíveis; os outros cartões levam null', () => {
  const { cartao, heroinaId } = falhaDaAliada();
  assert.deepEqual(cartao.amigos, [heroinaId]);
});

test('Q12: o Mestre declara o amigo atingido (aliadoAtingidoId) e o motor recebe-o', () => {
  const { m, cartao, fig, heroinaId } = falhaDaAliada({ danoDerivado: 100 });
  const antes = fig(heroinaId).vidaActual;
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'acerta-amigo', aliadoAtingidoId: heroinaId } }));
  assert.equal(m.motor.chamadas.at(-1).contexto.aliadoAtingidoId, heroinaId);
  assert.equal(fig(heroinaId).vidaActual, antes - 50);
});

test('Q12: amigo fora da lista, ou com outra desgraça — recusado (acao_invalida) e o cartão continua aberto', () => {
  const { m, cartao, orcId, heroinaId } = falhaDaAliada();
  for (const edicao of [{ desgraca: 'acerta-amigo', aliadoAtingidoId: orcId }, { desgraca: 'cai', aliadoAtingidoId: heroinaId }]) {
    const r = m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao });
    assert.equal(recibo(r).type, 'ROOM_REJECT', JSON.stringify(edicao));
  }
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'aprovar' }));
});
