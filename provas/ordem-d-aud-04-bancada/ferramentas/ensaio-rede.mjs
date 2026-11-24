// ORDEM-D-AUD-04-BANCADA — ENSAIO DE REDE das fichas que acertam (calibração; NÃO é a batalha medida).
//
//   node provas/ordem-d-aud-04-bancada/ferramentas/ensaio-rede.mjs --privado=<pasta fora do Git> [--porta=8792]
//        [--motor=real|falso] [--rodadas=30]
//
// Arranca o servidor de PRODUÇÃO (servidor-ws.js) com a config que o `bancada-rede/preparar.mjs --fichas=acertam`
// escreve (motor real VLAB por omissão), entra como Mestre e como a Arqueira de Bancada pela rede (WebSocket, como o
// porteiro), prepara a mesa como o porteiro (LOBBY_SET → START → lobo e bruto em terra) e joga a arqueira sozinha:
// na vez dela ataca (o tiro certeiro enquanto houver PA, senão o arco; o lobo primeiro) e encerra; a dormir, encerra
// (a vez é o teste de morte). Os monstros jogam em `auto`. Pára no `fim` ou ao fim de --rodadas.
// No fim lê o journal do servidor e imprime uma linha JSON com a contagem: ataques, acertos, danos, quedas,
// testes de morte, mortes e o desfecho. Serve para provar, SEM janelas, que a bancada acerta antes de a correr com os
// clientes Godot (a batalha medida, com o ecrã do Mestre em Godot, é a do lancar.ps1 -Fichas acertam).
// Não toca no jogo: só escreve em --privado.
import { spawn, execFileSync } from 'node:child_process';
import { readFileSync, mkdirSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(AQUI, '..', '..', '..');
const SERVIDOR = path.join(REPO, 'rascunhos', 'servidor');
const args = Object.fromEntries(process.argv.slice(2).map((a) => {
  const m = /^--([^=]+)(?:=(.*))?$/.exec(a);
  return m ? [m[1], m[2] ?? true] : [a, true];
}));
const PRIVADO = path.resolve(String(args.privado ?? ''));
if (!args.privado) { console.error('falta --privado=<pasta>'); process.exit(2); }
const PORTA = Number(args.porta ?? 8792);
const RODADAS = Number(args.rodadas ?? 30);
mkdirSync(PRIVADO, { recursive: true });
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (t) => console.error(`[ensaio] ${t}`);

execFileSync(process.execPath, [path.join(REPO, 'bancada-rede', 'preparar.mjs'), `--privado=${PRIVADO}`, `--porta=${PORTA}`,
  '--host=127.0.0.1', `--motor=${args.motor ?? 'real'}`, '--modo=auto', '--fichas=acertam'], { stdio: ['ignore', 'inherit', 'inherit'] });
const cfg = JSON.parse(readFileSync(path.join(PRIVADO, 'config.json'), 'utf8'));
const srv = spawn(process.execPath, [path.join(SERVIDOR, 'adaptadores', 'node', 'servidor-ws.js'), path.join(PRIVADO, 'config.json')],
  { cwd: SERVIDOR, stdio: ['ignore', 'pipe', 'inherit'] });
await new Promise((ok) => srv.stdout.on('data', (d) => { if (String(d).includes('servidor de mesa pronto')) ok(); }));
const URL = `ws://127.0.0.1:${PORTA}/ws`;
const ROOM = cfg.sala.roomId;

function ligar(join) {
  return new Promise((ok, nao) => {
    const ws = new WebSocket(URL);
    const c = { ws, revision: 0, msgs: [], espera: new Map(), aoReceber: null };
    ws.onopen = () => ws.send(JSON.stringify({ v: 2, type: 'ROOM_JOIN', ...join, cliente: 'ensaio-d-aud-04' }));
    ws.onmessage = (ev) => {
      const m = JSON.parse(String(ev.data));
      c.msgs.push(m);
      if (Number.isInteger(m.revision) && m.revision > c.revision) c.revision = m.revision;
      if (m.type === 'ROOM_WELCOME') ok(c);
      if (m.type === 'ERRO') nao(new Error(JSON.stringify(m)));
      const id = m.cmdId ?? m.intentId;
      if ((m.type === 'ROOM_RECEIPT' || m.type === 'ROOM_REJECT') && c.espera.has(id)) { c.espera.get(id)(m); c.espera.delete(id); }
      c.aoReceber?.(m);
    };
    ws.onerror = () => nao(new Error('sem ligação'));
  });
}
function enviar(c, msg, chave) {
  const id = randomUUID();
  return new Promise((ok) => {
    c.espera.set(id, ok);
    c.ws.send(JSON.stringify({ v: 2, roomId: ROOM, revision: c.revision, [chave]: id, ...msg }));
  });
}

const lm = cfg.sala.lugares.find((l) => l.papel === 'mestre');
const lj = cfg.sala.lugares.find((l) => l.papel === 'jogadora');
const mestre = await ligar({ papel: 'mestre', pin: lm.pin });
await dormir(300);
const ids = [...new Set(cfg.bancada.criaturas.map((c) => c.fichaId))];
for (const [type, campos] of [['MASTER_LOBBY_SET', { mapaId: 'arena-teste', criaturasDisponiveis: ids, npcsDisponiveis: [] }], ['MASTER_START', {}],
  ...cfg.bancada.criaturas.map((c) => ['MASTER_PLACE', { fichaId: c.fichaId, casa: c.casa }])]) {
  const r = await enviar(mestre, { type, ...campos }, 'cmdId');
  log(`${type} → ${r.type} ${r.estado ?? r.motivo}`);
  await dormir(100);
}
const jog = await ligar({ papel: 'jogadora', nome: lj.nome, senha: lj.senha });
let ultimaOpcao = null;
let fim = false;
jog.aoReceber = (m) => {
  if (m.type === 'ROOM_OPTIONS') ultimaOpcao = m;
  if (m.type === 'ROOM_EVENT' && m.tipo === 'fim') fim = true;
};
// O nome público de cada figura (para escolher o lobo primeiro).
const nomeDe = (id) => {
  for (let i = jog.msgs.length - 1; i >= 0; i--) {
    const m = jog.msgs[i];
    if (m.type === 'ROOM_SNAPSHOT') { const f = (m.figuras ?? []).find((x) => x.id === id); if (f) return f.nomePublico; }
  }
  return '?';
};
const t0 = Date.now();
let vezes = 0;
while (!fim && Date.now() - t0 < 180000 && vezes < RODADAS * 2) {
  await dormir(150);
  const o = ultimaOpcao;
  if (!o || o.revision < jog.revision - 0 || !o.vezId) continue;
  ultimaOpcao = null;
  if (o.ataques?.length) {
    const ordem = [...o.ataques].sort((a, b) => (nomeDe(a.alvoId).includes('Lobo') ? 0 : 1) - (nomeDe(b.alvoId).includes('Lobo') ? 0 : 1)
      || (a.arma === 'tiro-certeiro-bancada' ? 0 : 1) - (b.arma === 'tiro-certeiro-bancada' ? 0 : 1));
    const a = ordem[0];
    const r = await enviar(jog, { type: 'ROOM_INTENT', acao: { tipo: 'atacar', alvoId: a.alvoId, arma: a.arma } }, 'intentId');
    log(`atacar ${nomeDe(a.alvoId)} com ${a.arma} → ${r.type} ${r.estado ?? r.motivo}`);
    continue; // as opções novas (sem ataque) chegam a seguir: encerra nelas
  }
  if (o.acoes?.includes('encerrar')) {
    vezes += 1;
    const r = await enviar(jog, { type: 'ROOM_INTENT', acao: { tipo: 'encerrar' } }, 'intentId');
    log(`encerrar → ${r.type} ${r.estado ?? r.motivo}`);
  }
}
await dormir(500);
jog.ws.close();
mestre.ws.close();
await dormir(300);
srv.kill();
await dormir(300);

// ---------------------------------------------------------------- a contagem, do journal do servidor
const j = JSON.parse(readFileSync(path.join(PRIVADO, cfg.journal), 'utf8'));
const reg = JSON.parse(String(j.registo).split('\n')[0]);
const ev = reg.eventos;
const fichaDe = (id) => reg.estado.figuras[id]?.fichaId ?? id;
const ataques = ev.filter((e) => e.tipo === 'ataque');
const resumo = {
  motor: cfg.motores,
  rodada: reg.estado.rodada,
  fase: reg.estado.fase,
  desfecho: reg.estado.desfecho ?? null,
  ataques: ataques.length,
  porResultado: ataques.reduce((acc, e) => ({ ...acc, [e.dados.resultado]: (acc[e.dados.resultado] ?? 0) + 1 }), {}),
  danos: ev.filter((e) => e.tipo === 'dano').map((e) => ({ de: fichaDe(e.dados.autorId), em: fichaDe(e.dados.alvoId), valor: e.dados.valor, tipos: e.dados.tipos })),
  testesDeMorte: ev.filter((e) => e.tipo === 'teste_morte').length,
  figuras: Object.values(reg.estado.figuras).map((f) => ({ ficha: f.fichaId, vida: f.vidaActual, vivo: f.vivo, caido: f.caido, estadoMorte: f.estadoMorte })),
  tipos: ev.reduce((acc, e) => ({ ...acc, [e.tipo]: (acc[e.tipo] ?? 0) + 1 }), {}),
};
console.log(JSON.stringify(resumo));
process.exit(0);
