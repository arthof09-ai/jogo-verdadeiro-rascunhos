// Ordem PLANO-2-F2 — os bots das provas dos aparelhos (Node ≥ 22: o WebSocket global, sem bibliotecas).
//
// BotJogadora: entra com nome e senha, guarda o seatToken e, como o cliente Godot (rede/rede.gd), volta a entrar com o
// token e o lastSeq depois de cair, com espera crescente 1-2-4-8 s (±20 %). Joga só «encerrar» na vez dela (sem dados:
// a partida é a mesma em qualquer corrida). Confere o seq: cada ROOM_EVENT tem de ser o anterior + 1 (o snapshot dá a
// base). Os intentId são deterministas (rótulo + contador), para a corrida de controlo ser igual byte a byte.
// BotMestre: entra com o PIN e abre o combate (LOBBY_SET, START e, se houver, PLACE das criaturas). Com
// `jogarCriaturas` (uma função que diz se ainda joga), encerra a vez de cada criatura (MASTER_ACT, modo manual: sem dados).
// Só fichas fictícias.

const PROTOCOLO = 2;
export const ESPERA_MIN_S = 1;
export const ESPERA_MAX_S = 8; // o mesmo tecto do cliente (rede.gd, Ordem PLANO-2-F2)

/** UUID v4 determinista a partir de um texto (o servidor só exige a forma). */
export function uuidDeterminista(texto) {
  let h1 = 0x811c9dc5;
  let h2 = 0x01000193;
  const hex = [];
  for (let k = 0; k < 4; k++) {
    for (const c of texto + '#' + k) {
      h1 = Math.imul(h1 ^ c.charCodeAt(0), 16777619) >>> 0;
      h2 = Math.imul(h2 + c.charCodeAt(0), 2246822519) >>> 0;
    }
    hex.push(((h1 ^ h2) >>> 0).toString(16).padStart(8, '0'));
  }
  const s = hex.join('');
  return `${s.slice(0, 8)}-${s.slice(8, 12)}-4${s.slice(13, 16)}-${'89ab'[parseInt(s[16], 16) & 3]}${s.slice(17, 20)}-${s.slice(20, 32)}`;
}

export class BotJogadora {
  constructor({ url, nome, senha, rotulo, registo = () => {}, aoMinhaVez = null, jogar = true }) {
    Object.assign(this, { url, nome, senha, rotulo, registo, aoMinhaVez, jogar });
    this.token = null;
    this.seatId = null;
    this.roomId = null;
    this.figura = null;
    this.vez = null;
    this.revision = 0;
    this.base = null; // seq do último snapshot
    this.ultimoSeq = null; // seq do último ROOM_EVENT (ou do snapshot)
    this.seqs = []; // todos os seq dos ROOM_EVENT, pela ordem de chegada
    this.buracos = [];
    this.repetidos = [];
    this.snapshots = 0;
    this.entradas = 0; // ROOM_WELCOME recebidos
    this.vezesJogadas = 0;
    this.recusas = 0;
    this.revisoesAntigas = 0;
    this.turno = null; // a vez actual (seq do evento `turno`, ou do snapshot): uma jogada por vez
    this.jogouEm = null;
    this.contador = 0;
    this.emVoo = null;
    this.parado = false;
    this.espera = ESPERA_MIN_S;
    this.ws = null;
    this.quedas = 0;
    this.tentativas = 0;
    this.welcomes = []; // instantes (ms) de cada ROOM_WELCOME
    this.sincronizacoes = []; // por entrada: {eventos, snapshot}
    this.ligado = false;
  }

  ligar() {
    if (this.parado) return;
    this.tentativas += 1;
    let ws;
    try {
      ws = new WebSocket(this.url);
    } catch {
      this.agendar();
      return;
    }
    this.ws = ws;
    ws.onopen = () => {
      const join = { v: PROTOCOLO, type: 'ROOM_JOIN', papel: 'jogadora', cliente: 'bot-f2/' + this.rotulo };
      if (this.roomId) join.roomId = this.roomId;
      if (this.token) {
        join.seatToken = this.token;
        if (this.ultimoSeq !== null) join.lastSeq = this.ultimoSeq;
        this.lastSeqEnviado = join.lastSeq ?? null;
      } else {
        join.nome = this.nome;
        join.senha = this.senha;
      }
      ws.send(JSON.stringify(join));
    };
    ws.onmessage = (ev) => this.receber(JSON.parse(String(ev.data)));
    ws.onerror = () => {};
    ws.onclose = () => {
      if (this.ws !== ws) return;
      this.ws = null;
      if (this.ligado) this.quedas += 1;
      this.ligado = false;
      this.emVoo = null; // como a fila do cliente: a intenção fica DESCONHECIDA e o recibo diz o que foi
      this.agendar();
    };
  }

