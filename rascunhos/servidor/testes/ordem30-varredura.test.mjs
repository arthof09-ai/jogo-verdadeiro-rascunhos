// Ordem 30 do CM-000009 — varredura do servidor (V26+): o adaptador WebSocket com sockets TCP reais.
// V26: o cliente que fecha a ligação TCP sem quadro de fecho (aplicação morta, FIN) continuava «ligado» no servidor.
// O http do Node abre o servidor com allowHalfOpen e, depois do upgrade, tira o seu ouvinte de 'end'; a Ligacao só
// ouvia 'close'/'error', que só chegam quando o servidor escreve (ping de 20 s) e leva o RST. Até lá a sala contava a
// ligação: o lugar do Mestre não pausava a mesa (E-C4) e a jogadora não «saía». RFC 6455 §7.1.4: fechada a ligação TCP,
// a ligação WebSocket está fechada.
// Os testes 1 e 2 falhavam em 0e70a22 (nenhum conexaoFechada dentro do prazo); o 3.º é controlo e passava.
//
// V27: quadros de continuação VAZIOS (sem fin) entravam um a um na lista de partes da mensagem fragmentada; o limite de
// 16 KB só soma bytes, por isso nunca disparava. 6 bytes no fio por quadro: 12 MB guardavam ~400 MB numa só ligação
// (medido), sem limite. Agora o pedaço vazio não se guarda (não muda nada à mensagem). O 4.º teste falhava em 5f73c34;
// o 5.º é controlo e passava.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import net from 'node:net';
import v8 from 'node:v8';
import { runInNewContext } from 'node:vm';
import { EventEmitter } from 'node:events';
import { criarSala } from '../nucleo/sala.js';
import { criarServidor } from '../adaptadores/node/servidor-ws.js';
import { rngDeterministico, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
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
const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

/** Servidor real numa porta livre; a sala é embrulhada para registar as aberturas e os fechos que o adaptador pede. */
async function montar() {
  const sr = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(30), agora: () => Date.now(), config: CONFIG() });
  const registo = [];
  const sala = {
    ...sr,
    conexaoAberta: (s) => { registo.push(['aberta', s]); return sr.conexaoAberta(s); },
    conexaoFechada: (s) => { registo.push(['fechada', s]); return sr.conexaoFechada(s); },
  };
  const servidor = criarServidor({ sala });
  // Para o teste acabar mesmo quando falha: o fim destrói os sockets que o servidor ainda tenha meio abertos.
  const sockets = new Set();
  servidor.on('connection', (s) => sockets.add(s));
  const fecharTudo = () => { for (const s of sockets) s.destroy(); servidor.close(); };
  await new Promise((r) => servidor.listen(0, '127.0.0.1', r));
  return { servidor: { close: fecharTudo }, registo, porta: servidor.address().port };
}

function quadroTexto(obj) {
  const d = Buffer.from(JSON.stringify(obj), 'utf8');
  const m = Buffer.from([0x30, 0x26, 0x0e, 0x7a]);
  for (let i = 0; i < d.length; i++) d[i] ^= m[i & 3];
  const cab = d.length < 126 ? Buffer.from([0x81, 0x80 | d.length]) : Buffer.from([0x81, 0xfe, d.length >> 8, d.length & 0xff]);
  return Buffer.concat([cab, m, d]);
}

