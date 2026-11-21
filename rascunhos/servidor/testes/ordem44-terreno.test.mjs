// Ordem 44 (parte A): o TERRENO DO MAPA no servidor.
// O servidor lê o pacote dados/terreno-floresta.json, que o cliente gera com as mesmas funções com que desenha
// (cliente/cenas/arena/ferramentas/exportar_terreno.gd). Com ele, as casas bloqueadas do mapa (menires, santuário,
// água funda, escarpa…) não se pisam, não se ocupam e não se atravessam; a altura de cada casa e o pé das figuras
// ficam a ser os do cliente. Na grelha de sempre (20 × 20 de 1,5 m) não há casas bloqueadas: nada muda.
// Ordem 48: o pacote passou a ser o mapa inteiro (terreno/2) e a grelha viva recorta-se dele; os testes de qualquer
// tamanho, da falha nomeada e da cobertura na borda estão em ordem48-terreno-qualquer-grelha.test.mjs.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { prepararTerreno } from '../nucleo/terreno.js';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

const PACOTE = JSON.parse(readFileSync(new URL('../dados/terreno-floresta.json', import.meta.url), 'utf8'));
const clone = (o) => JSON.parse(JSON.stringify(o));

test('o pacote do terreno lê-se: o mapa inteiro, gerado pelo cliente, com as fontes e sem casas bloqueadas na grelha de sempre', () => {
  const t = prepararTerreno(PACOTE);
  assert.equal(t.formato, 'terreno/2');
  assert.equal(t.mapa, 'floresta');
  // Ordem 48: já não são 6 grelhas feitas — é o mapa inteiro, e cada escala serve todas as grelhas que cabem nele
  assert.deepEqual(t.escalas.map((e) => `${e.casaM}:${e.ladoMax}`), ['1:75', '1.5:50', '2:37']);
  for (const [l, a, c] of [[20, 20, 1], [20, 20, 1.5], [20, 20, 2], [30, 30, 1], [30, 30, 1.5], [30, 30, 2]]) {
    assert.equal(t.motivoSemGrelha(l, a, c), null, `as 6 grelhas da Ordem 44 servem-se (${l}x${a}@${c})`);
  }
  assert.ok(Object.keys(t.fontes).includes('cenas/arena/assentamento.gd'), 'o SHA da regra do assentamento vai no pacote');
  assert.match(PACOTE.cabecalho.geradoPor, /exportar_terreno\.gd/);
  assert.equal(t.para(20, 20, 1.5).casasBloqueadas(), 0, 'a zona livre (20 × 20) não tem casas bloqueadas');
  const g30 = t.para(30, 30, 1.5);
  // ORDEM MAPA-JOGÁVEL: das casas que o pacote bloqueia nesta grelha, as do lago («água funda») passam a casas de
  // água, que se pisam; as outras bloqueiam como antes. LAGO-MAIOR: o lago maior (17 → 47 casas de água) e a floresta
  // de fora do campo do meio devolvida (26 → 43 bloqueadas: troncos e rochas do anel de fora).
  assert.equal(g30.casasBloqueadas(), 43);
  assert.equal(g30.casasDeAgua(), 47);
  assert.equal(g30.motivo(1, 0), 'menir');
  assert.equal(g30.bloqueada(1, 0), true);
  assert.equal(g30.bloqueada(10, 10), false);
  // o anel de fora da zona livre (as 5 casas de cada lado) tem tudo o que bloqueia; o centro 20 × 20 nada
  for (let y = 5; y < 25; y++) for (let x = 5; x < 25; x++) assert.equal(g30.bloqueada(x, y), false, `(${x},${y}) dentro da zona livre`);
  // com casas de 1,5 m cada casa do jogo é uma casa do mapa: a (0,0) da 30 × 30 é a casa (10,10) do mapa
  assert.deepEqual(g30.casaDoMapa(0, 0), { coluna: 10, linha: 10 });
  assert.equal(typeof g30.alturaM(0, 0), 'number');
  assert.equal(g30.alturaM(30, 0), null, 'fora da grelha: null');
});

test('o pacote falha fechado: formato, tamanhos, valores, motivos e redes', () => {
  assert.throws(() => prepararTerreno(null), /pacote em falta/);
  const p1 = clone(PACOTE); p1.cabecalho.formato = 'terreno/1';
  assert.throws(() => prepararTerreno(p1), /formato desconhecido/);
  const p2 = clone(PACOTE); p2.mapa.bloqueadas.pop();
  assert.throws(() => prepararTerreno(p2), /mapa\.bloqueadas tem de ter 2500/);
  const p3 = clone(PACOTE); p3.redes[0].peM = p3.redes[0].peM.slice(0, -12);
  assert.throws(() => prepararTerreno(p3), /redes\[0\]\.peM tem de ter/);
  const p4 = clone(PACOTE); p4.mapa.bloqueadas[p4.mapa.bloqueadas.indexOf(0)] = 1;
  assert.throws(() => prepararTerreno(p4), /bloqueada sem motivo/);
  const p5 = clone(PACOTE); p5.mapa.cobertura[0] = 3;
  assert.throws(() => prepararTerreno(p5), /cobertura/);
  const p6 = clone(PACOTE); p6.redes = [];
  assert.throws(() => prepararTerreno(p6), /sem redes/);
  const p7 = clone(PACOTE); p7.redes[0].colunaMapa[0] = 50;
  assert.throws(() => prepararTerreno(p7), /colunaMapa/);
  const p8 = clone(PACOTE); p8.redes[0].alturaM = '!!não é base64!!';
  assert.throws(() => prepararTerreno(p8), /alturaM tem de ter/);
  // uma tabela que promete uma grelha que nenhuma rede serve: não se prepara (nada de «tudo se pisa» mais tarde)
  const p9 = clone(PACOTE); p9.redes = p9.redes.filter((r) => !(r.casaM === 2 && r.largura === 36));
  assert.throws(() => prepararTerreno(p9), /não encaixa em nenhuma rede/);
});

