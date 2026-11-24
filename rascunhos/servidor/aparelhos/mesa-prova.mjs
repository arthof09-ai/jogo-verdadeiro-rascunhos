// Ordem PLANO-2-F2 — a mesa de prova dos aparelhos (FICTÍCIA): o servidor de mesa de verdade (nucleo/sala.js e
// adaptadores/node/servidor-ws.js, sem mudar uma linha deles) com 3 lugares de jogadora e o Mestre.
//
//   node aparelhos/mesa-prova.mjs --porta=8080 [--host=0.0.0.0] [--estatica=../../build/web] [--medicoes=<pasta>]
//        [--pin=<6+ dígitos>] [--mestre-auto] [--criaturas] [--jogadoras=1..3] [--motor=<motores embrulhados .mjs>]
//
// --estatica   o export web (o mesmo que a jogadora abre pelo QR); a mesma origem do ws://…/ws.
// --medicoes   a pasta onde caem os JSON da V1.0 (POST /medicao).
// --pin        o PIN do Mestre (sem ele, sai um fresco e aleatório no terminal).
// --mestre-auto  um Mestre-bot no próprio processo abre o combate logo ao arrancar (as provas sem Mestre humano: o
//              ROOM_SNAPSHOT do combate na web, no Windows e no Android; na rede da casa, o Mestre só olha).
// --jogadoras  quantos lugares de jogadora (os primeiros de JOGADORAS; 3 por omissão). Um lugar sem ninguém prende a mesa
//              na vez dele: na prova da casa (1 Android + 1 PC) são 2.
// --criaturas  o Mestre-bot coloca as duas criaturas de bancada (a IA do jogo joga-as, modo auto).
// Motor: o FALSO dos testes (acerta sempre, 2 de dano) — não é regra, é canalização; ou o VLAB real com --motor=.
// As senhas são de bancada (fichas fictícias, servidor temporário): ver JOGADORAS. Nada do Mestre real.
import { readFileSync } from 'node:fs';
import { randomInt } from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';
import { criarSala } from '../nucleo/sala.js';
import { carregarFichas } from '../nucleo/carregar-fichas.js';
import { criarServidor, rngNode, urlsDaRede, textoQrDoTerminal } from '../adaptadores/node/servidor-ws.js';
import { criarMotorFalso } from '../testes/motor-falso.mjs';
import { BotMestre } from './bots.mjs';

const AQUI = path.dirname(fileURLToPath(import.meta.url));

export const JOGADORAS = Object.freeze([
  { nome: 'Espadachim de Bancada', senha: 'prova-espadachim', fichaId: 'espadachim-bancada', casa: { x: 8, y: 5 } },
  { nome: 'Arqueira de Bancada', senha: 'prova-arqueira', fichaId: 'arqueira-bancada', casa: { x: 11, y: 4 } },
  { nome: 'Batedora de Bancada', senha: 'prova-batedora', fichaId: 'arqueira-bancada', casa: { x: 5, y: 6 } },
]);
export const CRIATURAS = Object.freeze([['bruto-bancada', { x: 9, y: 13 }], ['lobo-bancada', { x: 12, y: 14 }]]);
const INICIATIVA = { 'arqueira-bancada': 16, 'lobo-bancada': 14, 'espadachim-bancada': 12, 'bruto-bancada': 10 };

export function fichasDeBancada() {
  const r = carregarFichas(JSON.parse(readFileSync(path.join(AQUI, '../autojogo/fichas-bancada.json'), 'utf8')));
  if (!r.ok) throw new Error('fichas de bancada inválidas: ' + JSON.stringify(r.erros));
  return r.fichas;
}

/** A sala de prova. `rng` e `agora` injectáveis (a prova dos 3 bots compara duas corridas). */
export function criarMesaProva({ pin, motores = null, rng = rngNode(), agora = () => Date.now(), modoPadrao = 'auto', jogadoras = 3 } = {}) {
  const terreno = JSON.parse(readFileSync(path.join(AQUI, '../dados/terreno-floresta.json'), 'utf8'));
  return criarSala({
    terreno,
    motores: motores ?? criarMotorFalso({ resultado: 'acerto', dano: 2 }),
    fichas: fichasDeBancada(),
    rng,
    agora,
    config: {
      roomId: 'mesa-prova-f2',
      teste: true, // sala de TESTE (o selo só o Mestre o vê)
      mapa: { largura: 20, altura: 20 },
      iniciativa: INICIATIVA,
      modoPadrao,
      lugares: [...JOGADORAS.slice(0, jogadoras).map((j) => ({ papel: 'jogadora', ...j })), { papel: 'mestre', nome: 'Mestre da prova', pin }],
    },
  });
}

