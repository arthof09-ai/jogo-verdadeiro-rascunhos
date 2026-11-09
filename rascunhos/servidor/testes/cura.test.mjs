// Ordem 7 do CM-000009: a acção de CURA no protocolo, pelas regras do site (REF_31).
//  - vlab-completo.js aplicarCura: a cura não acorda quem está a morrer, não ressuscita, não passa da Vida cheia;
//    o total fica em soDoMestre.
//  - jogo.js vlabAplicarCuraDepois (Q4): sobre a estabilizada (1 de Vida, caída), a cura soma por cima do 1; a marca
//    sai, ela levanta-se e a rotação volta a dar-lhe a vez (passarVez já não a salta).
// Caminho completo: a heroína cai, fica a morrer (não se pode curar), estabiliza (1 de Vida, a vez salta), a aliada
// cura-a (1 + cura), ela levanta-se e, na vez dela, anda e ataca.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { carregarFichas } from '../nucleo/carregar-fichas.js';
import { criarMotorFalso } from './motor-falso.mjs';
import { montarMesa, listaDeFichas, recibo, exigirAplicada } from './ajudantes.mjs';

const CURA = 7;
const TECNICA_CURA = {
  id: 'cura-teste', nome: 'Cura de Teste', expressaoAtaque: '1d20+1', expressaoDano: '1d4', tipo: 'cortante',
  expressaoCura: '1d8+2', custoPA: 3, alcanceM: 9, usaArma: false,
};

function fichasComCura() {
  const lista = listaDeFichas({ comAliada: true });
  lista.find((f) => f.id === 'aliada-teste').tecnicas.push(JSON.parse(JSON.stringify(TECNICA_CURA)));
  const r = carregarFichas(lista);
  if (!r.ok) throw new Error('fichas inválidas: ' + JSON.stringify(r.erros));
  return r.fichas;
}

/** Motor falso: o orc deita a heroína a 0 (aMorrer); os testes de morte seguem `desfechos` (continua → estabilizado). */
function motorDaCura(desfechos) {
  const motor = criarMotorFalso({ cura: CURA, faceCura: 5 });
  const ataqueBase = motor.Vlab.resolverAtaque;
  motor.Vlab.resolverAtaque = (entrada) => {
    const s = ataqueBase(entrada);
    if (entrada.alvo?.id !== 'heroina-teste') return s;
    if (entrada.alvo?.estadoMorte?.fase) return { ...s, resultado: 'acerto', danoAplicado: 0, soDoMestre: {} };
    return {
      ...s, resultado: 'acerto', danoAplicado: entrada.alvo.vidaActual,
      soDoMestre: { alvoDepois: { vidaActual: 0, estadoMorte: { fase: 'aMorrer', sucessos: 0, falhas: 0 } } },
    };
  };
  const testes = [];
  motor.Vlab.resolverTesteDeMorte = (entrada) => {
    testes.push(JSON.parse(JSON.stringify(entrada)));
    const desfecho = desfechos[Math.min(testes.length, desfechos.length) - 1];
    const estab = desfecho === 'estabilizado';
    const estadoMorte = estab ? { fase: 'estabilizado', sucessos: 3, falhas: 0 } : { fase: 'aMorrer', sucessos: 1, falhas: 0 };
    return {
      cd: 10, cdEfectiva: 10, sucesso: true, estadoMorte, estabilizado: estab, morteAdjudicada: false, morteVia: null, desfecho,
      publico: { recibo: { texto: estab ? 'estabilizou' : 'aguenta' } }, soDoMestre: { cd: 10, cdEfectiva: 10, estadoMorte },
    };
  };
  return { motor, testes };
}

function figura(m, id) {
  return m.sala.depuracao.estado().figuras[id];
}

function mestreEncerra(m, figuraId, rotulo) {
  exigirAplicada(m.enviar('mestre', {
    type: 'MASTER_ACT', intentId: m.novoId('act'), revision: m.clientes.mestre.revision, figuraId, acao: { tipo: 'encerrar' },
  }), rotulo);
}

