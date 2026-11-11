// Ordem 23 do CM-000009 — E-22-1 (dívida registada na ordem 22, item 3): a guarda de versão do «Recomeçar»
// (recomecarBatalha) comparava só o vlabSha, e null === null passava — uma sala sem sha registado não se distinguia de
// uma sala com o mesmo motor. Regra desta ordem: sha em falta de QUALQUER um dos lados = motor NÃO provado igual =
// a recusa aplica-se (acao_invalida, MOTOR_DIFERENTE só ao Mestre), como na recusa por versão diferente (17-3).
// O 1.º teste (a: null dos dois lados) falhava antes (conferido com o sala.js de 6697f37); os outros (a: falta só de
// um lado; b; c) são controlo e passavam antes.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import { montarMesa, exigirAplicada, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const CONFIG = () => ({
  roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
  lugares: [
    { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
    { papel: 'mestre', nome: 'Mestre', pin: PIN },
  ],
});
const JOIN_HEROINA = { v: 2, type: 'ROOM_JOIN', papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina };
const JOIN_MESTRE = { v: 2, type: 'ROOM_JOIN', papel: 'mestre', pin: PIN };
const lugarDe = (sala, papel) => Object.values(sala.depuracao.estado().lugares).find((s) => s.papel === papel);
const respostaA = (saidas, seatId) => saidas.filter((s) => s.seatId === seatId).map((s) => s.msg);
const reciboDe = (msgs) => msgs.find((x) => x.type === 'ROOM_RECEIPT' || x.type === 'ROOM_REJECT') ?? null;

function motorSemSha() {
  const m = criarMotorFalso();
  delete m.MOTOR_SHA256;
  return m;
}
function motorCom(sha) {
  const m = criarMotorFalso();
  m.MOTOR_SHA256 = sha;
  return m;
}
function ligar(sala, join, ip) {
  const r = sala.entrar(join, { ip });
  assert.equal(r.ok, true, 'entrou');
  sala.conexaoAberta(r.seatId);
  return r;
}
/** Sessão terminada (fim), gravada com o motor dado. */
function salaNoFim(motor) {
  const m = montarMesa({ motor });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' }), 'terminar');
  assert.equal(m.sala.depuracao.estado().fase, 'fim');
  return m;
}
function restaurar(m, motor) {
  return criarSala({ motores: motor, fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config: CONFIG(), restaurarDe: m.sala.exportar() });
}
/** O Mestre pede o «Recomeçar» na sala restaurada; devolve o recibo, a Party e o seq dela. */
function recomecar(sala2, cmdId) {
  const rh = ligar(sala2, JOIN_HEROINA, '10.0.9.1');
  const rm = ligar(sala2, JOIN_MESTRE, '10.0.9.2');
  const seqParty = lugarDe(sala2, 'jogadora').seq;
  const rev = lugarDe(sala2, 'mestre').revision;
  const saidas = sala2.receber(rm.seatId, { v: 2, type: 'MASTER_SUPERVISOR', op: 'recomecar', cmdId, revision: rev });
  return { rec: reciboDe(respostaA(saidas, rm.seatId)), party: respostaA(saidas, rh.seatId), seqParty };
}
function exigirRecusaMotor(sala2, r) {
  assert.equal(r.rec?.type, 'ROOM_REJECT');
  assert.equal(r.rec?.motivo, 'acao_invalida');
  assert.equal(sala2.depuracao.estado().fase, 'fim', 'a batalha não recomeça (E-C11)');
  const recusa = sala2.depuracao.eventos().filter((e) => e.tipo === 'recusa').at(-1);
  assert.match(recusa?.soMestre?.detalhe ?? '', /^MOTOR_DIFERENTE/, 'o porquê só ao Mestre');
  assert.equal(r.party.length, 0, 'a Party não recebe nada');
  assert.equal(lugarDe(sala2, 'jogadora').seq, r.seqParty, 'nem no fluxo dela');
}

// ------------------------------------------------------------------ (a) sha em falta → recusa

test('ordem 23 (E-22-1 a): sala gravada sem vlabSha, restaurada com o mesmo motor sem sha — o «Recomeçar» é recusado', () => {
  const m = salaNoFim(motorSemSha());
  assert.equal(m.sala.depuracao.estado().motores?.vlabSha ?? null, null, 'gravada sem sha');
  const sala2 = restaurar(m, motorSemSha());
  exigirRecusaMotor(sala2, recomecar(sala2, 'rec-a1'));
});

test('ordem 23 (E-22-1 a): sha em falta só de um lado (gravado ou agora) — recusa', () => {
  const s1 = restaurar(salaNoFim(motorSemSha()), motorCom('e'.repeat(64)));
  exigirRecusaMotor(s1, recomecar(s1, 'rec-a2'));
  const s2 = restaurar(salaNoFim(motorCom('e'.repeat(64))), motorSemSha());
  exigirRecusaMotor(s2, recomecar(s2, 'rec-a3'));
});

// ------------------------------------------------------------------ (b) sha presente e igual → como hoje

test('ordem 23 (E-22-1 b, controlo): sha presente e igual dos dois lados — o «Recomeçar» funciona como antes', () => {
  const sala2 = restaurar(salaNoFim(motorCom('e'.repeat(64))), motorCom('e'.repeat(64)));
  const r = recomecar(sala2, 'rec-b1');
  assert.equal(r.rec?.type, 'ROOM_RECEIPT');
  assert.equal(r.rec?.estado, 'APLICADA');
  assert.equal(sala2.depuracao.estado().fase, 'combate');
  // E numa sala nunca restaurada, com o motor de sempre (com sha), também.
  const m = salaNoFim(criarMotorFalso());
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar sem restauro');
  assert.equal(m.sala.depuracao.estado().fase, 'combate');
});

// ------------------------------------------------------------------ (c) sha presente e diferente → recusa, como hoje

test('ordem 23 (E-22-1 c, controlo): sha presente e diferente — recusa, como hoje', () => {
  const sala2 = restaurar(salaNoFim(motorCom('f'.repeat(64))), motorCom('e'.repeat(64)));
  exigirRecusaMotor(sala2, recomecar(sala2, 'rec-c1'));
});
