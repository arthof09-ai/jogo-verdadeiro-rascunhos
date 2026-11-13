// Ordem 34 do CM-000009, item 7 — destino do N28-1 (regra D-1, palavra do Mestre de 12/11/2026):
//   «A personagem volta para a casa mais próxima.»
// No «Recomeçar», cada figura volta à sua casaColocacao; se essa casa é também a casa de colocação de outra figura
// colocada depois, a meio do jogo (a ocupante), a ocupante fica e quem volta vai para a casa livre mais próxima da sua
// casa de colocação; ninguém é despejado. Distância = passos do BFS do motor (4 vizinhos, dentro do mapa, as outras
// figuras vivas a bloquear, como distanciaCasas/distanciaEntre do site). Desempate: a primeira na ordem de leitura do
// mapa (linha a linha, de cima para baixo, da esquerda para a direita).
// Casos que a regra não cobre (N34-2, sem regra inventada): nenhuma casa livre alcançável, ou duas figuras que voltam a
// querer a mesma casa → o «Recomeçar» é recusado sem mexer em nada; o porquê vai só ao Mestre.
// Cada teste de correcção falhava antes (o recomecarBatalha punha duas figuras na mesma casa) e passa depois.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import { montarMesa, exigirAplicada, recibo, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const estado = (m) => m.sala.depuracao.estado();
const casa = (f) => ({ x: f.x, y: f.y });
const recusado = (r) => recibo(r)?.type === 'ROOM_REJECT';

/** Nenhuma casa com duas figuras colocadas. */
function semCasaRepetida(e, rotulo) {
  const vistas = new Map();
  for (const f of Object.values(e.figuras)) {
    if (!f.colocada) continue;
    const k = f.x + ',' + f.y;
    assert.ok(!vistas.has(k), `${rotulo}: ${vistas.get(k)} e ${f.id} na mesma casa (${k})`);
    vistas.set(k, f.id);
  }
}

/** As figuras colocadas com uma ficha, pela ordem de colocação não importa: devolve a lista. */
const comFicha = (e, fichaId) => Object.values(e.figuras).filter((f) => f.colocada && f.fichaId === fichaId);

function mover(m, chave, destino) {
  return exigirAplicada(m.intencao(chave, { tipo: 'mover', destino }), `mover ${chave} → ${destino.x},${destino.y}`);
}

function actoMestre(m, figuraId, acao, rotulo) {
  return exigirAplicada(m.enviar('mestre', {
    type: 'MASTER_ACT', intentId: m.novoId('act'), revision: m.clientes.mestre.revision, figuraId, acao,
  }), rotulo);
}

test('D-1 (N28-1): a criatura colocada a meio do jogo fica; a heroína vai para a casa livre mais próxima, sem casa repetida', () => {
  const m = montarMesa({ comEspectador: true });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 9, y: 9 }]]);
  const h = m.clientes.heroina;
  // A reprodução do README: a heroína colocada em (2,2) anda para (3,2); o Mestre coloca o lobo em (2,2).
  mover(m, 'heroina', { x: 3, y: 2 });
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 2, y: 2 } }), 'lobo em (2,2)');
  const lobo = comFicha(estado(m), 'lobo-teste')[0].id;
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar');
  const e = estado(m);
  semCasaRepetida(e, 'depois do recomeçar');
  assert.deepEqual(casa(e.figuras[lobo]), { x: 2, y: 2 }, 'a ocupante (colocada a meio do jogo) fica onde está');
  // Vizinhas livres de (2,2) a 1 passo: (2,1), (1,2), (3,2), (2,3). A primeira na leitura do mapa é (2,1).
  assert.deepEqual(casa(e.figuras[h.figuraId]), { x: 2, y: 1 }, 'a heroína vai para a casa livre mais próxima (ordem de leitura)');
  assert.deepEqual({ x: e.figuras[h.figuraId].casaColocacao.x, y: e.figuras[h.figuraId].casaColocacao.y }, { x: 2, y: 2 },
    'a casa de colocação dela não muda');
  // O que a Party vê no snapshot novo: as duas em casas diferentes.
  for (const chave of ['heroina', 'espectador']) {
    const snap = m.clientes[chave].ultimo('ROOM_SNAPSHOT');
    const casas = snap.figuras.map((f) => f.x + ',' + f.y);
    assert.equal(new Set(casas).size, casas.length, `${chave}: nenhuma casa repetida no snapshot`);
  }
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'a batalha segue');
});

