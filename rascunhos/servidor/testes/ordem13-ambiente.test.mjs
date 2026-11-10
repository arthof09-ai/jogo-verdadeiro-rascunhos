// Ordem 13 do CM-000009 (2026-11-10), parte B: dano do ambiente (dívida E1 da auditoria da ordem 10).
// As regras do Mestre (as do painel Ambiente do site, jogo.js «RAIO E FOGO», REF_39):
//  (1) onde o raio cai, a casa pega fogo; (2) o raio é aleatório; (3) raio numa pessoa: pega fogo e sofre dano;
//  (4) dano do raio = 15 fixo, provisório; (5) fogo = 1d8 enquanto estiver na casa a arder; sair para a chuva apaga,
//  sem chuva não apaga; (6) a RD fica FORA do dano do ambiente.
// O dado do ambiente entra injetado (`dadoAmbiente`): cada teste diz que faces saem, e o roteiro confere que o servidor
// pediu o dado certo (d400 para a casa num mapa 20×20, d6 para o combustível e a chuva, d8 para o fogo).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as Amb from '../nucleo/ambiente.js';
import { carregarFichas } from '../nucleo/carregar-fichas.js';
import { montarMesa, exigirAplicada, recibo, listaDeFichas, procurarCanarios } from './ajudantes.mjs';

/** Dado com roteiro: [[faces, valor], ...]. Acabado o roteiro, sai o máximo (sem extinção, sem raio automático). */
function roteiro(passos = []) {
  const fila = passos.slice();
  const pedidos = [];
  const dado = (faces) => {
    pedidos.push(faces);
    if (!fila.length) return faces;
    const [f, v] = fila.shift();
    assert.equal(faces, f, `o servidor pediu d${faces}, o roteiro esperava d${f} (pedido n.º ${pedidos.length})`);
    return v;
  };
  dado.pedidos = pedidos;
  dado.resto = () => fila.length;
  dado.juntar = (mais) => fila.push(...mais);
  return dado;
}
/** Índice 1..400 da casa (x, y) num mapa 20×20 (o d400 do raio). */
const casa20 = (x, y) => y * 20 + x + 1;
/** O roteiro de um raio que cai em (x, y) longe da borda: casa, combustível dela e das 4 vizinhas. */
const raioEm = (x, y, comb = 4) => [[400, casa20(x, y)], [6, comb], [6, comb], [6, comb], [6, comb], [6, comb]];

function fichasCom(mudar) {
  const lista = listaDeFichas();
  mudar(Object.fromEntries(lista.map((f) => [f.id, f])));
  const r = carregarFichas(lista);
  if (!r.ok) throw new Error(JSON.stringify(r.erros));
  return r.fichas;
}

/** Mesa em manual: a heroína em (2,2), o orc em (2,6) (longe), tempestade com raios ligados. */
function mesaDaTempestade({ dado, fichas = null, orc = { x: 2, y: 6 }, clima = 'tempestade' } = {}) {
  const m = montarMesa({ modoPadrao: 'manual', dadoAmbiente: dado, comEspectador: true, ...(fichas ? { fichas } : {}) });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', orc]]);
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { clima, raios: true }), 'tempestade');
  const h = m.clientes.heroina;
  const orcId = h.idPorNome('Orc');
  const estado = () => m.sala.depuracao.estado();
  const her = () => estado().figuras[h.figuraId];
  const fOrc = () => estado().figuras[orcId];
  /** A heroína encerra e o Mestre encerra o orc: a rodada vira (momento de ambiente) e volta a vez dela. */
  const virarRodada = (rot) => {
    exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar heroína ' + rot);
    if (estado().vez?.figuraId === orcId) {
      exigirAplicada(m.enviar('mestre', {
        type: 'MASTER_ACT', intentId: m.novoId('act'), revision: m.clientes.mestre.revision, figuraId: orcId, acao: { tipo: 'encerrar' },
      }), 'encerrar orc ' + rot);
    }
  };
  return { m, h, orcId, estado, her, fOrc, virarRodada };
}

const eventosDepois = (c, n, tipo) => c.msgs.slice(n).filter((x) => x.type === 'ROOM_EVENT' && (!tipo || x.tipo === tipo));

