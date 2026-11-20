// ORDEM PROVAS-MAPA (prova 2): o MESTRE e o ESPECTADOR da batalha de bancada, pela ligação de verdade (WebSocket).
// A jogadora é o cliente Godot (bancada_jogadora_mapa.gd), já na mesa quando isto arranca.
//
//   node bancada-mestre.mjs 8791 <relatorio.json>
//
// Mestre: lobby → começar → o orc DENTRO DO LAGO (38,11) → espera o passo da heroína a 1,5 m → escala 1 m → espera
// o passo a 1 m → escala 2 m → espera o passo a 2 m → fim. Regista o que o Mestre recebe de cada mudança (grelhaAntes,
// grelha, as figuras antes e depois).
// Espectador: recebe tudo o que a Party recebe; no fim, a SONDA DE PRIVACIDADE varre as mensagens dele.
// Só fichas fictícias. Sai com 0 se tudo correu e a sonda está limpa, 1 se não.
import { randomUUID } from 'node:crypto';
import { writeFileSync } from 'node:fs';
import { PIN, SENHAS, FIXTURE, procurarCanarios } from '../../../../rascunhos/servidor/testes/ajudantes.mjs';

const porta = Number(process.argv[2] ?? 8791);
const saida = process.argv[3] ?? null;
const ROOM = 'sala-bancada-mapa';
const ORC_CASA = { x: 38, y: 11 };
const ESCALAS = [1, 2];
const rel = { mestre: { recibos: [], escalas: [], movimentos: [] }, espectador: {}, falhas: [] };
const log = (t) => console.log(`[mestre] ${t}`);
const falhar = (t) => { rel.falhas.push(t); console.error(`[mestre] FALHA: ${t}`); };

function cliente(join, aoReceber) {
  const ws = new WebSocket(`ws://127.0.0.1:${porta}/ws`);
  const c = { ws, msgs: [], revision: 0, espera: new Map() };
  ws.onopen = () => ws.send(JSON.stringify({ v: 2, type: 'ROOM_JOIN', roomId: ROOM, ...join }));
  ws.onmessage = (ev) => {
    const m = JSON.parse(String(ev.data));
    c.msgs.push(m);
    if (Number.isInteger(m.revision) && m.revision > c.revision) c.revision = m.revision;
    const id = m.cmdId ?? m.intentId;
    if ((m.type === 'ROOM_RECEIPT' || m.type === 'ROOM_REJECT') && c.espera.has(id)) {
      c.espera.get(id)(m);
      c.espera.delete(id);
    }
    aoReceber?.(m);
  };
  return c;
}

const esperarAte = (cond, ms, rotulo) => new Promise((ok, nao) => {
  const t0 = Date.now();
  const v = () => (cond() ? ok() : Date.now() - t0 > ms ? nao(new Error('tempo esgotado: ' + rotulo)) : setTimeout(v, 50));
  v();
});

let mestre;
function comando(type, campos = {}) {
  const cmdId = randomUUID();
  return new Promise((ok) => {
    mestre.espera.set(cmdId, (r) => {
      rel.mestre.recibos.push({ type, campos, recibo: r.type, estado: r.estado ?? null, motivo: r.motivo ?? null });
      log(`${type} ${JSON.stringify(campos)} → ${r.type} ${r.estado ?? r.motivo ?? ''}`);
      ok(r);
    });
    mestre.ws.send(JSON.stringify({ v: 2, type, roomId: ROOM, cmdId, revision: mestre.revision, ...campos }));
  });
}
const exigir = async (p, rotulo) => {
  const r = await p;
  if (r.type !== 'ROOM_RECEIPT' || r.estado !== 'APLICADA') falhar(`${rotulo}: ${JSON.stringify(r)}`);
  return r;
};

/** As figuras como o Mestre as vê (o último snapshot dele). */
function figurasDoMestre() {
  const s = [...mestre.msgs].reverse().find((m) => m.type === 'ROOM_SNAPSHOT');
  return { mapa: s?.mapa ?? null, figuras: (s?.figuras ?? []).map((f) => ({ id: f.id, nome: f.nomePublico, x: f.x, y: f.y })) };
}

const limite = setTimeout(() => { falhar('tempo esgotado (180 s)'); fim(); }, 180000);
let movimentos = 0;
mestre = cliente({ papel: 'mestre', pin: PIN }, (m) => {
  if (m.type === 'ROOM_EVENT' && m.tipo === 'movimento') {
    movimentos += 1;
    rel.mestre.movimentos.push(m.dados ?? null);
  }
  if (m.type === 'ROOM_EVENT' && m.tipo === 'escala') rel.mestre.escalas.push({ evento: m.dados ?? null });
});
const espectador = cliente({ papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador });

