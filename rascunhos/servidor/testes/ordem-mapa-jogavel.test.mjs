// ORDEM MAPA-JOGÁVEL (palavra do Mestre, 2026-11-20: «Eu quero que todo o mapa seja jogável» — água incluída).
// A decisão escala × malha (ESTADO-FINAL-ORDEM-MAPA-JOGAVEL.md §0): a grelha da batalha é o MAIOR QUADRADO DE CASAS QUE
// CABE NO MAPA na escala viva — 75 × 75 de 1 m (o mapa, borda a borda), 50 × 50 de 1,5 m (a malha do relevo, casa a
// casa) e 37 × 37 de 2 m (74 m: fica uma faixa de 0,5 m em cada borda, menos do que uma casa). Cada casa da batalha
// leva o terreno da casa da malha debaixo do seu centro (a regra de sempre do pacote); a malha e o pacote não mudam.
// O lago: as casas que o pacote bloqueia por «água funda» são CASAS DE ÁGUA — entram-se, ocupam-se, atravessam-se, com
// o MESMO custo de uma casa seca (o cânone não tem regra de água: [FALTA] na Passagem).
// Provas:
//  (a) a sala com terreno nasce com a grelha = o mapa inteiro, e o Mestre muda a escala para 1 m e 2 m com a grelha a
//      seguir o mapa (75 / 50 / 37), sem ninguém mudar de sítio no mapa;
//  (b) em cada escala, UMA FIGURA ATRAVESSA O MAPA INTEIRO E ENTRA NO LAGO: com reserva para o mapa todo, as opções de
//      mover cobrem TODAS as casas que se pisam (nenhuma inalcançável por desenho) — as de água incluídas — e a
//      heroína anda do canto NO ao canto SE e daí para dentro do lago (intenções aplicadas);
//  (c) a prova dos 6 m da ESCALA (6 / 4 / 3 casas) sobre a água: do meio do lago, 6 m cobrem N casas e N + 1 não; uma
//      técnica de 6 m chega a N casas e não a N + 1;
//  (d) o ataque de oportunidade passa pela grelha nova: sair de ao pé do orc, dentro da água, em cada escala;
//  (e) as recusas da mudança de escala na grelha-mapa (figuras juntas numa casa; casa bloqueada) deixam a sala igual;
//  (f) privacidade: a Party recebe o mapa novo e o evento `escala` vazio; o antes/depois (grelhaAntes) é só do Mestre.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { carregarFichas } from '../nucleo/carregar-fichas.js';
import { prepararTerreno, MOTIVOS_DE_AGUA } from '../nucleo/terreno.js';
import { CASA_M } from '../nucleo/sala.js';
import { montarMesa, exigirAplicada, recibo, listaDeFichas, procurarCanarios, FIXTURE } from './ajudantes.mjs';

const PACOTE = JSON.parse(readFileSync(new URL('../dados/terreno-floresta.json', import.meta.url), 'utf8'));
const T = prepararTerreno(PACOTE);
const estado = (m) => m.sala.depuracao.estado();
const escala = (m, casaM) => m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM });
const idDaFicha = (m, fichaId) => Object.values(estado(m).figuras).find((f) => f.fichaId === fichaId)?.id;

// A decisão: o lado da grelha-mapa e a origem (canto NO, m) por escala; 6 m em casas (a tabela da ESCALA).
const MAPA_POR_ESCALA = [
  { casaM: 1, lado: 75, origem: -37.5, casas6m: 6 },
  { casaM: 1.5, lado: 50, origem: -37.5, casas6m: 4 },
  { casaM: 2, lado: 37, origem: -37, casas6m: 3 },
];

/** Fichas de teste com a heroína a andar `deslocamentoM` e as técnicas dela a `alcanceM`. */
function fichas({ deslocamentoM = 9, alcanceM = null } = {}) {
  const lista = listaDeFichas();
  const h = lista.find((f) => f.id === 'heroina-teste');
  h.deslocamentoBase = deslocamentoM;
  if (alcanceM !== null) for (const t of h.tecnicas) t.alcanceM = alcanceM;
  const r = carregarFichas(lista);
  if (!r.ok) throw new Error('fichas inválidas: ' + JSON.stringify(r.erros));
  return r.fichas;
}