// =====================================================================================================================
// ambiente.js sozinho (sem sala): as regras com o dado na mão

function mundo({ clima = 'tempestade', raios = true, figuras = {}, rodada = 2 } = {}) {
  const fs = {};
  for (const [id, f] of Object.entries(figuras)) {
    fs[id] = { id, lado: 'criatura', colocada: true, vivo: true, vidaActual: 100, estadoMorte: null, x: 0, y: 0, ...f };
  }
  return { mapa: { largura: 20, altura: 20, casaM: 1.5 }, ambiente: { clima, raios, raioPendente: false }, figuras: fs, rodada, fogo: Amb.fogoVazio() };
}
const antes = (f) => ({ vis: f.vivo ? 'de_pe' : 'morta', vida: f.vidaActual });

test('ordem 13 (ambiente.js): a chuva vem do clima (chuva = pouca, tempestade = forte) e os raios pedem chuva', () => {
  assert.equal(Amb.chuvaDe({ clima: 'chuva' }), 1);
  assert.equal(Amb.chuvaDe({ clima: 'tempestade' }), 2);
  for (const c of ['limpo', 'nublado', 'nevoeiro', 'neve', null]) assert.equal(Amb.chuvaDe({ clima: c }), 0, String(c));
  assert.equal(Amb.haTempestade({ clima: 'chuva', raios: true }), true);
  assert.equal(Amb.haTempestade({ clima: 'tempestade', raios: false }), false);
  assert.equal(Amb.haTempestade({ clima: 'limpo', raios: true }), false);
});

test('ordem 13 (ambiente.js): regras 1, 3, 4 e 6 — o raio acende a casa e a cruz, fere 15 fixos sem RD e pega fogo', () => {
  const m = mundo({ figuras: { a: { x: 5, y: 5, vidaActual: 40, rd: { geral: 99 } } } });
  const d = roteiro([[6, 3], [6, 1], [6, 2], [6, 5], [6, 6]]);
  const r = Amb.impactoRaio(m, 5, 5, 'pedido', d, antes);
  assert.equal(r.alvoId, 'a');
  assert.equal(r.aplicado, Amb.DANO_RAIO);
  assert.equal(Amb.DANO_RAIO, 15, 'o raio é 15 fixo (provisório)');
  assert.equal(m.figuras.a.vidaActual, 25, '40 − 15, sem RD (a RD da figura não entra)');
  assert.equal(r.desfecho, null);
  assert.deepEqual(Amb.fogoDoMestre(m).casas, [
    { x: 5, y: 4, combustivel: 1 }, { x: 4, y: 5, combustivel: 5 }, { x: 5, y: 5, combustivel: 3 }, { x: 6, y: 5, combustivel: 6 },
    { x: 5, y: 6, combustivel: 2 },
  ], 'a cruz: a casa do impacto e as 4 vizinhas, cada uma com o seu combustível 1d6');
  assert.deepEqual(Amb.fogoPublico(m).aArder, ['a'], 'quem o raio atinge fica a arder');
  assert.equal(Amb.fogoPublico(m).casas[0].combustivel, undefined, 'o combustível não sai no fogo público');
});

test('ordem 13 (ambiente.js): a cruz corta-se na borda; o re-impacto renova a casa; a vizinha acesa guarda o combustível', () => {
  const m = mundo();
  Amb.impactoRaio(m, 0, 0, 'automatico', roteiro([[6, 2], [6, 2], [6, 2]]), antes);
  assert.equal(Amb.fogoPublico(m).casas.length, 3, 'no canto só há 2 vizinhas');
  Amb.impactoRaio(m, 1, 0, 'automatico', roteiro([[6, 6], [6, 4], [6, 4]]), antes);
  const c = Object.fromEntries(Amb.fogoDoMestre(m).casas.map((k) => [k.x + ',' + k.y, k.combustivel]));
  assert.equal(c['1,0'], 6, 'a casa atingida outra vez renova o combustível');
  assert.equal(c['0,0'], 2, 'a vizinha que já ardia conserva o combustível');
  assert.equal(c['2,0'], 4);
  assert.equal(c['1,1'], 4);
});

