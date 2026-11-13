// Ordem 35 do CM-000009 (13/11/2026), trabalho 1 — o defeito do «voltar» (registo N34-1).
// O «voltar» para um instante em que uma figura ainda não existia deixa na história os cartões nascidos depois,
// fechados «revertido» (delta REF_21/REF_24: nada se apaga), e esses cartões apontam para a figura que já não está
// no estado. A conferência da ordem 34 (N31-1, camada 2) exigia a figura de TODOS os cartões: o estado que o próprio
// servidor gravou era recusado no arranque seguinte e a sala nunca mais abria.
// A correcção: só os cartões ABERTOS validam a figura (são os únicos que o servidor volta a ler: o cartão pendente, a
// MASTER_VIEW e o MASTER_APPROVE só olham para os abertos). Os fechados são história: a forma continua conferida.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import { ErroJournal } from '../nucleo/journal.js';
import { jsonCanonico } from '../nucleo/util.js';
import { sha256Hex } from '../nucleo/sha256.js';
import { abrirSalaComJournal, envelopeJournal } from '../adaptadores/node/servidor-ws.js';
import { montarMesa, exigirAplicada, recibo, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const CONFIG = () => ({
  roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
  lugares: [
    { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
    { papel: 'mestre', nome: 'Mestre', pin: PIN },
  ],
});
const criarDe = (restaurarDe) => criarSala({
  motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config: CONFIG(), restaurarDe,
});
const assinado = (corpo) => {
  const t = jsonCanonico(corpo);
  return t + '\n' + 'sha256:' + sha256Hex(t) + '\n';
};
const corpoDe = (exportado) => JSON.parse(exportado.split('\n')[0]);

/**
 * O caminho do defeito, como o Mestre o faz: combate começado, o Orc posto, a heroína ataca-o com falha crítica (cartão
 * de desgraça aberto, alvo = o Orc) e o Mestre volta ao instante ANTES de pôr o Orc.
 */
function voltarParaAntesDoOrc() {
  const m = montarMesa();
  m.entrarTodos();
  exigirAplicada(m.mestre('MASTER_LOBBY_SET', { mapaId: 'arena-teste', criaturasDisponiveis: ['orc-teste'], npcsDisponiveis: [] }));
  exigirAplicada(m.mestre('MASTER_START'));
  const antesDoOrc = m.sala.depuracao.journalSeq();
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'orc-teste', casa: { x: 2, y: 3 } }));
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  m.motor.cfg.resultado = 'falha_critica';
  assert.equal(recibo(m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'fc-1' })).estado, 'AGUARDANDO_MESTRE');
  m.motor.cfg.resultado = 'acerto';
  const cartao = m.clientes.mestre.ultimo('MASTER_CARD');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: antesDoOrc }));
  return { m, orc, cartao };
}

