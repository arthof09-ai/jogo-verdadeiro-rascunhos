// ORDEM AUTOJOGO — FERRAMENTA DE MEDIÇÃO (não é o servidor do jogo, não entra no caminho normal).
//
// Lança o servidor de mesa DE VERDADE (a sala de nucleo/sala.js e o WebSocket de adaptadores/node/servidor-ws.js,
// sem mudar uma linha deles) para UMA partida do autojogo:
//   - o dado é SEMEADO (a mesma semente dá os mesmos dados, os mesmos ids e a mesma partida);
//   - o relógio é fixo (anda 250 ms por leitura): os carimbos não dependem da hora e o ritmo de 10 comandos/s do
//     servidor nunca trava a bancada;
//   - as criaturas nascem em modo MANUAL: a IA do jogo (proporIA) não joga; quem as joga é a IA de bancada do
//     cliente, pelo lugar do Mestre (MASTER_ACT);
//   - o motor é o VLAB real (o mesmo ficheiro público que o CI baixa), embrulhado por motores/embrulhar.mjs.
// As REGRAS continuam todas aqui, no servidor: esta ferramenta só escolhe a semente, o cenário e o motor.
//
//   node servidor/autojogo/servidor-autojogo.mjs --porta=8790 --semente=7 --pin=<PIN da partida> [--cenario=<json>] [--motor=<vlab-completo.js>]
//   (Ordem CAIXA-RELATO-B7-CORRECOES-6: o PIN do Mestre já não vem do cenário cometido; o autojogo.gd gera um fresco por
//   partida e passa-o por --pin=. Sem ele, ou fora de /^\d{6,}$/, sai com 2 — antes de ler o cenário; B7-CORRECOES-7.)
//        [--info=<ficheiro>] [--vida-max-s=900] [--motor-falso]
//
// --info: quando o servidor está a ouvir, escreve aqui um JSON com a semente, a sala, o SHA do motor e o das fichas
//         (o cliente lê-o para saber que o servidor está pronto e para carimbar o registo).
// --motor-falso: só para provar a canalização sem rede (o motor falso dos testes). NÃO serve para medir equilíbrio;
//         o registo fica marcado com motor «falso».
// O processo fecha-se sozinho quando o Mestre da bancada sai, ou ao fim de --vida-max-s (nunca fica órfão).
import { readFileSync, writeFileSync, mkdirSync, existsSync, renameSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { pathToFileURL, fileURLToPath } from 'node:url';
import path from 'node:path';
import { criarSala } from '../nucleo/sala.js';
import { carregarFichas } from '../nucleo/carregar-fichas.js';
import { criarServidor } from '../adaptadores/node/servidor-ws.js';
import { embrulhar } from '../motores/embrulhar.mjs';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const URL_MOTOR = 'https://arthof09-ai.github.io/arena-das-bestas-prototipo-cm9/jogo-t1/vlab-completo.js'; // o do CI
const CACHE = path.join(AQUI, '.cache');

function argumentos(argv) {
  const a = {};
  for (const x of argv.slice(2)) {
    const m = /^--([a-z-]+)(?:=(.*))?$/.exec(x);
    if (m) a[m[1]] = m[2] ?? true;
  }
  return a;
}

/** Dado semeado (mulberry32 sobre a semente misturada): devolve inteiros de 32 bits, como o rngNode do adaptador. */
export function rngSemeado(semente) {
  let s = (Math.imul((semente >>> 0) ^ 0x9e3779b9, 0x85ebca6b) ^ 0xc2b2ae35) >>> 0;
  return () => {
    s = (s + 0x6d2b79f5) >>> 0;
    let t = s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return (t ^ (t >>> 14)) >>> 0;
  };
}

function relogioFixo(inicio = Date.UTC(2026, 10, 16, 12, 0, 0), passo = 250) {
  let t = inicio;
  return () => (t += passo);
}

const sha256 = (bytes) => createHash('sha256').update(bytes).digest('hex');

async function carregarMotor(args) {
  if (args['motor-falso']) {
    const { criarMotorFalso } = await import('../testes/motor-falso.mjs');
    return { motores: criarMotorFalso(), rotulo: 'falso', sha: null };
  }
  let fonte = typeof args.motor === 'string' ? path.resolve(args.motor) : path.join(CACHE, 'vlab-completo.js');
  if (!existsSync(fonte)) {
    if (typeof args.motor === 'string') throw new Error('motor não encontrado: ' + fonte);
    mkdirSync(CACHE, { recursive: true });
    const r = await fetch(URL_MOTOR, { signal: AbortSignal.timeout(30000) });
    if (!r.ok) throw new Error(`não consegui baixar o motor (${r.status}); passe --motor=<vlab-completo.js>`);
    const tmp = fonte + '.' + process.pid + '.tmp';
    writeFileSync(tmp, Buffer.from(await r.arrayBuffer()));
    renameSync(tmp, fonte); // troca atómica: duas partidas em paralelo não lêem meio ficheiro
  }
  const { sha, codigo } = embrulhar(readFileSync(fonte));
  mkdirSync(CACHE, { recursive: true });
  const modulo = path.join(CACHE, `motores-${sha.slice(0, 16)}.mjs`);
  if (!existsSync(modulo)) {
    const tmp = modulo + '.' + process.pid + '.tmp';
    writeFileSync(tmp, codigo);
    renameSync(tmp, modulo);
  }
  const mod = await import(pathToFileURL(modulo).href);
  return {
    motores: { Dmg: mod.Dmg, Vlab: mod.Vlab, MOTOR_SHA256: mod.MOTOR_SHA256, DMG_VERSAO: 'real', LEVELUP_SHA: null },
    rotulo: 'vlab-real', sha,
  };
}

export function lerCenario(caminho) {
  const bytes = readFileSync(caminho);
  const c = JSON.parse(bytes.toString('utf8'));
  if (c.formato !== 'cenario-autojogo/1') throw new Error('cenário: formato desconhecido (esperava cenario-autojogo/1)');
  const caminhoFichas = path.resolve(path.dirname(caminho), c.fichas);
  const bytesFichas = readFileSync(caminhoFichas);
  const r = carregarFichas(JSON.parse(bytesFichas.toString('utf8')));
  if (!r.ok) throw new Error('fichas do cenário inválidas: ' + JSON.stringify(r.erros));
  if (!Array.isArray(c.heroinas) || !c.heroinas.length) throw new Error('cenário: falta a lista de heroínas');
  if (!Array.isArray(c.criaturas) || !c.criaturas.length) throw new Error('cenário: falta a lista de criaturas');
  return { cenario: c, fichas: r.fichas, shaCenario: sha256(bytes), shaFichas: sha256(bytesFichas) };
}

async function principal() {
  const args = argumentos(process.argv);
  const porta = Number(args.porta ?? 8790);
  const semente = Number(args.semente ?? 1);
  if (!Number.isInteger(semente) || semente < 0) throw new Error('--semente tem de ser um inteiro ≥ 0');
  // Ordem CAIXA-RELATO-B7-CORRECOES-7 (B2/JD3): o --pin= valida-se ANTES de se ler o cenário e a recusa sai com 2,
  // como nos dois servidor-bancada-prova.mjs (antes lançava erro depois do lerCenario e saía com 1).
  const pin = typeof args.pin === 'string' ? args.pin : '';
  if (!/^\d{6,}$/.test(pin)) {
    console.error('[autojogo] falta --pin=<6 dígitos ou mais> (o PIN da partida; o cenário já não o traz)');
    process.exit(2);
  }
  const caminhoCenario = path.resolve(typeof args.cenario === 'string' ? args.cenario : path.join(AQUI, 'cenario-bancada.json'));
  const { cenario, fichas, shaCenario, shaFichas } = lerCenario(caminhoCenario);
  const motor = await carregarMotor(args);
  const terreno = JSON.parse(readFileSync(new URL('../dados/terreno-floresta.json', import.meta.url), 'utf8'));
  const roomId = 'autojogo-s' + semente;

  const lugares = cenario.heroinas.map((h) => ({ papel: 'jogadora', nome: h.nome, senha: h.senha, fichaId: h.fichaId, casa: h.casa }));
  lugares.push({ papel: 'mestre', nome: 'Mestre da bancada', pin });
  const salaReal = criarSala({
    terreno,
    motores: motor.motores,
    fichas,
    rng: rngSemeado(semente),
    agora: relogioFixo(),
    config: {
      roomId,
      teste: true, // sala de TESTE (o selo só o Mestre o vê)
      mapa: cenario.mapa ?? { largura: 20, altura: 20 },
      iniciativa: cenario.iniciativa ?? {},
      modoPadrao: 'manual', // a IA do jogo não joga: as criaturas são da IA de bancada (MASTER_ACT)
      lugares,
    },
  });

  // O Mestre da bancada saiu → a partida acabou → o processo fecha (nunca fica um servidor órfão).
  const mestres = new Set();
  const sala = Object.freeze({
    get roomId() { return salaReal.roomId; },
    ...Object.fromEntries(Object.entries(salaReal).filter(([k]) => k !== 'roomId')),
    entrar: (msg, ctx) => {
      const r = salaReal.entrar(msg, ctx);
      if (r.ok && msg?.papel === 'mestre') mestres.add(r.seatId);
      return r;
    },
    conexaoFechada: (seatId) => {
      const s = salaReal.conexaoFechada(seatId);
      if (mestres.has(seatId)) setTimeout(() => process.exit(0), 150);
      return s;
    },
  });

  const servidor = criarServidor({ sala, registo: (t) => console.log('[servidor]', t) });
  const vidaMax = Number(args['vida-max-s'] ?? 900);
  setTimeout(() => { console.log('[autojogo] vida máxima esgotada: fecho'); process.exit(3); }, vidaMax * 1000).unref();
  servidor.on('error', (e) => { console.error('[autojogo] servidor:', e?.message ?? e); process.exit(2); });
  servidor.listen(porta, '127.0.0.1', () => {
    const info = {
      pronto: true, porta, semente, roomId,
      motor: motor.rotulo, motorSha256: motor.sha,
      cenario: path.basename(caminhoCenario), cenarioSha256: shaCenario, fichasSha256: shaFichas,
    };
    if (typeof args.info === 'string') {
      const tmp = args.info + '.tmp';
      writeFileSync(tmp, JSON.stringify(info));
      renameSync(tmp, args.info);
    }
    console.log('pronto-autojogo ' + JSON.stringify(info));
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  principal().catch((e) => {
    console.error('[autojogo] ' + (e?.message ?? e));
    process.exit(1);
  });
}
