// Ordem 15 do CM-000009 (2026-11-10), parte D — palavra do Mestre: apagar-se SEM chuva, como no site
// (jogo-t1/jogo.js rfPodeApagarFogo e a acção 'apagar-fogo', RF_FIM_SECO = 'acao-movimento'): quem está a arder,
// fora de uma casa a arder e sem chuva, gasta a Acção de Movimento da vez a apagar-se (a reserva zera; o ataque
// continua livre). Com chuva continua automático (ordem 13). No site só a jogadora o faz («a IA dos monstros não o
// faz nesta casca»).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as Amb from '../nucleo/ambiente.js';
import { montarMesa, exigirAplicada, recibo, procurarCanarios } from './ajudantes.mjs';

/** Dado com roteiro: [[faces, valor], ...]; acabado, sai o máximo (sem extinção, sem raio automático). */
function roteiro(passos = []) {
  const fila = passos.slice();
  const dado = (faces) => {
    if (!fila.length) return faces;
    const [f, v] = fila.shift();
    assert.equal(faces, f, `o servidor pediu d${faces}, o roteiro esperava d${f}`);
    return v;
  };
  return dado;
}
const casa20 = (x, y) => y * 20 + x + 1;
const raioEm = (x, y, comb = 6) => [[400, casa20(x, y)], [6, comb], [6, comb], [6, comb], [6, comb], [6, comb]];

/** O raio pedido cai nela em (2,2) no início da rodada 2 (tempestade): ela arde, na casa a arder, na vez dela. */
function aArderNaVezDela() {
  const m = montarMesa({ modoPadrao: 'manual', comEspectador: true, dadoAmbiente: roteiro([...raioEm(2, 2), [6, 6], [8, 1]]) });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 9 }]]);
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { clima: 'tempestade', raios: true }), 'tempestade');
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { raioAgora: true }), 'raio agora');
  const h = m.clientes.heroina;
  const orcId = h.idPorNome('Orc');
  const estado = () => m.sala.depuracao.estado();
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar');
  exigirAplicada(m.enviar('mestre', {
    type: 'MASTER_ACT', intentId: 'orc-enc', revision: m.clientes.mestre.revision, figuraId: orcId, acao: { tipo: 'encerrar' },
  }), 'encerrar orc');
  assert.equal(estado().rodada, 2);
  assert.equal(estado().vez.figuraId, h.figuraId);
  assert.deepEqual(estado().fogo.aArder, [h.figuraId], 'ela arde');
  const opcoes = () => h.ultimo('ROOM_OPTIONS');
  return { m, h, orcId, estado, opcoes };
}

test('ordem 15 (ambiente.js): podeApagarSeco — a arder, fora do fogo e SEM chuva; com chuva ou na casa a arder, não', () => {
  const m = {
    mapa: { largura: 20, altura: 20, casaM: 1.5 }, ambiente: { clima: 'limpo', raios: false }, rodada: 2,
    figuras: { a: { id: 'a', lado: 'jogadora', colocada: true, vivo: true, x: 5, y: 5 } },
    fogo: { casas: [{ x: 1, y: 1, combustivel: 3 }], aArder: ['a'], ultimoTick: {}, rodadaResolvida: 2 },
  };
  const a = m.figuras.a;
  assert.equal(Amb.podeApagarSeco(m, a), true, 'a arder, fora do fogo, sem chuva');
  m.ambiente.clima = 'chuva';
  assert.equal(Amb.podeApagarSeco(m, a), false, 'com chuva pouca, não (é automático)');
  m.ambiente.clima = 'tempestade';
  assert.equal(Amb.podeApagarSeco(m, a), false, 'com chuva forte, não');
  m.ambiente.clima = 'limpo';
  a.x = 1; a.y = 1;
  assert.equal(Amb.podeApagarSeco(m, a), false, 'na casa a arder, não (o site: fora de qualquer casa a arder)');
  a.x = 5; a.y = 5;
  m.fogo.aArder = [];
  assert.equal(Amb.podeApagarSeco(m, a), false, 'quem não arde não tem fogo para apagar');
  assert.equal(Amb.apagarSeco(m, a), null);
  m.fogo.aArder = ['a'];
  assert.deepEqual(Amb.apagarSeco(m, a), { tipo: 'apagado', figuraId: 'a', porque: 'seco' });
  assert.deepEqual(m.fogo.aArder, []);
});

