// Ajudantes dos testes do adaptador Node (ordem 34): um socket falso e uma ligação WebSocket feita à mão sobre o
// `criarServidor`, sem rede (o mesmo método dos testes das ordens 16, 17, 18 e 27, aqui num sítio só).
import { EventEmitter } from 'node:events';

export class SocketFalso extends EventEmitter {
  constructor() {
    super();
    this.saida = [];
    this.terminado = false;
  }
  setNoDelay() {}
  write(b) {
    this.saida.push(Buffer.from(b));
    return true;
  }
  end(b) {
    if (b !== undefined) this.saida.push(Buffer.from(b));
    this.terminado = true;
  }
  destroy() {}
}

export function quadroTexto(dados) {
  const mascara = Buffer.from([0x11, 0x22, 0x33, 0x44]);
  const n = dados.length;
  const cab = n < 126 ? Buffer.from([0x81, 0x80 | n]) : Buffer.from([0x81, 0x80 | 126, n >> 8, n & 0xff]);
  return Buffer.concat([cab, mascara, Buffer.from(dados.map((b, i) => b ^ mascara[i & 3]))]);
}

/** Um quadro de controlo do cliente (0x9 ping, 0xA pong), mascarado e vazio. */
export function quadroControlo(opcode) {
  return Buffer.from([0x80 | opcode, 0x80, 0x11, 0x22, 0x33, 0x44]);
}

/** Abre uma ligação (o pedido de upgrade) e devolve o socket e os atalhos para enviar. */
export function ligarWs(servidor, ip = '10.0.34.1') {
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
    pong: () => socket.emit('data', quadroControlo(0xa)),
    cair: () => socket.emit('close'),
  };
}

/** A resposta ao pedido de upgrade foi o 101? (a ligação recusada antes do handshake não o tem). */
export function aceite(socket) {
  return socket.saida.length > 0 && socket.saida[0].toString('latin1').startsWith('HTTP/1.1 101');
}

/** O quadro de fecho que o servidor mandou: {codigo, motivo} ou null. */
export function fecho(socket) {
  const q = socket.saida.slice(1).find((b) => (b[0] & 0x0f) === 0x8);
  return q ? { codigo: q.readUInt16BE(2), motivo: q.subarray(4, 2 + (q[1] & 0x7f)).toString('utf8') } : null;
}

/** As mensagens JSON (quadros de texto) que o servidor mandou a este socket. */
export function mensagensWs(socket) {
  const out = [];
  for (const b of socket.saida.slice(1)) {
    if ((b[0] & 0x0f) !== 0x1) continue;
    let len = b[1] & 0x7f;
    let off = 2;
    if (len === 126) {
      len = b.readUInt16BE(2);
      off = 4;
    } else if (len === 127) {
      len = b.readUInt32BE(6);
      off = 10;
    }
    out.push(JSON.parse(b.subarray(off, off + len).toString('utf8')));
  }
  return out;
}