test('regressão: na grelha de sempre (20 × 20), com ou sem terreno, as opções e o estado são os mesmos', () => {
  const correr = (terreno) => {
    const m = montarMesa({ terreno });
    m.entrarTodos();
    m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
    exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 3, y: 3 } }), 'mover');
    return { m, opcoes: m.sala.depuracao.opcoes(m.clientes.heroina.figuraId), hash: m.sala.depuracao.hashEstado() };
  };
  const sem = correr(null);
  const com = correr(PACOTE);
  assert.deepEqual(com.opcoes, sem.opcoes, 'as casas do mover, os alvos e o resto: iguais');
  assert.equal(com.hash, sem.hash, 'o estado gravado é o mesmo (o terreno não entra no journal)');
  assert.equal(sem.m.sala.depuracao.juizoTerreno(), null, 'sem terreno o servidor não julga alturas (como antes)');
  const j = com.m.sala.depuracao.juizoTerreno();
  assert.equal(j.casas.length, 400);
  assert.ok(j.casas.every((c) => c.passavel), 'todas as 400 casas se pisam');
});

test('grelha maior (30 × 30): o servidor conhece os marcos — não se colocam figuras nas casas bloqueadas (recusa nomeada ao Mestre)', () => {
  const m = montarMesa({ terreno: PACOTE, mapa: { largura: 30, altura: 30 } });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 10, y: 10 }]]);
  const r = m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 1, y: 0 } });
  assert.equal(recibo(r).type, 'ROOM_REJECT', 'colocar em cima do menir (1,0) é recusado');
  const recusas = m.sala.depuracao.eventos().filter((e) => e.tipo === 'recusa');
  assert.ok(recusas.some((e) => JSON.stringify(e).includes('CASA_BLOQUEADA: (1,0) menir')), 'o porquê vai ao Mestre, nomeado');
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 1, y: 1 } }), 'ao lado do menir pode');
});

test('grelha maior (30 × 30): o mover não oferece casas bloqueadas e o caminho contorna-as', () => {
  const m = montarMesa({ terreno: PACOTE, mapa: { largura: 30, altura: 30 } });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 20, y: 20 }]]);
  const g = prepararTerreno(PACOTE).para(30, 30, 1.5);
  const h = m.clientes.heroina;
  const op = m.sala.depuracao.opcoes(h.figuraId);
  assert.ok(op.mover.length > 0);
  const bloqueadas = op.mover.filter((c) => g.bloqueada(c.x, c.y));
  assert.deepEqual(bloqueadas, [], 'nenhuma casa bloqueada nas opções do mover');
  // a heroína está em (2,2); o menir (3,2) fica a leste: (4,2) está a 2 casas em linha recta, mas o caminho contorna
  const casa42 = op.mover.find((c) => c.x === 4 && c.y === 2);
  assert.ok(casa42, '(4,2) chega-se');
  const sem = montarMesa({ mapa: { largura: 30, altura: 30 } });
  sem.entrarTodos();
  sem.iniciarCombate([['orc-teste', { x: 20, y: 20 }]]);
  const casa42Sem = sem.sala.depuracao.opcoes(sem.clientes.heroina.figuraId).mover.find((c) => c.x === 4 && c.y === 2);
  assert.ok(casa42.custoM > casa42Sem.custoM, `com o menir o caminho é mais comprido (${casa42.custoM} m contra ${casa42Sem.custoM} m)`);
  const rr = m.intencao('heroina', { tipo: 'mover', destino: { x: 3, y: 2 } });
  assert.equal(recibo(rr).type, 'ROOM_REJECT', 'andar para cima do menir é recusado');
});

test('o juízo do terreno segue a escala viva (o Mestre muda a casa para 2 m: a grelha de 30 × 30 de 2 m)', () => {
  const m = montarMesa({ terreno: PACOTE, mapa: { largura: 30, altura: 30 } });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 15, y: 15 }]]);
  const t = prepararTerreno(PACOTE);
  const j15 = m.sala.depuracao.juizoTerreno();
  assert.equal(j15.casaM, 1.5);
  assert.equal(j15.casas.filter((c) => !c.passavel).length, t.para(30, 30, 1.5).casasBloqueadas());
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 2 }), 'escala 2 m');
  const j2 = m.sala.depuracao.juizoTerreno();
  assert.equal(j2.casaM, 2);
  assert.equal(j2.casas.filter((c) => !c.passavel).length, t.para(30, 30, 2).casasBloqueadas());
  const g2 = t.para(30, 30, 2);
  for (const c of j2.casas) {
    assert.equal(c.alturaM, g2.alturaM(c.x, c.y));
    assert.equal(c.peM, g2.peM(c.x, c.y));
  }
});