test('D-1: a distância é o BFS do motor — vizinhas tomadas não contam; desempate pela ordem de leitura', () => {
  const m = montarMesa();
  m.entrarTodos();
  // Orcs colocados no lobby em (2,1) e (1,2): tapam duas vizinhas de (2,2).
  m.iniciarCombate([['orc-teste', { x: 2, y: 1 }], ['orc-teste', { x: 1, y: 2 }]]);
  const h = m.clientes.heroina;
  mover(m, 'heroina', { x: 3, y: 2 });
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 2, y: 2 } }), 'lobo em (2,2)');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar');
  const e = estado(m);
  semCasaRepetida(e, 'depois do recomeçar');
  // Livres a 1 passo: (3,2) e (2,3); a leitura do mapa dá (3,2) (linha 2 antes da linha 3).
  assert.deepEqual(casa(e.figuras[h.figuraId]), { x: 3, y: 2 });
  const orcs = comFicha(e, 'orc-teste').map(casa).sort((a, b) => a.y - b.y || a.x - b.x);
  assert.deepEqual(orcs, [{ x: 2, y: 1 }, { x: 1, y: 2 }], 'os orcs voltam às casas deles');
});

test('D-1: duas criaturas com a mesma casa de colocação — fica a última colocada; o mesmo depois de restaurar o journal', () => {
  const m = montarMesa({ modoPadrao: 'manual' });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 5, y: 5 }]]);
  const orc = comFicha(estado(m), 'orc-teste')[0].id;
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'a heroína passa a vez');
  assert.equal(estado(m).vez?.figuraId, orc, 'vez do orc');
  actoMestre(m, orc, { tipo: 'mover', destino: { x: 6, y: 5 } }, 'o orc anda');
  actoMestre(m, orc, { tipo: 'encerrar' }, 'o orc encerra');
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 5, y: 5 } }), 'lobo em (5,5)');
  const lobo = comFicha(estado(m), 'lobo-teste')[0].id;
  const exportado = m.sala.exportar();

  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar');
  const e = estado(m);
  semCasaRepetida(e, 'depois do recomeçar');
  assert.deepEqual(casa(e.figuras[lobo]), { x: 5, y: 5 }, 'o lobo (colocado depois) fica');
  assert.deepEqual(casa(e.figuras[orc]), { x: 5, y: 4 }, 'o orc vai para a vizinha livre que vem primeiro na leitura');

  // O journal grava o estado na forma canónica (chaves ordenadas): a ordem de colocação tem de sobreviver ao restauro.
  const sala2 = criarSala({
    motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), restaurarDe: exportado,
    config: {
      roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'manual', depurar: true,
      lugares: [
        { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
        { papel: 'mestre', nome: 'Mestre', pin: PIN },
      ],
    },
  });
  const r = sala2.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'mestre', pin: PIN }, { ip: '10.0.0.9' });
  assert.ok(r.ok, 'o Mestre entra na sala restaurada');
  sala2.conexaoAberta(r.seatId);
  const revisao = sala2.depuracao.estado().lugares[r.seatId].revision;
  const saidas = sala2.receber(r.seatId, {
    v: 2, roomId: 'sala-teste', type: 'MASTER_SUPERVISOR', op: 'recomecar', cmdId: 'cmd-r2', revision: revisao,
  });
  exigirAplicada(saidas.filter((s) => s.seatId === r.seatId).map((s) => s.msg), 'recomeçar na sala restaurada');
  const e2 = sala2.depuracao.estado();
  assert.deepEqual(casa(e2.figuras[lobo]), { x: 5, y: 5 }, 'restaurada: o lobo fica');
  assert.deepEqual(casa(e2.figuras[orc]), { x: 5, y: 4 }, 'restaurada: o orc vai para a mesma casa');
});

