// Ordem 48: o terreno do servidor para QUALQUER tamanho de grelha.
// O pacote dados/terreno-floresta.json passou a ser o mapa inteiro (terreno/2): o servidor recorta dele a grelha viva
// (tamanho e escala). Um tamanho que não caiba no mapa já não cai em silêncio em «todas as casas se pisam»: a sala não
// abre, a escala não muda, e o porquê vai nomeado (TERRENO_GRELHA_FORA_DO_MAPA). A prova cliente↔servidor (bits do
// double) é a do cliente: cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { prepararTerreno, TERRENO_GRELHA_FORA_DO_MAPA } from '../nucleo/terreno.js';
import { criarSala } from '../nucleo/sala.js';
import { criarMotorFalso } from './motor-falso.mjs';
import { montarMesa, exigirAplicada, recibo, fichasDeTeste, rngDeterministico, relogio, SENHAS, PIN, INICIATIVA } from './ajudantes.mjs';

const PACOTE = JSON.parse(readFileSync(new URL('../dados/terreno-floresta.json', import.meta.url), 'utf8'));
const T = prepararTerreno(PACOTE);

const recusasDoMestre = (m) => m.sala.depuracao.eventos().filter((e) => e.tipo === 'recusa').map((e) => JSON.stringify(e));

test('25 × 25 (o tamanho que caía na queda): servido pelo recorte — as casas bloqueadas do mapa bloqueiam, com o nome', () => {
  assert.equal(T.motivoSemGrelha(25, 25, 1.5), null);
  const g = T.para(25, 25, 1.5);
  assert.deepEqual([...g.origemM], [-18, -18], 'a origem da arena para 25 × 25 de 1,5 m (encostada às linhas do mapa)');
  // ORDEM MAPA-JOGÁVEL: eram 10; 2 são do lago e passam a casas de água (pisam-se).
  assert.equal(g.casasBloqueadas(), 8);
  assert.equal(g.casasDeAgua(), 2);
  const m = montarMesa({ terreno: PACOTE, mapa: { largura: 25, altura: 25 } });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 12, y: 12 }]]);
  const j = m.sala.depuracao.juizoTerreno();
  assert.equal(j.casas.length, 625, 'o servidor julga as 625 casas');
  const bloqueadas = j.casas.filter((c) => !c.passavel);
  assert.equal(bloqueadas.length, 8);
  assert.equal(j.casas.filter((c) => c.agua).length, 2, 'as 2 casas do lago pisam-se (ORDEM MAPA-JOGÁVEL)');
  assert.ok(j.casas.filter((c) => c.agua).every((c) => c.passavel && c.motivo === null));
  assert.ok(bloqueadas.every((c) => typeof c.motivo === 'string' && c.motivo.length > 0), 'cada casa bloqueada tem o motivo');
  // colocar em cima de cada casa bloqueada é recusado, com o nome do motivo ao Mestre
  for (const c of bloqueadas) {
    const r = m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: c.x, y: c.y } });
    assert.equal(recibo(r).type, 'ROOM_REJECT', `(${c.x},${c.y}) ${c.motivo}: recusada`);
    assert.ok(recusasDoMestre(m).some((e) => e.includes(`CASA_BLOQUEADA: (${c.x},${c.y}) ${c.motivo}`)), `o porquê de (${c.x},${c.y}) vai nomeado`);
  }
  // e o mover da heroína (em (2,2)) não oferece nenhuma
  const op = m.sala.depuracao.opcoes(m.clientes.heroina.figuraId);
  assert.deepEqual(op.mover.filter((c) => g.bloqueada(c.x, c.y)), []);
});

test('25 × 25 nas outras escalas e grelhas não quadradas: servidas, a altura e o pé de cada casa vêm do recorte', () => {
  for (const [l, a, c, bloq] of [[25, 25, 1, 0], [25, 25, 2, 28], [21, 17, 1, 0], [33, 27, 2, 35], [44, 20, 1.5, null], [1, 1, 1, null]]) { // MAPA-JOGÁVEL: 41 e 48 menos 13 do lago
    assert.equal(T.motivoSemGrelha(l, a, c), null, `${l}x${a}@${c}`);
    const g = T.para(l, a, c);
    if (bloq !== null) assert.equal(g.casasBloqueadas(), bloq, `${l}x${a}@${c}: casas bloqueadas`);
    for (let y = 0; y < a; y++) {
      for (let x = 0; x < l; x++) {
        assert.ok(Number.isFinite(g.alturaM(x, y)) && Number.isFinite(g.peM(x, y)));
        if (g.bloqueada(x, y)) assert.equal(typeof g.motivo(x, y), 'string');
      }
    }
  }
});

