// Ordem 11 do CM-000009 (2026-11-09), no servidor: paridade da escala com o site (REF_36 + Emenda 1; itens P8a e P8b
// da auditoria da ordem 10).
//  - P8a: só valem 1 / 1,5 / 2 m por casa (site: ESCALAS_CASA_M). Outro valor é recusado; o detalhe ESCALA_INVALIDA
//    vai só ao Mestre (o texto da recusa é o fixo, sem números — E-P7);
//  - P8b: o alcance conta-se em casas com piso de 1 casa, alcanceEmCasas = max(1, metros / casaM) (site: jogo.js
//    alcanceEmCasas). Toda a técnica chega pelo menos à casa vizinha, em qualquer escala — também no ataque de
//    oportunidade. A métrica continua a do JV (euclidiana em casas); só o piso é novo.
// Fichas de teste: o orc tem só o machado de 1,5 m.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

const estado = (m) => m.sala.depuracao.estado();
const idDaFicha = (m, fichaId) => Object.values(estado(m).figuras).find((f) => f.fichaId === fichaId)?.id;
const escala = (m, casaM) => m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM });
const chamadasAoO = (m) => m.motor.chamadas.filter((c) => c.contexto?.ataqueDeOportunidade === true);

// ------------------------------------------------------------------ P8a: valores de escala

test('ordem 11 (P8a): a escala aceita 1, 1,5 e 2 m por casa', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['lobo-teste', { x: 7, y: 2 }]]);
  for (const v of [1, 2, 1.5]) {
    exigirAplicada(escala(m, v), 'escala ' + v);
    assert.equal(estado(m).mapa.casaM, v);
    assert.equal(m.clientes.heroina.ultimo('ROOM_SNAPSHOT').mapa.casaM, v, 'a Party recebe o resultado');
  }
});

test('ordem 11 (P8a): qualquer outro valor é recusado com erro claro — a escala não muda', () => {
  const m = montarMesa({ comEspectador: true });
  m.entrarTodos();
  m.iniciarCombate([['lobo-teste', { x: 7, y: 2 }]]);
  for (const mau of [3, 0.5, 2.5, 1.25, 0.75, 1.4999, 10]) {
    const r = recibo(escala(m, mau));
    assert.equal(r?.estado, 'RECUSADA', 'casaM ' + mau);
    assert.equal(r?.motivo, 'acao_invalida', 'casaM ' + mau);
    assert.equal(estado(m).mapa.casaM, 1.5, 'a escala não muda com ' + mau);
  }
  // O detalhe (com os valores que valem) é só do Mestre; a Party nunca o vê.
  const doMestre = JSON.stringify(m.clientes.mestre.msgs);
  assert.ok(doMestre.includes('ESCALA_INVALIDA'), 'o Mestre vê porque foi recusado');
  assert.ok(doMestre.includes('só valem 1 / 1.5 / 2 m'), 'e que valores valem');
  for (const chave of ['heroina', 'espectador']) {
    assert.equal(JSON.stringify(m.clientes[chave].msgs).includes('ESCALA_INVALIDA'), false, chave + ': sem o detalhe');
    assert.equal(m.clientes[chave].eventos('escala').length, 0, chave + ': nada mudou');
  }
  // Depois das recusas, um valor que vale continua a passar.
  exigirAplicada(escala(m, 2), 'escala 2 depois das recusas');
});

// ------------------------------------------------------------------ P8b: piso de 1 casa no alcance

/** Mesa em manual: heroína em (2,2), orc em `casaOrc`; o Mestre põe a escala `casaM`; a heroína encerra; vez do orc. */
function vezDoOrc(casaM, casaOrc) {
  const m = montarMesa({ modoPadrao: 'manual' });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', casaOrc]]);
  const h = m.clientes.heroina;
  const orc = idDaFicha(m, 'orc-teste');
  if (casaM !== 1.5) exigirAplicada(escala(m, casaM), 'escala ' + casaM);
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar');
  assert.equal(estado(m).vez.figuraId, orc, 'vez do orc');
  const golpe = () => recibo(m.enviar('mestre', {
    type: 'MASTER_ACT', intentId: 'orc-golpe', revision: m.clientes.mestre.revision, figuraId: orc,
    acao: { tipo: 'atacar', alvoId: h.figuraId, arma: 'machado-teste' },
  }));
  return { m, h, orc, golpe };
}

test('ordem 11 (P8b): técnica de 1,5 m com casa de 1 m — chega à vizinha e à diagonal (1,5 casas), não a 2 casas', () => {
  assert.equal(vezDoOrc(1, { x: 2, y: 3 }).golpe()?.estado, 'APLICADA', 'vizinha');
  assert.equal(vezDoOrc(1, { x: 3, y: 3 }).golpe()?.estado, 'APLICADA', 'diagonal: √2 ≈ 1,41 casas ≤ 1,5');
  assert.equal(vezDoOrc(1, { x: 2, y: 4 }).golpe()?.estado, 'RECUSADA', '2 casas: fora');
});

test('ordem 11 (P8b): técnica de 1,5 m com casa de 2 m — o piso de 1 casa dá-lhe a vizinha (antes: 2 m > 1,5 m, fora)', () => {
  assert.equal(vezDoOrc(2, { x: 2, y: 3 }).golpe()?.estado, 'APLICADA', 'vizinha: max(1; 0,75) = 1 casa');
  assert.equal(vezDoOrc(2, { x: 3, y: 3 }).golpe()?.estado, 'RECUSADA', 'diagonal: √2 casas > 1');
  assert.equal(vezDoOrc(2, { x: 2, y: 4 }).golpe()?.estado, 'RECUSADA', '2 casas: fora');
});

test('ordem 11 (P8b): na escala de sempre (1,5 m) nada muda — vizinha e diagonal sim, 2 casas não', () => {
  assert.equal(vezDoOrc(1.5, { x: 2, y: 3 }).golpe()?.estado, 'APLICADA', 'vizinha');
  assert.equal(vezDoOrc(1.5, { x: 3, y: 3 }).golpe()?.estado, 'RECUSADA', 'diagonal: √2 casas > 1');
  assert.equal(vezDoOrc(1.5, { x: 2, y: 4 }).golpe()?.estado, 'RECUSADA', '2 casas: fora');
});

/** A heroína em (2,2) com o orc em (2,3); o Mestre põe a escala; ela sai para (2,0). */
function saidaNaEscala(casaM) {
  const m = montarMesa({ modoPadrao: 'auto' });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const h = m.clientes.heroina;
  exigirAplicada(escala(m, casaM), 'escala ' + casaM);
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 2, y: 0 } }), 'sair');
  return { m, h, orc: idDaFicha(m, 'orc-teste') };
}

test('ordem 11 (P8b): ataque de oportunidade com casa de 1 m — a técnica de 1,5 m continua a chegar à casa vizinha', () => {
  const { m, h } = saidaNaEscala(1);
  const aoo = chamadasAoO(m);
  assert.equal(aoo.length, 1, 'o orc golpeia de oportunidade (antes: 1,5 m > 1 m, não golpeava)');
  assert.equal(aoo[0].tecnica?.id, 'machado-teste');
  assert.ok(h.eventos('ataque').some((e) => e.dados?.ataqueDeOportunidade === true), 'a Party vê o golpe');
});

test('ordem 11 (P8b): ataque de oportunidade com casa de 2 m — também chega', () => {
  const { m } = saidaNaEscala(2);
  const aoo = chamadasAoO(m);
  assert.equal(aoo.length, 1);
  assert.equal(aoo[0].tecnica?.id, 'machado-teste');
});
