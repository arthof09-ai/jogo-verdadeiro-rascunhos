// L1 e L2 do desenho JV3.1 (ecrã do Mestre), pedidos pela revisão do Muse de 08/11/2026 (I0004).
// L1: a vista do Mestre traz, por figura, o nome verdadeiro, o nome público e os totais de vida e de PA.
// L2: o cartão de desgraça traz a lista que o Mestre pode escolher no «Editar»; fora dela, o servidor recusa.
// Controlo positivo do canário: o que a Party nunca vê (privacidade.test.mjs) TEM de estar na vista do Mestre.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada, recibo, FIXTURE } from './ajudantes.mjs';

const fichaPorId = Object.fromEntries((FIXTURE.fichas ?? FIXTURE).map((f) => [f.id, f]));
const LISTA = ['cai', 'arma-cai', 'arma-quebra', 'acerta-se', 'quebra-corpo', 'acerta-amigo', 'nenhuma'];

function pedirVista(m) {
  const r = m.enviar('mestre', { type: 'MASTER_VIEW' });
  const v = r.find((x) => x.type === 'MASTER_VIEW');
  assert.ok(v, 'o Mestre recebe a vista');
  return v;
}

test('L1: antes do START, a vista do Mestre já tem a heroína (não colocada) com os totais e os nomes da ficha', () => {
  const m = montarMesa();
  m.entrarTodos();
  const v = pedirVista(m);
  const her = v.mestre.figuras.find((f) => f.fichaId === 'heroina-teste');
  assert.ok(her, 'a heroína está nas figuras do Mestre');
  assert.equal(her.colocada, false);
  assert.equal(her.vidaTotal, fichaPorId['heroina-teste'].vidaTotal);
  assert.equal(her.paTotal, fichaPorId['heroina-teste'].paTotal);
  assert.equal(her.nome, fichaPorId['heroina-teste'].nome);
  assert.equal(typeof her.nomePublico, 'string');
});

test('L1: em combate, cada figura do Mestre tem vidaActual/vidaTotal e PA gasto/PA total; a criatura traz o nome verdadeiro', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  const v = pedirVista(m);
  for (const f of v.mestre.figuras) {
    const ficha = fichaPorId[f.fichaId];
    assert.equal(f.vidaTotal, ficha.vidaTotal, `vidaTotal de ${f.fichaId}`);
    assert.equal(f.paTotal, ficha.paTotal, `paTotal de ${f.fichaId}`);
    assert.ok(Number.isInteger(f.vidaActual) && Number.isInteger(f.paGasto));
  }
  const orc = v.mestre.figuras.find((f) => f.fichaId === 'orc-teste');
  assert.equal(orc.nome, 'Orc Verdadeiro Teste', 'o nome verdadeiro só vive aqui');
  assert.equal(orc.nomePublico, 'Orc');
  assert.equal(orc.vidaTotal, 7777, 'controlo positivo do canário 7777');
});

test('L1: a Party continua sem totais nem nomes verdadeiros de ninguém além dela (o snapshot da heroína)', () => {
  const m = montarMesa({ comAliada: true, comEspectador: true });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  for (const chave of ['heroina', 'aliada', 'espectador']) {
    const snap = m.clientes[chave].ultimo('ROOM_SNAPSHOT');
    assert.ok(snap, `${chave} tem snapshot`);
    assert.equal(snap.mestre, undefined, `${chave} não recebe o bloco do Mestre`);
    const texto = JSON.stringify(m.clientes[chave].msgs);
    assert.ok(!texto.includes('Orc Verdadeiro'), `${chave}: sem o nome verdadeiro`);
    assert.ok(!texto.includes('7777'), `${chave}: sem a vida total do orc`);
  }
});

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
  return { m, h, cartao: m.clientes.mestre.ultimo('MASTER_CARD') };
}
const abertos = (m) => m.sala.depuracao.estado().cartoes.filter((c) => c.estado === 'aberto');

test('L2: o cartão de desgraça traz a lista do «Editar» (6 desgraças + «nenhuma»), pela ordem', () => {
  const { cartao } = cartaoDeDesgraca();
  assert.equal(cartao.tipo, 'desgraca');
  assert.deepEqual(cartao.desgracas, LISTA);
});

test('L2: editar com uma desgraça da lista aplica; com uma de fora, o servidor recusa e o cartão fica aberto', () => {
  const { m, cartao } = cartaoDeDesgraca();
  const r = m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'voar' } });
  const rec = recibo(r);
  assert.ok(rec && (rec.type === 'ROOM_REJECT' || rec.estado === 'RECUSADA'), 'fora da lista: recusado');
  assert.equal(abertos(m).length, 1, 'o cartão continua por decidir');
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'editar', edicao: { desgraca: 'nenhuma' } }));
  assert.equal(abertos(m).length, 0);
});

test('L2: os cartões que não são de desgraça levam a lista a null', () => {
  const m = montarMesa({ modoPadrao: 'semi' });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  // A heroína passa a vez; o orc (semi) propõe → cartão «ia».
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  const c = m.clientes.mestre.ultimo('MASTER_CARD');
  assert.equal(c?.tipo, 'ia');
  assert.equal(c.desgracas, null);
});

// L8 do desenho JV3.1 (I0004, 08/11/2026): o servidor diz ao Mestre a que pontos o «voltar» aceita ir.
test('L8: a vista do Mestre traz os pontos de «voltar», do mais novo ao mais velho, todos antes do ponto actual', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  const v = pedirVista(m);
  assert.ok(Array.isArray(v.pontos) && v.pontos.length > 0, 'há pontos');
  assert.ok(v.pontos.length <= 50);
  for (let i = 0; i < v.pontos.length; i++) {
    const p = v.pontos[i];
    assert.ok(p.journalSeq < v.journalSeq, 'nunca o ponto actual (o servidor recusa-o)');
    if (i > 0) assert.ok(p.journalSeq < v.pontos[i - 1].journalSeq, 'do mais novo ao mais velho');
    assert.ok(Array.isArray(p.tipos) && p.tipos.length > 0);
    assert.ok(Number.isInteger(p.rodada));
  }
  const inicial = v.pontos.find((p) => p.journalSeq === 0);
  assert.deepEqual(inicial?.tipos, ['inicio'], 'o ponto inicial está na lista');
});

test('L8: o «voltar» aceita qualquer ponto da lista e recusa o ponto actual', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  const v = pedirVista(m);
  const actual = m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: v.journalSeq });
  assert.ok(recibo(actual)?.type === 'ROOM_REJECT' || recibo(actual)?.estado === 'RECUSADA', 'o ponto actual é recusado');
  const alvo = v.pontos[Math.min(1, v.pontos.length - 1)];
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: alvo.journalSeq }), 'voltar a um ponto da lista');
  const depois = pedirVista(m);
  assert.ok(depois.pontos.some((p) => p.journalSeq === alvo.journalSeq), 'o ponto continua na lista (o journal não apaga)');
});

test('L8: os pontos só vão ao Mestre (nenhuma mensagem da Party os leva)', () => {
  const m = montarMesa({ comAliada: true, comEspectador: true });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  pedirVista(m);
  for (const chave of ['heroina', 'aliada', 'espectador']) {
    for (const msg of m.clientes[chave].msgs) assert.equal(msg.pontos, undefined, `${chave} recebeu pontos em ${msg.type}`);
  }
});
