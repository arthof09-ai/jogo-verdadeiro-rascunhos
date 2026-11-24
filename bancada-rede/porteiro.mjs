// ORDEM-CORR10-PREP — o PORTEIRO da bancada de rede: entra na sala pela ligação de verdade, com as credenciais de
// cada lugar, e deixa o lugar (seatToken) no `user://lugar.cfg` do cliente Godot desse lugar. O cliente, ao abrir
// como em produção (cena principal → lobby), encontra o lugar guardado e entra SOZINHO, sem formulário
// (lobby.gd: «com token guardado, entra sozinha»). É o mesmo que o Mestre faria a escrever o PIN e a jogadora o nome
// e a senha, só que feito uma vez por quem lança a bancada. O código do jogo não muda.
//
//   node bancada-rede/porteiro.mjs --config=<privado/config.json> --mestre=<user-dir> --jogadora=<user-dir>
//                                  [--aliada=<user-dir>] [--so-lobby] [--orc=38,11] [--espera-s=180]
//
//   <user-dir> = a pasta `user://` desse cliente (o lançador dá a cada cliente o seu APPDATA, para dois clientes no
//                mesmo PC não partilharem o lugar.cfg).
//
// Passos:
//   1. espera o servidor (tenta ligar até 60 s);
//   2. o MESTRE entra com o PIN; sem --so-lobby, prepara a batalha como as bancadas PROVAS-MAPA: MASTER_LOBBY_SET
//      (o orc disponível) → MASTER_START → MASTER_PLACE do orc DENTRO do lago (38,11). A vez é da heroína.
//      Com `bancada.criaturas` na config (preparar.mjs --fichas=acertam), põe essas criaturas nessas casas;
//   3. cada JOGADORA entra com o nome e a senha, recebe o WELCOME, e o porteiro fecha a ligação dela logo a seguir
//      (assim o cliente Godot não é «segundo aparelho» — 4002 — quando entrar);
//   4. escreve os lugar.cfg;
//   5. a ligação do Mestre fica ABERTA até o cliente Godot do Mestre entrar (o porteiro vê o token do lugar.cfg dele
//      mudar: a Rede regrava-o a cada ROOM_WELCOME). Só então fecha. Se fechasse antes, a sala ficaria sem Mestre
//      ligado e pausava (E-C4, `mestre_desconectado`). Ao fim de --espera-s sem o Mestre Godot, fecha na mesma (o
//      Mestre retoma com «Continuar» no ecrã dele).
// O seatToken nunca vai à consola nem ao registo.
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import path from 'node:path';

const args = Object.fromEntries(process.argv.slice(2).map((a) => {
  const m = /^--([^=]+)(?:=(.*))?$/.exec(a);
  return m ? [m[1], m[2] ?? true] : [a, true];
}));
const log = (t) => console.log(`[porteiro] ${t}`);
const cfg = JSON.parse(readFileSync(String(args.config), 'utf8'));
const PORTA = cfg.porta ?? 8790;
const HOST_CLIENTE = String(args['host-cliente'] ?? '127.0.0.1');
const URL = `ws://${HOST_CLIENTE}:${PORTA}/ws`; // tem de ser igual ao `url_servidor()` do cliente (rede.gd)
const ROOM = cfg.sala.roomId;
const lugarDe = (papel, nome) => cfg.sala.lugares.find((l) => l.papel === papel && (nome === undefined || l.nome === nome));
const ORC = String(args.orc ?? '38,11').split(',').map(Number);
const ESPERA_MS = Number(args['espera-s'] ?? 180) * 1000;

const dormir = (ms) => new Promise((r) => setTimeout(r, ms));

/** Liga e manda o ROOM_JOIN; resolve com {ws, welcome, msgs, revision}. Tenta até o servidor estar de pé. */
async function entrar(join, rotulo, prazoMs = 60000) {
  const t0 = Date.now();
  for (;;) {
    try {
      return await new Promise((ok, nao) => {
        const ws = new WebSocket(URL);
        const c = { ws, welcome: null, msgs: [], revision: 0, espera: new Map() };
        ws.onopen = () => ws.send(JSON.stringify({ v: 2, type: 'ROOM_JOIN', ...join, cliente: 'bancada-rede-porteiro' }));
        ws.onmessage = (ev) => {
          const m = JSON.parse(String(ev.data));
          c.msgs.push(m);
          if (Number.isInteger(m.revision) && m.revision > c.revision) c.revision = m.revision;
          if (m.type === 'ROOM_WELCOME') { c.welcome = m; ok(c); }
          if (m.type === 'ERRO' && !c.welcome) nao(new Error(`${rotulo}: ERRO ${m.codigo ?? ''} ${m.texto ?? ''}`.trim()));
          const id = m.cmdId ?? m.intentId;
          if ((m.type === 'ROOM_RECEIPT' || m.type === 'ROOM_REJECT') && c.espera.has(id)) {
            c.espera.get(id)(m);
            c.espera.delete(id);
          }
        };
        ws.onerror = () => nao(new Error('sem ligação'));
        ws.onclose = () => { if (!c.welcome) nao(new Error('fechou antes do WELCOME')); };
      });
    } catch (e) {
      if (!/sem ligação|fechou antes/.test(e.message) || Date.now() - t0 > prazoMs) throw e;
      await dormir(500);
    }
  }
}

