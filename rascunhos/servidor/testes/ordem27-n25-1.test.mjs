// Ordem 27 do CM-000009 — N25-1 (palavra do Mestre, 11/11/2026: SIM): travão para a ligação sem lugar.
// Antes, uma ligação que ainda não entrou na sala podia mandar mensagens sem ROOM_JOIN sem fim, cada uma a receber
// ERRO sem_lugar, sem contar para nenhum fecho. Agora, ao 5.º ERRO sem_lugar seguido, a ligação fecha (1008).
// Escolha (o Mestre não fixou o número nem o ritmo): a família do fecho de formato do mesmo adaptador
// (MAX_REJEICOES_FORMATO = 5, código 1008, §2) — ver README «Ordem 27». Só o sem_lugar conta: outros erros
// (formato, credenciais) não contam nem desfazem a série; só a entrada na sala (lugar) a zera.
// O 1.º e o 3.º testes falhavam em 9c66c2a (acabam no fecho); o 2.º e o 4.º são controlo e passavam.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { criarSala } from '../nucleo/sala.js';
import { criarServidor } from '../adaptadores/node/servidor-ws.js';
import { rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const CONFIG = () => ({
  roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
  lugares: [
    { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
    { papel: 'mestre', nome: 'Mestre', pin: PIN },
  ],
});
const novaSala = () => criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config: CONFIG() });
const JOIN_HEROINA = { v: 2, type: 'ROOM_JOIN', papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina };

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
function quadroTexto(dados) {
  const mascara = Buffer.from([0x11, 0x22, 0x33, 0x44]);
  const n = dados.length;
  const cab = n < 126 ? Buffer.from([0x81, 0x80 | n]) : Buffer.from([0x81, 0x80 | 126, n >> 8, n & 0xff]);
  return Buffer.concat([cab, mascara, Buffer.from(dados.map((b, i) => b ^ mascara[i & 3]))]);
}
function ligarWs(servidor, ip) {
  const socket = new SocketFalso();
  const req = {
    url: '/ws', method: 'GET', httpVersionMajor: 1, httpVersionMinor: 1,
    headers: { 'sec-websocket-key': 'dGhlIHNhbXBsZSBub25jZQ==', 'sec-websocket-version': '13', upgrade: 'websocket', host: 'local' },
    socket: { remoteAddress: ip },
  };
  servidor.emit('upgrade', req, socket, Buffer.alloc(0));
  return {
    socket,
    texto: (t) => socket.emit('data', quadroTexto(Buffer.from(t, 'utf8'))),
    json: (o) => socket.emit('data', quadroTexto(Buffer.from(JSON.stringify(o), 'utf8'))),
  };
}
/** O quadro de fecho que o servidor mandou: {codigo, motivo} ou null. */
const fecho = (socket) => {
  const q = socket.saida.slice(1).find((b) => (b[0] & 0x0f) === 0x8);
  return q ? { codigo: q.readUInt16BE(2), motivo: q.subarray(4, 2 + (q[1] & 0x7f)).toString('utf8') } : null;
};
function mensagensWs(socket) {
  const out = [];
  for (const b of socket.saida.slice(1)) {
    if ((b[0] & 0x0f) !== 0x1) continue;
    let len = b[1] & 0x7f;
    let off = 2;
    if (len === 126) { len = b.readUInt16BE(2); off = 4; }
    out.push(JSON.parse(b.subarray(off, off + len).toString('utf8')));
  }
  return out;
}
const semLugar = (socket) => mensagensWs(socket).filter((x) => x.type === 'ERRO' && x.codigo === 'sem_lugar').length;
const RESYNC = { v: 2, type: 'ROOM_RESYNC', lastSeq: 0 };

test('ordem 27 (N25-1, falhava antes): 5 mensagens seguidas sem ROOM_JOIN (ERRO sem_lugar) fecham a ligação com 1008', () => {
  const servidor = criarServidor({ sala: novaSala() });
  const a = ligarWs(servidor, '10.0.27.1');
  for (let i = 0; i < 5; i++) a.json(RESYNC);
  assert.equal(semLugar(a.socket), 5, 'cada uma recebeu o ERRO sem_lugar');
  assert.deepEqual(fecho(a.socket), { codigo: 1008, motivo: 'sem lugar' });
  // Depois de fechada, mais nada sai.
  const antes = a.socket.saida.length;
  a.json(RESYNC);
  assert.equal(a.socket.saida.length, antes);
  servidor.close();
});

test('ordem 27 (N25-1, controlo): 4 seguidas não fecham', () => {
  const servidor = criarServidor({ sala: novaSala() });
  const a = ligarWs(servidor, '10.0.27.2');
  for (let i = 0; i < 4; i++) a.json({ v: 2, type: 'ROOM_INTENT', intentId: 'x' + i, revision: 0, acao: { tipo: 'encerrar' } });
  assert.equal(semLugar(a.socket), 4);
  assert.equal(fecho(a.socket), null);
  servidor.close();
});

// Ordem 34 (N30-1, sentença da bancada de 2026-11-12): antes da entrada, a mensagem que não é ROOM_JOIN passou a
// contar TAMBÉM para a família de formato (soma-se ao JSON inválido). Este teste tinha 4 sem_lugar + 1 JSON inválido e
// esperava a ligação aberta; agora isso são 5 da família e fecha (ver ordem34-n30-1.test.mjs). Fica aqui o que a N25-1
// continua a garantir: as credenciais erradas pelo meio não contam nem desfazem a série do sem_lugar.
test('ordem 27 (N25-1, falhava antes): erros que não são sem_lugar não desfazem a série — credenciais erradas pelo meio', () => {
  const servidor = criarServidor({ sala: novaSala() });
  const a = ligarWs(servidor, '10.0.27.3');
  for (let i = 0; i < 4; i++) a.json(RESYNC);
  a.json({ ...JOIN_HEROINA, senha: 'errada-errada' }); // ERRO credenciais: não conta
  assert.equal(fecho(a.socket), null, 'só 4 sem_lugar até aqui');
  a.json(RESYNC); // 5.º sem_lugar da série: o outro erro não a desfez
  assert.equal(semLugar(a.socket), 5);
  assert.deepEqual(fecho(a.socket), { codigo: 1008, motivo: 'sem lugar' });
  servidor.close();
});

test('ordem 27 (N25-1, controlo): quem entra na sala fica com o lugar — a série zera e o resto segue como antes', () => {
  const servidor = criarServidor({ sala: novaSala() });
  const a = ligarWs(servidor, '10.0.27.4');
  for (let i = 0; i < 4; i++) a.json(RESYNC);
  a.json(JOIN_HEROINA);
  assert.ok(mensagensWs(a.socket).some((x) => x.type === 'ROOM_WELCOME'), 'entrou');
  for (let i = 0; i < 6; i++) a.json(RESYNC);
  assert.equal(fecho(a.socket), null, 'com lugar, o sem_lugar não volta');
  assert.equal(semLugar(a.socket), 4);
  servidor.close();
});
