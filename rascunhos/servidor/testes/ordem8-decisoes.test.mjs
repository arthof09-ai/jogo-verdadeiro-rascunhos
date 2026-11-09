// Ordem 8 do CM-000009 (2026-11-09), no servidor:
//  - item 5 (desempate do Mestre 09/11 08:17; site REF_34, T-DESGRACA-NADA): ao recusar a proposta de desgraça, o
//    Mestre pode escolher «Não acontece nada» — só ele, fora da tabela, sem peso, nunca por acaso nem pela IA; escolhida,
//    nenhum efeito de desgraça acontece e a segunda chamada ao motor não se faz;
//  - item 8 (desempate do Mestre 09/11 08:18): mudar a escala a meio da batalha — acção só do Mestre, sem custo; as
//    posições guardam-se em casas; o movimento já gasto na volta conta em metros na escala nova; o servidor é dono da
//    posição; a Party vê o resultado, nunca a mecânica interna.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

const estado = (m) => m.sala.depuracao.estado();
const abertos = (m) => estado(m).cartoes.filter((c) => c.estado === 'aberto');

// ------------------------------------------------------------------ item 5: «Não acontece nada»

/** A heroína tem uma falha crítica contra o orc adjacente: o cartão (proposta) vai ao Mestre. */
function cartaoDaHeroina(opcoes = {}) {
  const m = montarMesa(opcoes);
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  m.motor.cfg.resultado = 'falha_critica';
  const r = m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'fc-nada' });
  assert.equal(recibo(r)?.estado, 'AGUARDANDO_MESTRE', 'a proposta espera pelo Mestre');
  return { m, h, orc, cartao: m.clientes.mestre.ultimo('MASTER_CARD') };
}

test('item 5: «Não acontece nada» (recusar + semDesgraca) fecha o cartão sem desgraça e SEM segunda chamada ao motor', () => {
  const { m, h, cartao } = cartaoDaHeroina();
  const chamadasAntes = m.motor.chamadas.length;
  const paAntes = estado(m).figuras[h.figuraId].paGasto;
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'recusar', edicao: { semDesgraca: true } }), 'nada');
  assert.equal(m.motor.chamadas.length, chamadasAntes, 'o motor não é chamado outra vez');
  assert.equal(abertos(m).length, 0, 'o cartão fecha');
  const fig = estado(m).figuras[h.figuraId];
  assert.equal(fig.armaCaida, false, 'a proposta (arma-cai) não se aplicou');
  assert.equal(fig.caido, false);
  assert.equal(fig.corpoPartido, false);
  assert.equal(fig.armaQuebrada, false);
  assert.equal(fig.paGasto, paAntes + 2, 'os custos da falha crítica pagam-se na mesma (PA do chicote)');
  assert.equal(estado(m).vez.atacou, true, 'o ataque conta como feito');
  assert.equal(h.eventos('desgraca').length, 0, 'a Party não vê desgraça nenhuma');
  const [at] = h.eventos('ataque');
  assert.equal(at?.dados?.resultado, 'falha_critica', 'a Party vê o golpe falhado');
  const rec = m.sala.depuracao.recibo(h.seatId, 'fc-nada');
  assert.equal(rec?.estado, 'APLICADA', 'o recibo da jogadora fica APLICADA');
  // O Mestre vê a decisão (interna); a Party não recebe o tipo `acao`.
  const doMestre = m.clientes.mestre.eventos('acao').find((e) => e.dados?.tipo === 'sem_desgraca');
  assert.ok(doMestre, 'a escolha fica no registo do Mestre');
  assert.equal(doMestre.dados.soMestre?.escolha, 'nada');
  assert.equal(JSON.stringify(h.msgs).includes('sem_desgraca'), false, 'a Party nunca vê a escolha');
  assert.equal(JSON.stringify(h.msgs).includes('semDesgraca'), false);
});

test('item 5: o monstro também — o Mestre recusa a proposta do orc com «Não acontece nada»', () => {
  const m = montarMesa({ modoPadrao: 'manual' });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar');
  m.motor.cfg.resultado = 'falha_critica';
  const r = m.enviar('mestre', {
    type: 'MASTER_ACT', intentId: 'act-nada', revision: m.clientes.mestre.revision, figuraId: orc,
    acao: { tipo: 'atacar', alvoId: h.figuraId, arma: 'machado-teste' },
  });
  assert.equal(recibo(r)?.estado, 'AGUARDANDO_MESTRE');
  const cartao = m.clientes.mestre.ultimo('MASTER_CARD');
  assert.equal(cartao.figuraId, orc);
  const n = m.motor.chamadas.length;
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'recusar', edicao: { semDesgraca: true } }), 'nada (orc)');
  assert.equal(m.motor.chamadas.length, n, 'sem segunda chamada');
  assert.equal(estado(m).figuras[orc].armaCaida, false, 'o orc fica com a arma');
  assert.equal(h.eventos('desgraca').length, 0);
});

