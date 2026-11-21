// ORDEM-PROVAS-MAPA-CORR7 (correcção 7 da sentença da conferência PROVAS-MAPA): a PROVAS-MAPA provou, em batalha de
// bancada, a mudança de escala 1,5 → 1 → 2 m na grelha-mapa. Ficaram por provar o sentido de RETORNO (2 → 1,5 m) e as
// duas recusas da mudança de escala — ESCALA_JUNTA_FIGURAS e ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS (a ordem chama-
// lhe «ESCALA_BLOQUEADAS»; o código que o servidor emite é este). Só provas: nenhuma linha de nucleo/ muda.
//  (a) o retorno 2 → 1,5 m a meio da batalha: cada figura na casa que contém o centro da casa de antes (ninguém muda
//      de sítio no mapa), a grelha volta a 50 × 50, a vez e os metros da vez ficam, e a batalha continua;
//  (b) ESCALA_JUNTA_FIGURAS dispara a subir (1,5 → 2 m) com duas figuras que caem na mesma casa, e a sala fica igual;
//      a descer (2 → 1,5 m) nunca pode disparar: duas casas de 2 m nunca caem na mesma de 1,5 m;
//  (c) ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS dispara a subir (1,5 → 2 m) com uma figura numa casa que a grelha de 2 m
//      bloqueia, e a sala fica igual; a descer nunca pode disparar: a prova é exaustiva e está no próprio teste —
//      `caem == []` sobre as 1.326 casas livres de 2 m (nenhuma cai numa bloqueada de 1,5 m); no servidor corre só uma
//      amostra de confirmação, até 60 das casas de risco (aqui 46 das 92, 1 em cada 2).
// Estatuto da prova «a descer» (b) e (c): assenta na enumeração exaustiva + a confirmação no servidor. A réplica
// `noLugar` abaixo partilha a fórmula com `casaNoLugar` (nucleo/sala.js), por isso o teste verifica que o servidor
// APLICA a regra do sítio (§0), não a geometria da regra de forma independente.
// O caso 1 → 2 m das duas recusas já está em ordem-mapa-jogavel.test.mjs (e) e o da grelha fixa em ordem62.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { prepararTerreno } from '../nucleo/terreno.js';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

const PACOTE = JSON.parse(readFileSync(new URL('../dados/terreno-floresta.json', import.meta.url), 'utf8'));
const T = prepararTerreno(PACOTE);
const estado = (m) => m.sala.depuracao.estado();
const escala = (m, casaM) => m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM });
const idDaFicha = (m, fichaId) => Object.values(estado(m).figuras).find((f) => f.fichaId === fichaId)?.id;
const mundo = (m) => JSON.parse(JSON.stringify({ figuras: estado(m).figuras, mapa: estado(m).mapa, vez: estado(m).vez }));
const recusas = (m) => m.sala.depuracao.eventos().filter((e) => e.tipo === 'recusa');
const emBloqueadas = (m) => {
  const j = m.sala.depuracao.juizoTerreno();
  return Object.values(estado(m).figuras)
    .filter((f) => f.colocada && !j.casas[f.y * j.largura + f.x].passavel)
    .map((f) => `(${f.x},${f.y}) ${j.casas[f.y * j.largura + f.x].motivo}`);
};

// A grelha-mapa por escala (ESTADO-FINAL-ORDEM-MAPA-JOGAVEL.md §0): o lado e a grelha do terreno.
const LADO = { 1: 75, 1.5: 50, 2: 37 };
const G = { 1: T.para(75, 75, 1), 1.5: T.para(50, 50, 1.5), 2: T.para(37, 37, 2) };

/** A casa da grelha-mapa de `para` que contém, no mapa, o centro da casa `c` da grelha-mapa de `de` (a regra §0). */
function noLugar(c, de, para) {
  const eixo = (v, i) => {
    const centro = G[de].origemM[i] + (v + 0.5) * de;
    return Math.min(LADO[para] - 1, Math.max(0, Math.floor((centro - G[para].origemM[i]) / para + 1e-9)));
  };
  return { x: eixo(c.x, 0), y: eixo(c.y, 1) };
}

/**
 * Sala sem tamanho na config (= o mapa inteiro, 50 × 50 de 1,5 m). A heroína nasce em `casaHeroina` (de 1,5 m); o
 * Mestre começa a batalha, muda para `casaM` (se não for 1,5) e põe as `criaturas` em casas dessa escala.
 */
