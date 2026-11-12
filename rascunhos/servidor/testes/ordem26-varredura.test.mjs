// Ordem 26 do CM-000009, item 1 — varredura do servidor (V21+), pela superfície do sala.js que faltava ler: as regras de
// combate (opções, movimento, ataque de oportunidade, vez, teste de morte, fim, IA), os recibos, o ritmo, a consulta,
// a entrada (ROOM_JOIN e o travão) e o MASTER_SEARCH. O teste de correcção falhava antes (conferido com o sala.js de
// 801a614) e passa depois; os de controlo passavam antes.
//
//  V21  O ataque de oportunidade escolhia a técnica com `t.usaArma && f.armaQuebrada`, mas a regra do VLAB real (e do
//       resto da sala: `usaArmaDe`, nas opções) é «sem o campo `usaArma`, a técnica USA arma». Um monstro com a arma
//       quebrada e uma técnica sem o campo (a `mordida-teste` da fixture) ia ao motor com essa técnica — o VLAB real
//       recusa (ARMA_QUEBRADA) e fica `erro_motor`, com a reacção do monstro gasta —, mesmo quando tinha outra técnica
//       sem arma que chegava. Agora usa a mesma regra das opções.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, listaDeFichas, exigirAplicada } from './ajudantes.mjs';
import { carregarFichas } from '../nucleo/carregar-fichas.js';

const estado = (m) => m.sala.depuracao.estado();
const abertos = (m) => estado(m).cartoes.filter((c) => c.estado === 'aberto');
const idDaFicha = (m, fichaId) => Object.values(estado(m).figuras).find((f) => f.fichaId === fichaId)?.id;
const chamadasAoO = (m) => m.motor.chamadas.filter((c) => c.contexto?.ataqueDeOportunidade === true);

function fichasComLobo(tecnicasExtra) {
  const lista = listaDeFichas();
  const lobo = lista.find((f) => f.id === 'lobo-teste');
  lobo.tecnicas.push(...tecnicasExtra);
  const r = carregarFichas(lista);
  if (!r.ok) throw new Error('fixture inválida: ' + JSON.stringify(r.erros));
  return r.fichas;
}

/**
 * Heroína em (2,2), lobo adjacente em (3,2). Ela encerra; na vez do lobo (auto) a IA ataca com a `mordida-teste` (sem o
 * campo `usaArma`), falha crítica → cartão → o Mestre escolhe «arma-quebra»: o lobo fica com a arma quebrada. De
 * volta à vez dela, ela sai para (2,0) e o lobo, ainda com a reacção, ataca de oportunidade.
 */
function loboDeArmaQuebrada(fichas) {
  const m = montarMesa({ fichas, modoPadrao: 'auto' });
  m.entrarTodos();
  m.iniciarCombate([['lobo-teste', { x: 3, y: 2 }]]);
  const h = m.clientes.heroina;
  const lobo = idDaFicha(m, 'lobo-teste');
  assert.equal(estado(m).vez.figuraId, h.figuraId, 'a heroína tem a vez');
  m.motor.cfg.resultado = 'falha_critica';
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar');
  const [c] = abertos(m);
  assert.equal(c?.figuraId, lobo, 'o cartão da desgraça do lobo está aberto');
  assert.equal(c.tecnicaId, 'mordida-teste');
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: c.cartaoId, decisao: 'editar', edicao: { desgraca: 'arma-quebra' } }), 'arma-quebra');
  m.motor.cfg.resultado = 'erro';
  assert.equal(estado(m).figuras[lobo].armaQuebrada, true, 'o lobo ficou com a arma quebrada');
  assert.equal(estado(m).vez.figuraId, h.figuraId, 'a vez voltou a ela');
  assert.equal(estado(m).figuras[lobo].reacaoDisponivel, true, 'o lobo ainda tem a reacção');
  const antes = chamadasAoO(m).length;
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 2, y: 0 } }), 'sair');
  return { m, h, lobo, novas: chamadasAoO(m).slice(antes) };
}

test('V21: AoO de monstro com a arma quebrada usa a técnica sem arma, não a que não declara `usaArma`', () => {
  const garras = { id: 'garras-teste', nome: 'Garras', expressaoAtaque: '1d20+2', expressaoDano: '1d4', tipos: ['corte'], alcanceM: 3, custoPA: 0, usaArma: false };
  const { novas } = loboDeArmaQuebrada(fichasComLobo([garras]));
  assert.equal(novas.length, 1, 'um ataque de oportunidade');
  assert.equal(novas[0].tecnica.id, 'garras-teste', 'a mordida (sem `usaArma` = usa arma) está quebrada');
});

test('V21: AoO de monstro com a arma quebrada e só técnicas de arma não vai ao motor e não gasta a reacção', () => {
  const { m, lobo, novas } = loboDeArmaQuebrada(listaDeFichasCarregadas());
  assert.equal(novas.length, 0, 'sem técnica que sirva, não há AoO');
  assert.equal(estado(m).figuras[lobo].reacaoDisponivel, true, 'a reacção fica');
  assert.equal(m.sala.depuracao.eventos().filter((e) => e.tipo === 'erro_motor').length, 0);
});

test('V21 (controlo): monstro com a arma inteira continua a atacar de oportunidade com a técnica de arma', () => {
  const m = montarMesa({ modoPadrao: 'auto' });
  m.entrarTodos();
  m.iniciarCombate([['lobo-teste', { x: 3, y: 2 }]]);
  m.motor.cfg.resultado = 'erro';
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 2, y: 0 } }), 'sair');
  const aoo = chamadasAoO(m);
  assert.equal(aoo.length, 1);
  assert.equal(aoo[0].tecnica.id, 'mordida-teste');
});

function listaDeFichasCarregadas() {
  const r = carregarFichas(listaDeFichas());
  if (!r.ok) throw new Error('fixture inválida');
  return r.fichas;
}
