// Journal da sala: eventos, estado e recibos gravados JUNTOS (princípio 8).
// REGRA: sem node:*. O hash é SHA-256 em JS puro (./sha256.js) ou injetado.
//
// Formato da exportação (MESTRE-ONLY, E-P13):
//   <JSON canónico do corpo>\n<assinatura>\n
// em que <assinatura> é "sha256:<hex>" ou, com chave, "hmac-sha256:<hex>".
// A restauração recusa qualquer byte adulterado: no corpo, na assinatura ou na moldura.
// Nota honesta: sem chave, o "sha256:" só apanha adulteração ingénua ou acidental
// (quem altera pode recalcular o hash). Com `chave` (HMAC), só quem tem a chave assina.

import { sha256Hex, hmacSha256Hex } from './sha256.js';
import { jsonCanonico, clonarJson, congelarProfundo, iguaisTempoConstante } from './util.js';

// Ordem 17 (V3): o journal guarda CÓPIAS congeladas dos eventos, das mensagens dos fluxos e dos recibos. Antes guardava
// as referências que lhe passavam: quem mexesse numa saída entregue (a mesma mensagem vai ao fluxo e à mesa) ou no que o
// journal devolve mudava o registo exportado, e um evento mexido partia a cadeia do restauro.
const copiaFixa = (v) => congelarProfundo(clonarJson(v));
const ehObjecto = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);

export const FORMATO_JOURNAL = 'journal-sala/1';
const CADEIA_ZERO = '0'.repeat(64);

export class ErroJournal extends Error {
  constructor(motivo) {
    super(motivo);
    this.name = 'ErroJournal';
    this.motivo = motivo;
  }
}

/**
 * @param {{estadoInicial?:Object, restaurado?:Object, hash?:(s:string)=>string}} p
 */
export function criarJournal({ estadoInicial, restaurado, hash = sha256Hex } = {}) {
  let estado;
  const eventos = [];
  const recibos = new Map(); // chave "seatId\u0000id" → recibo
  const fluxos = new Map(); // seatId → [mensagens já projetadas e numeradas]
  let hashCadeia = CADEIA_ZERO;

  if (restaurado) {
    estado = clonarJson(restaurado.estado);
    for (const ev of restaurado.eventos) eventos.push(copiaFixa(ev));
    for (const [k, r] of restaurado.recibos) recibos.set(k, copiaFixa(r));
    for (const [s, f] of Object.entries(restaurado.fluxos)) fluxos.set(s, f.map(copiaFixa));
    hashCadeia = restaurado.hashCadeia;
  } else {
    estado = clonarJson(estadoInicial ?? {});
  }

  function proximaCadeia(anterior, ev) {
    return hash(anterior + jsonCanonico(ev));
  }

  return {
    get estado() {
      return estado;
    },
    get journalSeq() {
      return eventos.length;
    },
    get hashCadeia() {
      return hashCadeia;
    },
    /** Cópia dos eventos internos (só para o Mestre, exportação e testes). */
    eventos() {
      return clonarJson(eventos);
    },
    /** O recibo gravado (congelado: para mudar, faz-se uma cópia e grava-se num commit). */
    recibo(chave) {
      return recibos.get(chave) ?? null;
    },
    *todosRecibos() {
      yield* recibos.entries();
    },
    /** As mensagens gravadas do lugar (congeladas), numa lista nova: mexer na lista não muda o fluxo. */
    fluxo(seatId) {
      return (fluxos.get(seatId) ?? []).slice();
    },

    /**
     * Grava evento(s), estado novo e recibo(s) de uma vez.
     * Primeiro valida e calcula tudo; só depois muda. Se a validação falhar, nada muda.
     * @param {{estado:Object, eventos:Array, recibos:Array<[string,Object]>, fluxos:Object<string,Array>}} tx
     */
    commit(tx) {
      // 1) validar (pode lançar; nada mudou ainda)
      if (!tx || typeof tx.estado !== 'object' || tx.estado === null) throw new ErroJournal('commit sem estado');
      const novos = (tx.eventos ?? []).map(copiaFixa); // o que se grava (e se encadeia) é a cópia
      novos.forEach((ev, i) => {
        if (ev.journalSeq !== eventos.length + 1 + i) throw new ErroJournal('journalSeq com buraco');
      });
      let cadeia = hashCadeia;
      for (const ev of novos) cadeia = proximaCadeia(cadeia, ev);
      const textoEstado = JSON.stringify(tx.estado); // garante JSON puro antes de gravar
      const novoEstado = JSON.parse(textoEstado);
      const novosRecibos = (tx.recibos ?? []).map(([k, r]) => [k, copiaFixa(r)]);
      const novosFluxos = Object.entries(tx.fluxos ?? {}).map(([s, msgs]) => [s, msgs.map(copiaFixa)]);
      for (const [s, msgs] of novosFluxos) {
        const atual = fluxos.get(s) ?? [];
        msgs.forEach((m, i) => {
          if (m.seq !== atual.length + 1 + i) throw new ErroJournal(`seq com buraco no lugar ${s}`);
        });
      }
      // 2) aplicar (operações que não lançam)
      for (const ev of novos) eventos.push(ev);
      estado = novoEstado;
      for (const [k, r] of novosRecibos) recibos.set(k, r);
      for (const [s, msgs] of novosFluxos) {
        if (!fluxos.has(s)) fluxos.set(s, []);
        const f = fluxos.get(s);
        for (const m of msgs) f.push(m);
      }
      hashCadeia = cadeia;
    },

    /** Hash lógico do estado (para comparar replays e restaurações). */
    hashEstado() {
      return hash(jsonCanonico(estado));
    },

    /**
     * Exportação MESTRE-ONLY. Leva o hash dos seatToken (no estado), nunca o token.
     * PIN e senha nunca entram (vivem só na memória da sala).
     */
    exportar({ chave } = {}) {
      const corpo = {
        formato: FORMATO_JOURNAL,
        marca: 'MESTRE-ONLY',
        eventos,
        estado,
        recibos: [...recibos.entries()].sort((a, b) => (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0)),
        fluxos: Object.fromEntries(fluxos.entries()),
        hashCadeia,
      };
      const texto = jsonCanonico(corpo);
      const assinatura = chave ? 'hmac-sha256:' + hmacSha256Hex(chave, texto) : 'sha256:' + hash(texto);
      return texto + '\n' + assinatura + '\n';
    },
  };
}