test('item 5: «Não acontece nada» não é linha da tabela — a lista do cartão continua a ser só as 6, e não há outro caminho', () => {
  const { m, cartao } = cartaoDaHeroina();
  assert.ok(!cartao.desgracas.includes('nada') && !cartao.desgracas.includes('nenhuma'), 'fora da tabela');
  const tenta = (campos) => recibo(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, ...campos }));
  // Pela lista do «Editar» não entra (não é desgraça da tabela).
  assert.notEqual(tenta({ decisao: 'editar', edicao: { desgraca: 'nada' } })?.estado, 'APLICADA');
  // semDesgraca só com «recusar».
  assert.notEqual(tenta({ decisao: 'aprovar', edicao: { semDesgraca: true } })?.estado, 'APLICADA');
  assert.notEqual(tenta({ decisao: 'editar', edicao: { desgraca: 'cai', semDesgraca: true } })?.estado, 'APLICADA');
  // Recusar sem escolher continua a não deitar a rolagem fora (o «← Voltar» do site).
  assert.notEqual(tenta({ decisao: 'recusar' })?.estado, 'APLICADA');
  assert.equal(abertos(m).length, 1, 'o cartão continua por decidir');
  // A jogadora não pode mandar a decisão.
  const rj = m.enviar('heroina', { type: 'MASTER_APPROVE', cmdId: 'x-1', revision: m.clientes.heroina.revision, cartaoId: cartao.cartaoId, decisao: 'recusar', edicao: { semDesgraca: true } });
  assert.notEqual(recibo(rj)?.estado, 'APLICADA', 'só o Mestre');
  assert.equal(abertos(m).length, 1);
});

test('item 5: a IA nunca a escolhe — em auto, a falha crítica do monstro espera sempre pelo Mestre', () => {
  const m = montarMesa({ modoPadrao: 'auto' });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  m.motor.cfg.resultado = 'falha_critica';
  const h = m.clientes.heroina;
  m.intencao('heroina', { tipo: 'encerrar' });
  const eventos = m.sala.depuracao.eventos();
  assert.equal(eventos.some((e) => e.tipo === 'acao' && e.dados?.tipo === 'sem_desgraca'), false, 'nenhum «nada» sem o Mestre');
  const fc = m.motor.chamadas.filter((c) => c.contexto?.modoDesgraca);
  assert.ok(fc.every((c) => c.contexto.desgracaEscolhida !== 'nada'), 'o motor nunca recebe «nada»');
  if (abertos(m).length) assert.equal(abertos(m)[0].tipo === 'desgraca' || abertos(m)[0].tipo === 'ia', true);
  assert.equal(h.eventos('desgraca').every((e) => e.dados.efeito !== null), true);
});

// ------------------------------------------------------------------ item 8: mudar a escala

function mesaDaEscala() {
  const m = montarMesa({ comEspectador: true });
  m.entrarTodos();
  // Heroína em (2,2); lobo a 4 casas em (6,2): 6 m a 1,5 (dentro do chicote de 9 m), 12 m a 3 (fora).
  m.iniciarCombate([['lobo-teste', { x: 6, y: 2 }]]);
  return m;
}
const escala = (m, casaM, extra = {}) => m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM, ...extra });

test('item 8: o Mestre muda a escala — as posições ficam em casas, a reserva em metros, as opções contam na escala nova', () => {
  const m = mesaDaEscala();
  const h = m.clientes.heroina;
  assert.equal(h.opcoes.orcamentoM, 9);
  assert.equal(h.opcoes.ataques.length, 1, 'a 1,5 m o lobo está ao alcance');
  const antes = estado(m);
  const posicoes = Object.fromEntries(Object.values(antes.figuras).map((f) => [f.id, [f.x, f.y]]));
  exigirAplicada(escala(m, 3), 'escala 3');
  const depois = estado(m);
  assert.equal(depois.mapa.casaM, 3);
  for (const f of Object.values(depois.figuras)) assert.deepEqual([f.x, f.y], posicoes[f.id], 'ninguém mexe: as posições são casas');
  assert.equal(h.opcoes.orcamentoM, 9, 'a reserva continua em metros');
  assert.ok(h.opcoes.mover.length > 0);
  assert.ok(h.opcoes.mover.every((o) => o.custoM % 3 === 0 && o.custoM <= 9), 'cada casa custa 3 m: no máximo 3 casas');
  assert.ok(h.opcoes.mover.some((o) => o.custoM === 9));
  assert.equal(h.opcoes.ataques.length, 0, 'a 3 m por casa o lobo fica a 12 m: fora do chicote');
  assert.equal(h.ultimo('ROOM_SNAPSHOT').mapa.casaM, 3, 'a Party recebe o resultado no snapshot');
});