test('ordem 35 (N34-1, falhava antes): o estado gravado depois de «voltar» para antes de uma figura volta a abrir', () => {
  const { m, orc, cartao } = voltarParaAntesDoOrc();
  const est = m.sala.depuracao.estado();
  // As condições do defeito: o Orc já não existe e o cartão dele ficou na história, fechado, a apontar para ele.
  assert.equal(est.figuras[orc], undefined, 'o Orc ainda não existia no instante');
  const historia = est.cartoes.find((c) => c.cartaoId === cartao.cartaoId);
  assert.equal(historia?.estado, 'fechado');
  assert.equal(historia?.decisao, 'revertido');
  assert.equal(historia?.alvoId, orc, 'o cartão fechado aponta para a figura que ainda não existe');

  const exportado = m.sala.exportar();
  let sala2;
  assert.doesNotThrow(() => { sala2 = criarDe(exportado); }, 'a sala reabre do journal que o próprio servidor gravou');
  assert.equal(sala2.depuracao.hashEstado(), m.sala.depuracao.hashEstado(), 'o mesmo estado, sem reparação');
  assert.deepEqual(sala2.depuracao.estado().cartoes, est.cartoes, 'a história dos cartões fica como estava');

  // E a sala continua jogável: o Mestre entra, pede a vista e volta a pôr o Orc.
  const r = sala2.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'mestre', pin: PIN }, { ip: '10.0.35.1' });
  assert.equal(r.ok, true);
  sala2.conexaoAberta(r.seatId);
  const vista = sala2.receber(r.seatId, { v: 2, type: 'MASTER_VIEW' }).find((s) => s.msg.type === 'MASTER_VIEW');
  assert.ok(vista, 'a MASTER_VIEW sai');
  const revision = r.mensagens.find((x) => typeof x.revision === 'number')?.revision ?? vista.msg.revision;
  const pos = sala2.receber(r.seatId, { v: 2, type: 'MASTER_PLACE', roomId: 'sala-teste', cmdId: 'cmd-35-1', revision, fichaId: 'orc-teste', casa: { x: 2, y: 3 } });
  const rec = pos.find((s) => s.seatId === r.seatId && s.msg.type === 'ROOM_RECEIPT')?.msg;
  assert.equal(rec?.estado, 'APLICADA', JSON.stringify(rec));
});

test('ordem 35 (N34-1, falhava antes): pelo adaptador, o arranque abre a sala (antes: recusada para sempre, os mesmos bytes)', () => {
  const { m } = voltarParaAntesDoOrc();
  const bytes = envelopeJournal(m.sala.exportar());
  const a = abrirSalaComJournal({ caminho: 'registo-MESTRE-ONLY-sala.json', criar: criarDe, invalidas: new Map(), ler: () => bytes });
  assert.equal(a.ok, true, `recusada: campo ${a.campo}: ${a.erro?.message}`);
  assert.equal(a.restaurada, true);
});

test('ordem 35 (N34-1, controlo): o cartão ABERTO continua a validar a figura; o fechado continua a ter a forma conferida', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  m.motor.cfg.resultado = 'falha_critica';
  m.intencao('heroina', { tipo: 'atacar', alvoId: m.clientes.heroina.idPorNome('Orc'), arma: 'chicote-teste' });
  const base = corpoDe(m.sala.exportar());
  const i = base.estado.cartoes.findIndex((c) => c.estado === 'aberto');
  assert.ok(i >= 0, 'há um cartão aberto');
  const recusa = (mexer, caminho, rotulo) => {
    const c = JSON.parse(JSON.stringify(base));
    mexer(c.estado.cartoes[i]);
    let erro = null;
    try { criarDe(assinado(c)); } catch (e) { erro = e; }
    assert.ok(erro instanceof ErroJournal, `${rotulo}: veio ${erro?.name}: ${erro?.message}`);
    assert.equal(erro.caminho, caminho, rotulo);
  };
  const abre = (mexer, rotulo) => {
    const c = JSON.parse(JSON.stringify(base));
    mexer(c.estado.cartoes[i]);
    assert.doesNotThrow(() => criarDe(assinado(c)), rotulo);
  };
  recusa((c) => { c.figuraId = 'f-ninguem'; }, `cartoes.${i}.figuraId`, 'aberto, figura que não existe');
  recusa((c) => { c.alvoId = 'f-ninguem'; }, `cartoes.${i}.alvoId`, 'aberto, alvo que não existe');
  recusa((c) => { c.estado = 'fechado'; c.decisao = 'revertido'; c.figuraId = 42; }, `cartoes.${i}.figuraId`, 'fechado, figuraId que não é texto');
  recusa((c) => { c.estado = 'fechado'; c.decisao = 'revertido'; c.alvoId = ''; }, `cartoes.${i}.alvoId`, 'fechado, alvoId vazio');
  abre((c) => { c.estado = 'fechado'; c.decisao = 'revertido'; c.figuraId = 'f-ninguem'; c.alvoId = 'f-ninguem'; }, 'fechado, figuras que não existem: é história');
});