/** Liga, faz o handshake, manda o JOIN e espera pelo ROOM_WELCOME. */
async function entrar(porta, join) {
  const c = net.connect(porta, '127.0.0.1');
  c.on('error', () => {});
  const estado = { fechou: false, bytes: Buffer.alloc(0) };
  c.on('close', () => { estado.fechou = true; });
  c.on('data', (d) => { estado.bytes = Buffer.concat([estado.bytes, d]); });
  await new Promise((r) => c.on('connect', r));
  c.write('GET /ws HTTP/1.1\r\nHost: 127.0.0.1\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n'
    + 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n');
  c.write(quadroTexto(join));
  for (let i = 0; i < 100 && !estado.bytes.includes('ROOM_WELCOME'); i++) await esperar(10);
  assert.ok(estado.bytes.includes('ROOM_WELCOME'), 'entrou na sala');
  return { c, estado };
}

test('ordem 30 (V26, falhava antes): o Mestre que fecha o TCP sem quadro de fecho (FIN) sai da sala logo, e o servidor fecha o seu lado', async () => {
  const { servidor, registo, porta } = await montar();
  try {
    const { c, estado } = await entrar(porta, JOIN_MESTRE);
    const seatMestre = registo.find(([k]) => k === 'aberta')[1];
    c.end(); // só o FIN: nenhum quadro de fecho
    for (let i = 0; i < 100 && !registo.some(([k]) => k === 'fechada'); i++) await esperar(10);
    assert.deepEqual(registo.filter(([k]) => k === 'fechada'), [['fechada', seatMestre]], 'a sala soube da queda do Mestre (E-C4)');
    for (let i = 0; i < 100 && !estado.fechou; i++) await esperar(10);
    assert.equal(estado.fechou, true, 'o servidor fechou também o seu lado da ligação');
  } finally {
    servidor.close();
  }
});

test('ordem 30 (V26, falhava antes): a jogadora cuja aplicação morre (socket destruído sem quadro de fecho) deixa de contar como ligada', async () => {
  const { servidor, registo, porta } = await montar();
  try {
    const { c } = await entrar(porta, JOIN_HEROINA);
    const seat = registo.find(([k]) => k === 'aberta')[1];
    c.destroy();
    for (let i = 0; i < 100 && !registo.some(([k]) => k === 'fechada'); i++) await esperar(10);
    assert.deepEqual(registo.filter(([k]) => k === 'fechada'), [['fechada', seat]]);
  } finally {
    servidor.close();
  }
});

test('ordem 30 (controlo, passava antes): com quadro de fecho e depois o FIN, a sala conta UM só fecho', async () => {
  const { servidor, registo, porta } = await montar();
  try {
    const { c, estado } = await entrar(porta, JOIN_HEROINA);
    const m = Buffer.from([1, 2, 3, 4]);
    const p = Buffer.from([0x03, 0xe8]);
    for (let i = 0; i < p.length; i++) p[i] ^= m[i & 3];
    c.write(Buffer.concat([Buffer.from([0x88, 0x82]), m, p]));
    for (let i = 0; i < 100 && !estado.fechou; i++) await esperar(10);
    c.end();
    await esperar(100);
    assert.equal(estado.fechou, true);
    assert.equal(registo.filter(([k]) => k === 'fechada').length, 1);
  } finally {
    servidor.close();
  }
});

// ---------------------------------------------------------------- V27 (socket falso: só o laço dos quadros)
class SocketFalso extends EventEmitter {
  constructor() {
    super();
    this.saida = [];
  }
  setNoDelay() {}
  write(b) {
    this.saida.push(Buffer.from(b));
    return true;
  }
  end() {}
  destroy() {}
}
function ligarFalso(sala) {
  const servidor = criarServidor({ sala });
  const socket = new SocketFalso();
  servidor.emit('upgrade', {
    url: '/ws', method: 'GET', httpVersionMajor: 1, httpVersionMinor: 1,
    headers: { 'sec-websocket-key': 'dGhlIHNhbXBsZSBub25jZQ==', 'sec-websocket-version': '13', upgrade: 'websocket', host: 'local' },
    socket: { remoteAddress: '10.0.30.1' },
  }, socket, Buffer.alloc(0));
  return socket;
}
/** Quadro mascarado com máscara zero (os bytes ficam como estão). */
const quadro = (b0, dados = Buffer.alloc(0)) => Buffer.concat([Buffer.from([b0, 0x80 | dados.length, 0, 0, 0, 0]), dados]);
function salaQueGuarda() {
  const recebidas = [];
  return {
    recebidas,
    sala: {
      entrar: (msg) => { recebidas.push(msg); return { ok: false, mensagens: [], saidas: [] }; },
      receber: () => [], conexaoAberta: () => [], conexaoFechada: () => [], exportar: () => '',
    },
  };
}
v8.setFlagsFromString('--expose-gc');
const gc = runInNewContext('gc');

test('ordem 30 (V27, falhava antes): 2 000 000 quadros de continuação vazios (12 MB no fio) não ficam guardados na memória', () => {
  const { sala } = salaQueGuarda();
  const socket = ligarFalso(sala);
  socket.emit('data', quadro(0x01)); // texto, sem fin, vazio
  const bloco = Buffer.concat(Array(10000).fill(quadro(0x00)));
  gc();
  const antes = process.memoryUsage().heapUsed;
  for (let i = 0; i < 200; i++) socket.emit('data', bloco);
  gc();
  const mais = (process.memoryUsage().heapUsed - antes) / 1048576;
  assert.ok(mais < 50, `memória a mais depois dos quadros vazios: ${mais.toFixed(1)} MB (antes da correcção: ~400 MB)`);
});

test('ordem 30 (controlo, passava antes): a mensagem partida em pedaços, com vazios pelo meio, chega inteira e igual', () => {
  const { sala, recebidas } = salaQueGuarda();
  const socket = ligarFalso(sala);
  const msg = { v: 2, type: 'ROOM_JOIN', papel: 'mestre', pin: '12345678' };
  const d = Buffer.from(JSON.stringify(msg), 'utf8');
  socket.emit('data', Buffer.concat([
    quadro(0x01, d.subarray(0, 10)), quadro(0x00), quadro(0x00, d.subarray(10, 20)), quadro(0x00), quadro(0x80, d.subarray(20)),
  ]));
  assert.deepEqual(recebidas, [msg]);
});