/** A grelha-mapa da escala `casaM`, as casas de água e as casas que se pisam. */
function grelhaMapa(casaM) {
  const { lado } = MAPA_POR_ESCALA.find((e) => e.casaM === casaM);
  const g = T.para(lado, lado, casaM);
  const agua = [];
  const pisaveis = [];
  for (let y = 0; y < lado; y++) {
    for (let x = 0; x < lado; x++) {
      if (g.agua(x, y)) agua.push({ x, y });
      if (!g.bloqueada(x, y)) pisaveis.push({ x, y });
    }
  }
  return { g, lado, agua, pisaveis };
}

/**
 * A casa de 1,5 m (a escala com que a sala nasce) cujo centro, no mapa, cai na casa `alvo` da grelha-mapa de `casaM`
 * (a regra da mudança de escala: ninguém muda de sítio no mapa), ou null se nenhuma cai lá.
 */
function casaDe15(casaM, alvo) {
  const { origem } = MAPA_POR_ESCALA.find((e) => e.casaM === casaM);
  const img = (i) => Math.floor((-37.5 + (i + 0.5) * 1.5 - origem) / casaM + 1e-9);
  const x = [...Array(50).keys()].find((i) => img(i) === alvo.x);
  const y = [...Array(50).keys()].find((i) => img(i) === alvo.y);
  return x === undefined || y === undefined ? null : { x, y };
}

/** A casa de água com mais casas de água seguidas para sul (o «meio do lago» da prova), onde a heroína pode nascer. */
function meioDoLago(casaM) {
  const { g, agua } = grelhaMapa(casaM);
  const corrida = (c) => { let n = 0; while (g.agua(c.x, c.y + n + 1)) n++; return n; };
  return agua.filter((c) => casaDe15(casaM, c)).map((c) => ({ ...c, corrida: corrida(c) }))
    .sort((a, b) => b.corrida - a.corrida || a.y - b.y || a.x - b.x)[0];
}

/**
 * LAGO-MAIOR: a casa do canto SO de `casaM` onde a criatura nasce por omissão — a do próprio canto se o sítio dela no
 * mapa se pisa nas TRÊS escalas (a mudança de escala não a pode deixar numa casa bloqueada); senão a mais perto do
 * canto que o faz. (Com a floresta devolvida, o canto SO a 2 m tem um abeto.)
 */
function cantoSO(casaM) {
  const livreEmTodas = (px, pz) => MAPA_POR_ESCALA.every(({ casaM: s, lado, origem }) => {
    const x = Math.floor((px - origem) / s);
    const y = Math.floor((pz - origem) / s);
    return x >= 0 && y >= 0 && x < lado && y < lado && !grelhaMapa(s).g.bloqueada(x, y);
  });
  const { lado, origem } = MAPA_POR_ESCALA.find((e) => e.casaM === casaM);
  for (let d = 0; d < lado; d++) {
    for (let k = 0; k <= d; k++) {
      for (const [x, y] of [[k, lado - 1 - d], [d, lado - 1 - k]]) {
        if (livreEmTodas(origem + (x + 0.5) * casaM, origem + (y + 0.5) * casaM)) return { x, y };
      }
    }
  }
  return null;
}

/**
 * Sala sem tamanho na config (= o mapa inteiro). A heroína nasce na casa `casaHeroina` da grelha-mapa de `casaM`; o
 * Mestre começa a batalha, muda a escala e só depois põe as criaturas (`criaturas` em casas da escala `casaM`).
 */
