// Ordem ESCALA (2026-11-20; palavra do Mestre, como no protótipo `hudt1-escala`): a casa NÃO é fixa — é a ESCALA DO
// MUNDO, 1 · 1,5 · 2 m por casa, escolhida pelo Mestre; pré-definida 1,5 m. No servidor a fonte única é sala.js
// (ESCALAS_CASA_M + CASA_M) e a escala viva é `mapa.casaM` do mundo (ordens 8, 11, 48 e 62). Esta prova fecha a
// ordem do lado do servidor:
//  (a) a sala nasce a 1,5 m (o comportamento de sempre);
//  (b) uma distância conhecida — 6 m — cobre 6 casas a 1 m, 4 casas a 1,5 m e 3 casas a 2 m: no DESLOCAMENTO (opções e
//      intenção aplicada/recusada) e no ALCANCE de uma técnica de 6 m;
//  (c) a escala é persistente na partida: fica de vez para vez, a jogadora que volta recebe-a, e a sala restaurada do
//      journal reabre nela;
//  (d) só o Mestre a muda; a Party vê o resultado (mapa.casaM), nunca a mecânica nem vida/alma.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { carregarFichas } from '../nucleo/carregar-fichas.js';
import { criarSala, CASA_M, ESCALAS_CASA_M } from '../nucleo/sala.js';
import { montarMesa, exigirAplicada, recibo, listaDeFichas, procurarCanarios, rngDeterministico, relogio, FIXTURE, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const estado = (m) => m.sala.depuracao.estado();
const escala = (m, casaM) => m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM });

/** A heroína com 6 m de deslocamento e um chicote de 6 m de alcance (a distância conhecida da prova). */
function fichasDe6m() {
  const lista = listaDeFichas();
  const h = lista.find((f) => f.id === 'heroina-teste');
  h.deslocamentoBase = 6;
  for (const t of h.tecnicas) t.alcanceM = 6;
  const r = carregarFichas(lista);
  if (!r.ok) throw new Error('fichas de 6 m inválidas: ' + JSON.stringify(r.erros));
  return r.fichas;
}

/** Heroína em (2,2), vez dela; o lobo onde se pedir; o Mestre põe a escala `casaM` (sem custo). */
function mesa6m(casaM, casaLobo = { x: 15, y: 15 }) {
  const m = montarMesa({ fichas: fichasDe6m() });
  m.entrarTodos();
  m.iniciarCombate([['lobo-teste', casaLobo]]);
  if (casaM !== CASA_M) exigirAplicada(escala(m, casaM), 'escala ' + casaM);
  assert.equal(estado(m).mapa.casaM, casaM);
  assert.equal(estado(m).vez.figuraId, m.clientes.heroina.figuraId, 'a vez é da heroína');
  return m;
}

// 6 m em casas, por escala: a tabela da ordem.
const CASAS_EM_6M = [[1, 6], [1.5, 4], [2, 3]];

test('ordem ESCALA (a): as escalas que valem são 1 · 1,5 · 2 m e a sala nasce na pré-definida, 1,5 m', () => {
  assert.deepEqual([...ESCALAS_CASA_M], [1, 1.5, 2]);
  assert.equal(CASA_M, 1.5);
  const m = montarMesa();
  m.entrarTodos();
  assert.equal(estado(m).mapa.casaM, 1.5, 'no lobby');
  assert.equal(m.clientes.heroina.ultimo('ROOM_SNAPSHOT').mapa.casaM, 1.5, 'a jogadora vê a escala vigente');
  m.iniciarCombate([['lobo-teste', { x: 15, y: 15 }]]);
  assert.equal(estado(m).mapa.casaM, 1.5, 'no combate, sem o Mestre mexer');
});

for (const [casaM, casas] of CASAS_EM_6M) {
  test(`ordem ESCALA (b): a ${casaM} m por casa, 6 m de deslocamento cobrem ${casas} casas — opções e intenção`, () => {
    const m = mesa6m(casaM);
    const h = m.clientes.heroina;
    assert.equal(h.opcoes.orcamentoM, 6, 'a reserva está em metros: 6 m em qualquer escala');
    const maxCusto = Math.max(...h.opcoes.mover.map((o) => o.custoM));
    assert.equal(maxCusto, casas * casaM, `a casa mais longe custa ${casas} × ${casaM} m`);
    for (const o of h.opcoes.mover) {
      const passos = Math.abs(o.x - 2) + Math.abs(o.y - 2);
      assert.ok(passos <= casas, `(${o.x},${o.y}) a ${passos} casas`);
      assert.equal(o.custoM, Math.round(passos * casaM * 100) / 100, 'custo = casas × escala');
    }
    assert.ok(h.opcoes.mover.some((o) => o.x === 2 && o.y === 2 + casas), `a casa a ${casas} casas a direito está nas opções`);
    assert.ok(!h.opcoes.mover.some((o) => o.x === 2 && o.y === 2 + casas + 1), 'a seguinte não');
    // A intenção: uma casa a mais é recusada; as N casas passam e gastam os 6 m todos.
    const r = recibo(m.intencao('heroina', { tipo: 'mover', destino: { x: 2, y: 2 + casas + 1 } }));
    assert.notEqual(r?.estado, 'APLICADA', `${casas + 1} casas: fora dos 6 m`);
    exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 2, y: 2 + casas } }), `${casas} casas`);
    assert.equal(estado(m).vez.reservaM, 0, 'os 6 m foram todos');
    assert.equal(estado(m).vez.andouM, 6, 'andou 6 m');
  });

  test(`ordem ESCALA (b): a ${casaM} m por casa, uma técnica de 6 m chega a ${casas} casas e não a ${casas + 1}`, () => {
    const dentro = mesa6m(casaM, { x: 2, y: 2 + casas });
    assert.equal(dentro.clientes.heroina.opcoes.ataques.length, 1, `lobo a ${casas} casas = ${casas * casaM} m: ao alcance`);
    const fora = mesa6m(casaM, { x: 2, y: 2 + casas + 1 });
    assert.equal(fora.clientes.heroina.opcoes.ataques.length, 0, `lobo a ${casas + 1} casas = ${(casas + 1) * casaM} m: fora`);
  });
}

