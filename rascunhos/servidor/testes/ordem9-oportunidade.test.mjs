// Ordem 9 do CM-000009 (2026-11-09), no servidor: cartão TAMBÉM na oportunidade (decisão do Mestre 09/11 11:29,
// «Opção C — Sim, cartão também na oportunidade»; extensão M2 da frente das desgraças dos monstros, no site).
//  - a falha crítica do ataque de oportunidade do MONSTRO passa pelo cartão do Mestre como as outras;
//  - a heroína TERMINA primeiro o movimento (já chegou ao destino) e só então o Mestre decide;
//  - valem as mesmas opções do cartão, incluindo recusar com «Não acontece nada» (sem segunda chamada ao motor);
//  - a IA propõe, só o Mestre decide: o cartão abre em qualquer modo, nada se resolve sozinho.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

const estado = (m) => m.sala.depuracao.estado();
const abertos = (m) => estado(m).cartoes.filter((c) => c.estado === 'aberto');
const idDaFicha = (m, fichaId) => Object.values(estado(m).figuras).find((f) => f.fichaId === fichaId)?.id;
const chamadasAoO = (m) => m.motor.chamadas.filter((c) => c.contexto?.ataqueDeOportunidade === true);

/**
 * Heroína em (2,2) com o orc adjacente em (2,3) (e, com `comLobo`, o lobo em (3,2)). Ela sai para (2,0): fica longe
 * de todos, por isso cada um ataca de oportunidade na chegada. A falha crítica do primeiro abre o cartão.
 */
function saidaComFalhaCritica({ comLobo = false, modoPadrao = 'auto' } = {}) {
  const m = montarMesa({ modoPadrao });
  m.entrarTodos();
  const criaturas = [['orc-teste', { x: 2, y: 3 }]];
  if (comLobo) criaturas.push(['lobo-teste', { x: 3, y: 2 }]);
  m.iniciarCombate(criaturas);
  const h = m.clientes.heroina;
  assert.equal(estado(m).vez.figuraId, h.figuraId, 'a heroína tem a vez');
  m.motor.cfg.resultado = 'falha_critica';
  const r = m.intencao('heroina', { tipo: 'mover', destino: { x: 2, y: 0 } }, { intentId: 'sai-fc' });
  return { m, h, r, orc: idDaFicha(m, 'orc-teste'), lobo: idDaFicha(m, 'lobo-teste') };
}

test('ordem 9: a falha crítica do AoO do monstro abre o cartão do Mestre DEPOIS de o movimento terminar', () => {
  const { m, h, r, orc } = saidaComFalhaCritica();
  // O movimento terminou: o recibo dela é APLICADA, ela está no destino e a reserva já foi debitada.
  assert.equal(recibo(r)?.estado, 'APLICADA', 'o movimento não fica à espera do Mestre');
  const eu = estado(m).figuras[h.figuraId];
  assert.deepEqual([eu.x, eu.y], [2, 0], 'ela já chegou ao destino');
  assert.equal(estado(m).vez.reservaM, 6, '9 m − 2 casas × 1,5 m');
  // O AoO foi ao motor em 'proposta' (já não há 'sorte') e o cartão está aberto, do orc contra ela.
  const [aoo] = chamadasAoO(m);
  assert.equal(aoo?.contexto?.modoDesgraca, 'proposta');
  assert.equal(m.motor.chamadas.some((c) => c.contexto?.modoDesgraca === 'sorte'), false, 'nunca em sorte');
  const [c] = abertos(m);
  assert.equal(c?.tipo, 'desgraca');
  assert.equal(c.figuraId, orc);
  assert.equal(c.alvoId, h.figuraId);
  assert.equal(c.ataqueDeOportunidade, true);
  // Ordem dos eventos no registo: o movimento vem antes do cartão.
  const ev = m.sala.depuracao.eventos();
  const iMov = ev.findIndex((e) => e.tipo === 'movimento');
  const iCartao = ev.findIndex((e) => e.tipo === 'cartao' && e.dados?.cartaoId === c.cartaoId);
  assert.ok(iMov >= 0 && iCartao > iMov, 'movimento primeiro, cartão depois');
  // O Mestre recebe o cartão com a lista do «Escolher outra»; nada se aplicou ainda.
  const mc = m.clientes.mestre.ultimo('MASTER_CARD');
  assert.equal(mc.cartaoId, c.cartaoId);
  assert.equal(mc.figuraId, orc);
  assert.ok(Array.isArray(mc.desgracas) && mc.desgracas.length > 0);
  assert.equal(estado(m).figuras[orc].armaCaida, false, 'a proposta não se aplicou sem o Mestre');
  assert.equal(h.eventos('desgraca').length, 0);
  // Enquanto o cartão está aberto ela não age (a IA também não).
  const rb = m.intencao('heroina', { tipo: 'encerrar' });
  assert.notEqual(recibo(rb)?.estado, 'APLICADA', 'aguardando o Mestre');
  // O Mestre confirma a proposta: a desgraça aplica-se ao orc; ela continua no destino e volta a poder agir.
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: c.cartaoId, decisao: 'aprovar' }), 'aprovar AoO');
  assert.equal(abertos(m).length, 0);
  assert.equal(estado(m).figuras[orc].armaCaida, true, 'a proposta (arma-cai) aplicou-se ao orc');
  const at = h.eventos('ataque').find((e) => e.dados?.ataqueDeOportunidade === true);
  assert.equal(at?.dados?.resultado, 'falha_critica');
  assert.deepEqual([estado(m).figuras[h.figuraId].x, estado(m).figuras[h.figuraId].y], [2, 0]);
  assert.equal(estado(m).vez.figuraId, h.figuraId, 'a vez continua a ser dela');
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'ela age depois da decisão');
});