test('item 8: o movimento já gasto na volta conta em metros na escala nova', () => {
  const m = mesaDaEscala();
  const h = m.clientes.heroina;
  // A 1,5 m: anda 2 casas (3 m) → sobram 6 m.
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 2, y: 4 } }), 'mover 2 casas');
  assert.equal(estado(m).vez.reservaM, 6);
  assert.equal(estado(m).vez.andouM, 3);
  // Muda para 3 m: os 3 m já andados contam como 3 m (não como 2 casas = 6 m); 6 m pagam 2 casas.
  exigirAplicada(escala(m, 3), 'escala 3');
  assert.equal(estado(m).vez.reservaM, 6, 'a reserva não se reconverte');
  assert.equal(estado(m).vez.andouM, 3, 'o andado fica em metros');
  assert.equal(h.opcoes.orcamentoM, 6);
  assert.equal(Math.max(...h.opcoes.mover.map((o) => o.custoM)), 6, '2 casas de 3 m');
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 2, y: 6 } }), 'mover 2 casas a 3 m');
  assert.equal(estado(m).vez.reservaM, 0);
  assert.equal(estado(m).vez.andouM, 9, 'andou 9 m: 3 a 1,5 + 6 a 3');
  // Uma escala menor depois de gasta não devolve movimento.
  exigirAplicada(escala(m, 1.5), 'escala 1,5');
  assert.equal(estado(m).vez.reservaM, 0);
  assert.equal(h.opcoes.mover.length, 0);
});

test('item 8: sem custo — a vez, a acção, o PA e a reacção ficam como estavam', () => {
  const m = mesaDaEscala();
  const h = m.clientes.heroina;
  const a = estado(m);
  exigirAplicada(escala(m, 2), 'escala 2');
  const d = estado(m);
  assert.equal(d.vez.figuraId, a.vez.figuraId, 'a vez não passa');
  assert.equal(d.vez.atacou, a.vez.atacou);
  assert.equal(d.vez.correrUsado, a.vez.correrUsado);
  assert.equal(d.rodada, a.rodada);
  for (const f of Object.values(d.figuras)) {
    assert.equal(f.paGasto, a.figuras[f.id].paGasto, 'PA');
    assert.equal(f.reacaoDisponivel, a.figuras[f.id].reacaoDisponivel, 'reacção');
    assert.equal(f.vidaActual, a.figuras[f.id].vidaActual, 'vida');
  }
  assert.ok(h.opcoes.acoes.includes('correr'), 'ainda pode correr');
});

test('item 8: só o Mestre — a jogadora não muda a escala; valores inválidos, a mesma escala e cartão aberto são recusados', () => {
  const m = mesaDaEscala();
  const h = m.clientes.heroina;
  const rj = m.enviar('heroina', { type: 'MASTER_SUPERVISOR', cmdId: 'h-esc', revision: h.revision, op: 'escala', casaM: 3 });
  assert.notEqual(recibo(rj)?.estado, 'APLICADA', 'a jogadora não pode');
  assert.equal(estado(m).mapa.casaM, 1.5);
  for (const mau of [0, -1.5, '3', null]) {
    assert.notEqual(recibo(escala(m, mau))?.estado, 'APLICADA', 'casaM ' + JSON.stringify(mau));
  }
  assert.notEqual(recibo(m.mestre('MASTER_SUPERVISOR', { op: 'escala' }))?.estado, 'APLICADA', 'sem casaM');
  assert.notEqual(recibo(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar', casaM: 3 }))?.estado, 'APLICADA', 'casaM só com escala');
  assert.notEqual(recibo(escala(m, 1.5))?.estado, 'APLICADA', 'a mesma escala: nada a mudar');
  assert.equal(estado(m).mapa.casaM, 1.5);
  // Com um cartão aberto, o cartão decide-se primeiro.
  const { m: m2, cartao } = cartaoDaHeroina();
  assert.equal(recibo(escala(m2, 3))?.motivo, 'cartao_aberto');
  exigirAplicada(m2.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'aprovar' }));
  exigirAplicada(escala(m2, 3), 'depois do cartão');
});

test('item 8: a Party vê o resultado, nunca a mecânica — o evento `escala` vai vazio; o antes/depois é só do Mestre', () => {
  const m = mesaDaEscala();
  exigirAplicada(escala(m, 3), 'escala 3');
  for (const chave of ['heroina', 'espectador']) {
    const evs = m.clientes[chave].eventos('escala');
    assert.equal(evs.length, 1, chave + ' recebe o evento');
    assert.deepEqual(evs[0].dados, {}, chave + ': sem campos');
    assert.equal(JSON.stringify(m.clientes[chave].msgs).includes('casaMAntes'), false, chave + ': sem o antes');
    assert.equal(m.clientes[chave].ultimo('ROOM_SNAPSHOT').mapa.casaM, 3, chave + ': o resultado no snapshot');
  }
  const [ev] = m.clientes.mestre.eventos('escala');
  assert.equal(ev.dados.soMestre.casaMAntes, 1.5);
  assert.equal(ev.dados.soMestre.casaM, 3);
  assert.equal(ev.dados.soMestre.vez.casasQuePaga, 3);
});

test('item 8: o «voltar» a um ponto anterior repõe a escala desse instante', () => {
  const m = mesaDaEscala();
  const seq = m.sala.depuracao.journalSeq();
  exigirAplicada(escala(m, 3), 'escala 3');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: seq }), 'voltar');
  assert.equal(estado(m).mapa.casaM, 1.5);
  assert.equal(m.clientes.heroina.ultimo('ROOM_SNAPSHOT').mapa.casaM, 1.5);
});