function mesaMapa(casaM, { casaHeroina = { x: 0, y: 0 }, criaturas = null, deslocamentoM = 9, alcanceM = null, comEspectador = false } = {}) {
  const casa15 = casaDe15(casaM, casaHeroina);
  assert.ok(casa15, `a casa ${JSON.stringify(casaHeroina)} de ${casaM} m tem uma casa de 1,5 m no mesmo sítio`);
  const m = montarMesa({ terreno: PACOTE, mapa: null, casas: { heroina: casa15 }, fichas: fichas({ deslocamentoM, alcanceM }), comEspectador });
  m.entrarTodos();
  exigirAplicada(m.mestre('MASTER_LOBBY_SET', {
    mapaId: 'arena-teste', criaturasDisponiveis: ['orc-teste', 'lobo-teste'], npcsDisponiveis: ['bandido-teste'],
  }), 'LOBBY_SET');
  exigirAplicada(m.mestre('MASTER_START'), 'START');
  if (casaM !== CASA_M) exigirAplicada(escala(m, casaM), 'escala ' + casaM);
  const eu = estado(m).figuras[m.clientes.heroina.figuraId];
  assert.deepEqual([eu.x, eu.y], [casaHeroina.x, casaHeroina.y], 'a heroína está na casa pedida');
  // Por omissão a criatura fica longe, no canto SO (não se mete no caminho da prova) — cantoSO().
  for (const [fichaId, casa] of criaturas ?? [['orc-teste', cantoSO(casaM)]]) {
    exigirAplicada(m.mestre('MASTER_PLACE', { fichaId, casa }), 'PLACE ' + fichaId);
  }
  assert.equal(estado(m).vez?.figuraId, m.clientes.heroina.figuraId, 'a vez é da heroína');
  return m;
}

test('MAPA-JOGÁVEL: os números do mapa — 75 / 50 / 37 casas, a água do lago em cada escala', () => {
  assert.deepEqual([...MOTIVOS_DE_AGUA], ['água funda']);
  assert.deepEqual(T.escalas.map((e) => `${e.casaM}:${e.ladoMax}`), MAPA_POR_ESCALA.map((e) => `${e.casaM}:${e.lado}`));
  const contas = {};
  for (const { casaM, lado, origem } of MAPA_POR_ESCALA) {
    const { g, agua, pisaveis } = grelhaMapa(casaM);
    assert.deepEqual([...g.origemM], [origem, origem], `${casaM} m: a grelha-mapa começa no canto NO (${origem} m)`);
    // a grelha cobre o mapa: de −37,5 a 37,5 m (a 2 m, de −37 a 37: a faixa de 0,5 m é menos do que uma casa)
    const fim = origem + lado * casaM;
    assert.ok(origem - -37.5 < casaM && 37.5 - fim < casaM && fim <= 37.5, `${casaM} m: nada do mapa fica de fora que caiba numa casa`);
    assert.ok(agua.length > 0, `${casaM} m: o lago está dentro da grelha`);
    for (const c of agua) {
      assert.equal(g.bloqueada(c.x, c.y), false, `${casaM} m: (${c.x},${c.y}) é água e pisa-se`);
      assert.equal(g.motivo(c.x, c.y), null);
      assert.equal(PACOTE.mapa.motivos[`${g.casaDoMapa(c.x, c.y).coluna},${g.casaDoMapa(c.x, c.y).linha}`], 'água funda', 'é a água do pacote');
    }
    contas[casaM] = { casas: lado * lado, pisaveis: pisaveis.length, agua: agua.length, bloqueadas: g.casasBloqueadas() };
    assert.equal(pisaveis.length + g.casasBloqueadas(), lado * lado);
    assert.equal(g.casasDeAgua(), agua.length);
  }
  // A 1,5 m cada casa da batalha é uma casa da malha: as 131 casas de água funda do pacote, todas.
  assert.equal(contas[1.5].agua, Object.values(PACOTE.mapa.motivos).filter((v) => v === 'água funda').length);
  // LAGO-MAIOR: o lago maior (água: 50 / 21 / 13 → 301 / 131 / 75) e a floresta de dentro do campo devolvida (as
  // casas de tronco e de rocha: bloqueadas 156 / 67 / 43 → 348 / 152 / 94).
  assert.deepEqual(contas, {
    1: { casas: 5625, pisaveis: 5277, agua: 301, bloqueadas: 348 },
    1.5: { casas: 2500, pisaveis: 2348, agua: 131, bloqueadas: 152 },
    2: { casas: 1369, pisaveis: 1275, agua: 75, bloqueadas: 94 },
  });
});