function mesaMapa({ casaHeroina, casaM = 1.5, criaturas }) {
  const m = montarMesa({ terreno: PACOTE, mapa: null, casas: { heroina: casaHeroina } });
  m.entrarTodos();
  exigirAplicada(m.mestre('MASTER_LOBBY_SET', {
    mapaId: 'arena-teste', criaturasDisponiveis: ['orc-teste', 'lobo-teste'], npcsDisponiveis: ['bandido-teste'],
  }), 'LOBBY_SET');
  exigirAplicada(m.mestre('MASTER_START'), 'START');
  if (casaM !== 1.5) exigirAplicada(escala(m, casaM), 'escala ' + casaM);
  for (const [fichaId, casa] of criaturas) exigirAplicada(m.mestre('MASTER_PLACE', { fichaId, casa }), `PLACE ${fichaId} (${casa.x},${casa.y})`);
  assert.equal(estado(m).vez?.figuraId, m.clientes.heroina.figuraId, 'a vez é da heroína');
  return m;
}

/** A batalha continua: a heroína anda uma casa das opções e encerra a vez; a vez passa. */
function batalhaContinua(m, rotulo) {
  const h = m.clientes.heroina;
  assert.ok(h.opcoes.mover.length > 0, `${rotulo}: a heroína tem para onde andar`);
  const destino = h.opcoes.mover.slice().sort((a, b) => a.custoM - b.custoM || a.y - b.y || a.x - b.x)[0];
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: destino.x, y: destino.y } }), rotulo + ': mover');
  const eu = estado(m).figuras[h.figuraId];
  assert.deepEqual([eu.x, eu.y], [destino.x, destino.y], `${rotulo}: a heroína andou`);
  const rodada = estado(m).rodada;
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), rotulo + ': encerrar');
  const depois = estado(m);
  assert.ok(depois.vez?.figuraId !== h.figuraId || depois.rodada > rodada, `${rotulo}: a vez passou`);
}

test('CORR7 (a): o retorno 2 → 1,5 m a meio da batalha (1,5 → 1 → 2 → 1,5) — ninguém muda de sítio, a grelha volta a 50 × 50, a batalha continua', () => {
  const m = mesaMapa({ casaHeroina: { x: 20, y: 20 }, criaturas: [['orc-teste', { x: 30, y: 26 }], ['lobo-teste', { x: 5, y: 44 }]] });
  const h = m.clientes.heroina;
  // a heroína gasta 1 casa (1,5 m) antes das mudanças: os metros da vez têm de atravessar as três
  const passo = h.opcoes.mover.find((o) => Math.abs(o.custoM - 1.5) < 1e-9);
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: passo.x, y: passo.y } }), 'um passo a 1,5 m');
  const vezAntes = JSON.parse(JSON.stringify(estado(m).vez));
  assert.equal(vezAntes.andouM, 1.5);
  let de = 1.5;
  for (const para of [1, 2, 1.5]) {
    const antes = JSON.parse(JSON.stringify(estado(m).figuras));
    exigirAplicada(escala(m, para), `${de} → ${para} m`);
    assert.deepEqual(estado(m).mapa, { largura: LADO[para], altura: LADO[para], casaM: para }, `${para} m: a grelha é o mapa inteiro`);
    assert.deepEqual(h.ultimo('ROOM_SNAPSHOT').mapa, { largura: LADO[para], altura: LADO[para], casaM: para }, `${para} m: a jogadora recebe-a`);
    for (const [id, f] of Object.entries(antes)) {
      const n = estado(m).figuras[id];
      assert.deepEqual({ x: n.x, y: n.y }, noLugar(f, de, para), `${de} → ${para} m: ${f.fichaId} na casa que contém o centro de (${f.x},${f.y})`);
      if (f.casaInicial) assert.deepEqual(n.casaInicial, noLugar(f.casaInicial, de, para), `${de} → ${para} m: a casa inicial de ${f.fichaId} acompanha`);
    }
    de = para;
  }
  // O retorno: a sala está a 1,5 m, com o juízo do terreno a 50 × 50, a mesma vez e os mesmos metros.
  const j = m.sala.depuracao.juizoTerreno();
  assert.deepEqual([j.largura, j.altura, j.casaM], [50, 50, 1.5], 'o juízo do terreno recalculou para 50 × 50 de 1,5 m');
  assert.deepEqual(estado(m).vez, vezAntes, 'a vez, o andado (1,5 m) e a reserva (7,5 m) atravessam as três mudanças');
  assert.equal(h.opcoes.orcamentoM, vezAntes.reservaM, 'as opções contam a reserva em metros na escala de volta');
  assert.deepEqual(emBloqueadas(m), [], 'ninguém numa casa bloqueada');
  const ev = m.sala.depuracao.eventos().filter((e) => e.tipo === 'escala').at(-1);
  assert.equal(ev.soMestre.casaMAntes, 2, 'o último evento `escala` é o retorno 2 → 1,5 m');
  assert.equal(ev.soMestre.casaM, 1.5);
  batalhaContinua(m, '1,5 m de volta');
});

