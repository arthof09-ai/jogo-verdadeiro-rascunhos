// Ordem 21 do CM-000009 — as decisões do Mestre e do coordenador sobre os omissos N18/N19 (11/11/2026).
//
//  N18-2  (Mestre: SIM, avisar) a sala restaurada no fim com um motor de outra versão: o «Recomeçar» vai ser recusado
//         (17-3). O Mestre passa a ser avisado NA HORA do restauro, com um evento novo do journal (`aviso_motor`), só
//         dele; a Party não recebe nada. Com o mesmo motor, ou fora do fim, não há aviso.
//  N19-2  (Mestre: SIM, errata) o schema ROOM_JOIN deixa de exigir `roomId` (o servidor nunca o exigiu; o cliente só o
//         conhece do ROOM_WELCOME). Com o `roomId` certo ou sem ele, o JOIN entra igual.
//  N19-1  (coordenador) o exemplo MASTER_EXPORT mostra `conteudo` como o texto que o servidor manda (journal.exportar()).
//
// Os testes que lêem ../protocolo saltam no passo só de leitura do job servidor (a permissão só abre rascunhos/servidor);
// correm no job protocolo do CI e localmente.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { criarSala } from '../nucleo/sala.js';
import { montarMesa, exigirAplicada, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS, Cliente } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const CONFIG = () => ({
  roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
  lugares: [
    { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
    { papel: 'mestre', nome: 'Mestre', pin: PIN },
  ],
});

function criarDe(restaurarDe, motor = criarMotorFalso()) {
  return criarSala({ motores: motor, fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config: CONFIG(), restaurarDe });
}
function motorOutro() {
  const m = criarMotorFalso();
  m.MOTOR_SHA256 = 'e'.repeat(64);
  return m;
}

const JOIN_HEROINA = { v: 2, type: 'ROOM_JOIN', papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina };
const JOIN_MESTRE = { v: 2, type: 'ROOM_JOIN', papel: 'mestre', pin: PIN };
const lugarDe = (sala, papel) => Object.values(sala.depuracao.estado().lugares).find((s) => s.papel === papel);

function sessao() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 12, y: 2 }]]);
  const h = m.clientes.heroina;
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: h.idPorNome('Orc'), arma: 'chicote-teste' }));
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  return m;
}
function sessaoNoFim() {
  const m = sessao();
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' }), 'terminar');
  return m;
}

/** O cliente do Mestre (o da mesa original) volta a ligar-se ao servidor restaurado com o token e o lastSeq dele. */
function mestreVolta(sala2, m) {
  const c = m.clientes.mestre;
  const volta = new Cliente('mestre');
  const r = sala2.entrar({ v: 2, type: 'ROOM_JOIN', papel: 'mestre', seatToken: c.token, lastSeq: c.ultimoSeq }, { ip: '10.0.21.2' });
  assert.equal(r.ok, true, 'o Mestre volta a entrar com o token');
  for (const x of r.mensagens) volta.receber(x);
  return volta;
}

// ------------------------------------------------------------------ N18-2: aviso ao Mestre na hora do restauro

test('ordem 21 (N18-2): restaurar no fim com motor de outra versão avisa o Mestre logo (evento aviso_motor, só dele)', () => {
  const m = sessaoNoFim();
  const exportado = m.sala.exportar();
  const seqParty = m.clientes.heroina.ultimoSeq;

  const sala2 = criarDe(exportado, motorOutro());
  assert.equal(sala2.depuracao.estado().fase, 'fim');
  const aviso = sala2.depuracao.eventos().filter((e) => e.tipo === 'aviso_motor');
  assert.equal(aviso.length, 1, 'um evento aviso_motor no journal, na hora do restauro');
  assert.equal(aviso[0].soMestre?.codigo, 'MOTOR_DIFERENTE');
  assert.equal(aviso[0].soMestre?.recomecar, 'recusado');
  assert.equal(aviso[0].soMestre?.motorGravado, m.sala.depuracao.estado().motores.vlabSha);
  assert.equal(aviso[0].soMestre?.motorAgora, 'e'.repeat(64));
  assert.deepEqual(aviso[0].dados, {}, 'nada nos dados públicos');

  // O Mestre recebe-o pelo seu fluxo ao voltar (o cliente dele religa-se com o token e o lastSeq).
  const volta = mestreVolta(sala2, m);
  const ev = volta.eventos('aviso_motor');
  assert.equal(ev.length, 1, 'o Mestre recebe o ROOM_EVENT aviso_motor ao voltar');
  assert.equal(ev[0].dados.soMestre.codigo, 'MOTOR_DIFERENTE');

  // A Party não recebe nada: o seq dela não mexe e o fluxo dela não tem o tipo.
  assert.equal(lugarDe(sala2, 'jogadora').seq, seqParty, 'o fluxo da Party fica igual');
  const rh = sala2.entrar(JOIN_HEROINA, { ip: '10.0.21.1' });
  assert.equal(rh.ok, true);
  assert.ok(!rh.mensagens.some((x) => x.type === 'ROOM_EVENT' && x.tipo === 'aviso_motor'), 'a Party não vê o aviso');
  assert.ok(!JSON.stringify(rh.mensagens).includes('MOTOR_DIFERENTE'), 'nem o código');
});

