// ORDEM-PROVAS-MAPA-CORR8 (correcção 8 da sentença da conferência PROVAS-MAPA, ponto C2-4): a sonda de privacidade
// deu «0 achados» na batalha de bancada, mas nunca lhe deram um CONTROLO POSITIVO, ou seja, nunca se viu que ela apanha
// um canário quando um chega de facto à jogadora. E o «0 achados» não dizia o que a jogadora DEVE receber quando a
// escala muda, por isso não se distinguia o «silêncio correcto» de uma «notificação em falta». Só provas: nenhuma linha
// de nucleo/ muda.
//  (a) CONTROLO POSITIVO de procurarCanarios (a sonda Node do espectador e destes testes):
//      - no fio real da jogadora, numa mudança de escala na grelha-mapa, dá 0 achados;
//      - o mesmo fio com UMA mensagem de teste a mais, a imitar uma fuga, é apanhado. Há uma mensagem por tipo de
//        canário: as chaves só do Mestre (o evento `escala` tal como o Mestre o recebe), os textos (o detalhe da recusa
//        ESCALA_… e o nome verdadeiro do orc) e os números do orc. Cada uma é apanhada pelo que leva e por mais nada.
//  (b) O QUE A JOGADORA DEVE RECEBER numa mudança de escala aplicada, mensagem a mensagem (grelha-mapa e grelha fixa):
//      - na vez dela: ROOM_EVENT `escala` com dados {}, depois ROOM_SNAPSHOT (o mapa novo, as figuras no sítio e a
//        `propria`) e depois ROOM_OPTIONS (a reserva em metros e as casas na escala nova). Mais nada;
//      - fora da vez dela: o mesmo, sem o ROOM_OPTIONS;
//      - o espectador recebe o evento e o snapshot.
//  (c) O SILÊNCIO CORRECTO: nas recusas (ESCALA_JUNTA_FIGURAS, ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS,
//      ESCALA_INVALIDA e «a mesma escala») a jogadora e o espectador não recebem NENHUMA mensagem. O Mestre recebe o
//      ROOM_REJECT e, quando há detalhe, o evento `recusa`. Se for a jogadora a pedir a escala, recebe só o ERRO
//      «Só o Mestre.».
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { prepararTerreno } from '../nucleo/terreno.js';
import { montarMesa, exigirAplicada, procurarCanarios, FIXTURE, PIN } from './ajudantes.mjs';

const PACOTE = JSON.parse(readFileSync(new URL('../dados/terreno-floresta.json', import.meta.url), 'utf8'));
const T = prepararTerreno(PACOTE);
const estado = (m) => m.sala.depuracao.estado();
const escala = (m, casaM) => m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM });
const LADO = { 1: 75, 1.5: 50, 2: 37 };
const G = { 1: T.para(75, 75, 1), 1.5: T.para(50, 50, 1.5), 2: T.para(37, 37, 2) };

/** A casa da grelha-mapa de `para` que contém o centro da casa `c` da de `de` (a regra §0; como no CORR7). */
function noLugar(c, de, para) {
  const eixo = (v, i) => {
    const centro = G[de].origemM[i] + (v + 0.5) * de;
    return Math.min(LADO[para] - 1, Math.max(0, Math.floor((centro - G[para].origemM[i]) / para + 1e-9)));
  };
  return { x: eixo(c.x, 0), y: eixo(c.y, 1) };
}

/** Os canários da bancada da PROVAS-MAPA (bancada_jogadora_mapa.gd `_sonda`), com os números tirados da ficha. */
const ORC = FIXTURE.fichas.find((f) => f.id === 'orc-teste');
const CANARIOS = {
  numeros: [ORC.vidaTotal, ORC.paTotal, ORC.ca],
  textos: ['ESCALA_', 'CANARIO-FANTASMA', 'CANARIO-DESGRACA', 'CANARIO-SENHA', 'Orc Verdadeiro', PIN],
  chaves: ['casaMAntes', 'grelhaAntes', 'casasQuePaga', 'soMestre'],
};