test('ordem 13 (ambiente.js): o raio mata o monstro (sai do fogo); deita a heroína a morrer 0/0; não fere quem já está a morrer', () => {
  const m = mundo({ figuras: {
    mon: { x: 3, y: 3, vidaActual: 15 },
    her: { x: 9, y: 9, vidaActual: 10, lado: 'jogadora' },
    caida: { x: 12, y: 12, vidaActual: 0, lado: 'jogadora', estadoMorte: { fase: 'aMorrer', sucessos: 1, falhas: 2 } },
  } });
  const r1 = Amb.impactoRaio(m, 3, 3, 'pedido', roteiro(), antes);
  assert.equal(r1.desfecho, 'caiu');
  assert.equal(m.figuras.mon.vivo, false);
  assert.equal(Amb.estaAArder(m, 'mon'), false, 'a morte apaga o fogo da figura');
  const r2 = Amb.impactoRaio(m, 9, 9, 'pedido', roteiro(), antes);
  assert.equal(r2.desfecho, 'aMorrer');
  assert.deepEqual(m.figuras.her.estadoMorte, { fase: 'aMorrer', sucessos: 0, falhas: 0 }, 'o ambiente não soma falhas');
  assert.equal(m.figuras.her.vidaActual, 0);
  const r3 = Amb.impactoRaio(m, 12, 12, 'pedido', roteiro(), antes);
  assert.equal(r3.alvoId, undefined, 'a caída não leva dano do ambiente');
  assert.deepEqual(m.figuras.caida.estadoMorte, { fase: 'aMorrer', sucessos: 1, falhas: 2 }, 'nem falhas');
});

test('ordem 13 (ambiente.js): regra 5 — o tick 1d8 na casa a arder, uma vez por rodada; sair para a chuva apaga, sem chuva não', () => {
  const m = mundo({ figuras: { a: { x: 4, y: 4, vidaActual: 50 } } });
  m.fogo.casas.push({ x: 4, y: 4, combustivel: 3 });
  const t1 = Amb.tickInicioDaVez(m, m.figuras.a, roteiro([[8, 7]]), antes);
  assert.equal(t1.tipo, 'tick');
  assert.equal(t1.aplicado, 7, '1d8, sem RD');
  assert.equal(t1.pegouFogo, true, 'começar a vez na casa a arder pega fogo');
  assert.equal(m.figuras.a.vidaActual, 43);
  assert.equal(Amb.tickInicioDaVez(m, m.figuras.a, roteiro(), antes), null, 'um tick por figura e por rodada');

  // Sem chuva: sair do fogo NÃO apaga, e o fogo continua a morder fora da casa.
  m.ambiente.clima = 'limpo';
  m.figuras.a.x = 7;
  assert.equal(Amb.depoisDoMovimento(m, m.figuras.a), null, 'sem chuva, sair não apaga');
  assert.equal(Amb.estaAArder(m, 'a'), true);
  m.rodada = 3;
  const t2 = Amb.tickInicioDaVez(m, m.figuras.a, roteiro([[8, 2]]), antes);
  assert.equal(t2.aplicado, 2, 'a arder fora da casa, sem chuva: o fogo continua');

  // Com chuva: sair do fogo apaga logo no fim do movimento.
  m.ambiente.clima = 'chuva';
  const ap = Amb.depoisDoMovimento(m, m.figuras.a);
  assert.deepEqual(ap, { tipo: 'apagado', figuraId: 'a', porque: 'saiu' });
  assert.equal(Amb.estaAArder(m, 'a'), false);

  // Ainda dentro de uma casa a arder: a chuva não a apaga ao mover.
  m.fogo.aArder.push('a');
  m.fogo.casas.push({ x: 7, y: 4, combustivel: 2 });
  assert.equal(Amb.depoisDoMovimento(m, m.figuras.a), null);
  // E a arder fora do fogo, com chuva, apaga-se no início da vez (antes do tick).
  m.fogo.casas = [];
  m.rodada = 4;
  assert.deepEqual(Amb.tickInicioDaVez(m, m.figuras.a, roteiro(), antes), { tipo: 'apagado', figuraId: 'a', porque: 'chuva' });
});

