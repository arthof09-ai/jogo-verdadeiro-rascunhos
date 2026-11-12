// Ordem 27 do CM-000009 — N23-1 (palavra do Mestre, 11/11/2026: SIM). A guarda do motor fecha-se:
//  - sha em falta de um dos lados (ou dos dois) = motor NÃO provado igual, TAMBÉM no restauro (pausa de manutenção
//    E-C11 em combate; evento `aviso_motor` no fim) e no `avisoMotor` da MASTER_VIEW — como já era no «Recomeçar»
//    (E-22-1, ordem 23);
//  - a guarda passa a cobrir também o `dmgVersao` e o `levelupSha` (uma diferença em qualquer um = motor não provado
//    igual).
// Comportamento visível como o que já existe: a recusa e o aviso só ao Mestre; a Party não recebe nada novo.
// Os testes marcados «falhava antes» falhavam no sala.js de 9c66c2a; os marcados «controlo» passavam.
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

const FALTA = Symbol('campo em falta');
/** Motor falso com os três campos de versão escolhidos (FALTA = campo em falta no módulo). */
function motor(campos = {}) {
  const { sha, dmg, levelup } = { sha: 'a'.repeat(64), dmg: 'falso-0', levelup: null, ...campos };
  const m = criarMotorFalso();
  if (sha === FALTA) delete m.MOTOR_SHA256; else m.MOTOR_SHA256 = sha;
  if (dmg === FALTA) delete m.DMG_VERSAO; else m.DMG_VERSAO = dmg;
  if (levelup === FALTA) delete m.LEVELUP_SHA; else m.LEVELUP_SHA = levelup;
  return m;
}
function ligar(sala, join, ip) {
  const r = sala.entrar(join, { ip });
  assert.equal(r.ok, true, 'entrou');
  sala.conexaoAberta(r.seatId);
  return r;
}
function emCombate(mot) {
  const m = montarMesa({ motor: mot });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  assert.equal(m.sala.depuracao.estado().fase, 'combate');
  return m;
}
function noFim(mot) {
  const m = emCombate(mot);
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' }), 'terminar');
  assert.equal(m.sala.depuracao.estado().fase, 'fim');
  return m;
}
function restaurar(m, mot) {
  return criarSala({ motores: mot, fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config: CONFIG(), restaurarDe: m.sala.exportar() });
}
const avisos = (sala) => sala.depuracao.eventos().filter((e) => e.tipo === 'aviso_motor');

/** Sala restaurada no fim: aviso no journal (só Mestre), avisoMotor na vista, «Recomeçar» recusado, Party sem nada. */
function exigirMotorNaoProvadoNoFim(sala2, { gravado, agora }) {
  const av = avisos(sala2);
  assert.equal(av.length, 1, 'um aviso_motor no journal, na hora do restauro');
  assert.deepEqual(av[0].dados, {}, 'nada nos dados públicos');
  assert.deepEqual(av[0].soMestre, { codigo: 'MOTOR_DIFERENTE', recomecar: 'recusado', motorGravado: gravado, motorAgora: agora });

  const rh = ligar(sala2, JOIN_HEROINA, '10.0.27.1');
  assert.ok(!rh.mensagens.some((x) => x.type === 'MASTER_VIEW' || 'avisoMotor' in x), 'a Party não recebe a vista');
  assert.ok(!rh.mensagens.some((x) => x.type === 'ROOM_EVENT' && x.tipo === 'aviso_motor'));
  const rm = ligar(sala2, JOIN_MESTRE, '10.0.27.2');
  const vista = rm.mensagens.find((x) => x.type === 'MASTER_VIEW');
  assert.deepEqual(vista.avisoMotor, av[0].soMestre, 'a vista do Mestre traz o mesmo aviso');

  const seqParty = lugarDe(sala2, 'jogadora').seq;
  const rev = lugarDe(sala2, 'mestre').revision;
  const saidas = sala2.receber(rm.seatId, { v: 2, type: 'MASTER_SUPERVISOR', op: 'recomecar', cmdId: 'rec-27', revision: rev });
  const rec = reciboDe(respostaA(saidas, rm.seatId));
  assert.equal(rec?.type, 'ROOM_REJECT');
  assert.equal(rec?.motivo, 'acao_invalida');
  assert.equal(sala2.depuracao.estado().fase, 'fim', 'a batalha não recomeça (E-C11)');
  const recusa = sala2.depuracao.eventos().filter((e) => e.tipo === 'recusa').at(-1);
  assert.match(recusa?.soMestre?.detalhe ?? '', /^MOTOR_DIFERENTE/, 'o porquê só ao Mestre');
  assert.equal(respostaA(saidas, rh.seatId).length, 0, 'a Party não recebe nada');
  assert.equal(lugarDe(sala2, 'jogadora').seq, seqParty, 'nem no fluxo dela');
}
/** Sala restaurada a meio da batalha: pausa de manutenção do motor (E-C11), sem aviso_motor. */
function exigirPausaDoMotor(m, sala2) {
  const est = sala2.depuracao.estado();
  assert.equal(est.fase, 'pausa', 'a mesa acorda em pausa de manutenção');
  assert.equal(est.pausa.origem, 'motor');
  assert.equal(est.pausa.motivo, 'manutencao');
  assert.equal(avisos(sala2).length, 0, 'em combate não há aviso_motor (como antes)');
  assert.ok(m.sala.depuracao.estado().fase === 'combate', 'a sala gravada estava em combate');
}