test('ordem 15: com chuva a opção nunca aparece (na casa a arder; e ao sair a chuva apaga-a sozinha)', () => {
  const { m, h, estado, opcoes } = aArderNaVezDela();
  assert.equal(opcoes().acoes.includes('apagar_fogo'), false, 'na casa a arder e com chuva');
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 5, y: 2 } }), 'sair do fogo');
  assert.deepEqual(estado().fogo.aArder, [], 'a chuva apagou-a (ordem 13, sem mudança)');
  assert.equal(opcoes().acoes.includes('apagar_fogo'), false);
  assert.equal(recibo(m.intencao('heroina', { tipo: 'apagar_fogo' }))?.motivo, 'acao_invalida', 'sem a opção, recusado');
  assert.ok(h.figuraId);
});

test('ordem 15: sem chuva, fora do fogo — «apagar_fogo» gasta a Acção de Movimento e ela deixa de arder', () => {
  const { m, h, estado, opcoes } = aArderNaVezDela();
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { clima: 'limpo' }), 'a chuva pára');
  assert.equal(opcoes().acoes.includes('apagar_fogo'), false, 'ainda na casa a arder: não');
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 5, y: 2 } }), 'sair do fogo');
  assert.deepEqual(estado().fogo.aArder, [h.figuraId], 'sem chuva, sair não apaga');
  assert.ok(opcoes().acoes.includes('apagar_fogo'), 'a arder, fora do fogo, sem chuva: a opção aparece');
  assert.ok(opcoes().orcamentoM > 0, 'ainda tem reserva');

  const nH = h.msgs.length;
  const nE = m.clientes.espectador.msgs.length;
  exigirAplicada(m.intencao('heroina', { tipo: 'apagar_fogo' }), 'apagar o fogo');
  assert.deepEqual(estado().fogo.aArder, [], 'apagou-se');
  assert.equal(estado().vez.reservaM, 0, 'gastou a Acção de Movimento (a reserva zera)');
  assert.equal(estado().vez.atacou, false, 'o ataque continua livre');
  assert.equal(opcoes().orcamentoM, 0);
  assert.deepEqual(opcoes().mover, [], 'já não anda nesta vez');
  assert.equal(opcoes().acoes.includes('apagar_fogo'), false, 'já não arde');
  assert.equal(estado().vez.figuraId, h.figuraId, 'a vez continua dela');

  for (const c of [h, m.clientes.espectador]) {
    const fogo = c.msgs.slice(c === h ? nH : nE).filter((x) => x.type === 'ROOM_EVENT' && x.tipo === 'fogo').at(-1);
    assert.deepEqual(fogo?.dados.apagados, [{ figuraId: h.figuraId, porque: 'seco' }], 'a mesa vê que ela se apagou');
    assert.deepEqual(fogo.dados.aArder, []);
  }
  assert.deepEqual(procurarCanarios(h.msgs.slice(nH), { chaves: ['soMestre', 'combustivel'] }), [], 'nada do Mestre');
});

test('ordem 15: a heroína parada na vez dela sem chuva e fora do fogo também pode (o site não pede reserva por gastar)', () => {
  const { m, h, estado, opcoes } = aArderNaVezDela();
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { clima: 'limpo' }), 'a chuva pára');
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 5, y: 2 } }), 'sair do fogo');
  // Gasta o resto da reserva a andar; a opção continua (o site zera a reserva sem a pedir).
  const mais = opcoes().mover.filter((o) => o.y === 2 && o.x > 5).sort((a, b) => b.custoM - a.custoM)[0];
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: mais.x, y: mais.y } }), 'andar o resto');
  assert.ok(opcoes().acoes.includes('apagar_fogo'));
  exigirAplicada(m.intencao('heroina', { tipo: 'apagar_fogo' }), 'apagar');
  assert.deepEqual(estado().fogo.aArder, []);
  assert.ok(h.figuraId);
});