test('ordem 13 (ambiente.js): o momento de ambiente — extinção pela chuva, combustível, pedido e raio automático', () => {
  const m = mundo({ clima: 'chuva', figuras: { a: { x: 1, y: 1 } } });
  m.fogo.casas.push({ x: 1, y: 1, combustivel: 5 }, { x: 9, y: 9, combustivel: 1 });
  m.fogo.aArder.push('a');
  m.ambiente.raioPendente = true;
  // chuva pouca: extinção com 1–2. Casa (1,1): d6=2 → apaga (e a pessoa). Casa (9,9): d6=3 → gasta o último → apaga.
  // Pedido: raio em (15,15). Automático (pouca: 1 em 1d6): d6=1 → outro raio em (18,3).
  const d = roteiro([[6, 2], [6, 3], ...raioEm(15, 15), [6, 1], ...raioEm(18, 3)]);
  const regs = Amb.momentoDaRodada(m, d, antes);
  assert.deepEqual(regs.map((r) => r.tipo + ':' + (r.porque ?? r.origem ?? '')), [
    'extincao:chuva', 'extincao:combustivel', 'raio:pedido', 'raio:automatico',
  ]);
  assert.equal(regs[0].apagouId, 'a', 'a chuva apaga a casa e o fogo de quem lá está');
  assert.equal(m.ambiente.raioPendente, false, 'o pedido gastou-se');
  assert.equal(d.resto(), 0);
  assert.deepEqual(Amb.momentoDaRodada(m, roteiro(), antes), [], 'uma vez por rodada');
  m.rodada = 3;
  m.ambiente.raios = false;
  m.ambiente.raioPendente = true;
  const regs3 = Amb.momentoDaRodada(m, roteiro(), antes);
  assert.ok(regs3.some((r) => r.tipo === 'raio_cancelado'), 'sem raios ligados, o pedido cancela-se');
  assert.equal(regs3.some((r) => r.tipo === 'raio'), false, 'e não cai raio nenhum');
});

// =====================================================================================================================
// A sala: o Mestre controla, o dano aplica-se, o que é só do Mestre fica só com ele

test('ordem 13: o painel — raios e «Raio agora» só do Mestre; a Party não recebe evento nenhum do pedido', () => {
  const d = roteiro();
  const { m, h } = mesaDaTempestade({ dado: d });
  const nH = h.msgs.length;
  const nE = m.clientes.espectador.msgs.length;
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { raioAgora: true }), 'raio agora');
  assert.equal(m.sala.depuracao.estado().ambiente.raioPendente, true);
  assert.deepEqual(eventosDepois(h, nH), [], 'a heroína não sabe do pedido');
  assert.deepEqual(eventosDepois(m.clientes.espectador, nE), [], 'nem o espectador');

  const r2 = m.mestre('MASTER_AMBIENTE', { raioAgora: true });
  assert.equal(recibo(r2).type, 'ROOM_REJECT');
  assert.equal(recibo(r2).motivo, 'acao_invalida');
  const rec = m.clientes.mestre.eventos('recusa').at(-1);
  assert.match(rec.dados.soMestre.detalhe, /^RAIO_JA_PENDENTE/, 'o detalhe vai só ao Mestre');

  // Desligar os raios cancela o pedido.
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { raios: false }), 'raios off');
  assert.equal(m.sala.depuracao.estado().ambiente.raioPendente, false);
  assert.equal(m.clientes.mestre.eventos('ambiente_mestre').at(-1).dados.soMestre.raioCancelado, true);
  const r3 = m.mestre('MASTER_AMBIENTE', { raioAgora: true });
  assert.equal(recibo(r3).type, 'ROOM_REJECT', 'sem raios, não há «Raio agora»');
  assert.match(m.clientes.mestre.eventos('recusa').at(-1).dados.soMestre.detalhe, /^RAIO_SEM_TEMPESTADE/);
  // Formato: raios tem de ser booleano; raioAgora só true.
  assert.equal(recibo(m.mestre('MASTER_AMBIENTE', { raios: 'sim' })).motivo, 'formato');
  assert.equal(recibo(m.mestre('MASTER_AMBIENTE', { raioAgora: false })).motivo, 'formato');
  assert.deepEqual(d.pedidos, [], 'nenhum dado rolado só por mexer no painel');
});