// ------------------------------------------------------------------ sha em falta no restauro e no avisoMotor

test('ordem 27 (N23-1, falhava antes): sala no fim gravada e restaurada SEM sha dos dois lados — aviso ao Mestre e vista com avisoMotor', () => {
  const sala2 = restaurar(noFim(motor({ sha: FALTA })), motor({ sha: FALTA }));
  exigirMotorNaoProvadoNoFim(sala2, { gravado: null, agora: null });
});

test('ordem 27 (N23-1, falhava antes): sala em combate gravada e restaurada SEM sha dos dois lados — pausa de manutenção do motor', () => {
  const m = emCombate(motor({ sha: FALTA }));
  exigirPausaDoMotor(m, restaurar(m, motor({ sha: FALTA })));
});

test('ordem 27 (N23-1, controlo): sha em falta só de um lado — aviso no fim e pausa em combate, como já era', () => {
  exigirMotorNaoProvadoNoFim(restaurar(noFim(motor({ sha: FALTA })), motor({ sha: 'e'.repeat(64) })), { gravado: null, agora: 'e'.repeat(64) });
  exigirMotorNaoProvadoNoFim(restaurar(noFim(motor({ sha: 'e'.repeat(64) })), motor({ sha: FALTA })), { gravado: 'e'.repeat(64), agora: null });
  const m = emCombate(motor({ sha: 'e'.repeat(64) }));
  exigirPausaDoMotor(m, restaurar(m, motor({ sha: FALTA })));
});

// ------------------------------------------------------------------ dmgVersao e levelupSha entram na guarda

test('ordem 27 (N23-1, falhava antes): o mesmo vlabSha mas outro dmgVersao — no fim, aviso e «Recomeçar» recusado', () => {
  const sha = 'a'.repeat(64);
  const sala2 = restaurar(noFim(motor({ dmg: 'falso-0' })), motor({ dmg: 'falso-1' }));
  exigirMotorNaoProvadoNoFim(sala2, { gravado: sha, agora: sha });
});

test('ordem 27 (N23-1, falhava antes): o mesmo vlabSha mas outro dmgVersao — em combate, pausa de manutenção', () => {
  const m = emCombate(motor({ dmg: 'falso-0' }));
  exigirPausaDoMotor(m, restaurar(m, motor({ dmg: 'falso-1' })));
});

test('ordem 27 (N23-1, falhava antes): dmgVersao em falta de um lado — motor não provado igual', () => {
  const sha = 'a'.repeat(64);
  exigirMotorNaoProvadoNoFim(restaurar(noFim(motor({ dmg: 'falso-0' })), motor({ dmg: FALTA })), { gravado: sha, agora: sha });
});

test('ordem 27 (N23-1, falhava antes): o mesmo vlabSha mas outro levelupSha (ou levelupSha só de um lado) — aviso e recusa no fim, pausa em combate', () => {
  const sha = 'a'.repeat(64);
  exigirMotorNaoProvadoNoFim(restaurar(noFim(motor({ levelup: 'b'.repeat(64) })), motor({ levelup: 'c'.repeat(64) })), { gravado: sha, agora: sha });
  exigirMotorNaoProvadoNoFim(restaurar(noFim(motor({ levelup: null })), motor({ levelup: 'c'.repeat(64) })), { gravado: sha, agora: sha });
  const m = emCombate(motor({ levelup: 'b'.repeat(64) }));
  exigirPausaDoMotor(m, restaurar(m, motor({ levelup: null })));
});

// ------------------------------------------------------------------ controlo: tudo igual → nada muda

test('ordem 27 (N23-1, controlo): vlabSha, dmgVersao e levelupSha iguais (levelupSha null dos dois lados, como em todos os motores do repositório) — sem aviso, sem pausa, «Recomeçar» funciona', () => {
  const sala2 = restaurar(noFim(motor()), motor());
  assert.equal(avisos(sala2).length, 0);
  const rm = ligar(sala2, JOIN_MESTRE, '10.0.27.9');
  assert.equal(rm.mensagens.find((x) => x.type === 'MASTER_VIEW').avisoMotor, null);
  const rev = lugarDe(sala2, 'mestre').revision;
  const rec = reciboDe(respostaA(sala2.receber(rm.seatId, { v: 2, type: 'MASTER_SUPERVISOR', op: 'recomecar', cmdId: 'rec-27c', revision: rev }), rm.seatId));
  assert.equal(rec?.type, 'ROOM_RECEIPT');
  assert.equal(rec?.estado, 'APLICADA');

  const c = emCombate(motor());
  const sala3 = restaurar(c, motor());
  assert.notEqual(sala3.depuracao.estado().pausa?.origem, 'motor', 'sem pausa do motor');
});
