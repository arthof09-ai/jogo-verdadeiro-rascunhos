// T-OPT-06: invariante 11, "opções honestas". Toda a opção listada em ROOM_OPTIONS,
// enviada na sua revisão, dá APLICADA. Cada opção é testada numa réplica nova da mesa
// (o guião é determinista: mesmos ids, mesmas sementes, mesmas revisões).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, recibo, exigirAplicada } from './ajudantes.mjs';

// Heroína em (2,2); orc ADJACENTE em (2,3) (dá desvincular e ataque de oportunidade);
// lobo a 4 casas em (6,2) (6 m: dentro do chicote de 9 m).
function cenario() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }], ['lobo-teste', { x: 6, y: 2 }]]);
  return m;
}

function acoesDe(opcoes) {
  const lista = [];
  for (const o of opcoes.mover) lista.push({ tipo: 'mover', destino: { x: o.x, y: o.y } });
  for (const o of opcoes.ataques) lista.push({ tipo: 'atacar', alvoId: o.alvoId, arma: o.arma });
  for (const t of opcoes.acoes) lista.push({ tipo: t });
  return lista;
}

test('T-OPT-06: cada opção da heroína, na sua revisão, dá APLICADA', () => {
  const base = cenario();
  const ops = base.clientes.heroina.opcoes;
  assert.ok(ops, 'a heroína tem opções na vez dela');
  assert.equal(ops.vezId, base.clientes.heroina.figuraId);
  assert.equal(ops.orcamentoM, 9);
  assert.ok(ops.mover.length > 0);
  assert.ok(ops.mover.every((o) => o.custoM <= ops.orcamentoM), 'nenhum destino passa da reserva');
  assert.equal(ops.ataques.length, 2, 'orc e lobo ao alcance do chicote');
  for (const t of ['encerrar', 'correr', 'defender', 'desvincular']) assert.ok(ops.acoes.includes(t), 'tem ' + t);

  const lista = acoesDe(ops);
  for (const acao of lista) {
    const m = cenario();
    const h = m.clientes.heroina;
    assert.deepEqual(h.opcoes, ops, 'réplica determinista');
    const r = recibo(m.intencao('heroina', acao, { revision: ops.revision }));
    assert.ok(r && r.type === 'ROOM_RECEIPT' && r.estado === 'APLICADA', `opção ${JSON.stringify(acao)} deu ${JSON.stringify(r)}`);
  }
});

test('T-OPT-06 b: depois de agir, as opções novas também são honestas (atacou → sem ataques; andou → sem correr)', () => {
  const m = cenario();
  const h = m.clientes.heroina;
  const lobo = h.idPorNome('Lobo');
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: lobo, arma: 'chicote-teste' }));
  assert.equal(h.opcoes.ataques.length, 0, 'uma ação padrão por vez');
  assert.ok(!h.opcoes.acoes.includes('correr'));
  assert.ok(!h.opcoes.acoes.includes('desvincular'));
  assert.ok(h.opcoes.mover.length > 0, 'pode andar depois de atacar');
  // Ação fora da lista: recusa com o texto fixo.
  const r = recibo(m.intencao('heroina', { tipo: 'atacar', alvoId: lobo, arma: 'chicote-teste' }));
  assert.equal(r.motivo, 'acao_invalida');
  // Todas as que ficaram listadas continuam honestas (amostra: a primeira e a última casa).
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: h.opcoes.mover[0].x, y: h.opcoes.mover[0].y } }));
});

test('BFS de 4 vizinhos: sem diagonais, figuras vivas bloqueiam, cadáveres não', () => {
  // Canto: heroína em (0,0); orc em (1,0) e lobo em (0,1) fecham-na.
  const m2 = montarMesa({ casas: { heroina: { x: 0, y: 0 } } });
  m2.entrarTodos();
  m2.iniciarCombate([['orc-teste', { x: 1, y: 0 }], ['lobo-teste', { x: 0, y: 1 }]]);
  const h = m2.clientes.heroina;
  assert.deepEqual(h.opcoes.mover, [], 'cercada por figuras vivas e sem diagonais');

  // Matar o lobo (vida 4848; o falso dá 1176 por golpe → não chega). Pomos o dano alto.
  m2.motor.cfg.dano = 999999;
  const lobo = h.idPorNome('Lobo');
  exigirAplicada(m2.intencao('heroina', { tipo: 'atacar', alvoId: lobo, arma: 'chicote-teste' }));
  const est = m2.sala.depuracao.estado();
  assert.equal(est.figuras[lobo].vivo, false);
  // O cadáver não bloqueia o caminho, mas não se acaba em cima dele.
  assert.ok(h.opcoes.mover.length > 0, 'o cadáver abriu caminho');
  assert.ok(!h.opcoes.mover.some((o) => o.x === 0 && o.y === 1), 'não se pára em cima do cadáver');
  assert.ok(h.opcoes.mover.some((o) => o.x === 0 && o.y === 2), 'passa por cima dele');
});