try {
  await esperarAte(() => mestre.msgs.some((m) => m.type === 'ROOM_WELCOME'), 10000, 'Mestre entrou');
  await esperarAte(() => espectador.msgs.some((m) => m.type === 'ROOM_WELCOME'), 10000, 'espectador entrou');
  log('na mesa (Mestre e espectador)');
  await exigir(comando('MASTER_LOBBY_SET', { mapaId: 'arena-teste', criaturasDisponiveis: ['orc-teste'], npcsDisponiveis: [] }), 'LOBBY_SET');
  await exigir(comando('MASTER_START'), 'START');
  await exigir(comando('MASTER_PLACE', { fichaId: 'orc-teste', casa: ORC_CASA }), 'PLACE orc no lago');
  rel.mestre.inicio = figurasDoMestre();
  for (const [i, casaM] of ESCALAS.entries()) {
    await esperarAte(() => movimentos >= i + 1, 90000, `o passo ${i + 1} da heroína`);
    await new Promise((r) => setTimeout(r, 300));
    const antes = figurasDoMestre();
    const n = rel.mestre.escalas.length;
    await exigir(comando('MASTER_SUPERVISOR', { op: 'escala', casaM }), `escala ${casaM}`);
    await esperarAte(() => rel.mestre.escalas.length > n, 5000, `evento escala ${casaM}`).catch((e) => falhar(e.message));
    await new Promise((r) => setTimeout(r, 300));
    rel.mestre.escalas[rel.mestre.escalas.length - 1] = { ...rel.mestre.escalas.at(-1), casaM, antes, depois: figurasDoMestre() };
  }
  await esperarAte(() => movimentos >= ESCALAS.length + 1, 90000, 'o passo a 2 m');
  await new Promise((r) => setTimeout(r, 800));
  rel.mestre.final = figurasDoMestre();
} catch (e) {
  falhar(e.message);
}
fim();

function fim() {
  clearTimeout(limite);
  // A SONDA DE PRIVACIDADE no fio do espectador (o que a Party recebe): números do orc (os ≥ 100) e da heroína (são dela,
  // o espectador não os vê), textos e chaves só do Mestre.
  const num = (id) => { const f = FIXTURE.fichas.find((x) => x.id === id); return [f.ca, f.vidaTotal, f.paTotal].filter((v) => typeof v === 'number' && v >= 100); };
  const canarios = {
    numeros: [...num('orc-teste'), ...num('heroina-teste')],
    textos: ['ESCALA_', 'CANARIO-FANTASMA', 'CANARIO-DESGRACA', 'CANARIO-SENHA', 'Orc Verdadeiro', PIN],
    chaves: ['casaMAntes', 'grelhaAntes', 'casasQuePaga', 'soMestre'],
  };
  const achados = procurarCanarios(espectador.msgs, canarios);
  const mapas = espectador.msgs.filter((m) => m.type === 'ROOM_SNAPSHOT').map((m) => m.mapa);
  const escalasVistas = espectador.msgs.filter((m) => m.type === 'ROOM_EVENT' && m.tipo === 'escala').map((m) => m.dados ?? null);
  rel.espectador = { mensagens: espectador.msgs.length, canarios, achados, mapasVistos: [...new Set(mapas.map((x) => JSON.stringify(x)))].map((x) => JSON.parse(x)), eventosEscala: escalasVistas };
  if (achados.length) falhar(`sonda do espectador: ${achados.length} achados ${JSON.stringify(achados.slice(0, 5))}`);
  const sanidade = JSON.stringify(mestre.msgs).includes('grelhaAntes');
  rel.mestre.sanidadeGrelhaAntes = sanidade;
  if (!sanidade) falhar('sanidade: o Mestre não recebeu o grelhaAntes');
  log(`espectador: ${espectador.msgs.length} mensagens, ${achados.length} achados; mapas vistos ${JSON.stringify(rel.espectador.mapasVistos)}`);
  if (saida) writeFileSync(saida, JSON.stringify(rel, null, 1));
  log(rel.falhas.length ? `${rel.falhas.length} FALHAS` : 'TUDO PASSOU');
  try { mestre.ws.close(); espectador.ws.close(); } catch { /* fecha como puder */ }
  setTimeout(() => process.exit(rel.falhas.length ? 1 : 0), 200);
}
