// Adaptador Node da fase 1: HTTP + WebSocket na MESMA origem, servindo também uma pasta estática.
// Sem bibliotecas externas: o handshake (RFC 6455 §4) e o enquadramento mínimo estão aqui.
// O núcleo (../../nucleo) é puro; este arquivo é o único que toca em node:*.
//
// Limites (protocolo §2): mensagem do cliente ≤ 16 KB; o resto do ritmo é do núcleo.
// Ping de WebSocket a cada 20 s; ligação sem pong há mais de 45 s é fechada (E-C4).
// O "sem pulso" do princípio 6 refere-se à aplicação: o ping é só da camada WebSocket.
//
// NAC-OV-05: este arquivo NUNCA foi executado no PC PCDANASA. É um rascunho para a bancada.

import http from 'node:http';
import { createHash, webcrypto } from 'node:crypto';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const GUID_WS = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
export const LIMITE_MENSAGEM = 16 * 1024;
const PING_MS = 20_000;
const MORTO_MS = 45_000;
const MAX_REJEICOES_FORMATO = 5; // repetidas → fecha a ligação (§2)

const TIPOS_MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.glb': 'model/gltf-binary',
  '.wasm': 'application/wasm',
  '.ico': 'image/x-icon',
};

/** rng de 32 bits por CSPRNG (crypto.getRandomValues), para injetar no núcleo. */
export function rngNode() {
  const b = new Uint32Array(1);
  return () => {
    webcrypto.getRandomValues(b);
    return b[0];
  };
}

/** Uma ligação WebSocket (servidor). Só texto; binário dá 1003. */
class Ligacao {
  constructor(socket, ip, aoMensagem, aoFechar) {
    this.socket = socket;
    this.ip = ip;
    this.aoMensagem = aoMensagem;
    this.aoFechar = aoFechar;
    this.buf = Buffer.alloc(0);
    this.fragmentos = null;
    this.ultimoPong = Date.now();
    this.fechada = false;
    this.avisada = false;
    this.seatId = null;
    this.rejeicoesFormato = 0;
    socket.setNoDelay(true);
    socket.on('data', (d) => this.receberBytes(d));
    socket.on('close', () => this.terminar());
    socket.on('error', () => this.terminar());
  }

  receberBytes(d) {
    if (this.fechada) return;
    this.buf = this.buf.length ? Buffer.concat([this.buf, d]) : d;
    for (;;) {
      if (this.buf.length < 2) return;
      const b0 = this.buf[0];
      const b1 = this.buf[1];
      const fin = (b0 & 0x80) !== 0;
      const rsv = b0 & 0x70;
      const opcode = b0 & 0x0f;
      const mascarado = (b1 & 0x80) !== 0;
      let len = b1 & 0x7f;
      let off = 2;
      if (rsv !== 0) return this.fechar(1002, 'rsv'); // sem extensões
      if (len === 126) {
        if (this.buf.length < 4) return;
        len = this.buf.readUInt16BE(2);
        off = 4;
      } else if (len === 127) {
        if (this.buf.length < 10) return;
        if (this.buf.readUInt32BE(2) !== 0) return this.fechar(1009, 'grande');
        len = this.buf.readUInt32BE(6);
        off = 10;
      }
      if (!mascarado) return this.fechar(1002, 'sem mascara'); // o cliente TEM de mascarar
      if (len > LIMITE_MENSAGEM) return this.fechar(1009, 'grande');
      if (this.buf.length < off + 4 + len) return;
      const mascara = this.buf.subarray(off, off + 4);
      const dados = Buffer.from(this.buf.subarray(off + 4, off + 4 + len));
      for (let i = 0; i < len; i++) dados[i] ^= mascara[i & 3];
      this.buf = this.buf.subarray(off + 4 + len);
      this.tratarQuadro(fin, opcode, dados);
      if (this.fechada) return;
    }
  }

