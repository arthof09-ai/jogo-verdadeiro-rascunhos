// ORDEM-F2 — A PROVA DA ESCUTA PERMANENTE, FORA DA CORRIDA PADRÃO. É o servidor da bancada padrão
// (provas/ordem-mapa-jogavel/provas-bancada/ferramentas/bancada-servidor.mjs: criarSalaBancada + a MESMA função
// `escutar`, sem cópia) com um `alterar` que mete no fio da heroína as cinco mensagens de teste da CORR8
// (bancada-servidor-canario.mjs, mensagensDeTeste, sem mudança), na primeira mudança de escala, com o mesmo seq do
// evento `escala` real dela:
//   K1 chaves (o evento escala do Mestre) · K2 textos (ESCALA_…, nome verdadeiro do orc, CANARIO, PIN) ·
//   K3 números (Vida, PA, CA do orc) · K4 uma MASTER_VIEW (a Rede deita-a fora) · K5 um ROOM_REJECT alheio (a Rede ignora).
// Prova que a escuta da corrida padrão vê o fio inteiro: a sonda do fio (sonda-fio.mjs --canarios) tem de apanhar
// K1–K5, cada uma pelo conjunto exacto. NÃO é a corrida padrão e não entra nela.
//   node bancada-servidor-k.mjs 8796 <escuta.jsonl>
import { criarServidor } from '../../../rascunhos/servidor/adaptadores/node/servidor-ws.js';
import { FIXTURE, PIN } from '../../../rascunhos/servidor/testes/ajudantes.mjs';
import { criarSalaBancada, escutar } from '../../ordem-mapa-jogavel/provas-bancada/ferramentas/bancada-servidor.mjs';

const porta = Number(process.argv[2] ?? 8796);
const escuta = process.argv[3] ?? 'escuta-jogadora.jsonl';
const sala = criarSalaBancada();
const ORC = FIXTURE.fichas.find((f) => f.id === 'orc-teste');
const MESTRE = Object.values(sala.depuracao.estado().lugares).find((l) => l.papel === 'mestre')?.seatId;

/** As mensagens de teste com canário — a função da CORR8 (bancada-servidor-canario.mjs), igual. */
function mensagensDeTeste(real, doMestre) {
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
let injectadas = false;
const comEscuta = escutar(sala, escuta, {
  alterar(saidas, { HEROINA }) {
    for (const s of saidas) if (s.seatId === MESTRE && s.msg?.type === 'MASTER_VIEW') vistasDoMestre.push(s.msg);
    if (injectadas) return saidas;
    const i = saidas.findIndex((s) => s.seatId === HEROINA && s.msg?.type === 'ROOM_EVENT' && s.msg.tipo === 'escala');
    const doMestre = saidas.find((s) => s.seatId === MESTRE && s.msg?.type === 'ROOM_EVENT' && s.msg.tipo === 'escala');
    const snapDoMestre = saidas.find((s) => s.seatId === MESTRE && s.msg?.type === 'ROOM_SNAPSHOT')?.msg ?? null;
    if (i < 0 || !doMestre) return saidas;
    injectadas = true;
    const teste = mensagensDeTeste(saidas[i].msg, { evento: doMestre.msg, vistas: vistasDoMestre, snapshot: snapDoMestre });
    console.log(`[canario] ${teste.length} mensagens de teste no fio da heroína (${teste.map((t) => t.canarioTeste).join(', ')}), seq ${saidas[i].msg.seq}`);
    return [...saidas.slice(0, i + 1), ...teste.map((msg) => ({ seatId: HEROINA, msg })), ...saidas.slice(i + 1)];
  },
});
// a MASTER_VIEW da entrada do Mestre (base da K4) vem pelo `entrar`, que o `alterar` não vê
const entrar = comEscuta.entrar;
comEscuta.entrar = (msg, opcoes) => {
  const r = entrar(msg, opcoes);
  if (r.ok && r.seatId === MESTRE) for (const m of r.mensagens) if (m?.type === 'MASTER_VIEW') vistasDoMestre.push(m);
  return r;
};
const servidor = criarServidor({ sala: comEscuta, registo: (t) => console.log('[servidor]', t) });
servidor.listen(porta, '127.0.0.1', () => console.log(`pronto-bancada ${porta} (PROVA DA ESCUTA: com os canários K1–K5 — não é a corrida padrão)`));
