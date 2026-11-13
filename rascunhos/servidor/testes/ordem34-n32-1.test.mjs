// Ordem 34 do CM-000009 — N32-1 (sentença da bancada, 2026-11-12): a fila de MASTER_ALERTA que não se perde.
//  - cobre as duas quedas: a ligação do Mestre em baixo E o reinício do servidor;
//  - cada MASTER_ALERTA (bloqueio_join, segunda_ligacao e os que vierem) entra na fila esteja o Mestre ligado ou não,
//    com id único, número de ordem e hora;
//  - fila por sala, persistente, em ficheiro próprio separado do journal e do estado de jogo; sobrevive ao reinício;
//  - 100 alertas por sala, 7 dias de retenção; o 101.º tira o mais antigo; o que expira também é perdido; toda a perda
//    soma num contador e o próximo bloco abre com «perdidos por limite: N» — nunca perda silenciosa;
//  - entrega: quando o Mestre liga e pede a MASTER_VIEW, a fila entrega por ordem, antes de qualquer alerta novo, num
//    só bloco (MASTER_ALERTAS); o servidor só retira cada alerta com a confirmação (MASTER_ALERTA_ACK) por id; a
//    ligação que cai antes de confirmar recebe-os outra vez na seguinte (pelo menos uma vez);
//  - só o Mestre recebe alertas; nada disto toca a Party.
// Os testes de correcção falhavam antes (não havia fila: o alerta saía só às ligações vivas do Mestre).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import { criarFilaAlertas, ErroFilaAlertas, MAX_ALERTAS, RETENCAO_MS } from '../nucleo/fila-alertas.js';
import { criarServidor, criarGravadorAlertas } from '../adaptadores/node/servidor-ws.js';
import { montarMesa, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';
import { ligarWs, mensagensWs } from './ajudantes-ws.mjs';

const JOIN_MESTRE = { papel: 'mestre', pin: PIN };
const JOIN_HEROINA = { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina };
const ERRADA = { papel: 'jogadora', nome: 'Heroína Teste', senha: 'senha-errada' };
const RE_ID = /^[A-Za-z0-9_-]{1,64}$/;

/** Cinco entradas erradas do mesmo IP: o travão dispara (alvo ip e alvo lugar) = dois alertas. */
function travar(m, ip = '10.0.32.9') {
  for (let i = 0; i < 5; i++) assert.equal(m.entrar('intrusa', ERRADA, ip).ok, false);
}
const blocos = (c) => c.msgs.filter((x) => x.type === 'MASTER_ALERTAS');
const confirmar = (m, bloco) => m.enviar('mestre', { type: 'MASTER_ALERTA_ACK', ids: bloco.alertas.map((a) => a.id), perdidos: bloco.perdidos });

test('ordem 34 (N32-1, falhava antes): o Mestre em baixo — os alertas ficam na fila e chegam num só bloco quando ele entra', () => {
  const m = montarMesa({ comEspectador: true });
  m.entrar('heroina', JOIN_HEROINA, '10.0.32.1');
  m.entrar('espectador', { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador }, '10.0.32.2');
  travar(m); // o Mestre ainda não entrou: antes desta ordem, os dois alertas perdiam-se aqui
  const r = m.entrar('mestre', JOIN_MESTRE, '10.0.32.3');
  assert.ok(r.ok);
  const msgs = m.clientes.mestre.msgs;
  const iVista = msgs.findIndex((x) => x.type === 'MASTER_VIEW');
  const iBloco = msgs.findIndex((x) => x.type === 'MASTER_ALERTAS');
  assert.ok(iVista >= 0 && iBloco > iVista, 'o bloco vem com a MASTER_VIEW (logo a seguir)');
  assert.equal(blocos(m.clientes.mestre).length, 1, 'um bloco só');
  const b = msgs[iBloco];
  assert.equal(b.perdidos, 0);
  assert.equal(b.alertas.length, 2, 'os dois alertas do travão');
  assert.deepEqual(b.alertas.map((a) => [a.motivo, a.alvo]), [['bloqueio_join', 'ip'], ['bloqueio_join', 'lugar']], 'por ordem');
  assert.deepEqual(b.alertas.map((a) => a.ordem), [1, 2], 'número de ordem');
  for (const a of b.alertas) {
    assert.match(a.id, RE_ID, 'id opaco');
    assert.ok(!Number.isNaN(Date.parse(a.hora)) && a.hora.endsWith('Z'), 'hora ISO');
  }
  assert.notEqual(b.alertas[0].id, b.alertas[1].id, 'ids únicos');
  assert.ok(!msgs.some((x) => x.type === 'MASTER_ALERTA'), 'nenhum alerta solto: vão no bloco');
  // Nada disto toca a Party.
  for (const chave of ['heroina', 'espectador']) {
    const texto = JSON.stringify(m.clientes[chave].msgs);
    assert.ok(!texto.includes('MASTER_ALERTA') && !texto.includes('bloqueio_join'), `${chave}: nada de alertas`);
  }
});

test('ordem 34 (N32-1, falhava antes): sem confirmação os alertas voltam na ligação seguinte; confirmados por id, saem', () => {
  const m = montarMesa();
  m.entrar('heroina', JOIN_HEROINA, '10.0.32.1');
  travar(m);
  m.entrar('mestre', JOIN_MESTRE, '10.0.32.3');
  const b1 = blocos(m.clientes.mestre)[0];
  m.sair('mestre'); // a ligação cai antes de confirmar
  m.entrar('mestre', JOIN_MESTRE, '10.0.32.3');
  const b2 = blocos(m.clientes.mestre)[1];
  assert.ok(b2, 'o bloco volta na ligação seguinte');
  assert.deepEqual(b2.alertas.map((a) => a.id), b1.alertas.map((a) => a.id), 'os mesmos ids (o cliente resolve o duplicado)');
  // Confirmar só um: sai só esse.
  assert.deepEqual(m.enviar('mestre', { type: 'MASTER_ALERTA_ACK', ids: [b2.alertas[0].id] }), [], 'a confirmação não tem resposta');
  m.enviar('mestre', { type: 'MASTER_VIEW' });
  const b3 = blocos(m.clientes.mestre).at(-1);
  assert.deepEqual(b3.alertas.map((a) => a.id), [b2.alertas[1].id], 'fica só o que não foi confirmado');
  confirmar(m, b3);
  const n = blocos(m.clientes.mestre).length;
  m.enviar('mestre', { type: 'MASTER_VIEW' });
  m.sair('mestre');
  m.entrar('mestre', JOIN_MESTRE, '10.0.32.3');
  assert.equal(blocos(m.clientes.mestre).length, n, 'fila vazia: nenhum bloco');
});

test('ordem 34 (N32-1, falhava antes): com o Mestre ligado, o alerta sai na hora (com id, ordem e hora) e também fica na fila até à confirmação', () => {
  const m = montarMesa();
  m.entrarTodos();
  const nAlertas = m.clientes.mestre.msgs.filter((x) => x.type === 'MASTER_ALERTA').length;
  // Um segundo aparelho no lugar da heroína.
  m.entrar('heroina-2', JOIN_HEROINA, '10.0.32.7');
  const vivos = m.clientes.mestre.msgs.filter((x) => x.type === 'MASTER_ALERTA');
  assert.equal(vivos.length, nAlertas + 1, 'o alerta ao vivo');
  const a = vivos.at(-1);
  assert.equal(a.motivo, 'segunda_ligacao');
  assert.match(a.id, RE_ID);
  assert.ok(Number.isInteger(a.ordem) && a.ordem >= 1);
  assert.ok(!Number.isNaN(Date.parse(a.hora)));
  // Sem confirmação, o pedido da vista seguinte traz o bloco com ele.
  m.enviar('mestre', { type: 'MASTER_VIEW' });
  const b = blocos(m.clientes.mestre).at(-1);
  assert.ok(b, 'o bloco vem com a vista pedida');
  assert.deepEqual(b.alertas.map((x) => x.id), [a.id]);
  m.enviar('mestre', { type: 'MASTER_ALERTA_ACK', ids: [a.id] });
  const n = blocos(m.clientes.mestre).length;
  m.enviar('mestre', { type: 'MASTER_VIEW' });
  assert.equal(blocos(m.clientes.mestre).length, n, 'confirmado: a vista seguinte já não traz bloco');
});

test('ordem 34 (N32-1): a confirmação mal formada é ERRO formato; um id que já saiu não é erro', () => {
  const m = montarMesa();
  m.entrarTodos();
  for (const msg of [
    { type: 'MASTER_ALERTA_ACK' },
    { type: 'MASTER_ALERTA_ACK', ids: [] },
    { type: 'MASTER_ALERTA_ACK', ids: 'a1' },
    { type: 'MASTER_ALERTA_ACK', ids: ['não é id!'] },
    { type: 'MASTER_ALERTA_ACK', ids: ['a1'], perdidos: -1 },
    { type: 'MASTER_ALERTA_ACK', ids: ['a1'], extra: true },
  ]) {
    const r = m.enviar('mestre', msg);
    assert.equal(r[0]?.type, 'ERRO', JSON.stringify(msg));
    assert.equal(r[0]?.codigo, 'formato', JSON.stringify(msg));
  }
  assert.deepEqual(m.enviar('mestre', { type: 'MASTER_ALERTA_ACK', ids: ['ajaconfirmado'] }), []);
  // Só o Mestre confirma alertas.
  const r = m.enviar('heroina', { type: 'MASTER_ALERTA_ACK', ids: ['a1'] });
  assert.equal(r[0]?.type, 'ERRO');
  assert.equal(r[0]?.codigo, 'proibido');
});

test('ordem 34 (N32-1): o módulo da fila — 100 por sala, o 101.º tira o mais antigo, perdidos contados, ordem e ids', () => {
  let t = Date.UTC(2026, 10, 12, 21, 0, 0);
  let n = 0;
  const fila = criarFilaAlertas({ agora: () => t, novoId: () => 'id' + ++n });
  assert.equal(MAX_ALERTAS, 100);
  for (let i = 0; i < 101; i++) fila.juntar('bloqueio_join', { alvo: 'ip' });
  const p = fila.pendentes();
  assert.equal(p.alertas.length, 100);
  assert.equal(p.perdidos, 1, 'o 101.º tirou o mais antigo: um perdido');
  assert.equal(p.alertas[0].ordem, 2, 'saiu o n.º 1');
  assert.equal(p.alertas.at(-1).ordem, 101);
  assert.equal(new Set(p.alertas.map((a) => a.id)).size, 100);
  // Confirmar o bloco (com os perdidos que ele levava) zera o contador; uma perda nova depois disso conta outra vez.
  fila.confirmar(p.alertas.map((a) => a.id), p.perdidos);
  assert.deepEqual(fila.pendentes(), { alertas: [], perdidos: 0 });
  // Retenção: 7 dias. O que expira conta como perdido.
  assert.equal(RETENCAO_MS, 7 * 24 * 3600 * 1000);
  fila.juntar('segunda_ligacao', { papel: 'jogadora', nome: 'Heroína Teste' });
  t += RETENCAO_MS - 1;
  assert.equal(fila.pendentes().alertas.length, 1, 'ainda dentro dos 7 dias');
  fila.juntar('bloqueio_join', { alvo: 'lugar' });
  t += 1;
  const q = fila.pendentes();
  assert.equal(q.alertas.length, 1, 'o de há 7 dias saiu');
  assert.equal(q.perdidos, 1, 'e contou como perdido');
  assert.equal(q.alertas[0].motivo, 'bloqueio_join');
  // Os perdidos novos (chegados depois do bloco enviado) não se apagam com a confirmação do bloco antigo.
  fila.confirmar([], 0);
  assert.equal(fila.pendentes().perdidos, 1);
});

test('ordem 34 (N32-1, falhava antes): a fila sobrevive ao reinício do servidor, num ficheiro próprio, separado do journal', () => {
  const m = montarMesa();
  m.entrar('heroina', JOIN_HEROINA, '10.0.32.1');
  travar(m);
  const textoAlertas = m.sala.exportarAlertas();
  const textoJournal = m.sala.exportar();
  const fila = JSON.parse(textoAlertas);
  assert.equal(fila.marca, 'MESTRE-ONLY');
  assert.equal(fila.alertas.length, 2);
  // Separados: o journal não leva os alertas; o ficheiro dos alertas não leva o estado de jogo.
  for (const a of fila.alertas) assert.ok(!textoJournal.includes(a.id), 'o id do alerta não está no journal');
  assert.ok(!textoAlertas.includes('figuras') && !textoAlertas.includes('lugares'), 'nada do estado de jogo na fila');

  // Reinício: a sala nova abre do journal e da fila.
  const config = {
    roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  const sala2 = criarSala({
    motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config,
    restaurarDe: textoJournal, restaurarAlertasDe: textoAlertas,
  });
  const r = sala2.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', ...JOIN_MESTRE }, { ip: '10.0.32.3' });
  assert.ok(r.ok);
  const b = r.mensagens.find((x) => x.type === 'MASTER_ALERTAS');
  assert.ok(b, 'depois do reinício, o bloco chega ao Mestre');
  assert.deepEqual(b.alertas.map((a) => a.id), fila.alertas.map((a) => a.id));
  // O número de ordem continua (não recomeça no 1).
  sala2.conexaoAberta(r.seatId);
  const outra = sala2.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', ...JOIN_HEROINA }, { ip: '10.0.32.1' });
  sala2.conexaoAberta(outra.seatId);
  const terceira = sala2.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', ...JOIN_HEROINA }, { ip: '10.0.32.8' });
  const vivo = terceira.saidas.find((s) => s.msg.type === 'MASTER_ALERTA')?.msg;
  assert.ok(vivo, 'segunda ligação: alerta');
  assert.equal(vivo.ordem, 3, 'a ordem continua depois do reinício');
  assert.ok(!fila.alertas.some((a) => a.id === vivo.id), 'id novo');
});

test('ordem 34 (N32-1): o ficheiro da fila estragado — a sala não abre (falha fechada, como o journal), sem reparação', () => {
  const base = {
    motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(),
    config: {
      roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, depurar: true,
      lugares: [{ papel: 'mestre', nome: 'Mestre', pin: PIN }],
    },
  };
  const bom = JSON.parse(montarMesa().sala.exportarAlertas());
  for (const [rotulo, texto] of [
    ['não é JSON', '{lixo'],
    ['outra forma', JSON.stringify({ formato: 'outra/9' })],
    ['alerta sem id', JSON.stringify({ ...bom, alertas: [{ ordem: 1, hora: '2026-11-12T21:00:00.000Z', motivo: 'bloqueio_join' }] })],
    ['perdidos negativo', JSON.stringify({ ...bom, perdidos: -1 })],
    ['mais de 100', JSON.stringify({ ...bom, alertas: Array.from({ length: 101 }, (_, i) => ({ id: 'a' + i, ordem: i + 1, hora: '2026-11-12T21:00:00.000Z', motivo: 'bloqueio_join' })), proximaOrdem: 102 })],
  ]) {
    assert.throws(() => criarSala({ ...base, restaurarAlertasDe: texto }), ErroFilaAlertas, rotulo);
  }
});

test('ordem 34 (N32-1, falhava antes): no adaptador, a fila vai para o ficheiro próprio antes de o alerta sair, e volta no arranque', () => {
  const discos = new Map();
  const config = {
    roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  const CAMINHO = 'privado/sala-MESTRE-ONLY-alertas.json';
  const sala = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config });
  const alertas = criarGravadorAlertas({ sala, caminho: CAMINHO, escrever: (c, t) => discos.set(c, t) });
  const servidor = criarServidor({ sala, alertas });
  for (let i = 0; i < 5; i++) {
    const a = ligarWs(servidor, '10.0.32.20');
    a.json({ v: 2, type: 'ROOM_JOIN', ...ERRADA });
  }
  const gravado = discos.get(CAMINHO);
  assert.ok(gravado, 'a fila foi gravada no ficheiro dela');
  const fila = JSON.parse(gravado);
  assert.equal(fila.alertas.length, 2, 'com os dois alertas do travão (o Mestre não estava)');
  servidor.close();

  // Reinício: a sala nova abre com a fila do ficheiro; o Mestre liga e recebe o bloco.
  const sala2 = criarSala({
    motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config, restaurarAlertasDe: gravado,
  });
  const servidor2 = criarServidor({ sala: sala2, alertas: criarGravadorAlertas({ sala: sala2, caminho: CAMINHO, escrever: (c, t) => discos.set(c, t) }) });
  const mestre = ligarWs(servidor2, '10.0.32.21');
  mestre.json({ v: 2, type: 'ROOM_JOIN', ...JOIN_MESTRE });
  const b = mensagensWs(mestre.socket).find((x) => x.type === 'MASTER_ALERTAS');
  assert.ok(b, 'o bloco chega depois do reinício');
  assert.deepEqual(b.alertas.map((a) => a.id), fila.alertas.map((a) => a.id));
  // A confirmação também chega ao ficheiro.
  mestre.json({ v: 2, type: 'MASTER_ALERTA_ACK', roomId: 'sala-teste', ids: b.alertas.map((a) => a.id), perdidos: 0 });
  assert.equal(JSON.parse(discos.get(CAMINHO)).alertas.length, 0, 'confirmados: saem do ficheiro');
  servidor2.close();
});