test('ordem 13: «Raio agora» só em combate', () => {
  const m = montarMesa({ dadoAmbiente: roteiro() });
  m.entrarTodos();
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { clima: 'tempestade', raios: true }));
  assert.equal(recibo(m.mestre('MASTER_AMBIENTE', { raioAgora: true })).type, 'ROOM_REJECT');
  assert.match(m.clientes.mestre.eventos('recusa').at(-1).dados.soMestre.detalhe, /^RAIO_FORA_DO_COMBATE/);
});

test('ordem 13: o raio pedido cai no início da rodada seguinte, em cima dela — 15 de dano, fogo na cruz, tick 1d8 na vez dela', () => {
  const d = roteiro([...raioEm(2, 2, 4), [6, 6], [8, 5]]); // [6,6]: sem raio automático; [8,5]: o tick dela
  const { m, h, her, virarRodada, estado } = mesaDaTempestade({ dado: d });
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { raioAgora: true }), 'raio agora');
  assert.equal(estado().rodada, 1);
  const vida0 = her().vidaActual;
  const nH = h.msgs.length;
  const nE = m.clientes.espectador.msgs.length;
  const nM = m.clientes.mestre.msgs.length;
  virarRodada('1');
  assert.equal(estado().rodada, 2);
  assert.equal(d.resto(), 0, 'o roteiro gastou-se todo: raio, cruz, sem automático, tick');
  assert.equal(her().vidaActual, vida0 - 15 - 5, '15 do raio + 5 do fogo, sem RD');
  assert.equal(estado().vez.figuraId, h.figuraId, 'e a vez é dela');

  // A heroína vê: o raio que a atingiu, o número do dano DELA, o fogo, o estado dela.
  const evH = eventosDepois(h, nH);
  const raio = evH.find((x) => x.tipo === 'raio');
  assert.deepEqual(raio.dados, { x: 2, y: 2, alvoId: h.figuraId, desfecho: 'arde' });
  const danos = evH.filter((x) => x.tipo === 'dano_ambiente');
  assert.deepEqual(danos.map((x) => [x.dados.origem, x.dados.valor, x.dados.desfecho]), [['raio', 15, 'arde'], ['fogo', 5, 'arde']]);
  const fogo = evH.filter((x) => x.tipo === 'fogo').at(-1);
  assert.equal(fogo.dados.casas.length, 5, 'a cruz');
  assert.deepEqual(fogo.dados.aArder, [h.figuraId]);
  const ordem = evH.map((x) => x.tipo);
  assert.ok(ordem.indexOf('raio') < ordem.lastIndexOf('turno'), 'o momento de ambiente vem antes da vez dela');
  assert.ok(ordem.lastIndexOf('dano_ambiente') < ordem.lastIndexOf('turno'), 'o tick vem antes do «turno» dela');

  // O espectador vê o raio e o fogo, mas não o número.
  const evE = eventosDepois(m.clientes.espectador, nE);
  assert.ok(evE.some((x) => x.tipo === 'raio'));
  assert.ok(evE.filter((x) => x.tipo === 'dano_ambiente').every((x) => x.dados.valor === undefined), 'o número só a quem o sofreu');
  // Nada do Mestre na Party.
  assert.deepEqual(procurarCanarios([...evH, ...evE], { chaves: ['soMestre', 'combustivel', 'raioPendente', 'raios', 'rd', 'bruto'] }), []);

  // O Mestre vê o combustível, a origem do raio e o rd: 0.
  const evM = eventosDepois(m.clientes.mestre, nM);
  const raioM = evM.find((x) => x.tipo === 'raio');
  assert.equal(raioM.dados.soMestre.origem, 'pedido');
  assert.equal(raioM.dados.soMestre.combustivel, 4);
  assert.equal(raioM.dados.soMestre.rd, 0, 'a RD fica fora');
  const tickM = evM.find((x) => x.tipo === 'dano_ambiente' && x.dados.origem === 'fogo');
  assert.deepEqual(tickM.dados.soMestre.faces, [5]);
  assert.equal(tickM.dados.soMestre.pegouFogo, false, 'já ardia desde o raio');
  const vista = m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW');
  assert.equal(vista.mestre.fogo.casas.length, 5);
  assert.ok(vista.mestre.fogo.casas.every((c) => c.combustivel === 4));
  // Estatísticas: o dano do ambiente entra no dano sofrido dela.
  assert.equal(vista.estatisticas.danoSofrido[h.figuraId], 20);
});