/** Grelha-mapa (a sala nasce sem tamanho na config), a heroína em `casaHeroina`, o Mestre começa e põe as criaturas. */
function mesaMapa({ casaHeroina = { x: 20, y: 20 }, criaturas = [['orc-teste', { x: 30, y: 26 }]], modoPadrao = 'manual' } = {}) {
  const m = montarMesa({ terreno: PACOTE, mapa: null, casas: { heroina: casaHeroina }, comEspectador: true, modoPadrao });
  m.entrarTodos();
  exigirAplicada(m.mestre('MASTER_LOBBY_SET', {
    mapaId: 'arena-teste', criaturasDisponiveis: ['orc-teste', 'lobo-teste'], npcsDisponiveis: [],
  }), 'LOBBY_SET');
  exigirAplicada(m.mestre('MASTER_START'), 'START');
  for (const [fichaId, casa] of criaturas) exigirAplicada(m.mestre('MASTER_PLACE', { fichaId, casa }), `PLACE ${fichaId}`);
  return m;
}

/** O que cada papel recebeu durante `fn` (só as mensagens novas). */
function recebido(m, fn) {
  const n = Object.fromEntries(Object.entries(m.clientes).map(([k, c]) => [k, c.msgs.length]));
  const r = fn();
  return { r, ...Object.fromEntries(Object.entries(m.clientes).map(([k, c]) => [k, c.msgs.slice(n[k])])) };
}
const tipos = (msgs) => msgs.map((x) => (x.type === 'ROOM_EVENT' ? `ROOM_EVENT:${x.tipo}` : x.type));

test('CORR8 (a): controlo positivo da sonda — o fio real da jogadora dá 0 achados; uma mensagem de teste com canário, de cada tipo, é apanhada', () => {
  const m = mesaMapa();
  const h = m.clientes.heroina;
  const v = recebido(m, () => exigirAplicada(escala(m, 1), '1,5 → 1 m'));
  // O controlo negativo: o fio real dela (desde a entrada) está limpo.
  assert.deepEqual(procurarCanarios(h.msgs, CANARIOS), [], 'o fio real da jogadora está limpo');
  const real = v.heroina.find((x) => x.type === 'ROOM_EVENT' && x.tipo === 'escala');
  const doMestre = v.mestre.find((x) => x.type === 'ROOM_EVENT' && x.tipo === 'escala');
  assert.deepEqual(real.dados, {}, 'o evento real dela vai vazio');
  assert.ok(doMestre.dados.soMestre.grelhaAntes, 'o evento do Mestre leva o antes/depois (o canário existe de verdade)');
  // Uma recusa ESCALA_… real (ESCALA_INVALIDA, 3 m por casa), com o detalhe que só o Mestre recebe.
  const det = recebido(m, () => escala(m, 3));
  const recusaDoMestre = det.mestre.find((x) => x.type === 'ROOM_EVENT' && x.tipo === 'recusa');
  assert.match(recusaDoMestre.dados.soMestre.detalhe, /^ESCALA_INVALIDA/, 'o detalhe da recusa existe, no fio do Mestre');
  assert.deepEqual(det.heroina, [], 'e não chega à jogadora');

  // As mensagens de teste, cada uma com UM tipo de canário, no fio da jogadora logo a seguir ao evento real.
  const teste = {
    chaves: { ...real, dados: doMestre.dados }, // a fuga típica: o evento `escala` sem a projecção da Party
    textos: { ...real, tipo: 'escala', dados: { detalhe: recusaDoMestre.dados.soMestre.detalhe, nome: ORC.nome, eco: 'CANARIO-FANTASMA', pin: PIN } },
    numeros: { ...real, dados: { vida: ORC.vidaTotal, pa: ORC.paTotal, defesa: ORC.ca } },
  };
  const i = h.msgs.lastIndexOf(h.msgs.filter((y) => y.type === 'ROOM_EVENT' && y.tipo === 'escala').at(-1));
  for (const [classe, msg] of Object.entries(teste)) {
    const fio = [...h.msgs.slice(0, i + 1), msg, ...h.msgs.slice(i + 1)];
    const achados = procurarCanarios(fio, CANARIOS);
    assert.ok(achados.length > 0, `${classe}: a sonda APANHA a mensagem de teste`);
    assert.ok(achados.every((a) => a.i === i + 1), `${classe}: todos os achados são da mensagem de teste (índice ${i + 1})`);
    const apanhado = new Set(achados.map((a) => (a.porque ? 'chave:' + a.chave : typeof a.valor === 'number' ? 'numero:' + a.valor : 'texto:' + a.valor)));
    const esperado = {
      chaves: ['chave:soMestre', 'chave:casaMAntes', 'chave:grelhaAntes', 'chave:casasQuePaga'],
      textos: ['texto:ESCALA_', 'texto:Orc Verdadeiro', 'texto:CANARIO-FANTASMA', 'texto:' + PIN],
      numeros: [ORC.vidaTotal, ORC.paTotal, ORC.ca].map((n) => 'numero:' + n),
    }[classe];
    assert.deepEqual([...apanhado].sort(), [...esperado].sort(), `${classe}: apanha cada canário que a mensagem leva, e só esses`);
  }
});

