// ORDEM-PROVAS-MAPA-CORR8: o servidor da batalha de bancada da PROVAS-MAPA, com o CONTROLO POSITIVO da sonda. É o mesmo
// servidor de bancada-servidor.mjs (o sala.js de verdade atrás do adaptador WebSocket do repo, a grelha-mapa, o terreno,
// o motor falso, o modo manual e as fichas fictícias). O código do jogo não muda. Muda só isto, de fora, num invólucro do
// `sala.receber`:
//  1) A ESCUTA DO FIO DA JOGADORA. Cada mensagem que o servidor entrega ao lugar da heroína é escrita, pela ordem, numa
//     linha JSON de <escuta.jsonl>. É o fio dela, antes da Rede do cliente.
//  2) AS MENSAGENS DE TESTE COM CANÁRIO, só no lugar da heroína e só na PRIMEIRA mudança de escala (1,5 → 1 m). Vão logo a
//     seguir ao evento `escala` real dela, com o MESMO seq desse evento, por isso o Estado do cliente as descarta como
//     repetidas e a batalha não muda. Cada uma leva no topo `canarioTeste` com o nome do caso:
//       K1 chaves  — o evento `escala` com os dados do Mestre (soMestre: casaMAntes, grelhaAntes, vez.casasQuePaga);
//       K2 textos  — um evento `escala` com o detalhe de uma recusa ESCALA_…, o nome verdadeiro do orc, um CANARIO e o PIN;
//       K3 números — um evento `escala` com a Vida, os PA e a CA do orc (7777, 313, 9137);
//       K4 limite  — uma MASTER_VIEW do Mestre, com as figuras e o bloco `mestre` do snapshot que o Mestre recebe nesta
//                    mesma entrega (o orc inteiro: nome verdadeiro, Vida, PA). A Rede da jogadora deita-a fora;
//       K5 limite  — um ROOM_REJECT com o detalhe ESCALA_… e um intentId que não é dela. A Rede ignora-o.
//     K1–K3 são o controlo positivo: a sonda da jogadora TEM de os apanhar. K4 e K5 medem até onde a sonda chega.
//
//   node bancada-servidor-canario.mjs 8792 <escuta.jsonl>
import { readFileSync, writeFileSync, appendFileSync } from 'node:fs';
import { criarSala } from '../../../rascunhos/servidor/nucleo/sala.js';
import { criarServidor, rngNode } from '../../../rascunhos/servidor/adaptadores/node/servidor-ws.js';
import { criarMotorFalso } from '../../../rascunhos/servidor/testes/motor-falso.mjs';
import { fichasDeTeste, FIXTURE, INICIATIVA, PIN, SENHAS } from '../../../rascunhos/servidor/testes/ajudantes.mjs';

const porta = Number(process.argv[2] ?? 8792);
const escuta = process.argv[3] ?? 'escuta-jogadora.jsonl';
writeFileSync(escuta, '');
const terreno = JSON.parse(readFileSync(new URL('../../../rascunhos/servidor/dados/terreno-floresta.json', import.meta.url), 'utf8'));
const sala = criarSala({
  terreno,
  motores: criarMotorFalso({ resultado: 'falha_critica' }),
  fichas: fichasDeTeste(),
  rng: rngNode(),
  agora: () => Date.now(),
  config: {
    roomId: 'sala-bancada-mapa',
    teste: true,
    iniciativa: INICIATIVA,
    modoPadrao: 'manual',
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 38, y: 4 } },
      { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  },
});

const ORC = FIXTURE.fichas.find((f) => f.id === 'orc-teste');
const seatDe = (papel) => Object.values(sala.depuracao.estado().lugares).find((l) => l.papel === papel)?.seatId;
const HEROINA = seatDe('jogadora');
const MESTRE = seatDe('mestre');
let injectadas = false;
let n = 0;
let lote = 0; // uma entrega do servidor (uma chamada à sala): o que chega junto
const ouvir = (saidas, onde) => {
  lote += 1;
  for (const { seatId, msg } of saidas) {
    // o seatToken da entrada não se grava (é uma credencial, mesmo de teste); fica a marca de que existia
    const gravar = msg?.seatToken ? { ...msg, seatToken: '<retirado da escuta>' } : msg;
    if (seatId === HEROINA) appendFileSync(escuta, JSON.stringify({ n: n++, lote, onde, msg: gravar }) + '\n');
  }
};