test('cura (ordem 7, site REF_31): a estabilizada curada soma a cura por cima do 1, levanta-se e age na vez dela', () => {
  const { motor, testes } = motorDaCura(['continua', 'estabilizado']);
  const m = montarMesa({ motor, comAliada: true, comEspectador: true, fichas: fichasComCura(), casas: { aliada: { x: 8, y: 2 } } });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const h = m.clientes.heroina;
  const a = m.clientes.aliada;
  const her = h.figuraId;
  const ali = a.figuraId;
  const orc = h.idPorNome('Orc');

  // Rodada 1: a heroína e a aliada encerram; o orc (auto, adjacente) deita a heroína a 0.
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'heroína encerra 1');
  assert.deepEqual(a.opcoes.curas, [], 'ninguém ferido: sem curas (CURA_ALVO_VIDA_CHEIA)');
  exigirAplicada(m.intencao('aliada', { tipo: 'encerrar' }), 'aliada encerra 1');
  assert.equal(testes.length, 1, 'a vez dela foi um teste de morte');
  assert.equal(figura(m, her).estadoMorte?.fase, 'aMorrer', 'continua a morrer');
  exigirAplicada(m.mestre('MASTER_MODE', { figuraId: orc, modo: 'manual' }), 'orc manual');

  // A morrer: a cura não a acorda (aplicarCura: CURA_SOBRE_QUEM_ESTA_A_MORRER). Nem opção, nem intenção.
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'heroína encerra 2');
  assert.equal(m.sala.depuracao.estado().vez?.figuraId, ali);
  assert.ok(!a.opcoes.curas.some((o) => o.alvoId === her), 'a morrer não aparece nas curas');
  const rec = recibo(m.intencao('aliada', { tipo: 'curar', alvoId: her, tecnica: 'cura-teste' }));
  assert.notEqual(rec?.estado, 'APLICADA', 'curar quem está a morrer é recusado');
  assert.equal(motor.chamadasCura.length, 0, 'nem chegou ao motor');
  assert.equal(figura(m, her).vidaActual, 0);
  exigirAplicada(m.intencao('aliada', { tipo: 'encerrar' }), 'aliada encerra 2');
  mestreEncerra(m, orc, 'orc encerra 2');

  // Rodada 3: estabiliza — 1 de Vida, caída, só encerrar.
  assert.equal(testes.length, 2);
  let fh = figura(m, her);
  assert.equal(fh.estadoMorte?.fase, 'estabilizado');
  assert.equal(fh.vidaActual, 1, 'Q4: volta com 1 de Vida');
  assert.equal(fh.caido, true, 'Q4: caída');
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'heroína encerra 3');

  // A aliada cura-a: a opção existe e dá APLICADA.
  assert.equal(m.sala.depuracao.estado().vez?.figuraId, ali);
  assert.deepEqual(a.opcoes.curas, [{ alvoId: her, tecnica: 'cura-teste' }], 'a estabilizada é curável (e a aliada, cheia, não)');
  const paAliadaAntes = figura(m, ali).paGasto;
  exigirAplicada(m.intencao('aliada', { tipo: 'curar', alvoId: her, tecnica: 'cura-teste' }), 'curar');
  assert.equal(motor.chamadasCura.length, 1, 'a cura passou pelo motor');
  const entrada = motor.chamadasCura[0];
  assert.equal(entrada.alvo.vidaActual, 1, 'o motor cura a partir do 1 (Q4)');
  assert.equal(entrada.alvo.estadoMorte?.fase, 'estabilizado');
  assert.equal(entrada.origem.nome, 'Cura de Teste', 'toda a cura cita a técnica que a concede (CURA_SEM_ORIGEM)');
  assert.equal(entrada.expressaoCura, '1d8+2');
  assert.equal(entrada.custoPA, 3);
  assert.ok(Number.isInteger(entrada.contexto?.semente), 'semente do servidor');
  assert.equal(entrada.forcarSemPA, undefined, 'nunca forçar sem PA');

  fh = figura(m, her);
  assert.equal(fh.vidaActual, 1 + CURA, 'a cura soma por cima do 1');
  assert.equal(fh.estadoMorte, null, 'a marca de estabilizada sai');
  assert.equal(fh.caido, false, 'levanta-se');
  assert.equal(fh.vivo, true);
  assert.equal(figura(m, ali).paGasto, paAliadaAntes + 3, 'a aliada paga o custo da técnica');
  assert.ok(!a.opcoes.curas.length && !a.opcoes.ataques.length, 'PROVISÓRIO: a cura gastou a acção padrão');

  // O que cada um vê.
  const curaH = h.eventos('cura').at(-1);
  const curaA = a.eventos('cura').at(-1);
  const curaE = m.clientes.espectador.eventos('cura').at(-1);
  assert.deepEqual(curaE.dados, { curadorId: ali, alvoId: her, tecnica: 'cura-teste' }, 'Party: quem curou quem, sem números');
  assert.deepEqual(curaH.dados, { curadorId: ali, alvoId: her, tecnica: 'cura-teste' }, 'a curada não vê os dados de quem cura');
  assert.deepEqual(curaA.dados.faces, [5], 'quem cura vê as faces dela');
  assert.equal(curaA.dados.expressao, '1d8+2');
  assert.equal(curaA.dados.total, undefined, 'o total da cura é só do Mestre');
  const estH = h.eventos('estado').filter((e) => e.dados.figuraId === her).at(-1);
  assert.equal(estH.dados.vidaActual, 1 + CURA, 'a própria sabe a Vida nova');
  assert.equal(estH.dados.estadoMorte, null);
  assert.equal(estH.dados.visivel, 'de_pe', 'de pé para ela');
  const estE = m.clientes.espectador.eventos('estado').filter((e) => e.dados.figuraId === her).at(-1);
  assert.deepEqual(estE.dados, { figuraId: her, visivel: 'de_pe' }, 'de pé para a Party, sem a Vida');
  const curaM = m.clientes.mestre.eventos('cura').at(-1);
  assert.equal(curaM.dados.soMestre.soDoMestre.curaRolada, CURA, 'o Mestre vê o total');

  // A vez volta a ela (a rotação já não a salta) e ela age: movimento cheio e ataque.
  exigirAplicada(m.intencao('aliada', { tipo: 'encerrar' }), 'aliada encerra 3');
  mestreEncerra(m, orc, 'orc encerra 3');
  const est = m.sala.depuracao.estado();
  assert.equal(est.vez?.figuraId, her, 'é a vez dela');
  assert.equal(testes.length, 2, 'sem mais testes de morte');
  assert.equal(h.opcoes.vezId, her);
  // Levantar-se pela cura não gasta o movimento (no site a queda a 0 é só da vista); com 8 de 5150 ela está Fraca
  // (Regra 7, REF_7 §5: Vida × 10 < total) e anda metade dos 9 m — a cura não lhe tirou o Fraca (aplicarCura).
  assert.equal(h.opcoes.orcamentoM, 4.5, 'reserva = metade de 9 (Fraca), e não 0');
  assert.ok(h.opcoes.mover.length > 0, 'pode andar');
  assert.ok(h.opcoes.ataques.some((o) => o.alvoId === orc), 'pode atacar');
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }), 'heroína ataca');
  const atq = h.eventos('ataque').at(-1);
  assert.equal(atq.dados.atacanteId, her, 'ela agiu na vez dela');
});