for (const grelha of ['grelha-mapa', 'grelha fixa 30 × 30']) {
  test(`CORR8 (b): o que a jogadora DEVE receber numa mudança de escala aplicada (${grelha}) — evento vazio, snapshot e, na vez dela, as opções`, () => {
    const m = grelha === 'grelha-mapa'
      ? mesaMapa()
      : (() => {
        const mm = montarMesa({ terreno: PACOTE, mapa: { largura: 30, altura: 30 }, casas: { heroina: { x: 10, y: 10 } }, comEspectador: true, modoPadrao: 'manual' });
        mm.entrarTodos();
        mm.iniciarCombate([['orc-teste', { x: 15, y: 15 }]]);
        return mm;
      })();
    const h = m.clientes.heroina;
    assert.equal(estado(m).vez.figuraId, h.figuraId, 'é a vez da heroína');
    // na vez dela, a meio: anda uma casa e depois o Mestre muda a escala
    const passo = h.opcoes.mover.find((o) => Math.abs(o.custoM - 1.5) < 1e-9);
    exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: passo.x, y: passo.y } }), 'um passo');
    const casaM = 2;
    const v = recebido(m, () => exigirAplicada(escala(m, casaM), '1,5 → 2 m'));
    assert.deepEqual(tipos(v.heroina), ['ROOM_EVENT:escala', 'ROOM_SNAPSHOT', 'ROOM_OPTIONS'], 'jogadora, na vez dela: exactamente estas 3, por esta ordem');
    const [ev, snap, op] = v.heroina;
    assert.deepEqual(ev.dados, {}, '1) o evento `escala` vai vazio — nem antes/depois, nem a vez');
    assert.equal(snap.seq, ev.seq, '2) o snapshot leva o seq do evento');
    assert.deepEqual(snap.mapa, estado(m).mapa, '2) o snapshot leva o mapa novo');
    assert.equal(snap.mapa.casaM, casaM);
    if (grelha === 'grelha-mapa') assert.deepEqual([snap.mapa.largura, snap.mapa.altura], [37, 37], '2) a grelha-mapa a 2 m é 37 × 37');
    else assert.deepEqual([snap.mapa.largura, snap.mapa.altura], [30, 30], '2) a grelha fixa fica 30 × 30');
    for (const f of snap.figuras) {
      const real = estado(m).figuras[f.id];
      assert.deepEqual([f.x, f.y], [real.x, real.y], `2) o snapshot leva ${f.nomePublico} na casa nova`);
    }
    assert.equal(snap.propria.figuraId, h.figuraId, '2) e a `propria` dela');
    assert.equal(op.orcamentoM, 9 - 1.5, '3) as opções: a reserva continua em metros (9 − 1,5)');
    assert.ok(op.mover.every((o) => o.custoM <= op.orcamentoM + 1e-9 && Math.abs(o.custoM / casaM - Math.round(o.custoM / casaM)) < 1e-9),
      '3) as opções: o custo de cada casa é um múltiplo de 2 m e cabe na reserva');
    assert.deepEqual(tipos(v.espectador), ['ROOM_EVENT:escala', 'ROOM_SNAPSHOT'], 'espectador: o evento vazio e o snapshot');
    assert.deepEqual(v.espectador[0].dados, {});
    assert.ok(tipos(v.mestre).includes('ROOM_RECEIPT'), 'o recibo vai só ao Mestre');
    assert.deepEqual(procurarCanarios([...v.heroina, ...v.espectador], CANARIOS), [], 'nada do Mestre no que a Party recebeu');

    // Fora da vez dela: encerra, e o Mestre muda de volta para 1,5 m na vez do orc.
    exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar');
    assert.notEqual(estado(m).vez.figuraId, h.figuraId, 'a vez é do orc');
    const w = recebido(m, () => exigirAplicada(escala(m, 1.5), '2 → 1,5 m'));
    assert.deepEqual(tipos(w.heroina), ['ROOM_EVENT:escala', 'ROOM_SNAPSHOT'], 'jogadora, fora da vez: o evento e o snapshot, sem opções');
    assert.deepEqual(w.heroina[0].dados, {});
    assert.equal(w.heroina[1].mapa.casaM, 1.5);
    assert.deepEqual(tipos(w.espectador), ['ROOM_EVENT:escala', 'ROOM_SNAPSHOT']);
  });
}