test('ordem ESCALA (c): a escala é persistente na partida — de vez para vez, na reentrada e no restauro do journal', () => {
  const m = mesa6m(2);
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar');
  // A volta segue (o lobo joga em auto) até a vez voltar à heroína: a escala não se mexeu.
  assert.equal(estado(m).mapa.casaM, 2, 'depois de encerrar a vez');
  if (estado(m).vez?.figuraId === m.clientes.heroina.figuraId) {
    assert.equal(Math.max(...m.clientes.heroina.opcoes.mover.map((o) => o.custoM)), 6, 'na vez seguinte, 3 casas de 2 m');
  }
  // Reentrada da jogadora: o snapshot traz a escala viva.
  m.sair('heroina');
  const volta = m.entrar('heroina', { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina });
  assert.notEqual(volta.ok, false, 'a heroína volta a entrar');
  assert.equal(m.clientes.heroina.ultimo('ROOM_SNAPSHOT').mapa.casaM, 2, 'quem volta recebe a escala viva');
  // Restauro do journal: a sala reabre na escala gravada.
  const config = {
    roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  const sala2 = criarSala({ motores: criarMotorFalso(), fichas: fichasDe6m(), rng: rngDeterministico(7), agora: relogio(), config, restaurarDe: m.sala.exportar() });
  assert.equal(sala2.depuracao.estado().mapa.casaM, 2, 'a sala restaurada abre a 2 m por casa');
});

test('ordem ESCALA (d): só o Mestre muda a escala; a Party vê o resultado e nada de vida/alma nem a mecânica', () => {
  const m = montarMesa({ comEspectador: true });
  m.entrarTodos();
  m.iniciarCombate([['lobo-teste', { x: 15, y: 15 }]]);
  // A jogadora não tem a operação: a mensagem do Mestre vinda dela é recusada e a escala fica.
  const r = recibo(m.enviar('heroina', { type: 'MASTER_SUPERVISOR', intentId: 'escala-da-jogadora', revision: m.clientes.heroina.revision, op: 'escala', casaM: 2 }));
  assert.notEqual(r?.estado, 'APLICADA', 'a jogadora não muda a escala');
  assert.equal(estado(m).mapa.casaM, 1.5);
  exigirAplicada(escala(m, 1), 'o Mestre muda para 1 m');
  for (const chave of ['heroina', 'espectador']) {
    const c = m.clientes[chave];
    assert.equal(c.ultimo('ROOM_SNAPSHOT').mapa.casaM, 1, chave + ': vê a escala vigente');
    for (const e of c.eventos('escala')) assert.deepEqual(e.dados ?? {}, {}, chave + ': o evento vai vazio');
  }
  // O antes/depois da escala (soMestre) e os números do monstro (CA, Vida, PA da ficha) nunca chegam à Party.
  const lobo = FIXTURE.fichas.find((f) => f.id === 'lobo-teste');
  const numeros = [lobo.ca, lobo.vidaTotal, lobo.paTotal].filter((v) => typeof v === 'number' && v >= 100);
  assert.ok(numeros.length > 0, 'há canários do monstro para varrer');
  for (const chave of ['heroina', 'espectador']) {
    // As chaves de vida/alma do MONSTRO não existem na projecção da Party; a ficha da própria jogadora é dela (a regra
    // geral está em privacidade.test.mjs). Aqui: os números do lobo, o detalhe e o antes/depois da escala.
    const achados = procurarCanarios(m.clientes[chave].msgs, { numeros, textos: ['ESCALA_', 'CANARIO-FANTASMA'], chaves: ['casaMAntes', 'casasQuePaga'] });
    assert.deepEqual(achados, [], `vazamento para ${chave}: ${JSON.stringify(achados.slice(0, 5))}`);
  }
  const doMestre = JSON.stringify(m.clientes.mestre.msgs.slice(-20));
  assert.ok(doMestre.includes('casaMAntes'), 'sanidade: o Mestre recebe o antes/depois (o varrimento não está a varrer o vazio)');
});