test('D-1 / N34-2: sem casa livre alcançável, o «Recomeçar» é recusado e nada muda; a Party não recebe nada', () => {
  const m = montarMesa({ comEspectador: true });
  m.entrarTodos();
  // A casa da heroína (2,2) fica cercada: orcs do lobby em (2,1), (1,2), (3,2).
  m.iniciarCombate([['orc-teste', { x: 2, y: 1 }], ['orc-teste', { x: 1, y: 2 }], ['orc-teste', { x: 3, y: 2 }]]);
  const h = m.clientes.heroina;
  mover(m, 'heroina', { x: 2, y: 4 }); // por (2,3)
  // A meio do jogo: o lobo na casa dela e um bandido na única vizinha que sobrava.
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 2, y: 2 } }), 'lobo em (2,2)');
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'bandido-teste', casa: { x: 2, y: 3 } }), 'bandido em (2,3)');
  const antes = estado(m);
  const nParty = { heroina: h.msgs.length, espectador: m.clientes.espectador.msgs.length };
  const r = m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' });
  assert.ok(recusado(r), 'recusado');
  assert.equal(recibo(r).motivo, 'acao_invalida');
  const depois = estado(m);
  assert.deepEqual(depois.figuras, antes.figuras, 'nenhuma figura mexeu');
  assert.equal(depois.rodada, antes.rodada);
  assert.equal(depois.vez?.figuraId, antes.vez?.figuraId);
  assert.equal(h.msgs.length, nParty.heroina, 'a jogadora não recebe nada');
  assert.equal(m.clientes.espectador.msgs.length, nParty.espectador, 'o espectador não recebe nada');
  const ev = m.sala.depuracao.eventos().filter((x) => x.tipo === 'recusa').at(-1);
  assert.match(JSON.stringify(ev?.soMestre ?? ev), /RECOMECAR_SEM_CASA/, 'o porquê vai só ao Mestre');
});

test('D-1 / N34-2: duas figuras que voltam a querer a mesma casa livre — recusado, nada muda', () => {
  const m = montarMesa({ comAliada: true, casas: { heroina: { x: 2, y: 2 }, aliada: { x: 2, y: 4 } } });
  m.entrarTodos();
  // (2,2) e (2,4) só têm a vizinha (2,3) livre.
  m.iniciarCombate([
    ['orc-teste', { x: 2, y: 1 }], ['orc-teste', { x: 1, y: 2 }], ['orc-teste', { x: 3, y: 2 }],
    ['orc-teste', { x: 1, y: 4 }], ['orc-teste', { x: 3, y: 4 }], ['orc-teste', { x: 2, y: 5 }],
  ]);
  mover(m, 'heroina', { x: 0, y: 3 }); // (2,3) → (1,3) → (0,3)
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'a heroína passa a vez');
  assert.equal(estado(m).vez?.figuraId, m.clientes.aliada.figuraId, 'vez da aliada');
  mover(m, 'aliada', { x: 4, y: 3 }); // (2,3) → (3,3) → (4,3)
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 2, y: 2 } }), 'lobo em (2,2)');
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'lobo-teste', casa: { x: 2, y: 4 } }), 'lobo em (2,4)');
  const antes = estado(m);
  const r = m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' });
  assert.ok(recusado(r), 'recusado');
  assert.deepEqual(estado(m).figuras, antes.figuras, 'nenhuma figura mexeu');
  const ev = m.sala.depuracao.eventos().filter((x) => x.tipo === 'recusa').at(-1);
  assert.match(JSON.stringify(ev?.soMestre ?? ev), /RECOMECAR_SEM_CASA/);
});

test('D-1 (controlo): sem colocações a meio do jogo, todas voltam à casa de colocação, como antes', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 9, y: 9 }]]);
  const h = m.clientes.heroina;
  mover(m, 'heroina', { x: 3, y: 2 });
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar');
  const e = estado(m);
  assert.deepEqual(casa(e.figuras[h.figuraId]), { x: 2, y: 2 });
  assert.deepEqual(comFicha(e, 'orc-teste').map(casa), [{ x: 2, y: 6 }]);
  assert.deepEqual(comFicha(e, 'lobo-teste').map(casa), [{ x: 9, y: 9 }]);
});
