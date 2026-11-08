// Teste de morte (JV1.1-b, REF_7 §1): a jogadora a morrer nunca sai da ordem; a vez dela vira teste de morte.
// Motor falso com duas pontas trocadas: o ataque à heroína deixa-a a 0 de Vida e 'aMorrer' (como o VLAB real
// devolve em soDoMestre.alvoDepois), e o teste de morte devolve a forma REAL (estadoMorte no topo, morteAdjudicada,
// desfecho, soDoMestre.cd). A CD é um canário: é só do Mestre e nunca pode chegar à Party.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarMotorFalso } from './motor-falso.mjs';
import { montarMesa, recibo, exigirAplicada, procurarCanarios } from './ajudantes.mjs';

const CD_CANARIO = 8642;

function motorDeMorte(desfecho) {
  const motor = criarMotorFalso();
  const ataqueBase = motor.Vlab.resolverAtaque;
  const testes = [];
  motor.Vlab.resolverAtaque = (entrada) => {
    if (entrada.alvo?.id !== 'heroina-teste') return ataqueBase(entrada);
    const s = ataqueBase(entrada);
    // Já fora de combate (a morrer ou estabilizada): este teste NÃO decide se um golpe a volta a pôr a morrer —
    // é a pergunta de regra da JV1.1-b §9 («a jogadora a morrer continua a ser alvo?»), que vai à R0. O golpe
    // aqui não mexe no estado; assim o teste mede só a máquina de turnos. TODO(R0): trocar pela palavra do Mestre.
    if (entrada.alvo?.estadoMorte?.fase) return { ...s, resultado: 'acerto', danoAplicado: 0, soDoMestre: {} };
    return {
      ...s, resultado: 'acerto', danoAplicado: entrada.alvo.vidaActual,
      soDoMestre: { alvoDepois: { vidaActual: 0, estadoMorte: { fase: 'aMorrer', sucessos: 0, falhas: 0 } } },
    };
  };
  motor.Vlab.resolverTesteDeMorte = (entrada) => {
    testes.push(JSON.parse(JSON.stringify(entrada)));
    const morreu = desfecho === 'morreu';
    const estadoMorte = morreu ? { fase: 'aMorrer', sucessos: 0, falhas: 3 } : { fase: 'estabilizado', sucessos: 3, falhas: 0 };
    return {
      cd: CD_CANARIO, cdEfectiva: CD_CANARIO, sucesso: !morreu, estadoMorte,
      estabilizado: !morreu, morteAdjudicada: morreu, morteVia: morreu ? 'testesDeMorte' : null, desfecho,
      publico: { recibo: { texto: morreu ? 'falhou' : 'estabilizou' } },
      soDoMestre: { cd: CD_CANARIO, cdEfectiva: CD_CANARIO, estadoMorte },
    };
  };
  return { motor, testes };
}

/** Heroína encerra; o orc (auto, adjacente) ataca-a; a vez volta a ela, já a morrer. */
function levarHeroinaAMorrer(desfecho) {
  const { motor, testes } = motorDeMorte(desfecho);
  const m = montarMesa({ motor });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const h = m.clientes.heroina;
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar 1');
  return { m, h, testes };
}

test('morte: a heroína a 0 de Vida não sai da ordem, a vez dela é um teste de morte e estabilizar acaba a batalha (como no site)', () => {
  const { m, h, testes } = levarHeroinaAMorrer('estabilizado');
  const est = m.sala.depuracao.estado();
  const her = Object.values(est.figuras).find((f) => f.fichaId === 'heroina-teste' || f.id === h.figuraId);
  assert.ok(her, 'a heroína existe no estado');
  assert.equal(testes.length, 1, 'houve exatamente um teste de morte, na vez dela');
  assert.equal(testes[0].moribundo.testesDeMorteDesignado, true, 'a jogadora vai designada para o teste (VLAB real exige)');
  assert.equal(testes[0].moribundo.estadoMorte?.fase, 'aMorrer', 'o motor recebe o estadoMorte a morrer');
  assert.ok(Number.isInteger(testes[0].contexto?.semente), 'o teste usa a semente do servidor');
  assert.equal(her.estadoMorte?.fase, 'estabilizado', 'a saída real (estadoMorte no topo) foi aplicada');
  assert.equal(her.vivo, true, 'estabilizada continua viva');
  assert.ok(h.eventos('teste_morte').length >= 1, 'a jogadora vê que houve teste de morte');
  // Regra-mãe do Mestre (08/11): como no site, estabilizar ACABA a batalha (desfecho 'estabilizada').
  assert.equal(est.fase, 'fim', 'estabilizada: a batalha acaba, como no site');
  assert.equal(est.desfecho, 'estabilizada');
  const fim = h.eventos('fim');
  assert.equal(fim.length, 1, 'a jogadora recebe o fim uma vez');
  assert.equal(fim[0].dados?.desfecho, 'estabilizada');
  const r = recibo(m.intencao('heroina', { tipo: 'encerrar' }));
  assert.equal(r?.type, 'ROOM_REJECT', 'depois do fim não há vez');
  assert.equal(testes.length, 1, 'estabilizada não volta a fazer teste de morte');

  // Privacidade: a CD é só do Mestre.
  assert.deepEqual(procurarCanarios(h.msgs, { numeros: [CD_CANARIO], chaves: ['cd', 'cdEfectiva', 'soDoMestre'] }), [],
    'a CD do teste de morte não chega à jogadora');
  assert.ok(procurarCanarios(m.clientes.mestre.msgs, { numeros: [CD_CANARIO] }).length > 0, 'o Mestre vê a CD');
});

test('morte: três falhas → morteAdjudicada → a jogadora morre e a partida acaba em morte', () => {
  const { m, h, testes } = levarHeroinaAMorrer('morreu');
  assert.equal(testes.length, 1, 'houve o teste de morte');
  const est = m.sala.depuracao.estado();
  const her = Object.values(est.figuras).find((f) => f.fichaId === 'heroina-teste' || f.id === h.figuraId);
  assert.equal(her.vivo, false, 'morteAdjudicada:true mata a jogadora');
  assert.equal(est.fase, 'fim', 'sem jogadoras vivas, a partida acaba');
  assert.equal(est.desfecho, 'morte');
  const fim = h.eventos('fim');
  assert.equal(fim.length, 1, 'a jogadora recebe o fim uma vez');
  assert.equal(fim[0].dados?.desfecho, 'morte');
  assert.deepEqual(procurarCanarios(h.msgs, { numeros: [CD_CANARIO], chaves: ['cd', 'cdEfectiva', 'soDoMestre'] }), [],
    'a CD não chega à jogadora');
  // Depois do fim, nada se aceita.
  const r = recibo(m.intencao('heroina', { tipo: 'encerrar' }));
  assert.equal(r?.type, 'ROOM_REJECT', 'depois do fim não há vez');
});