  tratarQuadro(fin, opcode, dados) {
    if (opcode === 0x8) return this.fechar(1000, '');
    if (opcode === 0x9) return void this.enviarQuadro(0xa, dados.subarray(0, 125));
    if (opcode === 0xa) {
      this.ultimoPong = Date.now();
      return undefined;
    }
    if (opcode === 0x1 || opcode === 0x2 || opcode === 0x0) {
      if (opcode !== 0x0) {
        if (this.fragmentos) return this.fechar(1002, 'fragmento');
        this.fragmentos = { opcode, partes: [dados], total: dados.length };
      } else {
        if (!this.fragmentos) return this.fechar(1002, 'continuacao');
        this.fragmentos.partes.push(dados);
        this.fragmentos.total += dados.length;
      }
      if (this.fragmentos.total > LIMITE_MENSAGEM) return this.fechar(1009, 'grande');
      if (!fin) return undefined;
      const { opcode: op, partes } = this.fragmentos;
      this.fragmentos = null;
      if (op !== 0x1) return this.fechar(1003, 'so texto');
      this.ultimoPong = Date.now(); // qualquer tráfego conta como vivo
      this.aoMensagem(this, Buffer.concat(partes).toString('utf8'));
      return undefined;
    }
    return this.fechar(1002, 'opcode');
  }

  enviarQuadro(op, payload) {
    if (this.fechada) return false;
    const n = payload.length;
    let cab;
    if (n < 126) cab = Buffer.from([0x80 | op, n]);
    else if (n < 65536) {
      cab = Buffer.alloc(4);
      cab[0] = 0x80 | op;
      cab[1] = 126;
      cab.writeUInt16BE(n, 2);
    } else {
      cab = Buffer.alloc(10);
      cab[0] = 0x80 | op;
      cab[1] = 127;
      cab.writeUInt32BE(0, 2);
      cab.writeUInt32BE(n, 6);
    }
    try {
      this.socket.write(Buffer.concat([cab, payload]));
      return true;
    } catch {
      return false;
    }
  }

  enviarJson(obj) {
    return this.enviarQuadro(0x1, Buffer.from(JSON.stringify(obj), 'utf8'));
  }

  fechar(codigo, motivo = '') {
    if (this.fechada) return undefined;
    const texto = Buffer.from(String(motivo).slice(0, 100), 'utf8');
    const p = Buffer.alloc(2 + texto.length);
    p.writeUInt16BE(codigo, 0);
    texto.copy(p, 2);
    this.enviarQuadro(0x8, p);
    this.fechada = true;
    this.socket.end();
    setTimeout(() => this.socket.destroy(), 2000).unref();
    this.terminar();
    return undefined;
  }

  terminar() {
    this.fechada = true;
    if (this.avisada) return;
    this.avisada = true;
    this.aoFechar(this);
  }
}

function ipDe(req) {
  // TODO(JV1.x): atrás de um proxy, ler X-Forwarded-For só de proxies de confiança.
  return req.socket.remoteAddress ?? 'desconhecido';
}

async function servirEstatico(req, res, pasta) {
  const cabecalhosBase = { 'X-Content-Type-Options': 'nosniff', 'Cache-Control': 'no-cache', 'Referrer-Policy': 'no-referrer' };
  if (!pasta) {
    res.writeHead(404, cabecalhosBase).end();
    return;
  }
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.writeHead(405, cabecalhosBase).end();
    return;
  }
  let caminho;
  try {
    caminho = decodeURIComponent(new URL(req.url, 'http://local').pathname);
  } catch {
    res.writeHead(400, cabecalhosBase).end();
    return;
  }
  if (caminho.includes('\0') || caminho.split('/').some((p) => p.startsWith('.') && p.length > 0)) {
    res.writeHead(404, cabecalhosBase).end(); // nada de dotfiles nem ".."
    return;
  }
  if (caminho.endsWith('/')) caminho += 'index.html';
  const raiz = path.resolve(pasta);
  const alvo = path.resolve(raiz, '.' + caminho);
  if (alvo !== raiz && !alvo.startsWith(raiz + path.sep)) {
    res.writeHead(403, cabecalhosBase).end();
    return;
  }
  try {
    const st = await stat(alvo);
    if (!st.isFile()) throw new Error('não é arquivo');
    const corpo = await readFile(alvo);
    const tipo = TIPOS_MIME[path.extname(alvo).toLowerCase()] ?? 'application/octet-stream';
    res.writeHead(200, { ...cabecalhosBase, 'Content-Type': tipo, 'Content-Length': corpo.length });
    res.end(req.method === 'HEAD' ? undefined : corpo);
  } catch {
    res.writeHead(404, cabecalhosBase).end();
  }
}