test('cura (ordem 7): sem técnica de cura não há opção; intenção forjada, mal formada ou com alvo inimigo é recusada', () => {
  const { motor } = motorDaCura(['estabilizado']);
  const m = montarMesa({ motor, comAliada: true, fichas: fichasComCura(), casas: { aliada: { x: 8, y: 2 } } });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  assert.deepEqual(h.opcoes.curas, [], 'a heroína não tem técnica de cura');
  assert.notEqual(recibo(m.intencao('heroina', { tipo: 'curar', alvoId: h.figuraId, tecnica: 'chicote-teste' }))?.estado, 'APLICADA');
  const malFormada = recibo(m.intencao('heroina', { tipo: 'curar', alvoId: h.figuraId }));
  assert.notEqual(malFormada?.estado, 'APLICADA', 'sem `tecnica`: formato');
  const aMais = recibo(m.intencao('heroina', { tipo: 'curar', alvoId: h.figuraId, tecnica: 'x', extra: 1 }));
  assert.notEqual(aMais?.estado, 'APLICADA', 'chave a mais: formato');
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  const a = m.clientes.aliada;
  assert.notEqual(recibo(m.intencao('aliada', { tipo: 'curar', alvoId: orc, tecnica: 'cura-teste' }))?.estado, 'APLICADA',
    'não cura o inimigo (o orc nem está ferido nem é aliado)');
  assert.equal(motor.chamadasCura.length, 0);
  assert.deepEqual(a.opcoes.curas, []);
});