test('CORR7 (a): o retorno directo 2 → 1,5 m com a heroína a meio da vez — os metros andados a 2 m ficam em metros', () => {
  // a sala nasce a 1,5 m; o Mestre passa a 2 m antes de pôr as criaturas; a heroína anda 1 casa de 2 m; volta a 1,5 m
  const m = mesaMapa({ casaHeroina: { x: 20, y: 20 }, casaM: 2, criaturas: [['orc-teste', { x: 25, y: 20 }]] });
  const h = m.clientes.heroina;
  const passo = h.opcoes.mover.find((o) => Math.abs(o.custoM - 2) < 1e-9);
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: passo.x, y: passo.y } }), 'um passo a 2 m');
  const antes = JSON.parse(JSON.stringify(estado(m).figuras));
  exigirAplicada(escala(m, 1.5), '2 → 1,5 m');
  assert.deepEqual(estado(m).mapa, { largura: 50, altura: 50, casaM: 1.5 });
  for (const [id, f] of Object.entries(antes)) {
    const n = estado(m).figuras[id];
    assert.deepEqual({ x: n.x, y: n.y }, noLugar(f, 2, 1.5), `${f.fichaId}: de (${f.x},${f.y}) a 2 m para a casa do mesmo sítio a 1,5 m`);
  }
  assert.equal(estado(m).vez.andouM, 2, 'andou 2 m');
  assert.equal(estado(m).vez.reservaM, 7, 'sobram 7 m');
  assert.equal(Math.max(...h.opcoes.mover.map((o) => o.custoM)) <= 7 + 1e-9, true, 'nenhuma opção passa dos 7 m');
  batalhaContinua(m, '2 → 1,5 m');
});

test('CORR7 (b): ESCALA_JUNTA_FIGURAS a subir 1,5 → 2 m — recusada, a sala fica igual, e a batalha continua', () => {
  // duas casas vizinhas de 1,5 m, livres, que caem na mesma casa de 2 m (também livre)
  let par = null;
  for (let y = 10; y < 40 && !par; y++) {
    for (let x = 10; x < 40 && !par; x++) {
      const a = noLugar({ x, y }, 1.5, 2);
      const b = noLugar({ x: x + 1, y }, 1.5, 2);
      if (a.x === b.x && a.y === b.y && !G[1.5].bloqueada(x, y) && !G[1.5].bloqueada(x + 1, y) && !G[2].bloqueada(a.x, a.y)) {
        par = { heroina: { x, y }, orc: { x: x + 1, y }, junta: a };
      }
    }
  }
  assert.ok(par, 'há duas casas vizinhas de 1,5 m que a 2 m são uma');
  const m = mesaMapa({ casaHeroina: par.heroina, criaturas: [['orc-teste', par.orc]] });
  const antes = mundo(m);
  const r = recibo(escala(m, 2));
  assert.equal(r.type, 'ROOM_REJECT', 'a mudança é recusada');
  assert.equal(r.motivo, 'acao_invalida');
  assert.deepEqual(mundo(m), antes, 'nada mexeu: figuras, mapa e vez');
  assert.equal(m.sala.depuracao.juizoTerreno().casaM, 1.5, 'a escala fica 1,5 m');
  const rec = recusas(m).at(-1);
  assert.match(rec.soMestre.detalhe, /^ESCALA_JUNTA_FIGURAS: 2 figuras ficavam juntas com 2 m por casa — /);
  assert.deepEqual(rec.soMestre.figuras.map((f) => [f.x, f.y]), [[par.junta.x, par.junta.y], [par.junta.x, par.junta.y]],
    'as duas nomeadas ao Mestre na casa de 2 m em que ficavam juntas');
  assert.equal(JSON.stringify(m.clientes.heroina.msgs).includes('ESCALA_JUNTA_FIGURAS'), false, 'a Party não vê o detalhe');
  batalhaContinua(m, 'depois da recusa');
});