test('ordem 13: regra 5 com chuva — ela sai da casa a arder e apaga-se no fim do movimento', () => {
  const d = roteiro([...raioEm(2, 2, 4), [6, 6], [8, 3]]);
  const { m, h, her, virarRodada, estado } = mesaDaTempestade({ dado: d });
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { raioAgora: true }));
  virarRodada('1');
  assert.deepEqual(estado().fogo.aArder, [h.figuraId]);
  const nH = h.msgs.length;
  // (2,2) → (5,2): sai da cruz ((3,2) arde; (4,2) e (5,2) não).
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 5, y: 2 } }), 'sair do fogo');
  assert.deepEqual(estado().fogo.aArder, [], 'a chuva apagou-a');
  const f = eventosDepois(h, nH, 'fogo').at(-1);
  assert.deepEqual(f.dados.apagados, [{ figuraId: h.figuraId, porque: 'saiu' }]);
  assert.equal(her().x, 5);
});

test('ordem 13: regra 5 sem chuva — sair não apaga, e o fogo continua a morder na vez seguinte', () => {
  const d = roteiro([...raioEm(2, 2, 6), [6, 6], [8, 4]]);
  const { m, h, her, virarRodada, estado } = mesaDaTempestade({ dado: d });
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { raioAgora: true }));
  virarRodada('1');
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { clima: 'limpo' }), 'a chuva pára');
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 5, y: 2 } }), 'sair do fogo');
  assert.deepEqual(estado().fogo.aArder, [h.figuraId], 'sem chuva, continua a arder');
  const vida = her().vidaActual;
  d.juntar([[8, 6]]); // sem chuva não há rolagens de extinção: só o combustível desce; o tick dela é 6
  virarRodada('2');
  assert.equal(estado().rodada, 3);
  assert.equal(her().vidaActual, vida - 6, 'fora da casa, sem chuva: 1d8 outra vez');
  assert.equal(d.resto(), 0);
});

test('ordem 13: regra 6 — a RD da ficha não desconta no raio nem no fogo', () => {
  const fichas = fichasCom((f) => { f['orc-teste'].rd = { geral: 9, porTipo: {} }; });
  const d = roteiro([...raioEm(2, 6, 3), [6, 6]]);
  const { m, fOrc, virarRodada, estado, orcId } = mesaDaTempestade({ dado: d, fichas });
  const vida0 = fOrc().vidaActual;
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { raioAgora: true }));
  virarRodada('1');
  assert.equal(fOrc().vidaActual, vida0 - 15, 'raio 15 inteiro, RD 9 fora');
  // A vez do orc (rodada 2): o tick do fogo na casa dele, 1d8 = 8 inteiro.
  d.juntar([[8, 8]]);
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  assert.equal(estado().vez.figuraId, orcId);
  assert.equal(fOrc().vidaActual, vida0 - 15 - 8, 'fogo 8 inteiro, RD 9 fora');
});

test('ordem 13: o raio mata o último monstro — a batalha acaba em vitória no momento de ambiente', () => {
  const fichas = fichasCom((f) => { f['orc-teste'].vidaTotal = 12; });
  const d = roteiro([...raioEm(2, 6, 3), [6, 6]]);
  const { m, h, virarRodada, estado, fOrc } = mesaDaTempestade({ dado: d, fichas });
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { raioAgora: true }));
  const nH = h.msgs.length;
  virarRodada('1');
  assert.equal(fOrc().vivo, false);
  assert.equal(estado().fase, 'fim');
  assert.equal(d.resto(), 1, 'depois do raio que acaba a batalha, o automático já não se rola (como o site)');
  assert.equal(estado().desfecho, 'vitoria');
  const evH = eventosDepois(h, nH);
  assert.equal(evH.find((x) => x.tipo === 'raio').dados.desfecho, 'caiu');
  assert.deepEqual(evH.find((x) => x.tipo === 'fim').dados, { desfecho: 'vitoria' });
  const tipos = evH.map((x) => x.tipo);
  assert.equal(tipos.slice(tipos.indexOf('fim')).includes('turno'), false, 'não abre vez nenhuma depois do fim');
});