test('CORR8 (c): o silêncio correcto — nas recusas da escala a jogadora e o espectador não recebem nada; o Mestre recebe a recusa', () => {
  // ESCALA_JUNTA_FIGURAS (1,5 → 2 m): heroína e orc em duas casas de 1,5 m que caem na mesma de 2 m (como no CORR7 (b)).
  let junta = null;
  let bloq = null;
  for (let y = 10; y < 40; y++) {
    for (let x = 10; x < 40; x++) {
      const a = noLugar({ x, y }, 1.5, 2);
      const b = noLugar({ x: x + 1, y }, 1.5, 2);
      if (!junta && a.x === b.x && a.y === b.y && !G[1.5].bloqueada(x, y) && !G[1.5].bloqueada(x + 1, y) && !G[2].bloqueada(a.x, a.y)) {
        junta = { heroina: { x, y }, orc: { x: x + 1, y } };
      }
      // ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS: uma casa livre a 1,5 m que cai numa bloqueada a 2 m (CORR7 (c)).
      if (!bloq && !G[1.5].bloqueada(x, y) && G[2].bloqueada(a.x, a.y)) bloq = { x, y };
    }
  }
  assert.ok(junta && bloq, 'há casas para as duas recusas');
  const casos = [
    ['ESCALA_JUNTA_FIGURAS', mesaMapa({ casaHeroina: junta.heroina, criaturas: [['orc-teste', junta.orc]] }), 2],
    ['ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS', mesaMapa({ criaturas: [['orc-teste', bloq]] }), 2],
    ['ESCALA_INVALIDA', mesaMapa(), 3],
    ['a mesma escala (sem detalhe)', mesaMapa(), 1.5],
  ];
  for (const [nome, m, casaM] of casos) {
    const antes = JSON.stringify({ f: estado(m).figuras, mapa: estado(m).mapa });
    const v = recebido(m, () => escala(m, casaM));
    assert.deepEqual(v.heroina, [], `${nome}: a jogadora não recebe nenhuma mensagem`);
    assert.deepEqual(v.espectador, [], `${nome}: o espectador não recebe nenhuma mensagem`);
    const rej = v.mestre.find((x) => x.type === 'ROOM_REJECT');
    assert.equal(rej?.motivo, 'acao_invalida', `${nome}: o Mestre recebe o ROOM_REJECT`);
    const det = v.mestre.find((x) => x.type === 'ROOM_EVENT' && x.tipo === 'recusa')?.dados?.soMestre?.detalhe ?? null;
    if (nome.startsWith('ESCALA_')) assert.ok(det?.startsWith(nome + ':'), `${nome}: o detalhe vai ao Mestre — ${det}`);
    else assert.equal(det, null, `${nome}: sem detalhe`);
    assert.equal(JSON.stringify({ f: estado(m).figuras, mapa: estado(m).mapa }), antes, `${nome}: a sala fica igual`);
  }
  // A jogadora a pedir a escala: só o ERRO dela, e mais ninguém recebe nada.
  const m = mesaMapa();
  const v = recebido(m, () => m.enviar('heroina', { type: 'MASTER_SUPERVISOR', intentId: 'escala-dela', revision: m.clientes.heroina.revision, op: 'escala', casaM: 2 }));
  assert.deepEqual(v.heroina.map((x) => [x.type, x.texto]), [['ERRO', 'Só o Mestre.']], 'a jogadora recebe só o ERRO «Só o Mestre.»');
  assert.deepEqual([v.espectador, v.mestre], [[], []]);
  assert.equal(estado(m).mapa.casaM, 1.5);
});
