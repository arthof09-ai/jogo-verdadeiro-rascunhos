// Ordem 34 do CM-000009 — N32-1 (sentença da bancada, 2026-11-12): a fila de MASTER_ALERTA que não se perde.
// Núcleo puro (sem node:*): a sala junta cada alerta aqui, esteja o Mestre ligado ou não; o adaptador grava o texto
// de `exportar()` num ficheiro PRÓPRIO (separado do journal e do estado de jogo: avisos não se misturam com estado) e
// devolve-o no arranque (`restaurarDe`). Regras fechadas pela bancada:
//  - cada alerta com id único, número de ordem (1, 2, … pela sala, continua depois do reinício) e hora (ISO);
//  - 100 por sala (MAX_ALERTAS): ao entrar o 101.º sai o mais antigo; 7 dias de retenção (RETENCAO_MS): o que
//    expira sai também; toda a perda soma em `perdidos` (o próximo bloco abre com «perdidos por limite: N»);
//  - só sai da fila com a confirmação do cliente do Mestre, por id; os `perdidos` que o bloco levava descontam-se
//    com a confirmação desse bloco (as perdas chegadas depois ficam para o bloco seguinte).
// Um ficheiro estragado não se repara: `ErroFilaAlertas` (a sala não abre, como o journal: falha fechada).

export const MAX_ALERTAS = 100;
export const RETENCAO_MS = 7 * 24 * 3600 * 1000;
export const FORMATO_FILA_ALERTAS = 'alertas-mestre/1';
const MARCA = 'MESTRE-ONLY';
const RE_ID = /^[A-Za-z0-9_-]{1,64}$/;
const CAMPOS_EXTRA = Object.freeze(['alvo', 'papel', 'nome']);

export class ErroFilaAlertas extends Error {
  constructor(motivo) {
    super(motivo);
    this.name = 'ErroFilaAlertas';
  }
}

const ehIntPos = (v, min) => Number.isInteger(v) && v >= min;

function conferirAlerta(a, i) {
  const p = `alertas.${i}`;
  if (!a || typeof a !== 'object' || Array.isArray(a)) throw new ErroFilaAlertas(`${p}: não é objecto`);
  if (typeof a.id !== 'string' || !RE_ID.test(a.id)) throw new ErroFilaAlertas(`${p}.id: não é id`);
  if (!ehIntPos(a.ordem, 1)) throw new ErroFilaAlertas(`${p}.ordem: não é inteiro >= 1`);
  if (typeof a.hora !== 'string' || Number.isNaN(Date.parse(a.hora))) throw new ErroFilaAlertas(`${p}.hora: não é hora`);
  if (typeof a.motivo !== 'string' || !a.motivo) throw new ErroFilaAlertas(`${p}.motivo: não é texto`);
  for (const k of Object.keys(a)) {
    if (!['id', 'ordem', 'hora', 'motivo', ...CAMPOS_EXTRA].includes(k)) throw new ErroFilaAlertas(`${p}.${k}: campo desconhecido`);
  }
  for (const k of CAMPOS_EXTRA) {
    if (a[k] !== undefined && typeof a[k] !== 'string') throw new ErroFilaAlertas(`${p}.${k}: não é texto`);
  }
}

/** Confere o texto de um ficheiro da fila (forma, campos, limites). Devolve o corpo; lança ErroFilaAlertas. */
export function conferirTextoFilaAlertas(texto) {
  let c;
  try {
    c = JSON.parse(texto);
  } catch {
    throw new ErroFilaAlertas('não é JSON');
  }
  if (!c || typeof c !== 'object' || Array.isArray(c)) throw new ErroFilaAlertas('não é objecto');
  if (c.formato !== FORMATO_FILA_ALERTAS) throw new ErroFilaAlertas('formato desconhecido');
  if (c.marca !== MARCA) throw new ErroFilaAlertas('sem a marca MESTRE-ONLY');
  if (!ehIntPos(c.proximaOrdem, 1)) throw new ErroFilaAlertas('proximaOrdem: não é inteiro >= 1');
  if (!ehIntPos(c.perdidos, 0)) throw new ErroFilaAlertas('perdidos: não é inteiro >= 0');
  if (!Array.isArray(c.alertas)) throw new ErroFilaAlertas('alertas: não é lista');
  if (c.alertas.length > MAX_ALERTAS) throw new ErroFilaAlertas(`alertas: mais de ${MAX_ALERTAS}`);
  const ids = new Set();
  let anterior = 0;
  c.alertas.forEach((a, i) => {
    conferirAlerta(a, i);
    if (ids.has(a.id)) throw new ErroFilaAlertas(`alertas.${i}.id: repetido`);
    ids.add(a.id);
    if (a.ordem <= anterior) throw new ErroFilaAlertas(`alertas.${i}.ordem: fora de ordem`);
    anterior = a.ordem;
  });
  if (anterior >= c.proximaOrdem) throw new ErroFilaAlertas('proximaOrdem: não é maior que a última ordem');
  return c;
}

/**
 * @param {{agora:()=>number, novoId:(ordem:number, ts:number)=>string, restaurarDe?:string|null}} p
 */
export function criarFilaAlertas({ agora, novoId, restaurarDe = null }) {
  let alertas = [];
  let proximaOrdem = 1;
  let perdidos = 0;
  if (restaurarDe !== null && restaurarDe !== undefined) {
    const c = conferirTextoFilaAlertas(restaurarDe);
    alertas = c.alertas.map((a) => ({ ...a }));
    proximaOrdem = c.proximaOrdem;
    perdidos = c.perdidos;
  }

  /** Tira os que passaram dos 7 dias (contam como perdidos). */
  function expirar() {
    if (!alertas.length) return; // fila vazia: nada expira (e o relógio não é consultado)
    const t = agora();
    const antes = alertas.length;
    alertas = alertas.filter((a) => t - Date.parse(a.hora) < RETENCAO_MS);
    perdidos += antes - alertas.length;
  }

  return Object.freeze({
    /** Junta um alerta (com id, ordem e hora) e devolve-o. Ao passar dos 100, sai o mais antigo (perdido). */
    juntar(motivo, extra = {}) {
      expirar();
      const ts = agora();
      const ordem = proximaOrdem++;
      let id = novoId(ordem, ts);
      while (alertas.some((a) => a.id === id)) id = novoId(ordem, ts + 1); // nunca acontece com o hash da sala
      const a = { id, ordem, hora: new Date(ts).toISOString(), motivo };
      for (const k of CAMPOS_EXTRA) if (typeof extra[k] === 'string') a[k] = extra[k];
      alertas.push(a);
      while (alertas.length > MAX_ALERTAS) {
        alertas.shift();
        perdidos += 1;
      }
      return { ...a };
    },
    /** O que está por confirmar, por ordem, e os perdidos por contar ao Mestre. */
    pendentes() {
      expirar();
      return { alertas: alertas.map((a) => ({ ...a })), perdidos };
    },
    /** Confirmação do cliente do Mestre: os ids saem; os perdidos que o bloco levava descontam-se. */
    confirmar(ids, perdidosVistos = 0) {
      const s = new Set(ids);
      alertas = alertas.filter((a) => !s.has(a.id));
      if (Number.isInteger(perdidosVistos) && perdidosVistos > 0) perdidos = Math.max(0, perdidos - perdidosVistos);
    },
    /** O texto do ficheiro próprio da fila (MESTRE-ONLY). */
    exportar() {
      return JSON.stringify({ formato: FORMATO_FILA_ALERTAS, marca: MARCA, proximaOrdem, perdidos, alertas });
    },
  });
}