function argumentos(argv) {
  const a = {};
  for (const x of argv.slice(2)) {
    const m = /^--([a-z-]+)(?:=(.*))?$/.exec(x);
    if (m) a[m[1]] = m[2] ?? true;
  }
  return a;
}

async function principal() {
  const a = argumentos(process.argv);
  const pin = typeof a.pin === 'string' ? a.pin : String(randomInt(10_000_000, 99_999_999));
  if (!/^\d{6,32}$/.test(pin)) {
    console.error('--pin: 6 a 32 dígitos');
    process.exit(2);
  }
  let motores = null;
  if (typeof a.motor === 'string') {
    const mod = await import(pathToFileURL(path.resolve(a.motor)).href);
    motores = { Dmg: mod.Dmg, Vlab: mod.Vlab, MOTOR_SHA256: mod.MOTOR_SHA256, DMG_VERSAO: 'real', LEVELUP_SHA: null };
  }
  const jogadoras = Number(a.jogadoras ?? 3);
  if (![1, 2, 3].includes(jogadoras)) {
    console.error('--jogadoras: 1, 2 ou 3');
    process.exit(2);
  }
  const salaReal = criarMesaProva({ pin, motores, jogadoras });
  // O registo das ligações, com a hora (a prova da casa mede a reconexão por aqui): quem entra (com token ou senha, e
  // o lastSeq) e quem sai. Só o nome fictício do lugar; nunca o token nem a senha.
  const hora = () => new Date().toISOString().slice(11, 23);
  const nomeDe = (seatId) => salaReal.lugares().find((l) => l.seatId === seatId)?.nome ?? seatId;
  const sala = Object.freeze({
    get roomId() { return salaReal.roomId; },
    ...Object.fromEntries(Object.entries(salaReal).filter(([k]) => k !== 'roomId')),
    entrar: (msg, ctx) => {
      const r = salaReal.entrar(msg, ctx);
      if (r.ok) {
        console.log(`[ligações] ${hora()} ENTROU ${nomeDe(r.seatId)} (${msg?.seatToken ? 'token' : 'senha/PIN'}`
          + `${Number.isInteger(msg?.lastSeq) ? ', lastSeq ' + msg.lastSeq : ''}; ip ${ctx?.ip ?? '?'})`);
      }
      return r;
    },
    conexaoFechada: (seatId) => {
      console.log(`[ligações] ${hora()} SAIU ${nomeDe(seatId)}`);
      return salaReal.conexaoFechada(seatId);
    },
  });
  const porta = Number(a.porta ?? 8080);
  const host = typeof a.host === 'string' ? a.host : '0.0.0.0';
  const servidor = criarServidor({
    sala,
    pastaEstatica: typeof a.estatica === 'string' ? path.resolve(a.estatica) : null,
    medicoes: typeof a.medicoes === 'string' ? path.resolve(a.medicoes) : null,
    registo: (t) => console.log('[servidor] ' + t),
  });
  if (typeof a.medicoes === 'string') (await import('node:fs')).mkdirSync(path.resolve(a.medicoes), { recursive: true });
  servidor.on('error', (e) => {
    console.error('[mesa-prova] ' + (e?.message ?? e));
    process.exit(2);
  });
  servidor.listen(porta, host, async () => {
    const p = servidor.address().port;
    console.log(`[mesa-prova] a ouvir em ${host}:${p} (motor ${motores ? 'VLAB real' : 'falso'}; sala de TESTE)`);
    if (typeof a.pin !== 'string') console.log(`[mesa-prova] PIN do Mestre desta corrida: ${pin}`);
    console.log('[mesa-prova] jogadoras: ' + JOGADORAS.slice(0, jogadoras).map((j) => `${j.nome} / ${j.senha}`).join('; '));
    if (host !== '127.0.0.1') console.log(textoQrDoTerminal(urlsDaRede(p)));
    if (a['mestre-auto']) {
      const mestre = new BotMestre({ url: `ws://127.0.0.1:${p}/ws`, pin });
      await mestre.ligar();
      console.log('[mesa-prova] Mestre-bot na mesa');
      await mestre.abrirCombate({ criaturas: a.criaturas ? CRIATURAS : [] });
      console.log('[mesa-prova] combate aberto pelo Mestre-bot');
    }
    console.log('pronto-mesa-prova ' + p);
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  principal().catch((e) => {
    console.error('[mesa-prova] ' + (e?.stack ?? e));
    process.exit(1);
  });
}
