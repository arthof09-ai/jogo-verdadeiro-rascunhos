// Ordem PLANO-2-F2 (JV3.4): 3 bots e 25 s sem rede — o hash lógico fica igual e o seq contínuo.
//
//   node aparelhos/prova-3-bots.mjs [--corte-s=25] [--rodadas=6] [--saida=<relatorio.json>]
//
// O servidor de mesa de verdade (mesa-prova.mjs) em 127.0.0.1, o Mestre-bot e 3 jogadoras-bot, cada uma atrás do seu
// «Wi-Fi» (um proxy TCP). Duas corridas com o mesmo guião (só «encerrar», sem dados; dado e relógio semeados):
//   1. CONTROLO — ninguém cai;
//   2. QUEDA — quando chega a vez da 3.ª jogadora na 2.ª rodada, o Wi-Fi das outras duas desliga-se 25 s: os sockets do
//      lado delas morrem (como no telemóvel que perde o Wi-Fi) e as ligações novas são recusadas; do lado do servidor a
//      ligação velha fica pendurada e muda (o servidor não sabe de nada). A 3.ª joga a vez dela durante o corte; a vez
//      passa a uma que está fora, e a mesa espera. Ao fim dos 25 s a rede volta; elas entram com o token e o lastSeq.
// Aceite:
//   - o hash lógico do estado no fim da QUEDA é igual ao do CONTROLO (o estado do jogo sem a contabilidade das ligações:
//     tokenHash, epoch, seq, revision, revisaoHash e seqEspera de cada lugar, que mudam a cada entrada por desenho);
//   - em cada bot, os seq dos ROOM_EVENT são contínuos (sem buracos nem repetidos) e o último é o do servidor;
//   - quem caiu recuperou pelos eventos (não por snapshot) e entrou ≤ 30 s depois de a rede voltar;
//   - nada se perde: cada bot jogou as mesmas vezes nas duas corridas.
// Sai com 0 se tudo passa.
import net from 'node:net';
import { createHash } from 'node:crypto';
import { writeFileSync } from 'node:fs';
import { criarServidor } from '../adaptadores/node/servidor-ws.js';
import { jsonCanonico } from '../nucleo/util.js';
import { rngSemeado } from '../autojogo/servidor-autojogo.mjs';
import { criarMesaProva, JOGADORAS, CRIATURAS } from './mesa-prova.mjs';
import { BotJogadora, BotMestre } from './bots.mjs';

const args = Object.fromEntries(process.argv.slice(2).map((x) => /^--([a-z-]+)=(.*)$/.exec(x)).filter(Boolean).map((m) => [m[1], m[2]]));
const CORTE_S = Number(args['corte-s'] ?? 25);
const RODADAS = Number(args.rodadas ?? 6);
const PIN = '24680135';
const LIMITE_RECONEXAO_S = 30;

const t0 = Date.now();
const log = (t) => console.log(`[${((Date.now() - t0) / 1000).toFixed(1).padStart(6)} s] ${t}`);

/** O «Wi-Fi» de um aparelho: um proxy TCP que se pode desligar. */
function criarWifi(portaServidor) {
  const pares = new Set();
  let desligado = false;
  const srv = net.createServer((cliente) => {
    if (desligado) {
      cliente.destroy(); // sem rede: a ligação nova não chega a lado nenhum
      return;
    }
    const cima = net.connect(portaServidor, '127.0.0.1');
    const par = { cliente, cima, mudo: false };
    pares.add(par);
    cliente.on('data', (b) => { if (!par.mudo) cima.write(b); });
    cima.on('data', (b) => { if (!par.mudo) cliente.write(b); });
    const fim = () => {
      pares.delete(par);
      if (!par.mudo) {
        cliente.destroy();
        cima.destroy();
      }
    };
    cliente.on('close', fim);
    cima.on('close', fim);
    cliente.on('error', () => {});
    cima.on('error', () => {});
  });
  return {
    srv,
    ouvir: () => new Promise((r) => srv.listen(0, '127.0.0.1', () => r(srv.address().port))),
    desligar() {
      desligado = true;
      for (const p of pares) {
        p.mudo = true; // o lado do servidor fica pendurado e calado: ele não sabe que a rede caiu
        p.cliente.destroy(); // o aparelho perde o socket na hora (o Android fecha-os quando o Wi-Fi cai)
      }
    },
    ligar() {
      desligado = false;
    },
    fechar() {
      for (const p of pares) {
        p.cliente.destroy();
        p.cima.destroy();
      }
      srv.close();
    },
  };
}