test('o recorte é o mesmo de onde quer que se olhe: uma grelha menor é a maior, deslocada (mesmos doubles)', () => {
  // com 1,5 m as casas do jogo são as do mapa: a casa (x, y) da 25 × 25 é a casa (x + 13, y + 13) da 50 × 50 (o mapa todo)…
  const g25 = T.para(25, 25, 1.5);
  const g50 = T.para(50, 50, 1.5);
  const d = (g25.origemM[0] - g50.origemM[0]) / 1.5;
  for (let y = 0; y < 25; y++) {
    for (let x = 0; x < 25; x++) {
      assert.ok(Object.is(g25.alturaM(x, y), g50.alturaM(x + d, y + d)));
      assert.ok(Object.is(g25.peM(x, y), g50.peM(x + d, y + d)));
      assert.equal(g25.bloqueada(x, y), g50.bloqueada(x + d, y + d));
      assert.equal(g25.motivo(x, y), g50.motivo(x + d, y + d));
    }
  }
  // …e com 1 m, a 23 × 23 (centros nos metros inteiros) é um recorte da 75 × 75
  const g23 = T.para(23, 23, 1);
  const g75 = T.para(75, 75, 1);
  const k = g23.origemM[0] - g75.origemM[0];
  assert.ok(Number.isInteger(k));
  assert.ok(Object.is(g23.alturaM(0, 0), g75.alturaM(k, k)));
});

test('fim da queda silenciosa: uma grelha que não cabe no mapa não abre a sala (erro nomeado)', () => {
  assert.match(T.motivoSemGrelha(51, 51, 1.5), new RegExp(`^${TERRENO_GRELHA_FORA_DO_MAPA}: .*cabem até 50x50`));
  assert.match(T.motivoSemGrelha(38, 10, 2), /cabem até 37x37/);
  assert.match(T.motivoSemGrelha(76, 1, 1), /cabem até 75x75/);
  assert.match(T.motivoSemGrelha(20, 20, 3), /^TERRENO_ESCALA_SEM_TABELA: /);
  assert.throws(() => T.para(51, 51, 1.5), new RegExp(TERRENO_GRELHA_FORA_DO_MAPA), 'para() nunca devolve null: lança o porquê');
  assert.throws(() => montarMesa({ terreno: PACOTE, mapa: { largura: 51, altura: 51 } }),
    new RegExp(`criarSala: ${TERRENO_GRELHA_FORA_DO_MAPA}: a grelha 51x51 de 1.5 m não cabe no mapa`));
  assert.throws(() => montarMesa({ terreno: PACOTE, mapa: { largura: 60, altura: 20 } }), new RegExp(TERRENO_GRELHA_FORA_DO_MAPA));
  // sem terreno a sala é como sempre (nenhum mapa a respeitar): o 51 × 51 abre
  assert.doesNotThrow(() => montarMesa({ mapa: { largura: 51, altura: 51 } }));
});

test('a escala viva: mudar para uma escala em que a grelha não cabe é recusado ao Mestre, com o nome; a sala fica como estava', () => {
  const m = montarMesa({ terreno: PACOTE, mapa: { largura: 40, altura: 40 } });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 20, y: 20 }]]);
  const r = m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 2 });
  assert.equal(recibo(r).type, 'ROOM_REJECT', '40 × 40 de 2 m = 80 m: não cabe nos 75 m do mapa');
  assert.ok(recusasDoMestre(m).some((e) => e.includes(`${TERRENO_GRELHA_FORA_DO_MAPA}: a grelha 40x40 de 2 m`)), 'o porquê vai ao Mestre');
  assert.equal(m.sala.depuracao.juizoTerreno().casaM, 1.5, 'a escala não mudou');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 1 }), '40 × 40 de 1 m cabe');
  const j = m.sala.depuracao.juizoTerreno();
  assert.equal(j.casaM, 1);
  const g = T.para(40, 40, 1);
  assert.equal(j.casas.filter((c) => !c.passavel).length, g.casasBloqueadas());
  for (const c of j.casas) assert.ok(Object.is(c.alturaM, g.alturaM(c.x, c.y)) && Object.is(c.peM, g.peM(c.x, c.y)));
});