test('MAPA-JOGÁVEL (a): a sala com terreno nasce com a grelha = o mapa inteiro (50 × 50 de 1,5 m); sem terreno, a de sempre', () => {
  const m = montarMesa({ terreno: PACOTE, mapa: null });
  m.entrarTodos();
  assert.deepEqual(estado(m).mapa, { largura: 50, altura: 50, casaM: 1.5 });
  assert.deepEqual(m.clientes.heroina.ultimo('ROOM_SNAPSHOT').mapa, { largura: 50, altura: 50, casaM: 1.5 }, 'a jogadora recebe o mapa inteiro');
  const sem = montarMesa({ mapa: null });
  sem.entrarTodos();
  assert.deepEqual(estado(sem).mapa, { largura: 20, altura: 20, casaM: 1.5 }, 'sem terreno não há mapa: 20 × 20 como sempre');
  const dada = montarMesa({ terreno: PACOTE, mapa: { largura: 30, altura: 30 } });
  dada.entrarTodos();
  assert.deepEqual(estado(dada).mapa, { largura: 30, altura: 30, casaM: 1.5 }, 'um tamanho dado na config continua a valer');
});

test('MAPA-JOGÁVEL (a): mudar a escala com a grelha-mapa — 50 → 75 → 37 → 50, ninguém muda de sítio no mapa', () => {
  const m = mesaMapa(1.5, { casaHeroina: { x: 25, y: 25 } });
  const h = m.clientes.heroina;
  const orc = idDaFicha(m, 'orc-teste');
  const lugar = (f, casaM, origem) => [origem + (f.x + 0.5) * casaM, origem + (f.y + 0.5) * casaM];
  const perto = (a, b, casaM) => Math.abs(a[0] - b[0]) <= casaM / 2 + 1e-9 && Math.abs(a[1] - b[1]) <= casaM / 2 + 1e-9;
  let antes = { casaM: 1.5, origem: -37.5 };
  for (const { casaM, lado, origem } of [MAPA_POR_ESCALA[0], MAPA_POR_ESCALA[2], MAPA_POR_ESCALA[1]]) {
    const figurasAntes = JSON.parse(JSON.stringify(estado(m).figuras));
    exigirAplicada(escala(m, casaM), `${antes.casaM} → ${casaM} m`);
    assert.deepEqual(estado(m).mapa, { largura: lado, altura: lado, casaM }, `${casaM} m: a grelha é o mapa inteiro`);
    assert.deepEqual(h.ultimo('ROOM_SNAPSHOT').mapa, { largura: lado, altura: lado, casaM }, `${casaM} m: a jogadora recebe-a`);
    for (const id of [h.figuraId, orc]) {
      const ld = lugar(figurasAntes[id], antes.casaM, antes.origem);
      const ln = lugar(estado(m).figuras[id], casaM, origem);
      // a casa nova contém o centro da casa de antes (a 2 m, perto da borda, a casa da borda)
      assert.ok(perto(ld, ln, casaM) || figurasAntes[id].x === 0 || figurasAntes[id].y === lado - 1 || estado(m).figuras[id].y === lado - 1,
        `${casaM} m: ${id} fica no mesmo sítio do mapa (${ld} → ${ln})`);
    }
    antes = { casaM, origem };
  }
  // De volta a 1,5 m: a heroína está onde começou (25,25) — 1,5 → 1 → 2 → 1,5 m.
  const eu = estado(m).figuras[h.figuraId];
  assert.ok(Math.abs(eu.x - 25) <= 1 && Math.abs(eu.y - 25) <= 1, `a heroína volta ao sítio (${eu.x},${eu.y})`);
});