/** O hash lógico: o estado do jogo sem a contabilidade das ligações de cada lugar. */
export function hashLogico(estado) {
  const e = JSON.parse(JSON.stringify(estado));
  for (const l of Object.values(e.lugares ?? {})) {
    for (const k of ['tokenHash', 'epoch', 'seq', 'revision', 'revisaoHash', 'seqEspera']) delete l[k];
  }
  return createHash('sha256').update(jsonCanonico(e)).digest('hex');
}

const esperar = (ms) => new Promise((r) => setTimeout(r, ms));
async function ate(cond, ms, oque) {
  const fim = Date.now() + ms;
  while (!cond()) {
    if (Date.now() > fim) throw new Error('tempo esgotado: ' + oque + (globalThis.__diag ? ' ' + globalThis.__diag() : ''));
    await esperar(20);
  }
}

async function corrida(nome, comQueda) {
  // O mesmo dado e o mesmo relógio nas duas corridas (o relógio anda 1 s por leitura: o ritmo de 10/s nunca trava).
  let t = Date.UTC(2026, 10, 23, 21, 0, 0);
  // Modo manual: as criaturas não jogam sozinhas (sem dados); o Mestre-bot encerra-lhes a vez.
  const sala = criarMesaProva({ pin: PIN, rng: rngSemeado(20261123), agora: () => (t += 1000), modoPadrao: 'manual' });
  const servidor = criarServidor({ sala });
  await new Promise((r) => servidor.listen(0, '127.0.0.1', r));
  const porta = servidor.address().port;
  const mestre = new BotMestre({ url: `ws://127.0.0.1:${porta}/ws`, pin: PIN,
    jogarCriaturas: () => sala.depuracao.estado().rodada <= RODADAS });
  await mestre.ligar();
  // As criaturas de bancada ficam disponíveis no lobby; o Mestre só as coloca a meio da batalha (o ponto do guião).
  await mestre.abrirCombate({ disponiveis: CRIATURAS.map(([f]) => f) });
  const wifis = [];
  const bots = [];
  const marcas = { corte: null, volta: null, jogadasNoCorte: 0 };
  let rodadaDoCorte = false;
  let colocadas = false;
  let comecou = false; // a partida: ninguém joga antes de as 3 estarem na mesa
  for (const [i, j] of JOGADORAS.entries()) {
    const w = criarWifi(porta);
    const p = await w.ouvir();
    wifis.push(w);
    const rotulo = ['A', 'B', 'C'][i];
    bots.push(new BotJogadora({
      url: `ws://127.0.0.1:${p}/ws`, nome: j.nome, senha: j.senha, rotulo,
      registo: log,
      aoMinhaVez: (bot) => {
        if (!comecou) return false;
        const rodada = sala.depuracao.estado().rodada;
        if (rodada > RODADAS) return false; // o guião acabou: ninguém joga mais
        // O ponto do guião: a vez de C na rodada 2. Nas duas corridas, o Mestre coloca as duas criaturas antes de C
        // jogar (a mesma ordem de chegada ao servidor); na QUEDA, o Wi-Fi de A e B já caiu nesse instante.
        if (rotulo === 'C' && rodada === 2 && !rodadaDoCorte) {
          rodadaDoCorte = true;
          if (comQueda) {
            marcas.corte = Date.now();
            marcas.seqNoCorte = bots.map((b) => b.ultimoSeq);
            log(`${nome}: Wi-Fi de A e B DESLIGADO (${CORTE_S} s), na vez de C (rodada 2)`);
            wifis[0].desligar();
            wifis[1].desligar();
            setTimeout(() => {
              marcas.volta = Date.now();
              const lugares = sala.depuracao.estado().lugares;
              marcas.seqNaVolta = bots.map((b) => lugares[b.seatId]?.seq ?? null);
              log(`${nome}: Wi-Fi de A e B de volta`);
              wifis[0].ligar();
              wifis[1].ligar();
            }, CORTE_S * 1000);
          }
          (async () => {
            for (const [fichaId, casa] of CRIATURAS) await mestre.comando('MASTER_PLACE', { fichaId, casa });
            log(`${nome}: o Mestre colocou ${CRIATURAS.length} criaturas`);
            colocadas = true;
            bot.talvezJogar();
          })().catch((e) => log(`${nome}: FALHA ao colocar: ${e.message}`));
          return false;
        }
        if (rotulo === 'C' && rodadaDoCorte && !colocadas) return false;
        if (marcas.corte && !marcas.volta) marcas.jogadasNoCorte += 1;
        return true;
      },
    }));
  }
  for (const b of bots) b.ligar();
  globalThis.__diag = () => JSON.stringify({ rodada: sala.depuracao.estado().rodada, vez: sala.depuracao.estado().vez?.figuraId,
    bots: bots.map((b) => ({ r: b.rotulo, fig: b.figura, vez: b.vez, emVoo: b.emVoo, turno: b.turno, jogouEm: b.jogouEm, lig: b.ligado })),
    mestre: { vez: mestre.vez, emVoo: mestre.emVoo, criaturas: [...mestre.criaturas] } });
  await ate(() => bots.every((b) => b.ligado && b.figura), 15000, 'as 3 jogadoras na mesa');
  log(`${nome}: as 3 jogadoras na mesa`);
  comecou = true;
  for (const b of bots) b.talvezJogar();
  // O guião acaba quando a rodada passa de RODADAS (a 1.ª vez da rodada seguinte já não se joga).
  await ate(() => sala.depuracao.estado().rodada > RODADAS && bots.every((b) => b.ligado && !b.emVoo) && !mestre.emVoo,
    (CORTE_S + 60) * 1000, `rodada ${RODADAS + 1}`);
  await esperar(300); // os últimos eventos chegam
  const estado = sala.depuracao.estado();
  const r = {
    corrida: nome,
    rodadaFinal: estado.rodada,
    hashLogico: hashLogico(estado),
    hashEstadoCompleto: sala.depuracao.hashEstado(),
    corte: comQueda ? { segundos: CORTE_S, jogadasDeCDuranteOCorte: marcas.jogadasNoCorte } : null,
    bots: bots.map((b, i) => {
      const servidorSeq = estado.lugares[b.seatId]?.seq;
      const reentrada = comQueda && b.welcomes.length > 1 ? b.welcomes.find((w) => w >= marcas.volta) : null;
      return {
        bot: b.rotulo, nome: b.nome, entradas: b.entradas, quedas: b.quedas, tentativas: b.tentativas,
        eventos: b.seqs.length, primeiroSeq: b.seqs[0] ?? null, ultimoSeq: b.ultimoSeq, seqDoServidor: servidorSeq,
        buracos: b.buracos, repetidos: b.repetidos, snapshots: b.snapshots, vezesJogadas: b.vezesJogadas, recusas: b.recusas, revisoesAntigas: b.revisoesAntigas,
        sincronizacoes: b.sincronizacoes,
        eventosPerdidosNoCorte: comQueda && marcas.seqNaVolta ? marcas.seqNaVolta[i] - marcas.seqNoCorte[i] : null,
        reconexaoS: reentrada ? Number(((reentrada - marcas.volta) / 1000).toFixed(2)) : null,
      };
    }),
  };
  for (const b of bots) b.parar();
  mestre.ws.close();
  for (const w of wifis) w.fechar();
  servidor.close();
  for (const l of [...(servidor.listeners?.('connection') ?? [])]) void l;
  return r;
}

