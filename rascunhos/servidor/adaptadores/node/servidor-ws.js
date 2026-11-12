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
import { readFile, stat, realpath } from 'node:fs/promises';
import { readFileSync, writeFileSync, renameSync, rmSync } from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { ErroJournal } from '../../nucleo/journal.js';

const GUID_WS = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
export const LIMITE_MENSAGEM = 16 * 1024;
const PING_MS = 20_000;
const MORTO_MS = 45_000;
const MAX_REJEICOES_FORMATO = 5; // repetidas → fecha a ligação (§2)
// Ordem 27 (N25-1, palavra do Mestre 11/11/2026: sim; o número é escolha desta ordem, da família do de cima): a
// ligação sem lugar que recebe 5 ERRO sem_lugar seguidos fecha (1008). Só o sem_lugar conta; só a entrada na sala zera.
const MAX_SEM_LUGAR = 5;
const UTF8_ESTRITO = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true });

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
    this.errosSemLugar = 0; // ordem 27 (N25-1)
    socket.setNoDelay(true);
    socket.on('data', (d) => this.receberBytes(d));
    // Ordem 30 (V26; RFC 6455 §7.1.4): o FIN do cliente fecha a ligação. O http do Node abre o servidor com allowHalfOpen
    // e, no upgrade, tira o seu ouvinte de 'end': sem isto a ligação meio fechada contava como viva até um envio levar o
    // RST (o ping de 20 s; ~40 s medidos), e o Mestre caído não pausava a mesa (E-C4). Nada mais pode chegar dela.
    socket.on('end', () => {
      this.fechada = true;
      this.socket.end();
      this.terminar();
    });
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
      // Ordem 17 (V7; RFC 6455 §5.5): os quadros de controlo nunca vêm fragmentados e têm no máximo 125 bytes.
      if (opcode >= 0x8 && (!fin || len > 125)) return this.fechar(1002, 'controlo');
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
      // Ordem 18 (V9; RFC 6455 §8.1): texto que não é UTF-8 válido fecha com 1007. Antes, o toString trocava os bytes
      // maus por U+FFFD e a mensagem seguia para o núcleo. O BOM fica como estava (ignoreBOM: o JSON.parse recusa-o).
      let texto;
      try {
        texto = UTF8_ESTRITO.decode(Buffer.concat(partes));
      } catch {
        return this.fechar(1007, 'utf-8');
      }
      this.ultimoPong = Date.now(); // qualquer tráfego conta como vivo
      this.aoMensagem(this, texto);
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

// ---------------------------------------------------------------------------
// Journal em disco (Ordem 16 do CM-000009; TODO JV1.x; recomendação do estudo da ordem 14).
// O ficheiro é MESTRE-ONLY no nome e na marca. Tem a forma do «Exportar registo» do ecrã do Mestre:
//   {"formato":"registo-mestre/1","marca":"MESTRE-ONLY","registo":"<journal.exportar() intacto>"}
// (o ecrã do Mestre junta-lhe a "narracao"; o servidor não a tem e não a escreve).
// Quem lê abre o envelope e entrega SÓ o "registo" ao restaurarJournal (via criarSala({restaurarDe})).
// Aceita também a forma antiga (antes da ordem 13): o ficheiro é só a string JSON do texto.
// Qualquer outra forma falha FECHADO: não restaura nada. A "narracao" nunca é lida para o estado.
// ---------------------------------------------------------------------------
export const FORMATO_FICHEIRO_JOURNAL = 'registo-mestre/1';
export const MARCA_MESTRE = 'MESTRE-ONLY';

/** O envelope que o adaptador grava (texto JSON). O "registo" vai byte a byte como o servidor o exportou. */
export function envelopeJournal(texto) {
  if (typeof texto !== 'string') throw new ErroJournal('exportação tem de ser texto');
  return JSON.stringify({ formato: FORMATO_FICHEIRO_JOURNAL, marca: MARCA_MESTRE, registo: texto });
}

/**
 * Abre o ficheiro (o seu texto) e devolve o texto do journal para o restaurarJournal.
 * Lança ErroJournal se a forma não for uma das duas conhecidas. Não lê nem devolve a "narracao".
 */