for (const { casaM, lado } of MAPA_POR_ESCALA) {
  test(`MAPA-JOGÁVEL (b): a ${casaM} m, uma figura atravessa o mapa inteiro (${lado} × ${lado}) e entra no lago — nenhuma casa inalcançável`, () => {
    const { pisaveis, agua } = grelhaMapa(casaM);
    // Reserva para o mapa todo: as opções de mover são TODAS as casas alcançáveis da casa (0,0).
    const m = mesaMapa(casaM, { deslocamentoM: 1000 });
    const h = m.clientes.heroina;
    const orc = estado(m).figuras[idDaFicha(m, 'orc-teste')];
    const alcancaveis = new Set(h.opcoes.mover.map((o) => `${o.x},${o.y}`));
    const ocupadas = new Set([`${estado(m).figuras[h.figuraId].x},${estado(m).figuras[h.figuraId].y}`, `${orc.x},${orc.y}`]);
    const faltam = pisaveis.filter((c) => !ocupadas.has(`${c.x},${c.y}`) && !alcancaveis.has(`${c.x},${c.y}`));
    assert.deepEqual(faltam, [], `${casaM} m: todas as ${pisaveis.length} casas que se pisam alcançam-se (menos as 2 ocupadas)`);
    assert.equal(alcancaveis.size, pisaveis.length - 2);
    for (const c of agua) assert.ok(alcancaveis.has(`${c.x},${c.y}`), `${casaM} m: a casa de água (${c.x},${c.y}) alcança-se`);
    // Andar: do canto NO ao canto SE (o mapa de ponta a ponta) e daí para o meio do lago.
    const se = { x: lado - 1, y: lado - 1 };
    const opSE = h.opcoes.mover.find((o) => o.x === se.x && o.y === se.y);
    assert.ok(opSE, `${casaM} m: o canto SE está nas opções`);
    assert.ok(opSE.custoM >= 2 * (lado - 1) * casaM - 1e-9, 'o custo é o do caminho pelas casas (pelo menos a distância de Manhattan)');
    exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: se }), 'atravessa o mapa');
    assert.deepEqual([estado(m).figuras[h.figuraId].x, estado(m).figuras[h.figuraId].y], [se.x, se.y]);
    const lago = meioDoLago(casaM);
    assert.ok(h.opcoes.mover.some((o) => o.x === lago.x && o.y === lago.y), `${casaM} m: do canto SE, o lago (${lago.x},${lago.y}) está nas opções`);
    exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: lago.x, y: lago.y } }), 'entra no lago');
    const eu = estado(m).figuras[h.figuraId];
    assert.deepEqual([eu.x, eu.y], [lago.x, lago.y], `${casaM} m: a heroína está dentro do lago`);
    assert.equal(m.sala.depuracao.juizoTerreno().casas[eu.y * lado + eu.x].agua, true, 'e a casa é de água');
  });

  test(`MAPA-JOGÁVEL (c): a ${casaM} m, 6 m sobre a água cobrem ${MAPA_POR_ESCALA.find((e) => e.casaM === casaM).casas6m} casas — mover e alcance`, () => {
    const n = MAPA_POR_ESCALA.find((e) => e.casaM === casaM).casas6m;
    const lago = meioDoLago(casaM);
    const { g } = grelhaMapa(casaM);
    // mover: a heroína (6 m) no lago, a vez dela; a casa a N casas para sul custa 6 m e a N + 1 é recusada
    const m = mesaMapa(casaM, { casaHeroina: { x: lago.x, y: lago.y }, deslocamentoM: 6 });
    const h = m.clientes.heroina;
    assert.equal(g.agua(lago.x, lago.y), true, 'parte da água');
    assert.equal(h.opcoes.orcamentoM, 6);
    assert.equal(Math.max(...h.opcoes.mover.map((o) => o.custoM)), n * casaM, `a casa mais longe custa ${n} × ${casaM} m`);
    const nAgua = Math.min(n, lago.corrida);
    assert.ok(nAgua >= 1, 'pelo menos uma casa de água para sul');
    for (let k = 1; k <= nAgua; k++) {
      const o = h.opcoes.mover.find((c) => c.x === lago.x && c.y === lago.y + k);
      assert.equal(o?.custoM, Math.round(k * casaM * 100) / 100, `${k} casa(s) de água = ${k} × ${casaM} m (o custo de sempre)`);
    }
    assert.ok(h.opcoes.mover.some((o) => o.x === lago.x && o.y === lago.y + n), `${n} casas: nas opções`);
    assert.ok(!h.opcoes.mover.some((o) => o.x === lago.x && o.y === lago.y + n + 1), `${n + 1} casas: fora`);
    assert.notEqual(recibo(m.intencao('heroina', { tipo: 'mover', destino: { x: lago.x, y: lago.y + n + 1 } }))?.estado, 'APLICADA');
    exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: lago.x, y: lago.y + n } }), `${n} casas pela água`);
    assert.equal(estado(m).vez.andouM, 6, 'andou 6 m');
    // alcance: técnica de 6 m, a heroína dentro de água, o lobo a N casas (ao alcance) e a N + 1 (fora)
    for (const [dist, ao] of [[n, true], [n + 1, false]]) {
      const a = mesaMapa(casaM, { casaHeroina: { x: lago.x, y: lago.y }, alcanceM: 6, criaturas: [['lobo-teste', { x: lago.x, y: lago.y + dist }]] });
      assert.equal(a.clientes.heroina.opcoes.ataques.length > 0, ao, `lobo a ${dist} casas = ${dist * casaM} m: ${ao ? 'ao alcance' : 'fora'}`);
    }
  });

  test(`MAPA-JOGÁVEL (d): a ${casaM} m, o ataque de oportunidade passa pela grelha-mapa — sair de ao pé do orc, dentro de água`, () => {
    const lago = meioDoLago(casaM);
    assert.ok(lago.corrida >= 1, 'há água a sul do meio do lago');
    // a heroína no meio do lago, o orc na casa de água a sul dela
    const orcCasa = { x: lago.x, y: lago.y + 1 };
    const m = mesaMapa(casaM, { casaHeroina: { x: lago.x, y: lago.y }, criaturas: [['orc-teste', orcCasa]] });
    const h = m.clientes.heroina;
    const longe = (o) => Math.abs(o.x - orcCasa.x) + Math.abs(o.y - orcCasa.y);
    const saida = h.opcoes.mover.slice().sort((a, b) => longe(b) - longe(a) || a.custoM - b.custoM)[0];
    assert.ok(saida && longe(saida) >= 2, 'há para onde sair');
    const antes = m.motor.chamadas.length;
    exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: saida.x, y: saida.y } }), 'sai de ao pé do orc');
    const aoo = m.motor.chamadas.slice(antes).filter((c) => c.contexto?.ataqueDeOportunidade === true);
    assert.equal(aoo.length, 1, `${casaM} m: o orc ataca de oportunidade`);
  });
}