test('ordem 21 (N18-2): o aviso fica no journal — exportar e restaurar outra vez com o motor certo não o apaga', () => {
  const m = sessaoNoFim();
  const sala2 = criarDe(m.sala.exportar(), motorOutro());
  const sala3 = criarDe(sala2.exportar());
  assert.equal(sala3.depuracao.eventos().filter((e) => e.tipo === 'aviso_motor').length, 1, 'o aviso de antes fica; não nasce outro');
});

test('ordem 21 (N18-2, controlo): o mesmo motor — restaurar no fim não avisa nada e não escreve no journal', () => {
  const m = sessaoNoFim();
  const antes = m.sala.depuracao.eventos().length;
  const sala2 = criarDe(m.sala.exportar());
  assert.equal(sala2.depuracao.eventos().length, antes, 'restaurar com o mesmo motor não escreve nada');
});

test('ordem 21 (N18-2, controlo): em combate o motor de outra versão continua a ser a pausa de manutenção (E-C11), sem aviso_motor', () => {
  const m = sessao();
  const sala2 = criarDe(m.sala.exportar(), motorOutro());
  const e = sala2.depuracao.estado();
  assert.equal(e.fase, 'pausa');
  assert.equal(e.pausa.origem, 'motor');
  assert.equal(sala2.depuracao.eventos().filter((x) => x.tipo === 'aviso_motor').length, 0);
});

// ------------------------------------------------------------------ N19-2: errata — JOIN sem roomId

const PROTOCOLO_V2 = new URL('../../protocolo/v2/', import.meta.url);
function lerProtocolo(nome) {
  return JSON.parse(readFileSync(new URL(nome, PROTOCOLO_V2), 'utf8'));
}
let SEM_PROTOCOLO = false;
try {
  readFileSync(new URL('ROOM_JOIN.schema.json', PROTOCOLO_V2));
} catch (e) {
  SEM_PROTOCOLO = 'sem leitura de ../protocolo (passo só de leitura do job servidor): corre no job protocolo do CI (' + (e.code ?? e.message) + ')';
}

test('ordem 21 (N19-2): o schema ROOM_JOIN não exige roomId (errata: o cliente só o aprende no ROOM_WELCOME)', { skip: SEM_PROTOCOLO }, () => {
  const s = lerProtocolo('ROOM_JOIN.schema.json');
  assert.ok(!s.required.includes('roomId'), 'roomId fora do required');
  assert.ok(s.properties.roomId, 'roomId continua permitido (reentrada depois de um WELCOME)');
  assert.match(s.description, /N19-2/, 'a errata está registada no schema');
});

test('ordem 21 (N19-2, controlo): o servidor aceita o JOIN sem roomId e com o roomId certo', () => {
  const sala = criarDe(null);
  const sem = sala.entrar(JOIN_MESTRE, { ip: '10.0.21.3' });
  assert.equal(sem.ok, true, 'sem roomId: entra');
  assert.equal(sem.mensagens[0].type, 'ROOM_WELCOME');
  const com = sala.entrar({ ...JOIN_HEROINA, roomId: sem.mensagens[0].roomId }, { ip: '10.0.21.4' });
  assert.equal(com.ok, true, 'com o roomId do WELCOME: entra');
});

// ------------------------------------------------------------------ N19-1: o exemplo do MASTER_EXPORT

test('ordem 21 (N19-1): o exemplo MASTER_EXPORT tem conteudo em texto, como o servidor o manda', { skip: SEM_PROTOCOLO }, () => {
  const casos = lerProtocolo('exemplos/MASTER_EXPORT.json');
  assert.equal(casos.length, 1);
  const c = casos[0].mensagem.conteudo;
  assert.equal(typeof c, 'string', 'conteudo é texto (journal.exportar())');
  assert.match(c, /^[^\n]+\n[^\n]+\n$/, 'a forma do exportar: corpo, nova linha, assinatura, nova linha');
});

test('ordem 21 (N19-1, controlo): o MASTER_EXPORT pelo protocolo leva o texto de journal.exportar()', () => {
  const m = sessaoNoFim();
  m.mestre('MASTER_SUPERVISOR', { op: 'exportar' });
  const x = m.clientes.mestre.ultimo('MASTER_EXPORT');
  assert.ok(x, 'o Mestre recebe o MASTER_EXPORT');
  assert.equal(x.marca, 'MESTRE-ONLY');
  assert.equal(typeof x.conteudo, 'string');
  assert.equal(x.conteudo, m.sala.exportar(), 'o mesmo texto que a sala exporta');
  assert.match(x.conteudo, /^[^\n]+\n[^\n]+\n$/);
  assert.equal(m.clientes.heroina.ultimo('MASTER_EXPORT'), null, 'nunca à Party');
});