export function abrirFicheiroJournal(conteudoFicheiro) {
  if (typeof conteudoFicheiro !== 'string') throw new ErroJournal('ficheiro do journal ilegível');
  let dado;
  try {
    dado = JSON.parse(conteudoFicheiro);
  } catch {
    throw new ErroJournal('ficheiro do journal: formato desconhecido');
  }
  let texto = null;
  if (typeof dado === 'string') texto = dado; // forma antiga: a string JSON é o próprio texto
  else if (
    dado && typeof dado === 'object' && !Array.isArray(dado)
    && dado.formato === FORMATO_FICHEIRO_JOURNAL && dado.marca === MARCA_MESTRE && typeof dado.registo === 'string'
  ) {
    texto = dado.registo; // só o registo; a narração fica de fora
  }
  // Texto vazio também falha fechado: o criarSala trataria '' como «sem restauro» e abriria uma sala nova.
  if (!texto) throw new ErroJournal('ficheiro do journal: formato desconhecido');
  return texto;
}

/**
 * `alvo` está dentro de `raiz` (ou é ela)? Pelo path.relative da plataforma: no Windows compara sem olhar a maiúsculas,
 * como o disco (ordem 17, V4: o startsWith antigo deixava «c:\mesa\CLIENTE\...» fora de «C:\Mesa\cliente»).
 */
export function dentroDaPasta(raiz, alvo, p = path) {
  const rel = p.relative(raiz, alvo);
  return rel === '' || (rel !== '..' && !rel.startsWith('..' + p.sep) && !p.isAbsolute(rel));
}

/**
 * O nome do ficheiro tem de dizer MESTRE-ONLY e o ficheiro nunca pode cair na pasta estática (E-P13).
 * `p`: o módulo path (por omissão o da plataforma; os testes passam path.win32 / path.posix).
 */
export function conferirCaminhoJournal(caminho, pastaEstatica = null, p = path) {
  if (typeof caminho !== 'string' || !caminho) throw new ErroJournal('caminho do journal em falta');
  const alvo = p.resolve(caminho);
  if (!p.basename(alvo).includes(MARCA_MESTRE)) throw new ErroJournal('o nome do ficheiro do journal tem de dizer MESTRE-ONLY');
  if (pastaEstatica && dentroDaPasta(p.resolve(pastaEstatica), alvo, p)) {
    throw new ErroJournal('o journal não pode ficar na pasta estática (E-P13)');
  }
  return alvo;
}

/** Lê o ficheiro do disco. Devolve null se não existir; lança ErroJournal se existir com forma desconhecida. */
export function lerJournalDoDisco(caminho) {
  let conteudo;
  try {
    conteudo = readFileSync(caminho, 'utf8');
  } catch (e) {
    if (e && e.code === 'ENOENT') return null;
    throw e;
  }
  return abrirFicheiroJournal(conteudo);
}

/** Grava o envelope de uma vez: escreve ao lado e troca o nome (o ficheiro antigo nunca fica a meio). */
export function gravarJournalEmDisco(caminho, texto) {
  const temporario = caminho + '.a-gravar';
  try {
    writeFileSync(temporario, envelopeJournal(texto), { encoding: 'utf8', mode: 0o600 });
    renameSync(temporario, caminho);
  } catch (e) {
    // Ordem 17 (B1): a falha não deixa o «.a-gravar» (talvez a meio) ao lado do journal do Mestre.
    try {
      rmSync(temporario, { force: true });
    } catch {
      /* fica para a próxima tentativa, que o reescreve */
    }
    throw e;
  }
}

/**
 * Arranque: com ficheiro, restaura a partir dele; sem ficheiro, sala nova. Forma desconhecida ou journal
 * adulterado → {ok:false} e a sala NÃO abre (o ficheiro fica como estava, nada é escrito por cima).
 * @param {{caminho:string, criar:(restaurarDe:string|null)=>Object}} p
 */
export function abrirSalaComJournal({ caminho, criar }) {
  let texto;
  try {
    texto = lerJournalDoDisco(caminho);
  } catch (e) {
    return { ok: false, erro: e };
  }
  try {
    return { ok: true, sala: criar(texto), restaurada: texto !== null };
  } catch (e) {
    if (e instanceof ErroJournal) return { ok: false, erro: e };
    throw e;
  }
}

/**
 * Gravador ligado a uma sala: grava o journal sempre que a exportação muda (depois de cada commit).
 * Ordem 17 (B1; a parte do omisso 16-2 que não precisa da palavra do Mestre): a gravação que falhou fica `pendente()`
 * e o relógio do adaptador volta a tentá-la, mesmo que a mesa fique parada sem commits. A mesa continua como antes.
 */