/** As mensagens de teste com canário (ver o cabeçalho), feitas a partir do evento real dela e do do Mestre. */
function mensagensDeTeste(real, doMestre) {
  // A última MASTER_VIEW do Mestre (a da entrada), actualizada com o que o snapshot dele traz agora (o orc já está posto).
  const base = [...doMestre.vistas].reverse().find((m) => m.type === 'MASTER_VIEW') ?? { v: 2, type: 'MASTER_VIEW', roomId: real.roomId };
  const snap = doMestre.snapshot;
  const vista = snap ? { ...base, mapa: snap.mapa, figuras: snap.figuras, mestre: snap.mestre } : null;
  return [
    { ...real, canarioTeste: 'K1', dados: doMestre.evento.dados },
    { ...real, canarioTeste: 'K2', dados: { detalhe: 'ESCALA_JUNTA_FIGURAS: 2 figuras ficavam juntas com 1 m por casa — teste', nome: ORC.nome, eco: 'CANARIO-FANTASMA', pin: PIN } },
    { ...real, canarioTeste: 'K3', dados: { vida: ORC.vidaTotal, pa: ORC.paTotal, defesa: ORC.ca } },
    ...(vista ? [{ ...vista, canarioTeste: 'K4' }] : []),
    { v: 2, type: 'ROOM_REJECT', roomId: real.roomId, canarioTeste: 'K5', intentId: 'canario-k5', motivo: 'acao_invalida', texto: 'ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS: teste CANARIO-FANTASMA' },
  ];
}

const vistasDoMestre = [];
const invólucro = {
  ...sala,
  entrar(msg, opcoes) {
    const r = sala.entrar(msg, opcoes);
    if (r.ok && r.seatId === MESTRE) for (const m of r.mensagens) if (m?.type === 'MASTER_VIEW') vistasDoMestre.push(m);
    if (r.ok && r.seatId === HEROINA) ouvir(r.mensagens.map((msg) => ({ seatId: HEROINA, msg })), 'entrar');
    ouvir(r.saidas ?? [], 'entrar');
    return r;
  },
  conexaoAberta(seatId) { const s = sala.conexaoAberta(seatId); ouvir(s, 'conexaoAberta'); return s; },
  conexaoFechada(seatId) { const s = sala.conexaoFechada(seatId); ouvir(s, 'conexaoFechada'); return s; },
  receber(seatId, msg) {
    let saidas = sala.receber(seatId, msg);
    for (const s of saidas) if (s.seatId === MESTRE && s.msg?.type === 'MASTER_VIEW') vistasDoMestre.push(s.msg);
    if (!injectadas) {
      const i = saidas.findIndex((s) => s.seatId === HEROINA && s.msg?.type === 'ROOM_EVENT' && s.msg.tipo === 'escala');
      const doMestre = saidas.find((s) => s.seatId === MESTRE && s.msg?.type === 'ROOM_EVENT' && s.msg.tipo === 'escala');
      const snapDoMestre = saidas.find((s) => s.seatId === MESTRE && s.msg?.type === 'ROOM_SNAPSHOT')?.msg ?? null;
      if (i >= 0 && doMestre) {
        injectadas = true;
        const teste = mensagensDeTeste(saidas[i].msg, { evento: doMestre.msg, vistas: vistasDoMestre, snapshot: snapDoMestre });
        saidas = [...saidas.slice(0, i + 1), ...teste.map((msg) => ({ seatId: HEROINA, msg })), ...saidas.slice(i + 1)];
        console.log(`[canario] ${teste.length} mensagens de teste no fio da heroína (${teste.map((t) => t.canarioTeste).join(', ')}), seq ${saidas[i].msg.seq}`);
      }
    }
    ouvir(saidas, 'receber');
    return saidas;
  },
};
const servidor = criarServidor({ sala: invólucro, registo: (t) => console.log('[servidor]', t) });
servidor.listen(porta, '127.0.0.1', () => console.log(`pronto-bancada ${porta} (com o controlo positivo da sonda)`));