test('ordem 9: recusar com «Não acontece nada» no AoO não chama o motor outra vez e não aplica desgraça', () => {
  const { m, h, orc } = saidaComFalhaCritica({ modoPadrao: 'manual' });
  const [c] = abertos(m);
  assert.equal(c?.ataqueDeOportunidade, true);
  const n = m.motor.chamadas.length;
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: c.cartaoId, decisao: 'recusar', edicao: { semDesgraca: true } }), 'nada (AoO)');
  assert.equal(m.motor.chamadas.length, n, 'sem segunda chamada ao motor');
  assert.equal(abertos(m).length, 0, 'o cartão fecha');
  const o = estado(m).figuras[orc];
  assert.equal(o.armaCaida, false, 'o orc fica com a arma');
  assert.equal(o.caido, false);
  assert.equal(o.reacaoDisponivel, false, 'a reação do orc gastou-se no AoO');
  assert.equal(h.eventos('desgraca').length, 0, 'a Party não vê desgraça');
  const at = h.eventos('ataque').find((e) => e.dados?.ataqueDeOportunidade === true);
  assert.equal(at?.dados?.resultado, 'falha_critica', 'a Party vê só o golpe falhado');
  assert.ok(m.clientes.mestre.eventos('acao').some((e) => e.dados?.tipo === 'sem_desgraca'), 'fica no registo do Mestre');
  assert.equal(JSON.stringify(h.msgs).includes('sem_desgraca'), false);
  assert.deepEqual([estado(m).figuras[h.figuraId].x, estado(m).figuras[h.figuraId].y], [2, 0], 'ela continua no destino');
  // «recusar» sem escolher continua a não fechar (o «← Voltar» do site) — provado na ordem 8; aqui a mesma regra:
  // um segundo pedido sobre o cartão já fechado não faz nada.
  assert.notEqual(recibo(m.mestre('MASTER_APPROVE', { cartaoId: c.cartaoId, decisao: 'recusar', edicao: { semDesgraca: true } }))?.estado, 'APLICADA');
  assert.equal(m.motor.chamadas.length, n);
});

test('ordem 9: «Escolher outra» no AoO — a desgraça escolhida pelo Mestre aplica-se ao monstro', () => {
  const { m, orc } = saidaComFalhaCritica();
  const [c] = abertos(m);
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: c.cartaoId, decisao: 'editar', edicao: { desgraca: 'cai' } }), 'editar AoO');
  const ultima = m.motor.chamadas.at(-1);
  assert.equal(ultima.contexto.modoDesgraca, 'escolha');
  assert.equal(ultima.contexto.desgracaEscolhida, 'cai');
  assert.equal(ultima.contexto.ataqueDeOportunidade, true, 'a segunda chamada continua a ser o AoO (mesma semente)');
  assert.equal(ultima.contexto.semente, c.contexto.semente);
  assert.equal(estado(m).figuras[orc].caido, true);
});

test('ordem 9: com dois monstros, a série pára no cartão e o segundo só ataca depois da decisão', () => {
  const { m, h, orc, lobo } = saidaComFalhaCritica({ comLobo: true });
  // Iniciativa: lobo antes do orc. O lobo falha crítico → cartão; o orc ainda não atacou.
  const [c] = abertos(m);
  assert.equal(c?.figuraId, lobo);
  assert.deepEqual(c.aooRestantes, [orc], 'o orc fica guardado no cartão');
  assert.equal(chamadasAoO(m).length, 1, 'só o lobo foi ao motor');
  assert.equal(estado(m).figuras[orc].reacaoDisponivel, true);
  // O Mestre recusa com «Não acontece nada»; o orc ataca a seguir (erra), e é a ÚNICA chamada nova ao motor.
  m.motor.cfg.resultado = 'erro';
  const n = m.motor.chamadas.length;
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: c.cartaoId, decisao: 'recusar', edicao: { semDesgraca: true } }), 'nada (lobo)');
  assert.equal(m.motor.chamadas.length, n + 1, 'uma chamada: o AoO do orc; o lobo não volta ao motor');
  const nova = m.motor.chamadas.at(-1);
  assert.equal(nova.contexto.ataqueDeOportunidade, true);
  assert.equal(nova.atacante.id, 'orc-teste', 'quem ataca agora é o orc (a ficha dele vai ao motor)');
  assert.equal(estado(m).figuras[orc].reacaoDisponivel, false, 'o orc gastou a reação');
  assert.equal(abertos(m).length, 0);
  assert.equal(h.eventos('ataque').filter((e) => e.dados?.ataqueDeOportunidade === true).length, 2);
});

test('ordem 9: a falha crítica do segundo monstro da série também abre cartão (um de cada vez)', () => {
  const { m, orc, lobo } = saidaComFalhaCritica({ comLobo: true });
  const [c1] = abertos(m);
  assert.equal(c1.figuraId, lobo);
  // Mantém-se a falha crítica: depois do lobo, o orc também falha crítico → segundo cartão, já sem ninguém atrás.
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: c1.cartaoId, decisao: 'aprovar' }), 'aprovar lobo');
  const [c2] = abertos(m);
  assert.equal(c2?.figuraId, orc);
  assert.deepEqual(c2.aooRestantes, []);
  assert.equal(m.clientes.mestre.ultimo('MASTER_CARD').cartaoId, c2.cartaoId, 'o Mestre recebe o segundo cartão');
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: c2.cartaoId, decisao: 'recusar', edicao: { semDesgraca: true } }), 'nada (orc)');
  assert.equal(abertos(m).length, 0);
  assert.equal(estado(m).figuras[lobo].armaCaida, true);
  assert.equal(estado(m).figuras[orc].armaCaida, false);
});