/** Um comando do Mestre, com cmdId e a revisão que ele viu; resolve com o recibo ou a recusa. */
function comando(c, type, campos = {}) {
  const cmdId = randomUUID();
  return new Promise((ok, nao) => {
    const t = setTimeout(() => nao(new Error(`${type}: sem resposta`)), 15000);
    c.espera.set(cmdId, (r) => { clearTimeout(t); ok(r); });
    c.ws.send(JSON.stringify({ v: 2, type, roomId: ROOM, cmdId, revision: c.revision, ...campos }));
  });
}
async function exigir(c, type, campos) {
  const r = await comando(c, type, campos);
  const ok = r.type === 'ROOM_RECEIPT' && r.estado === 'APLICADA';
  log(`${type} ${JSON.stringify(campos ?? {})} → ${r.type} ${r.estado ?? r.motivo ?? ''}`);
  if (!ok) throw new Error(`${type} não foi aplicado: ${r.type} ${r.motivo ?? r.estado ?? ''}`);
  await dormir(100); // deixa chegar as mensagens desta revisão
  return r;
}

/** O lugar.cfg tal como rede.gd `_guardar_lugar()` o escreve (ConfigFile do Godot). */
function escreverLugar(userDir, welcome) {
  mkdirSync(userDir, { recursive: true });
  const q = (s) => JSON.stringify(String(s)); // só [A-Za-z0-9_-:/.] nestes campos: as aspas de JSON servem
  const texto = `[lugar]\n\nservidor=${q(URL)}\nroomId=${q(welcome.roomId)}\nseatId=${q(welcome.seatId)}\n`
    + `seatToken=${q(welcome.seatToken)}\npapel=${q(welcome.papel)}\n`;
  writeFileSync(path.join(userDir, 'lugar.cfg'), texto);
  // Pendentes de uma corrida anterior não servem para este lugar novo.
  const pend = path.join(userDir, 'pendentes.json');
  if (existsSync(pend)) writeFileSync(pend, JSON.stringify({ roomId: welcome.roomId, seatId: welcome.seatId, itens: [] }));
}
function tokenNoFicheiro(userDir) {
  try {
    return /seatToken="([^"]*)"/.exec(readFileSync(path.join(userDir, 'lugar.cfg'), 'utf8'))?.[1] ?? null;
  } catch { return null; }
}

try {
  // 2. o Mestre
  const lm = lugarDe('mestre');
  const mestre = await entrar({ papel: 'mestre', pin: lm.pin }, 'Mestre');
  log(`Mestre na sala ${mestre.welcome.roomId}`);
  await dormir(300); // o snapshot e a vista do Mestre chegam logo a seguir ao WELCOME
  const snap = () => [...mestre.msgs].reverse().find((m) => m.type === 'ROOM_SNAPSHOT' || m.type === 'MASTER_VIEW');
  const fase = snap()?.fase ?? '?';
  if (!args['so-lobby'] && fase === 'lobby') {
    // ORDEM-D-AUD-04-BANCADA: as criaturas vêm da config (`bancada.criaturas`, escrita pelo preparar.mjs); sem ela,
    // a de origem: o orc-teste em --orc (por omissão dentro do lago).
    const criaturas = cfg.bancada?.criaturas ?? [{ fichaId: 'orc-teste', casa: { x: ORC[0], y: ORC[1] } }];
    const ids = [...new Set(criaturas.map((c) => c.fichaId))];
    await exigir(mestre, 'MASTER_LOBBY_SET', { mapaId: 'arena-teste', criaturasDisponiveis: ids, npcsDisponiveis: [] });
    await exigir(mestre, 'MASTER_START');
    for (const c of criaturas) await exigir(mestre, 'MASTER_PLACE', { fichaId: c.fichaId, casa: c.casa });
  } else {
    log(`batalha não preparada (fase «${fase}»${args['so-lobby'] ? ', --so-lobby' : ''})`);
  }

  // 3. as jogadoras
  // A 1.ª jogadora da config vai para o cliente --jogadora; a 2.ª (com --aliada) para o --aliada.
  const nomesJog = cfg.sala.lugares.filter((l) => l.papel === 'jogadora').map((l) => l.nome);
  const jogadoras = [['jogadora', nomesJog[0]], ['aliada', nomesJog[1]]].filter(([k, nome]) => args[k] && nome);
  for (const [k, nome] of jogadoras) {
    const l = lugarDe('jogadora', nome);
    if (!l) throw new Error(`a config não tem o lugar «${nome}»`);
    const j = await entrar({ papel: 'jogadora', nome: l.nome, senha: l.senha }, nome);
    escreverLugar(String(args[k]), j.welcome);
    j.ws.close();
    log(`${nome}: lugar guardado no cliente (${k})`);
  }

  // 4./5. o lugar do Mestre, e a ligação dele aberta até o cliente Godot do Mestre entrar
  const dirMestre = String(args.mestre);
  escreverLugar(dirMestre, mestre.welcome);
  log('Mestre: lugar guardado no cliente (mestre)');
  console.log('pronto-porteiro');
  const t0 = Date.now();
  while (tokenNoFicheiro(dirMestre) === mestre.welcome.seatToken && Date.now() - t0 < ESPERA_MS) await dormir(500);
  if (tokenNoFicheiro(dirMestre) !== mestre.welcome.seatToken) {
    log('o ecrã do Mestre (Godot) entrou na sala; o porteiro sai');
    await dormir(2000); // o cliente já está ligado: a ligação do porteiro fecha sem pausar a mesa
  } else {
    log(`o ecrã do Mestre não entrou em ${ESPERA_MS / 1000} s; o porteiro sai (a mesa pausa: «Continuar» no ecrã do Mestre)`);
  }
  mestre.ws.close();
  await dormir(300);
  process.exit(0);
} catch (e) {
  console.error(`[porteiro] FALHA: ${e.message}`);
  process.exit(1);
}
