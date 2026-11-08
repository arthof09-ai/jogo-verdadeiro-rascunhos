// Delta REF_17 (I0004, 08/11/2026): no site, duas criaturas da IA podiam acabar na mesma casa (a segunda escolhia
// o destino enquanto a primeira ainda voava). No servidor o movimento é atómico: a primeira já está na casa quando a
// segunda escolhe. Este teste guarda essa invariante: duas figuras VIVAS nunca partilham uma casa.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada } from './ajudantes.mjs';

function conferirCasas(m, rotulo) {
  const vivas = Object.values(m.sala.depuracao.estado().figuras).filter((f) => f.vivo && f.colocada !== false);
  const vistas = new Map();
  for (const f of vivas) {
    const k = `${f.x},${f.y}`;
    assert.ok(!vistas.has(k), `${rotulo}: ${vistas.get(k)} e ${f.id} na mesma casa (${k})`);
    vistas.set(k, f.id);
  }
}

const ARRANJOS = [
  // As duas criaturas à mesma distância da jogadora: disputam a mesma casa ao lado dela (o caso do site).
  { criaturas: [['orc-teste', { x: 6, y: 2 }], ['lobo-teste', { x: 2, y: 6 }]], comAliada: false },
  { criaturas: [['orc-teste', { x: 5, y: 3 }], ['lobo-teste', { x: 3, y: 5 }]], comAliada: false },
  { criaturas: [['orc-teste', { x: 9, y: 9 }], ['lobo-teste', { x: 10, y: 8 }]], comAliada: true },
  { criaturas: [['lobo-teste', { x: 2, y: 9 }], ['orc-teste', { x: 9, y: 2 }]], comAliada: true },
];

test('REF_17: duas figuras vivas nunca ficam na mesma casa, ronda após ronda', () => {
  ARRANJOS.forEach((arranjo, i) => {
    const m = montarMesa({ comAliada: arranjo.comAliada });
    m.entrarTodos();
    m.iniciarCombate(arranjo.criaturas);
    conferirCasas(m, `arranjo ${i} início`);
    for (let ronda = 0; ronda < 6; ronda++) {
      const est = m.sala.depuracao.estado();
      if (est.fase !== 'combate') break;
      const vez = est.figuras[est.vez?.figuraId];
      const chave = vez?.lado === 'jogadora'
        ? Object.keys(m.clientes).find((k) => m.clientes[k].figuraId === vez.id)
        : null;
      if (!chave) break; // a vez parou numa criatura (cartão ou fim): basta o que já se conferiu
      exigirAplicada(m.intencao(chave, { tipo: 'encerrar' }), `arranjo ${i} ronda ${ronda}`);
      conferirCasas(m, `arranjo ${i} ronda ${ronda}`);
    }
  });
});