/**
 * Cria o servidor HTTP+WS para uma sala.
 * @param {{sala:Object, pastaEstatica?:string, caminhoWs?:string, registo?:(t:string)=>void}} p
 * IMPORTANTE: a pasta estática é só o cliente. Nunca lá ponha exportações do journal (E-P13).
 */
export function criarServidor({ sala, pastaEstatica = null, caminhoWs = '/ws', registo = () => {} }) {
  const porLugar = new Map(); // seatId → Set<Ligacao>
  const todas = new Set();

  function associar(lig, seatId) {
    lig.seatId = seatId;
    if (!porLugar.has(seatId)) porLugar.set(seatId, new Set());
    porLugar.get(seatId).add(lig);
  }

  function entregar(saidas) {
    for (const { seatId, msg } of saidas) {
      for (const l of porLugar.get(seatId) ?? []) {
        if (!l.enviarJson(msg)) l.fechar(4001, 'envio falhou'); // E-C7
      }
    }
  }

  function aoFechar(lig) {
    todas.delete(lig);
    if (!lig.seatId) return;
    const conjunto = porLugar.get(lig.seatId);
    if (conjunto) conjunto.delete(lig);
    const seatId = lig.seatId;
    lig.seatId = null;
    entregar(sala.conexaoFechada(seatId));
  }

  function aoMensagem(lig, texto) {
    let msg;
    try {
      msg = JSON.parse(texto);
    } catch {
      lig.enviarJson({ v: 2, type: 'ERRO', codigo: 'formato', texto: 'JSON inválido.' });
      return;
    }
    if (msg && msg.type === 'ROOM_JOIN') {
      // O seatToken vem na mensagem, nunca na URL (E-P9). Nunca o registar.
      const r = sala.entrar(msg, { ip: lig.ip });
      if (!r.ok) {
        for (const m of r.mensagens) lig.enviarJson(m);
        entregar(r.saidas);
        return;
      }
      if (lig.seatId && lig.seatId !== r.seatId) aoFecharLugar(lig);
      if (r.fecharAnteriores) {
        for (const outra of [...(porLugar.get(r.seatId) ?? [])]) if (outra !== lig) outra.fechar(4002, 'outra ligacao');
      }
      if (lig.seatId !== r.seatId) {
        associar(lig, r.seatId);
        entregar(sala.conexaoAberta(r.seatId));
      }
      for (const m of r.mensagens) lig.enviarJson(m);
      entregar(r.saidas);
      return;
    }
    if (!lig.seatId) {
      lig.enviarJson({ v: 2, type: 'ERRO', codigo: 'sem_lugar', texto: 'Entre na sala primeiro.' });
      return;
    }
    const saidas = sala.receber(lig.seatId, msg);
    // Rejeições de formato repetidas (inclui o excesso de ritmo) fecham a ligação.
    const formatoMal = saidas.some((s) => s.seatId === lig.seatId && s.msg?.type === 'ROOM_REJECT' && s.msg.motivo === 'formato');
    lig.rejeicoesFormato = formatoMal ? lig.rejeicoesFormato + 1 : 0;
    entregar(saidas);
    if (lig.rejeicoesFormato >= MAX_REJEICOES_FORMATO) lig.fechar(1008, 'formato');
  }

  function aoFecharLugar(lig) {
    const conjunto = porLugar.get(lig.seatId);
    if (conjunto) conjunto.delete(lig);
    const antigo = lig.seatId;
    lig.seatId = null;
    entregar(sala.conexaoFechada(antigo));
  }

  const servidor = http.createServer((req, res) => {
    servirEstatico(req, res, pastaEstatica).catch(() => {
      if (!res.headersSent) res.writeHead(500).end();
    });
  });

  servidor.on('upgrade', (req, socket, head) => {
    let url;
    try {
      url = new URL(req.url, 'http://local');
    } catch {
      socket.end('HTTP/1.1 400 Bad Request\r\n\r\n');
      return;
    }
    if (url.pathname !== caminhoWs) {
      socket.end('HTTP/1.1 404 Not Found\r\n\r\n');
      return;
    }
    const chave = req.headers['sec-websocket-key'];
    const versao = req.headers['sec-websocket-version'];
    if (typeof chave !== 'string' || String(req.headers.upgrade).toLowerCase() !== 'websocket' || versao !== '13') {
      socket.end('HTTP/1.1 400 Bad Request\r\n\r\n');
      return;
    }
    // Mesma origem: um Origin de outro host é recusado.
    const origem = req.headers.origin;
    if (origem) {
      let hostOrigem = null;
      try {
        hostOrigem = new URL(origem).host;
      } catch {
        /* inválido */
      }
      if (hostOrigem !== req.headers.host) {
        socket.end('HTTP/1.1 403 Forbidden\r\n\r\n');
        return;
      }
    }
    const aceite = createHash('sha1').update(chave + GUID_WS).digest('base64');
    socket.write(
      'HTTP/1.1 101 Switching Protocols\r\n'
      + 'Upgrade: websocket\r\n'
      + 'Connection: Upgrade\r\n'
      + `Sec-WebSocket-Accept: ${aceite}\r\n\r\n`,
    );
    const lig = new Ligacao(socket, ipDe(req), aoMensagem, aoFechar);
    todas.add(lig);
    if (head && head.length) lig.receberBytes(head);
  });

  // Ping da camada WebSocket (não é pulso de aplicação).
  const relogio = setInterval(() => {
    const t = Date.now();
    for (const lig of todas) {
      if (t - lig.ultimoPong > MORTO_MS) lig.fechar(1001, 'sem pong');
      else lig.enviarQuadro(0x9, Buffer.alloc(0));
    }
  }, PING_MS);
  relogio.unref();
  servidor.on('close', () => clearInterval(relogio));

  registo('servidor de mesa pronto (WebSocket em ' + caminhoWs + ')');
  return servidor;
}

