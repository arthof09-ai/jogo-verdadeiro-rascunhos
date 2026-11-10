// Ordem 15 do CM-000009 (2026-11-10), parte B — palavra do Mestre: o alcance do ataque mede-se pelo CAMINHO DAS CASAS
// (BFS de 4 vizinhos sobre a grelha), com as figuras vivas a bloquear o caminho, como no site (jogo-t1/jogo.js
// distanciaEntre). Cai a decisão B9 do JV (a régua a direito, euclidiana). Os valores de alcance das fichas não mudam;
// o piso de 1 casa (ordem 11) continua.
//
// Nota sobre o «caso inverso»: na grelha de 4 vizinhos o caminho nunca é mais curto do que a linha a direito, por isso
// não existe «o caminho chega e a direito não». O inverso que se cobre é o que a régua nova devolve quando o caminho
// está livre (ou quando quem bloqueava se afasta): o ataque volta a estar ao alcance.
//
// Fichas de teste: a heroína tem o chicote de 9 m (6 casas a 1,5 m); o orc e o lobo têm armas de 1,5 m.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

const estado = (m) => m.sala.depuracao.estado();
const idsDaFicha = (m, fichaId) => Object.values(estado(m).figuras).filter((f) => f.fichaId === fichaId).map((f) => f.id);
const alvosDoChicote = (m) =>
  (m.clientes.heroina.ultimo('ROOM_OPTIONS')?.ataques ?? []).filter((a) => a.arma === 'chicote-teste').map((a) => a.alvoId);

function mesa(casaHeroina, criaturas) {
  const m = montarMesa({ modoPadrao: 'manual', casas: { heroina: casaHeroina } });
  m.entrarTodos();
  m.iniciarCombate(criaturas);
  assert.equal(estado(m).vez.figuraId, m.clientes.heroina.figuraId, 'vez da heroína');
  return m;
}
const chicotada = (m, alvoId) => recibo(m.intencao('heroina', { tipo: 'atacar', alvoId, arma: 'chicote-teste' }));

test('ordem 15: a direito chega, mas o caminho está tapado pelas figuras — fora do alcance (opções e intenção)', () => {
  // A heroína no canto (0,0), fechada pelos dois lobos em (1,0) e (0,1). O orc em (2,2): a direito são √8 ≈ 2,8 casas
  // (≤ 6, a régua antiga dava-o ao alcance); pelo caminho das casas não há passagem.
  const m = mesa({ x: 0, y: 0 }, [['lobo-teste', { x: 1, y: 0 }], ['lobo-teste', { x: 0, y: 1 }], ['orc-teste', { x: 2, y: 2 }]]);
  const [orc] = idsDaFicha(m, 'orc-teste');
  const lobos = idsDaFicha(m, 'lobo-teste');
  const alvos = alvosDoChicote(m);
  assert.equal(alvos.includes(orc), false, 'o orc não aparece nas opções');
  for (const l of lobos) assert.ok(alvos.includes(l), 'os lobos que a fecham estão a 1 passo');
  const r = chicotada(m, orc);
  assert.notEqual(r?.estado, 'APLICADA');
  assert.equal(r?.motivo, 'acao_invalida', 'a intenção é recusada pelo servidor');
});

test('ordem 15: a direito chega (6 casas), mas o desvio à volta da figura passa do alcance — fora', () => {
  // Heroína (2,2), orc (2,8): 6 casas em linha recta = o alcance do chicote. Um lobo em (2,5) tapa a linha: o caminho
  // dá a volta (8 passos > 6).
  const m = mesa({ x: 2, y: 2 }, [['lobo-teste', { x: 2, y: 5 }], ['orc-teste', { x: 2, y: 8 }]]);
  const [orc] = idsDaFicha(m, 'orc-teste');
  const [lobo] = idsDaFicha(m, 'lobo-teste');
  assert.equal(alvosDoChicote(m).includes(orc), false, 'o orc fica fora');
  assert.ok(alvosDoChicote(m).includes(lobo), 'o lobo (3 passos) está ao alcance');
  assert.equal(chicotada(m, orc)?.motivo, 'acao_invalida');
});

test('ordem 15 (inverso): com o caminho livre, a mesma distância está ao alcance — e o ataque passa', () => {
  // A mesma geometria do teste anterior, com o lobo fora da linha: 6 passos ≤ 6 casas.
  const m = mesa({ x: 2, y: 2 }, [['lobo-teste', { x: 10, y: 10 }], ['orc-teste', { x: 2, y: 8 }]]);
  const [orc] = idsDaFicha(m, 'orc-teste');
  assert.ok(alvosDoChicote(m).includes(orc), 'o orc a 6 passos aparece');
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }), 'chicotada a 6 casas');
});

test('ordem 15 (inverso): a figura que tapa não conta quando é o próprio alvo, e o alvo atrás dela chega pelo desvio curto', () => {
  // Heroína (2,2), lobo (2,3) colado a ela, orc (2,5). A direito o orc está a 3; pelo caminho, à volta do lobo, 5 ≤ 6.
  const m = mesa({ x: 2, y: 2 }, [['lobo-teste', { x: 2, y: 3 }], ['orc-teste', { x: 2, y: 5 }]]);
  const [orc] = idsDaFicha(m, 'orc-teste');
  const [lobo] = idsDaFicha(m, 'lobo-teste');
  const alvos = alvosDoChicote(m);
  assert.ok(alvos.includes(lobo), 'o lobo vizinho');
  assert.ok(alvos.includes(orc), 'o orc pelo desvio de 5 passos');
});

test('ordem 15: a diagonal fica a 2 passos — uma técnica de 1,5 m não chega lá em nenhuma escala', () => {
  // Corpo-a-corpo: o orc na diagonal da heroína. Pelo caminho das casas são 2 passos; o piso dá 1 casa (1,5 e 2 m)
  // e 1,5 casas (1 m). A régua antiga deixava a diagonal com casa de 1 m.
  for (const casaM of [1, 1.5, 2]) {
    const m = montarMesa({ modoPadrao: 'manual' });
    m.entrarTodos();
    m.iniciarCombate([['orc-teste', { x: 3, y: 3 }]]);
    if (casaM !== 1.5) exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM }), 'escala ' + casaM);
    exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar');
    const [orc] = idsDaFicha(m, 'orc-teste');
    const r = recibo(m.enviar('mestre', {
      type: 'MASTER_ACT', intentId: 'orc-golpe', revision: m.clientes.mestre.revision, figuraId: orc,
      acao: { tipo: 'atacar', alvoId: m.clientes.heroina.figuraId, arma: 'machado-teste' },
    }));
    assert.equal(r?.motivo, 'acao_invalida', 'diagonal com casa de ' + casaM + ' m');
  }
});