const controlo = await corrida('CONTROLO', false);
log(`CONTROLO: rodada ${controlo.rodadaFinal}, hash lógico ${controlo.hashLogico.slice(0, 16)}…`);
const queda = await corrida('QUEDA', true);
log(`QUEDA: rodada ${queda.rodadaFinal}, hash lógico ${queda.hashLogico.slice(0, 16)}…`);

const falhas = [];
const conferir = (ok, texto) => {
  console.log(`  ${ok ? 'ok   ' : 'FALHA'} ${texto}`);
  if (!ok) falhas.push(texto);
};
conferir(queda.hashLogico === controlo.hashLogico, `hash lógico igual nas duas corridas (${queda.hashLogico.slice(0, 16)}…)`);
conferir(queda.corte.jogadasDeCDuranteOCorte >= 1, `C jogou a vez dela durante o corte (${queda.corte.jogadasDeCDuranteOCorte} envio(s) de «encerrar»; a revisão velha volta a tentar)`);
for (const [i, b] of queda.bots.entries()) {
  const c = controlo.bots[i];
  conferir(b.buracos.length === 0 && b.repetidos.length === 0,
    `${b.bot}: seq contínuo (${b.eventos} eventos, ${b.primeiroSeq}…${b.ultimoSeq}; buracos ${b.buracos.length}, repetidos ${b.repetidos.length})`);
  conferir(b.ultimoSeq === b.seqDoServidor, `${b.bot}: o último seq (${b.ultimoSeq}) é o do servidor (${b.seqDoServidor})`);
  conferir(b.vezesJogadas === c.vezesJogadas && b.recusas === 0,
    `${b.bot}: jogou ${b.vezesJogadas} vezes (no controlo, ${c.vezesJogadas}), ${b.recusas} recusadas`);
  if (b.bot !== 'C') {
    conferir(b.quedas >= 1 && b.entradas >= 2, `${b.bot}: caiu (${b.quedas}) e voltou a entrar (${b.entradas} entradas)`);
    const ultima = b.sincronizacoes.at(-1);
    conferir(b.eventosPerdidosNoCorte > 0, `${b.bot}: o servidor emitiu-lhe ${b.eventosPerdidosNoCorte} eventos durante o corte`);
    conferir(ultima && !ultima.snapshot && ultima.lastSeqEnviado !== null && ultima.primeiroSeq === ultima.lastSeqEnviado + 1,
      `${b.bot}: voltou com lastSeq ${ultima?.lastSeqEnviado} e recebeu os que faltavam a partir do ${ultima?.primeiroSeq} `
      + `(sem snapshot: ${!ultima?.snapshot})`);
    conferir(b.reconexaoS !== null && b.reconexaoS <= LIMITE_RECONEXAO_S,
      `${b.bot}: entrou ${b.reconexaoS} s depois de a rede voltar (≤ ${LIMITE_RECONEXAO_S} s)`);
  } else {
    conferir(b.quedas === 0, 'C: não caiu');
  }
}
const relatorio = { formato: 'prova-3-bots/1', corteS: CORTE_S, rodadas: RODADAS, controlo, queda, falhas };
if (args.saida) writeFileSync(args.saida, JSON.stringify(relatorio, null, 1) + '\n');
console.log(falhas.length ? `PROVA FALHOU (${falhas.length})` : 'PROVA OK: 3 bots, 25 s sem rede, hash lógico igual, seq contínuo');
process.exit(falhas.length ? 1 : 0);