// ---------------------------------------------------------------------------
// Arranque pela linha de comando:
//   node adaptadores/node/servidor-ws.js caminho/config.json
// config.json (Mestre-only, FORA do repositório):
//   {"porta":8080, "host":"0.0.0.0", "pastaEstatica":"../cliente",
//    "motores":"../motores/gerado/motores.mjs", "fichas":"../dados-exemplo/fichas-ficticias.json",
//    "sala":{ ...config de criarSala: lugares, iniciativa, mapa... }}
// TODO(JV1.x): gravar o journal em disco (append) a cada commit, e restaurar ao arrancar.
// TODO(JV1.x): carregar o pacote privado do Mestre (carregarPacote) em vez de um JSON solto.
// ---------------------------------------------------------------------------
async function principal(argv) {
  const caminhoConfig = argv[2];
  if (!caminhoConfig) {
    console.error('uso: node adaptadores/node/servidor-ws.js config.json');
    process.exitCode = 2;
    return;
  }
  const base = path.dirname(path.resolve(caminhoConfig));
  const cfg = JSON.parse(await readFile(caminhoConfig, 'utf8'));
  const { carregarFichas } = await import('../../nucleo/carregar-fichas.js');
  const { criarSala } = await import('../../nucleo/sala.js');
  const motores = await import(pathToFileURL(path.resolve(base, cfg.motores)).href);
  const r = carregarFichas(JSON.parse(await readFile(path.resolve(base, cfg.fichas), 'utf8')));
  if (!r.ok) {
    for (const e of r.erros) console.error(`ficha recusada: ${e.arquivo} ${e.campo}: ${e.motivo}`);
    process.exitCode = 1;
    return; // a sala não abre
  }
  const sala = criarSala({ motores, fichas: r.fichas, rng: rngNode(), agora: () => Date.now(), config: cfg.sala });
  const servidor = criarServidor({
    sala,
    pastaEstatica: cfg.pastaEstatica ? path.resolve(base, cfg.pastaEstatica) : null,
    registo: (t) => console.log(t),
  });
  servidor.listen(cfg.porta ?? 8080, cfg.host ?? '0.0.0.0');
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  principal(process.argv).catch((e) => {
    console.error(e);
    process.exitCode = 1;
  });
}