test('MAPA-JOGÁVEL (e): as recusas da escala na grelha-mapa — juntas numa casa, ou numa casa bloqueada — deixam tudo igual', () => {
  // juntas: a 1 m, duas figuras vizinhas (x = 42 e 43) caem na mesma casa de 2 m (a 21)
  const m = mesaMapa(1, { casaHeroina: { x: 42, y: 42 }, criaturas: [['orc-teste', { x: 43, y: 42 }]] });
  const antes = JSON.stringify({ f: estado(m).figuras, mapa: estado(m).mapa });
  const r = recibo(escala(m, 2));
  assert.equal(r.type, 'ROOM_REJECT');
  assert.equal(JSON.stringify({ f: estado(m).figuras, mapa: estado(m).mapa }), antes, 'nada mexeu');
  const rec = m.sala.depuracao.eventos().filter((e) => e.tipo === 'recusa').at(-1);
  assert.match(rec.soMestre.detalhe, /^ESCALA_JUNTA_FIGURAS: 2 figuras ficavam juntas com 2 m por casa — /);
  assert.equal(rec.soMestre.figuras.length, 2);
  // com o orc mais longe, a escala passa e cada um fica no seu sítio do mapa
  const m2 = mesaMapa(1, { casaHeroina: { x: 42, y: 42 }, criaturas: [['orc-teste', { x: 46, y: 42 }]] });
  exigirAplicada(escala(m2, 2), '1 → 2 m');
  assert.deepEqual(estado(m2).mapa, { largura: 37, altura: 37, casaM: 2 });
  const f2 = estado(m2).figuras;
  assert.deepEqual([f2[m2.clientes.heroina.figuraId].x, f2[m2.clientes.heroina.figuraId].y], [21, 21]);
  assert.deepEqual([f2[idDaFicha(m2, 'orc-teste')].x, f2[idDaFicha(m2, 'orc-teste')].y], [23, 21]);
  // casa bloqueada: a 1 m, uma figura numa casa livre cujo sítio, a 2 m, é uma casa bloqueada (menir, escarpa…)
  const g1 = T.para(75, 75, 1);
  const g2 = T.para(37, 37, 2);
  let alvo = null;
  for (let y = 0; y < 75 && !alvo; y++) {
    for (let x = 0; x < 75 && !alvo; x++) {
      if (!g1.bloqueada(x, y) && g2.bloqueada(Math.floor(x / 2), Math.floor(y / 2))) alvo = { x, y };
    }
  }
  assert.ok(alvo, 'há uma casa livre a 1 m que a 2 m é bloqueada');
  const m3 = mesaMapa(1, { casaHeroina: { x: 0, y: 0 }, criaturas: [['orc-teste', alvo]] });
  const antes3 = JSON.stringify({ f: estado(m3).figuras, mapa: estado(m3).mapa });
  assert.equal(recibo(escala(m3, 2)).type, 'ROOM_REJECT');
  assert.equal(JSON.stringify({ f: estado(m3).figuras, mapa: estado(m3).mapa }), antes3, 'nada mexeu');
  assert.match(m3.sala.depuracao.eventos().filter((e) => e.tipo === 'recusa').at(-1).soMestre.detalhe,
    /^ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS: 1 figura ficava em casas que o mapa bloqueia com 2 m por casa — /);
});