  agendar() {
    if (this.parado) return;
    const t = this.espera * (0.8 + Math.random() * 0.4);
    this.espera = Math.min(this.espera * 2, ESPERA_MAX_S);
    setTimeout(() => this.ligar(), t * 1000).unref?.();
  }

  parar() {
    this.parado = true;
    try {
      this.ws?.close();
    } catch {
      /* já fechada */
    }
  }

  receber(m) {
    if (Number.isInteger(m.revision) && m.revision > this.revision) this.revision = m.revision;
    if (m.type === 'ROOM_WELCOME') {
      this.token = m.seatToken;
      this.seatId = m.seatId;
      this.roomId = m.roomId;
      this.espera = ESPERA_MIN_S;
      this.ligado = true;
      this.entradas += 1;
      this.welcomes.push(Date.now());
      this.sincronizacoes.push({ lastSeqEnviado: this.token ? this.lastSeqEnviado ?? null : null, primeiroSeq: null,
        eventos: 0, snapshot: false });
    } else if (m.type === 'ROOM_SNAPSHOT') {
      this.snapshots += 1;
      if (this.sincronizacoes.length) this.sincronizacoes.at(-1).snapshot = true;
      this.base = m.seq;
      this.ultimoSeq = m.seq;
      if (m.propria?.figuraId) this.figura = m.propria.figuraId;
      if ('vezId' in m) this.vez = m.vezId;
      this.turno = 's' + m.seq;
    } else if (m.type === 'ROOM_EVENT') {
      if (this.sincronizacoes.length) {
        const sinc = this.sincronizacoes.at(-1);
        sinc.eventos += 1;
        if (sinc.primeiroSeq === null) sinc.primeiroSeq = m.seq;
      }
      if (this.ultimoSeq !== null) {
        if (m.seq <= this.ultimoSeq) this.repetidos.push(m.seq);
        else if (m.seq !== this.ultimoSeq + 1) this.buracos.push({ esperado: this.ultimoSeq + 1, veio: m.seq });
      }
      this.seqs.push(m.seq);
      if (this.ultimoSeq === null || m.seq > this.ultimoSeq) this.ultimoSeq = m.seq;
      if (m.tipo === 'turno' && m.dados?.figuraId) {
        this.vez = m.dados.figuraId;
        this.turno = 'e' + m.seq;
      }
      if (m.tipo === 'entrada' && !this.figura && m.dados?.figuraId && this.nome === m.dados?.nomePublico) this.figura = m.dados.figuraId;
    } else if ((m.type === 'ROOM_RECEIPT' || m.type === 'ROOM_REJECT') && m.intentId && m.intentId === this.emVoo) {
      this.emVoo = null;
      // A revisão que o bot viu ficou para trás (chegou outra coisa à mesa entretanto): como o cliente, tenta outra
      // vez com a revisão nova. Não fica no journal (rejeição não gravada), por isso não conta como recusa.
      if (m.type === 'ROOM_REJECT' && m.motivo === 'revisao_antiga') {
        this.revisoesAntigas += 1;
        this.jogouEm = null;
      } else if (m.type === 'ROOM_REJECT' || m.estado === 'RECUSADA') this.recusas += 1;
    } else if (m.type === 'ERRO') {
      this.registo(`[${this.rotulo}] ERRO ${m.codigo}: ${m.texto}`);
    }
    this.talvezJogar();
  }

  talvezJogar() {
    if (!this.jogar || !this.ligado || this.emVoo || !this.figura || this.vez !== this.figura) return;
    if (this.jogouEm !== null && this.jogouEm === this.turno) return;
    if (this.aoMinhaVez && this.aoMinhaVez(this) === false) return;
    this.jogouEm = this.turno;
    this.contador += 1;
    this.emVoo = uuidDeterminista(`${this.rotulo}|${this.contador}`);
    this.vezesJogadas += 1;
    this.ws.send(JSON.stringify({
      v: PROTOCOLO, type: 'ROOM_INTENT', roomId: this.roomId, intentId: this.emVoo, revision: this.revision,
      acao: { tipo: 'encerrar' },
    }));
  }
}