test('CORR7 (b): a descer 2 → 1,5 m, ESCALA_JUNTA_FIGURAS nunca pode disparar — vizinhas a 2 m ficam vizinhas a 1,5 m', () => {
  // o mapa todo: as 37 × 37 casas de 2 m caem em 1.369 casas de 1,5 m distintas
  const imagens = new Set();
  for (let y = 0; y < 37; y++) for (let x = 0; x < 37; x++) { const c = noLugar({ x, y }, 2, 1.5); imagens.add(`${c.x},${c.y}`); }
  assert.equal(imagens.size, 37 * 37, 'nenhuma casa de 1,5 m recebe duas de 2 m');
  // no servidor: a 2 m, a heroína e o orc lado a lado; o retorno passa e cada um tem a sua casa
  const m = mesaMapa({ casaHeroina: { x: 20, y: 20 }, casaM: 2, criaturas: [['orc-teste', { x: 16, y: 15 }]] });
  const f2 = estado(m).figuras;
  const h2 = f2[m.clientes.heroina.figuraId];
  const o2 = f2[idDaFicha(m, 'orc-teste')];
  assert.equal(Math.abs(h2.x - o2.x) + Math.abs(h2.y - o2.y), 1, 'a 2 m estão em casas vizinhas');
  exigirAplicada(escala(m, 1.5), '2 → 1,5 m com as duas vizinhas');
  const f = estado(m).figuras;
  assert.deepEqual({ x: f[h2.id].x, y: f[h2.id].y }, noLugar(h2, 2, 1.5));
  assert.deepEqual({ x: f[o2.id].x, y: f[o2.id].y }, noLugar(o2, 2, 1.5));
  assert.notDeepEqual([f[h2.id].x, f[h2.id].y], [f[o2.id].x, f[o2.id].y], 'cada uma na sua casa');
});

test('CORR7 (c): ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS a subir 1,5 → 2 m — recusada, a sala fica igual, e a batalha continua', () => {
  // uma casa livre de 1,5 m cujo sítio, a 2 m, é uma casa bloqueada (menir, escarpa, tronco…)
  let alvo = null;
  for (let y = 0; y < 50 && !alvo; y++) {
    for (let x = 0; x < 50 && !alvo; x++) {
      const c = noLugar({ x, y }, 1.5, 2);
      if (!G[1.5].bloqueada(x, y) && G[2].bloqueada(c.x, c.y) && Math.abs(x - 25) + Math.abs(y - 25) > 4) alvo = { x, y, em2: c };
    }
  }
  assert.ok(alvo, 'há uma casa livre a 1,5 m que a 2 m é bloqueada');
  const m = mesaMapa({ casaHeroina: { x: 25, y: 25 }, criaturas: [['orc-teste', { x: alvo.x, y: alvo.y }]] });
  const antes = mundo(m);
  const r = recibo(escala(m, 2));
  assert.equal(r.type, 'ROOM_REJECT', 'a mudança é recusada');
  assert.equal(r.motivo, 'acao_invalida');
  assert.deepEqual(mundo(m), antes, 'nada mexeu: figuras, mapa e vez');
  assert.equal(m.sala.depuracao.juizoTerreno().casaM, 1.5, 'a escala fica 1,5 m');
  assert.deepEqual(emBloqueadas(m), [], 'ninguém numa casa bloqueada');
  const rec = recusas(m).at(-1);
  assert.match(rec.soMestre.detalhe, /^ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS: 1 figura ficava em casas que o mapa bloqueia com 2 m por casa — /);
  assert.deepEqual(rec.soMestre.figuras.map((f) => [f.figuraId, f.x, f.y]), [[idDaFicha(m, 'orc-teste'), alvo.em2.x, alvo.em2.y]],
    'o orc nomeado ao Mestre, na casa de 2 m em que ficava');
  assert.equal(JSON.stringify(m.clientes.heroina.msgs).includes('ESCALA_DEIXA_FIGURAS'), false, 'a Party não vê o detalhe');
  batalhaContinua(m, 'depois da recusa');
});

