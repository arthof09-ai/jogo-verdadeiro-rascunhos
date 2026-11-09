// Ordem 12 do CM-000009 (2026-11-09), parte C: narração da caída atingida (paridade da auditoria da ordem 10).
// A MECÂNICA não muda (REF_35: golpe que acerta nela já a morrer = +1 falha, vem do motor). Este teste fixa o
// CONTRATO de que o ecrã do Mestre depende para narrar «ela, caída, piora visivelmente»:
//  - a falha nova chega ao Mestre no próprio evento `ataque`, em soMestre.soDoMestre.alvoDepois.estadoMorte;
//  - NÃO sai `estado` dela a seguir (a Vida continua 0 e o visível continua «caida») — por isso o cliente não pode
//    esperar pelo `estado` e tem de ler o `ataque`;
//  - a Party recebe o `ataque` sem soMestre (a falha é só do Mestre).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarMotorFalso } from './motor-falso.mjs';
import { montarMesa, exigirAplicada, procurarCanarios } from './ajudantes.mjs';

/** Motor falso: o 1.º golpe nela deixa-a a 0 e a morrer; golpe nela já a morrer soma +1 falha (como o VLAB real). */
function motorDaCaida() {
  const motor = criarMotorFalso();
  const base = motor.Vlab.resolverAtaque;
  motor.Vlab.resolverAtaque = (entrada) => {
    const s = base(entrada);
    if (entrada.alvo?.id !== 'heroina-teste') return s;
    const em = entrada.alvo.estadoMorte;
    if (em?.fase === 'aMorrer') {
      const falhas = (em.falhas | 0) + 1;
      return {
        ...s, resultado: 'acerto', danoAplicado: 7, totalEfectivo: 7,
        soDoMestre: { alvoDepois: { vidaActual: 0, estadoMorte: { fase: 'aMorrer', sucessos: em.sucessos | 0, falhas },
          ...(falhas >= 3 ? { morteAdjudicada: true } : {}) } },
      };
    }
    return {
      ...s, resultado: 'acerto', danoAplicado: entrada.alvo.vidaActual,
      soDoMestre: { alvoDepois: { vidaActual: 0, estadoMorte: { fase: 'aMorrer', sucessos: 0, falhas: 0 } } },
    };
  };
  // O teste de morte aguenta-se (1 sucesso): ela continua a morrer e a batalha segue.
  motor.Vlab.resolverTesteDeMorte = (entrada) => {
    const em = entrada.moribundo.estadoMorte;
    const estadoMorte = { fase: 'aMorrer', sucessos: (em.sucessos | 0) + 1, falhas: em.falhas | 0 };
    return { sucesso: true, estadoMorte, estabilizado: false, morteAdjudicada: false, desfecho: 'continua', soDoMestre: { estadoMorte } };
  };
  return motor;
}

test('ordem 12: o golpe na caída chega ao Mestre no `ataque` com a falha nova; não sai `estado`; a Party não a vê', () => {
  const m = montarMesa({ motor: motorDaCaida(), modoPadrao: 'manual' });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const h = m.clientes.heroina;
  const mestre = m.clientes.mestre;
  const orc = h.idPorNome('Orc');
  const golpe = (id) => exigirAplicada(m.enviar('mestre', {
    type: 'MASTER_ACT', intentId: id, revision: mestre.revision, figuraId: orc, acao: { tipo: 'atacar', alvoId: h.figuraId, arma: 'machado-teste' },
  }), id);
  const encerrarOrc = (id) => exigirAplicada(m.enviar('mestre', {
    type: 'MASTER_ACT', intentId: id, revision: mestre.revision, figuraId: orc, acao: { tipo: 'encerrar' },
  }), id);

  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar 1');
  golpe('golpe-1'); // cai: aMorrer 0/0 (aqui sai `estado`, o visível muda)
  encerrarOrc('orc-fim-1');
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar 2 (depois do teste de morte)');
  const her = () => m.sala.depuracao.estado().figuras[h.figuraId];
  assert.deepEqual(her().estadoMorte, { fase: 'aMorrer', sucessos: 1, falhas: 0 }, 'aguentou-se uma vez');

  const nMestre = mestre.msgs.length;
  const nHeroina = h.msgs.length;
  golpe('golpe-2'); // golpe nela já a morrer: +1 falha
  assert.deepEqual(her().estadoMorte, { fase: 'aMorrer', sucessos: 1, falhas: 1 }, 'a mecânica: +1 falha (REF_35)');
  assert.equal(m.sala.depuracao.estado().fase, 'combate', 'uma falha não acaba a batalha');

  const novosM = mestre.msgs.slice(nMestre).filter((x) => x.type === 'ROOM_EVENT');
  const at = novosM.find((x) => x.tipo === 'ataque');
  assert.ok(at, 'o Mestre recebe o ataque');
  assert.equal(at.dados.alvoId, h.figuraId);
  assert.equal(at.dados.atacanteId, orc);
  assert.equal(at.dados.ataqueDeOportunidade, false);
  assert.deepEqual(at.dados.soMestre?.soDoMestre?.alvoDepois?.estadoMorte, { fase: 'aMorrer', sucessos: 1, falhas: 1 },
    'a falha nova vem no soMestre do ataque');
  assert.equal(novosM.some((x) => x.tipo === 'estado' && x.dados.figuraId === h.figuraId), false,
    'não sai `estado` dela: o cliente do Mestre tem de ler o `ataque`');

  const novosH = h.msgs.slice(nHeroina).filter((x) => x.type === 'ROOM_EVENT');
  const atH = novosH.find((x) => x.tipo === 'ataque');
  assert.ok(atH, 'a Party vê que houve ataque');
  assert.equal(atH.dados.soMestre, undefined, 'sem soMestre na Party');
  assert.deepEqual(procurarCanarios(novosH, { chaves: ['soMestre', 'soDoMestre', 'alvoDepois', 'falhas'] }), [],
    'a falha por golpe não chega à Party');
});