export class BotMestre {
  constructor({ url, pin, registo = () => {}, jogarCriaturas = null }) {
    Object.assign(this, { url, pin, registo, jogarCriaturas });
    this.criaturas = new Set();
    this.vez = null;
    this.emVoo = null;
    this.atos = 0;
    this.revision = 0;
    this.respostas = new Map();
    this.n = 0;
    this.ws = null;
    this.vista = null;
  }

  ligar() {
    return new Promise((resolver, rejeitar) => {
      const ws = new WebSocket(this.url);
      this.ws = ws;
      const limite = setTimeout(() => rejeitar(new Error('o Mestre-bot não entrou em 10 s')), 10000);
      ws.onopen = () => ws.send(JSON.stringify({ v: PROTOCOLO, type: 'ROOM_JOIN', papel: 'mestre', pin: this.pin, cliente: 'bot-f2/mestre' }));
      ws.onerror = () => {};
      ws.onmessage = (ev) => {
        const m = JSON.parse(String(ev.data));
        if (Number.isInteger(m.revision) && m.revision > this.revision) this.revision = m.revision;
        if (m.type === 'MASTER_VIEW') this.vista = m;
        if (m.type === 'ROOM_EVENT' && m.tipo === 'colocacao' && m.dados?.lado && m.dados.lado !== 'jogadora') this.criaturas.add(m.dados.figuraId);
        if (m.type === 'ROOM_EVENT' && m.tipo === 'turno' && m.dados?.figuraId) this.vez = m.dados.figuraId;
        if (m.type === 'ROOM_WELCOME') {
          clearTimeout(limite);
          resolver();
        }
        if (m.type === 'ERRO' && !this.vista) {
          clearTimeout(limite);
          rejeitar(new Error(`o Mestre-bot foi recusado: ${m.codigo}`));
        }
        const id = m.cmdId ?? m.intentId;
        if (id && (m.type === 'ROOM_RECEIPT' || m.type === 'ROOM_REJECT')) {
          if (id === this.emVoo) this.emVoo = null;
          this.respostas.get(id)?.(m);
        }
        this.talvezAgir();
      };
    });
  }

  comando(type, campos = {}) {
    const cmdId = uuidDeterminista(`mestre|${++this.n}|${type}`);
    return new Promise((resolver, rejeitar) => {
      const limite = setTimeout(() => rejeitar(new Error(`${type}: sem recibo em 10 s`)), 10000);
      this.respostas.set(cmdId, (m) => {
        clearTimeout(limite);
        this.respostas.delete(cmdId);
        if (m.type === 'ROOM_RECEIPT' && m.estado === 'APLICADA') resolver(m);
        else rejeitar(new Error(`${type}: ${m.estado ?? m.motivo}`));
      });
      this.ws.send(JSON.stringify({ v: PROTOCOLO, type, cmdId, revision: this.revision, ...campos }));
    });
  }

  talvezAgir() {
    if (!this.jogarCriaturas || this.emVoo || !this.criaturas.has(this.vez) || !this.jogarCriaturas()) return;
    this.emVoo = uuidDeterminista(`mestre-act|${++this.atos}`);
    this.ws.send(JSON.stringify({ v: PROTOCOLO, type: 'MASTER_ACT', intentId: this.emVoo, revision: this.revision,
      figuraId: this.vez, acao: { tipo: 'encerrar' } }));
  }

  /** Abre o combate: LOBBY_SET (com as `disponiveis` para colocar mais tarde), START e o PLACE de cada criatura. */
  async abrirCombate({ criaturas = [], disponiveis = [], mapaId = 'floresta' } = {}) {
    const ids = [...new Set([...disponiveis, ...criaturas.map(([f]) => f)])];
    await this.comando('MASTER_LOBBY_SET', { mapaId, criaturasDisponiveis: ids, npcsDisponiveis: [] });
    await this.comando('MASTER_START');
    for (const [fichaId, casa] of criaturas) await this.comando('MASTER_PLACE', { fichaId, casa });
  }
}