test('CORR7 (c): a descer 2 → 1,5 m, ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS nunca pode disparar — provado por enumeração, confirmado no servidor numa amostra das casas de risco', () => {
  // no mapa todo: nenhuma casa livre de 2 m cai numa casa bloqueada de 1,5 m
  const livres2 = [];
  for (let y = 0; y < 37; y++) for (let x = 0; x < 37; x++) if (!G[2].bloqueada(x, y)) livres2.push({ x, y });
  // 1.326 casas livres de 2 m no terreno actual (sonda-mapeamento.log); muda com a LAGO-MAIOR (seguimento S1)
  assert.equal(livres2.length, 1326, 'as casas livres de 2 m do terreno actual (1.326)');
  const caem = livres2.filter((c) => { const n = noLugar(c, 2, 1.5); return G[1.5].bloqueada(n.x, n.y); });
  assert.deepEqual(caem, [], `nenhuma das ${livres2.length} casas livres de 2 m cai numa bloqueada de 1,5 m`);
  // as casas de risco: livres a 2 m cuja casa de 1,5 m encosta (8 vizinhas) a uma bloqueada a 1,5 m
  const encosta = (n) => [-1, 0, 1].some((dy) => [-1, 0, 1].some((dx) => {
    const x = n.x + dx; const y = n.y + dy;
    return x >= 0 && y >= 0 && x < 50 && y < 50 && G[1.5].bloqueada(x, y);
  }));
  const risco = livres2.filter((c) => encosta(noLugar(c, 2, 1.5)) && !(c.x === 15 && c.y === 15));
  // O número exacto do terreno actual: 92 casas de risco (sonda-mapeamento.log: «de risco 92»). Antes era
  // `risco.length >= 20`, frouxo de propósito: a LAGO-MAIOR, por fundir, muda o terreno (bloqueadas 67 → 152) e o
  // número de casas de risco com ele. Agora está apertado ao exacto (sentença CORR7, R1): quando a LAGO-MAIOR
  // fundir, este assert falha de propósito e obriga a correr outra vez a sonda e a registar o número novo (S1).
  assert.equal(risco.length, 92, `as casas de risco do terreno actual (${risco.length})`);
  // no servidor: uma amostra de confirmação (até 60, espalhadas — aqui 46, 1 em cada 2), a 2 m; o retorno passa e
  // ninguém cai numa bloqueada. A prova é o `caem == []` acima; isto confirma que o servidor aplica a mesma regra.
  const passo = Math.max(1, Math.ceil(risco.length / 60));
  const escolhidas = risco.filter((_, i) => i % passo === 0);
  assert.equal(escolhidas.length, 46, 'a amostra no servidor: 46 das 92 (1 em cada 2)');
  const m = mesaMapa({ casaHeroina: noLugarInverso({ x: 15, y: 15 }), casaM: 2, criaturas: escolhidas.map((c) => ['orc-teste', c]) });
  assert.deepEqual(emBloqueadas(m), [], 'a 2 m: todas em casas livres');
  const antes = JSON.parse(JSON.stringify(estado(m).figuras));
  exigirAplicada(escala(m, 1.5), `2 → 1,5 m com ${escolhidas.length} figuras nas casas de risco`);
  assert.deepEqual(emBloqueadas(m), [], 'a 1,5 m: nenhuma figura numa casa bloqueada');
  for (const [id, f] of Object.entries(antes)) {
    const n = estado(m).figuras[id];
    assert.deepEqual({ x: n.x, y: n.y }, noLugar(f, 2, 1.5), `${f.fichaId} (${f.x},${f.y}) no mesmo sítio`);
  }
  assert.equal(recusas(m).filter((e) => /^ESCALA_/.test(e.soMestre?.detalhe ?? '')).length, 0, 'nenhuma recusa ESCALA_ na sala');
});

/** A casa de 1,5 m cujo centro cai na casa `c` de 2 m (para a heroína nascer lá). */
function noLugarInverso(c) {
  for (let y = 0; y < 50; y++) for (let x = 0; x < 50; x++) {
    const n = noLugar({ x, y }, 1.5, 2);
    if (n.x === c.x && n.y === c.y) return { x, y };
  }
  throw new Error('sem casa de 1,5 m para ' + JSON.stringify(c));
}
