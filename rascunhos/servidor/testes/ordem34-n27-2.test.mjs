// Ordem 34 do CM-000009 — N27-2 (sentença da bancada, 2026-11-12): o contrato D-35/D-36 ganha UM campo novo,
// `quaisDiferem` — lista de 1 a 3 valores, sem repetidos, só "vlabSha", "dmgVersao", "levelupSha" e nesta ordem fixa
// (os NOMES dos campos que diferem, nunca os valores). motorGravado/motorAgora ficam exactamente como estão.
// Vai no soMestre do evento `aviso_motor` (D-35) e no `avisoMotor` da MASTER_VIEW (D-36); só ao Mestre.
// «Diferem» é a mesma regra da guarda (motorProvadoIgual, N23-1): o vlabSha difere se falta de um dos lados ou se é
// outro; o dmgVersao e o levelupSha diferem se não são iguais (null dos dois lados = igual, N27-1 não muda).
// Os testes de correcção falhavam antes (o campo não existia); o de controlo passava.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import { montarMesa, exigirAplicada, rngDeterministico, relogio, fichasDeTeste, despejar, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
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
const NOMES = ['vlabSha', 'dmgVersao', 'levelupSha'];

const FALTA = Symbol('campo em falta');
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
function noFim(mot) {
  const m = montarMesa({ motor: mot });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' }), 'terminar');
  assert.equal(m.sala.depuracao.estado().fase, 'fim');
  return m;
}
function restaurar(m, mot) {
  return criarSala({ motores: mot, fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config: CONFIG(), restaurarDe: m.sala.exportar() });
}

/** Grava com `antes`, restaura com `agora`; devolve o soMestre do aviso_motor, o avisoMotor da vista e o que a Party viu. */
function avisoDe(antes, agora) {
  const m = noFim(motor(antes));
  const gravados = m.sala.depuracao.estado().motores;
  const sala2 = restaurar(m, motor(agora));
  const ev = sala2.depuracao.eventos().filter((e) => e.tipo === 'aviso_motor');
  assert.equal(ev.length, 1, 'um aviso_motor no restauro');
  const rm = ligar(sala2, JOIN_MESTRE, '10.0.27.2');
  const vista = rm.mensagens.find((x) => x.type === 'MASTER_VIEW');
  despejar('sai', 'mestre', vista); // o tráfego conferido com o schema (job protocolo)
  const rh = ligar(sala2, JOIN_HEROINA, '10.0.27.1');
  return { evento: ev[0].soMestre, vista: vista.avisoMotor, party: rh.mensagens, gravados };
}

const CASOS = [
  ['só o vlabSha', {}, { sha: 'b'.repeat(64) }, ['vlabSha']],
  ['só o dmgVersao', {}, { dmg: 'falso-1' }, ['dmgVersao']],
  ['só o levelupSha', {}, { levelup: 'c'.repeat(64) }, ['levelupSha']],
  ['vlabSha e levelupSha', {}, { sha: 'b'.repeat(64), levelup: 'c'.repeat(64) }, ['vlabSha', 'levelupSha']],
  ['dmgVersao e levelupSha', { levelup: 'd'.repeat(64) }, { dmg: 'falso-1', levelup: 'c'.repeat(64) }, ['dmgVersao', 'levelupSha']],
  ['os três', {}, { sha: 'b'.repeat(64), dmg: 'falso-1', levelup: 'c'.repeat(64) }, ['vlabSha', 'dmgVersao', 'levelupSha']],
  ['vlabSha em falta agora', {}, { sha: FALTA }, ['vlabSha']],
  ['vlabSha em falta na gravação', { sha: FALTA }, {}, ['vlabSha']],
  ['dmgVersao em falta agora', {}, { dmg: FALTA }, ['dmgVersao']],
];

for (const [rotulo, antes, agora, esperado] of CASOS) {
  test(`ordem 34 (N27-2, falhava antes): ${rotulo} → quaisDiferem ${JSON.stringify(esperado)}, no evento e na vista`, () => {
    const { evento, vista, party, gravados } = avisoDe(antes, agora);
    assert.deepEqual(evento.quaisDiferem, esperado, 'no soMestre do aviso_motor (D-35)');
    assert.deepEqual(vista.quaisDiferem, esperado, 'no avisoMotor da vista (D-36)');
    assert.deepEqual(vista, evento, 'a vista e o evento dizem o mesmo');
    // motorGravado/motorAgora exactamente como estão (os dois são o vlabSha).
    assert.equal(vista.motorGravado, gravados?.vlabSha ?? null);
    assert.equal(vista.motorAgora, agora.sha === FALTA ? null : (agora.sha ?? 'a'.repeat(64)));
    assert.deepEqual(Object.keys(vista).sort(), ['codigo', 'motorAgora', 'motorGravado', 'quaisDiferem', 'recomecar'], 'um campo novo, e só um');
    // Nomes, nunca valores; sem repetidos; na ordem fixa.
    assert.ok(vista.quaisDiferem.every((n) => NOMES.includes(n)));
    assert.deepEqual(vista.quaisDiferem, NOMES.filter((n) => vista.quaisDiferem.includes(n)));
    // Nada disto chega à Party.
    assert.ok(!JSON.stringify(party).includes('quaisDiferem'), 'a Party não vê o campo');
    assert.ok(!party.some((x) => x.type === 'ROOM_EVENT' && x.tipo === 'aviso_motor'));
  });
}

test('ordem 34 (N27-2, controlo): o mesmo motor (dmgVersao/levelupSha null dos dois lados = igual) — sem aviso', () => {
  const m = noFim(motor({ dmg: null, levelup: null }));
  const sala2 = restaurar(m, motor({ dmg: null, levelup: null }));
  assert.equal(sala2.depuracao.eventos().filter((e) => e.tipo === 'aviso_motor').length, 0);
  const rm = ligar(sala2, JOIN_MESTRE, '10.0.27.3');
  assert.equal(rm.mensagens.find((x) => x.type === 'MASTER_VIEW').avisoMotor, null);
});