test('ordem 13: o raio deita a heroína a morrer com 0/0 (sem falhas novas) e o fogo não a fere caída', () => {
  const fichas = fichasCom((f) => { f['heroina-teste'].vidaTotal = 12; });
  const d = roteiro([...raioEm(2, 2, 5), [6, 6]]);
  const { m, h, her, virarRodada } = mesaDaTempestade({ dado: d, fichas });
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { raioAgora: true }));
  const nH = h.msgs.length;
  virarRodada('1');
  const evH = eventosDepois(h, nH);
  const raio = evH.find((x) => x.tipo === 'raio');
  assert.equal(raio.dados.desfecho, 'aMorrer');
  const est = evH.find((x) => x.tipo === 'estado' && x.dados.figuraId === h.figuraId);
  assert.deepEqual(est.dados.estadoMorte, { fase: 'aMorrer', sucessos: 0, falhas: 0 }, 'o ambiente não soma falhas');
  assert.equal(est.dados.visivel, 'caida');
  assert.equal(evH.filter((x) => x.tipo === 'dano_ambiente').length, 1, 'só o raio: caída, o fogo não lhe faz tick');
  assert.equal(d.pedidos.includes(8), false, 'nenhum d8 rolado para ela');
  assert.ok(evH.some((x) => x.tipo === 'teste_morte'), 'a vez dela é o teste de morte, como no site');
  assert.ok(her().estadoMorte, 'continua no relógio da morte');
});

test('ordem 13: o «voltar» repõe o fogo do instante; o «Recomeçar» começa sem fogo e sem pedido', () => {
  const d = roteiro([...raioEm(2, 2, 4), [6, 6], [8, 1]]);
  const { m, estado, virarRodada } = mesaDaTempestade({ dado: d });
  const antesSeq = m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW').journalSeq;
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { raioAgora: true }));
  virarRodada('1');
  assert.equal(estado().fogo.casas.length, 5);
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: antesSeq }), 'voltar');
  assert.equal(estado().fogo.casas.length, 0, 'antes do raio não havia fogo');
  assert.equal(estado().ambiente.raioPendente, false, 'nem pedido');
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { raioAgora: true }));
  d.juntar([...raioEm(2, 2, 4), [6, 6], [8, 1]]);
  virarRodada('1 de novo');
  assert.equal(estado().fogo.casas.length, 5);
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar');
  assert.deepEqual(estado().fogo, Amb.fogoVazio());
  assert.equal(estado().ambiente.raioPendente, false);
  assert.equal(estado().ambiente.raios, true, 'o painel fica o do Mestre');
  const snapH = m.clientes.heroina.ultimo('ROOM_SNAPSHOT');
  assert.deepEqual(snapH.fogo, { casas: [], aArder: [] });
});

test('ordem 13: o raio é aleatório — sem roteiro, a casa sai do dado da sala e cai dentro do tabuleiro', () => {
  const { m, estado, virarRodada } = mesaDaTempestade({ dado: null });
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { raioAgora: true }));
  virarRodada('1');
  const raios = m.clientes.mestre.eventos('raio');
  assert.ok(raios.length >= 1, 'o pedido caiu');
  for (const r of raios) {
    assert.ok(r.dados.x >= 0 && r.dados.x < 20 && r.dados.y >= 0 && r.dados.y < 20);
    assert.ok(['pedido', 'automatico'].includes(r.dados.soMestre.origem));
  }
  assert.ok(estado().fogo.casas.length >= 3, 'pelo menos a casa e 2 vizinhas (canto)');
});