test('MAPA-JOGÁVEL (f): a Party recebe o mapa novo e o evento vazio; o antes/depois da grelha é só do Mestre', () => {
  const m = mesaMapa(1.5, { casaHeroina: { x: 10, y: 10 }, comEspectador: true });
  exigirAplicada(escala(m, 1), '1,5 → 1 m');
  for (const chave of ['heroina', 'espectador']) {
    const c = m.clientes[chave];
    assert.deepEqual(c.ultimo('ROOM_SNAPSHOT').mapa, { largura: 75, altura: 75, casaM: 1 }, chave + ': o mapa novo');
    for (const e of c.eventos('escala')) assert.deepEqual(e.dados ?? {}, {}, chave + ': o evento vai vazio');
    const lobo = FIXTURE.fichas.find((f) => f.id === 'orc-teste');
    const numeros = [lobo.ca, lobo.vidaTotal, lobo.paTotal].filter((v) => typeof v === 'number' && v >= 100);
    const achados = procurarCanarios(c.msgs, { numeros, textos: ['ESCALA_', 'CANARIO-FANTASMA'], chaves: ['casaMAntes', 'grelhaAntes', 'casasQuePaga'] });
    assert.deepEqual(achados, [], `vazamento para ${chave}: ${JSON.stringify(achados.slice(0, 5))}`);
  }
  assert.ok(JSON.stringify(m.clientes.mestre.msgs.slice(-20)).includes('grelhaAntes'), 'sanidade: o Mestre recebe o antes/depois');
});