test('restaurar com terreno uma sala gravada numa grelha que não cabe: não abre, com o nome', () => {
  // gravada SEM terreno (nada a respeitar), 40 × 40 a 2 m; restaurada COM terreno: o mapa não a serve
  const sem = montarMesa({ mapa: { largura: 40, altura: 40 } });
  sem.entrarTodos();
  sem.iniciarCombate([['orc-teste', { x: 20, y: 20 }]]);
  exigirAplicada(sem.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 2 }), 'sem terreno a escala muda');
  const exp = sem.sala.exportar();
  const config = {
    roomId: 'sala-teste', iniciativa: INICIATIVA, mapa: { largura: 40, altura: 40 },
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste' },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  const abrir = (terreno) => criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(), agora: relogio(), config, restaurarDe: exp, terreno });
  assert.throws(() => abrir(PACOTE), new RegExp(`criarSala: ${TERRENO_GRELHA_FORA_DO_MAPA}: a grelha 40x40 de 2 m`));
  assert.doesNotThrow(() => abrir(null), 'sem terreno restaura como sempre');
});

test('a cobertura na faixa da borda: o servidor só afirma o que sabe (2 é 2; abaixo disso, null); longe da borda é a do mapa', () => {
  const borda = PACOTE.cabecalho.bordaCoberturaM;
  assert.equal(borda, 1.35);
  const g = T.para(30, 30, 1.5);
  let nulas = 0;
  let servidas = 0;
  for (let y = 0; y < 30; y++) {
    for (let x = 0; x < 30; x++) {
      const c = g.cobertura(x, y);
      const naBorda = x === 0 || y === 0 || x === 29 || y === 29; // com 1,5 m o centro da casa do mapa está a 0,75 m da borda
      if (!naBorda) assert.ok(c === 0 || c === 1 || c === 2, `(${x},${y}) longe da borda: servida`);
      if (c === null) {
        nulas += 1;
        assert.ok(naBorda, `(${x},${y}): null só na faixa da borda`);
      } else servidas += 1;
      if (g.bloqueada(x, y)) assert.equal(c, 2, 'uma casa bloqueada dá cobertura total, também na borda');
    }
  }
  assert.ok(nulas > 0 && nulas <= 116, `${nulas} casas da borda sem cobertura afirmada`);
  assert.equal(nulas + servidas, 900);
  // o juízo da sala leva o mesmo null (o porquê está no pacote: bordaCoberturaM)
  const m = montarMesa({ terreno: PACOTE, mapa: { largura: 30, altura: 30 } });
  m.entrarTodos();
  const j = m.sala.depuracao.juizoTerreno();
  assert.equal(j.casas.filter((c) => c.cobertura === null).length, nulas);
  assert.equal(g.cobertura(30, 0), null, 'fora da grelha: null');
});

test('regressão na zona livre: a grelha de sempre (20 × 20 de 1,5 m), com e sem terreno recortado, dá o mesmo combate', () => {
  const correr = (terreno) => {
    const m = montarMesa({ terreno });
    m.entrarTodos();
    m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
    exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 3, y: 3 } }), 'mover');
    exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 2 }), 'escala 2 m');
    exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 1 }), 'escala 1 m');
    return { opcoes: m.sala.depuracao.opcoes(m.clientes.heroina.figuraId), hash: m.sala.depuracao.hashEstado() };
  };
  const sem = correr(null);
  const com = correr(PACOTE);
  assert.deepEqual(com.opcoes, sem.opcoes);
  assert.equal(com.hash, sem.hash);
  assert.equal(T.para(20, 20, 1).casasBloqueadas(), 0, 'a 20 × 20 de 1 m também não tem casas bloqueadas');
});