export function criarGravadorJournal({ sala, caminho, registo = () => {} }) {
  let ultimo = null;
  let pendente = false;
  return {
    gravar() {
      const texto = sala.exportar();
      if (texto === ultimo) {
        pendente = false;
        return false;
      }
      try {
        gravarJournalEmDisco(caminho, texto);
        ultimo = texto;
        if (pendente) registo('journal: gravação em disco reposta');
        pendente = false;
        return true;
      } catch (e) {
        if (!pendente) registo('journal: falhou a gravação em disco (' + (e?.code ?? e?.message ?? 'erro') + ')');
        pendente = true;
        return false;
      }
    },
    /** Há uma exportação que ainda não chegou ao disco? */
    pendente: () => pendente,
  };
}

/** Sec-WebSocket-Key: base64 de exactamente 16 bytes (RFC 6455 §4.1 e §4.2.1) = 22 caracteres + «==». */
export function chaveWsValida(chave) {
  return typeof chave === 'string' && /^[A-Za-z0-9+/]{21}[AQgw]==$/.test(chave);
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
  // Nada de dotfiles nem "..". Ordem 17 (V5): os pedaços cortam-se também no «\», que o Windows lê como separador
  // («/sub%5C.segredo» servia sub\.segredo).
  if (caminho.includes('\0') || caminho.split(/[\\/]/).some((p) => p.startsWith('.') && p.length > 0)) {
    res.writeHead(404, cabecalhosBase).end();
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
    // Ordem 17 (V5): o caminho de verdade no disco também não pode ter dotfiles nem sair da pasta. No Windows o nome
    // curto 8.3 («SEGRED~1») abre «.segredo»; o realpath devolve o nome longo. Também apanha ligações para fora.
    const raizReal = await realpath(raiz);
    const real = await realpath(alvo);
    if (!dentroDaPasta(raizReal, real) || path.relative(raizReal, real).split(path.sep).some((p) => p.startsWith('.'))) {
      throw new Error('fora da pasta ou dotfile');
    }
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
 * @param {{sala:Object, pastaEstatica?:string, caminhoWs?:string, registo?:(t:string)=>void,
 *   journal?:{gravar:()=>boolean}}} p
 * IMPORTANTE: a pasta estática é só o cliente. Nunca lá ponha exportações do journal (E-P13).
 * `journal` (ordem 16): o gravador de criarGravadorJournal; grava ANTES de entregar as saídas.
 */
export function criarServidor({ sala, pastaEstatica = null, caminhoWs = '/ws', registo = () => {}, journal = null }) {
  const porLugar = new Map(); // seatId → Set<Ligacao>
  const todas = new Set();

  function associar(lig, seatId) {
    lig.seatId = seatId;
    lig.errosSemLugar = 0; // ordem 27 (N25-1): entrou na sala, a série acaba
    if (!porLugar.has(seatId)) porLugar.set(seatId, new Set());
    porLugar.get(seatId).add(lig);
  }

  function entregar(saidas) {
    if (journal) journal.gravar(); // o que a mesa vê já está em disco
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

  /**
   * Ordem 18 (V8): conta as rejeições de formato seguidas desta ligação e fecha-a (1008) ao chegar ao máximo (§2).
   * Antes só contava o ROOM_REJECT formato; o ERRO formato (JSON inválido aqui; tipo desconhecido ou sala errada no
   * núcleo) não contava, e um cliente podia mandar lixo sem fim. Qualquer outra resposta repõe a contagem, como antes.
   */
  function contarFormato(lig, formatoMal) {
    lig.rejeicoesFormato = formatoMal ? lig.rejeicoesFormato + 1 : 0;
    if (lig.rejeicoesFormato >= MAX_REJEICOES_FORMATO) lig.fechar(1008, 'formato');
  }

  function aoMensagem(lig, texto) {
    let msg;
    try {
      msg = JSON.parse(texto);
    } catch {
      lig.enviarJson({ v: 2, type: 'ERRO', codigo: 'formato', texto: 'JSON inválido.' });
      contarFormato(lig, true);
      return;
    }
    if (msg && msg.type === 'ROOM_JOIN') {
      // O seatToken vem na mensagem, nunca na URL (E-P9). Nunca o registar.
      const r = sala.entrar(msg, { ip: lig.ip, seatIdDaLigacao: lig.seatId });
      if (journal) journal.gravar(); // antes de qualquer resposta (também a de recusa)
      if (!r.ok) {
        for (const m of r.mensagens) lig.enviarJson(m);
        entregar(r.saidas);
        // Ordem 18 (V8): o JOIN mal formado não passa pelo travão do núcleo (não é tentativa de credenciais): conta aqui.
        contarFormato(lig, r.mensagens.some((m) => m?.type === 'ERRO' && m.codigo === 'formato'));
        return;
      }
      lig.rejeicoesFormato = 0;
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
      // Ordem 27 (N25-1): antes, sem fim. Os outros erros (formato, credenciais) não contam nem desfazem a série
      // (senão um JOIN errado pelo meio deixava-a recomeçar sem fim); só a entrada na sala a zera (associar).
      lig.errosSemLugar += 1;
      if (lig.errosSemLugar >= MAX_SEM_LUGAR) lig.fechar(1008, 'sem lugar');
      return;
    }
    const saidas = sala.receber(lig.seatId, msg);
    // Rejeições de formato repetidas (inclui o excesso de ritmo) fecham a ligação.
    const formatoMal = saidas.some((s) => s.seatId === lig.seatId && (
      (s.msg?.type === 'ROOM_REJECT' && s.msg.motivo === 'formato') || (s.msg?.type === 'ERRO' && s.msg.codigo === 'formato')));
    entregar(saidas);
    contarFormato(lig, formatoMal);
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
    // Ordem 25 (V20; RFC 6455 §4.2.1): só um GET em HTTP/1.1 ou acima, com uma chave que é base64 de 16 bytes. Antes, um
    // POST, um HTTP/1.0 ou a chave «x» (ou vazia) recebiam 101. (O «Connection: Upgrade» já o exige o http do Node.)
    const http11 = req.httpVersionMajor > 1 || (req.httpVersionMajor === 1 && req.httpVersionMinor >= 1);
    if (req.method !== 'GET' || !http11 || !chaveWsValida(chave)
      || String(req.headers.upgrade).toLowerCase() !== 'websocket' || versao !== '13') {
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
    // Ordem 17 (B1): a gravação do journal que falhou volta a tentar-se aqui, sem esperar por um commit novo.
    if (journal && typeof journal.pendente === 'function' && journal.pendente()) journal.gravar();
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
//    "sala":{ ...config de criarSala: lugares, iniciativa, mapa... },
//    "journal":"../privado/registo-MESTRE-ONLY-sala.json", "chaveJournal":"<opcional, HMAC>"}
// Ordem 16: com "journal", o adaptador grava o journal nesse ficheiro a cada commit (o ficheiro inteiro,
// trocado de uma vez) e, ao arrancar, restaura a partir dele. Forma desconhecida → a sala não abre.
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
  const pastaEstatica = cfg.pastaEstatica ? path.resolve(base, cfg.pastaEstatica) : null;
  const criar = (restaurarDe) => criarSala({
    motores, fichas: r.fichas, rng: rngNode(), agora: () => Date.now(), config: cfg.sala,
    chaveJournal: cfg.chaveJournal ?? null, restaurarDe,
  });
  let sala;
  let journal = null;
  if (cfg.journal) {
    const caminhoJournal = conferirCaminhoJournal(path.resolve(base, cfg.journal), pastaEstatica);
    const aberta = abrirSalaComJournal({ caminho: caminhoJournal, criar });
    if (!aberta.ok) {
      console.error('journal recusado: ' + (aberta.erro?.motivo ?? aberta.erro?.message ?? aberta.erro));
      process.exitCode = 1;
      return; // falha fechada: não restaura nada e não escreve por cima do ficheiro
    }
    sala = aberta.sala;
    console.log(aberta.restaurada ? 'sala restaurada do journal em disco' : 'sala nova (sem journal em disco)');
    journal = criarGravadorJournal({ sala, caminho: caminhoJournal, registo: (t) => console.error(t) });
    journal.gravar();
  } else {
    sala = criar(null);
  }
  const servidor = criarServidor({
    sala,
    pastaEstatica,
    registo: (t) => console.log(t),
    journal,
  });
  servidor.listen(cfg.porta ?? 8080, cfg.host ?? '0.0.0.0');
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  principal(process.argv).catch((e) => {
    console.error(e);
    process.exitCode = 1;
  });
}