/**
 * Restaura um journal exportado. Lança ErroJournal se 1 byte que seja estiver adulterado.
 * @param {string} exportado
 * @param {{chave?:string, hash?:(s:string)=>string}} [opcoes]
 */
export function restaurarJournal(exportado, { chave, hash = sha256Hex } = {}) {
  if (typeof exportado !== 'string') throw new ErroJournal('exportação tem de ser texto');
  if (!exportado.endsWith('\n')) throw new ErroJournal('moldura inválida');
  const semFim = exportado.slice(0, -1);
  const corte = semFim.lastIndexOf('\n');
  if (corte < 0) throw new ErroJournal('moldura inválida');
  const texto = semFim.slice(0, corte);
  const assinatura = semFim.slice(corte + 1);

  let esperada;
  if (chave) esperada = 'hmac-sha256:' + hmacSha256Hex(chave, texto);
  else esperada = 'sha256:' + hash(texto);
  if (!iguaisTempoConstante(assinatura, esperada)) throw new ErroJournal('assinatura não confere: exportação adulterada');

  let corpo;
  try {
    corpo = JSON.parse(texto);
  } catch {
    throw new ErroJournal('JSON inválido');
  }
  if (!corpo || corpo.formato !== FORMATO_JOURNAL || corpo.marca !== 'MESTRE-ONLY') throw new ErroJournal('formato desconhecido');
  if (jsonCanonico(corpo) !== texto) throw new ErroJournal('texto não está na forma canónica');
  if (!Array.isArray(corpo.eventos) || !Array.isArray(corpo.recibos) || !ehObjecto(corpo.fluxos) || !ehObjecto(corpo.estado)) {
    throw new ErroJournal('corpo incompleto');
  }
  // Ordem 17 (V2): a forma de cada parte confere-se aqui. Sem chave, o "sha256:" recalcula-se; um corpo bem assinado com
  // a estrutura errada dava TypeError (que o adaptador não trata como «journal recusado»), não ErroJournal.
  if (typeof corpo.hashCadeia !== 'string') throw new ErroJournal('cadeia de eventos não confere');
  if (!corpo.eventos.every(ehObjecto)) throw new ErroJournal('evento inválido');
  if (!corpo.recibos.every((p) => Array.isArray(p) && p.length === 2 && typeof p[0] === 'string' && ehObjecto(p[1]))) {
    throw new ErroJournal('recibo inválido');
  }
  // Cadeia de eventos: o replay tem de dar o mesmo hash.
  let cadeia = CADEIA_ZERO;
  corpo.eventos.forEach((ev, i) => {
    if (ev.journalSeq !== i + 1) throw new ErroJournal('journalSeq com buraco');
    cadeia = hash(cadeia + jsonCanonico(ev));
  });
  if (cadeia !== corpo.hashCadeia) throw new ErroJournal('cadeia de eventos não confere');
  for (const [s, f] of Object.entries(corpo.fluxos)) {
    if (!Array.isArray(f)) throw new ErroJournal('fluxo inválido');
    f.forEach((m, i) => {
      if (!ehObjecto(m)) throw new ErroJournal('fluxo inválido');
      if (m.seq !== i + 1) throw new ErroJournal(`seq com buraco no lugar ${s}`);
    });
  }
  return criarJournal({ restaurado: corpo, hash });
}
