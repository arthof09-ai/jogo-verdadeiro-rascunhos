// ORDEM-D-AUD-07-REGISTO (24/11/2026): o rótulo de cada linha do Registo do Mestre diz QUEM FEZ A JOGADA.
// Cada linha é um ponto de «voltar» (MASTER_VIEW.pontos), um por transacção. A `rodada`/`vezId` do ponto são o estado
// DEPOIS da transacção (para onde o «voltar» vai); numa transacção que fecha uma vez, isso já é a figura seguinte (e, no
// fim da volta, a rodada seguinte). Por isso o ponto leva também `autorId`/`rodadaAutor`: a vez e a rodada de ANTES.
// Reprodução do defeito (auditoria r-40, INVESTIGA l30): «Rodada 2 · vez de Heroína Teste · Ação do monstro, vez nova»
// era o encerrar da IA do orc na rodada 1.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada } from './ajudantes.mjs';

function pedirVista(m) {
  const v = m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW');
  assert.ok(v, 'o Mestre recebe a vista');
  return v;
}

/** Duas voltas: a heroína encerra, a IA do orc (auto) joga e encerra, a heroína encerra outra vez. */
function duasVoltas() {
  const m = montarMesa({ modoPadrao: 'auto' });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  const v0 = pedirVista(m);
  const id = Object.fromEntries(v0.mestre.figuras.map((f) => [f.fichaId, f.id]));
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  return { m, v: pedirVista(m), her: id['heroina-teste'], orc: id['orc-teste'] };
}

test('D-AUD-07: o encerrar da IA do orc na rodada 1 fica rotulado com o orc e a rodada 1, mesmo com a vez já da heroína na rodada 2', () => {
  const { v, her, orc } = duasVoltas();
  const p = v.pontos.find((x) => x.tipos.includes('ia') && x.tipos.includes('turno'));
  assert.ok(p, 'há o ponto do encerrar da IA (ia + turno na mesma transacção)');
  // O estado do «voltar» não muda: depois da transacção é a vez da heroína, rodada 2.
  assert.equal(p.vezId, her, 'vezId = a vez DEPOIS (a heroína)');
  assert.equal(p.rodada, 2, 'rodada = a rodada DEPOIS (2)');
  // O rótulo: quem fez a jogada, na rodada em que a fez.
  assert.equal(p.autorId, orc, 'autorId = o orc, que encerrou');
  assert.equal(p.rodadaAutor, 1, 'rodadaAutor = 1, a rodada em que o orc jogou');
});

test('D-AUD-07: o encerrar da heroína fica rotulado com a heroína (não com o orc que vem a seguir)', () => {
  const { v, her, orc } = duasVoltas();
  const encerrares = v.pontos.filter((x) => x.tipos.length === 1 && x.tipos[0] === 'turno');
  assert.equal(encerrares.length, 2, 'os dois encerrar da heroína (rodadas 1 e 2)');
  for (const p of encerrares) {
    assert.equal(p.vezId, orc, 'depois do encerrar, a vez é do orc');
    assert.equal(p.autorId, her, 'mas quem encerrou foi a heroína');
    assert.equal(p.rodadaAutor, p.rodada, 'a meio da volta, a rodada não muda');
  }
  assert.deepEqual(encerrares.map((p) => p.rodadaAutor).sort(), [1, 2]);
});

test('D-AUD-07: as acções a meio da vez têm autor = vez (nada muda); o ponto inicial e o lobby não têm autor', () => {
  const { v, orc } = duasVoltas();
  const ataques = v.pontos.filter((x) => x.tipos.includes('ia') && !x.tipos.includes('turno'));
  assert.ok(ataques.length >= 2, 'a IA do orc jogou nas duas rodadas');
  for (const p of ataques) {
    assert.equal(p.autorId, orc);
    assert.equal(p.autorId, p.vezId);
    assert.equal(p.rodadaAutor, p.rodada);
  }
  for (const p of v.pontos.filter((x) => x.fase === 'lobby')) {
    assert.equal(p.autorId, null, `ponto ${p.journalSeq} (${p.tipos}) sem autor`);
    assert.equal(p.rodadaAutor, 0);
  }
  // O START (colocação + primeira vez): antes dele não havia vez nem rodada.
  const start = v.pontos.find((x) => x.tipos.includes('colocacao') && x.tipos.includes('turno'));
  assert.ok(start, 'há o ponto do START');
  assert.equal(start.autorId, null);
  assert.equal(start.rodadaAutor, 0);
});

test('D-AUD-07: os campos novos vão só nos pontos do Mestre (nenhuma mensagem da Party leva pontos nem rodadaAutor)', () => {
  // O `autorId` já existe, público, nos eventos `dano` (projecao.js); o que não pode sair é o ponto do «voltar».
  const m = montarMesa({ comAliada: true, comEspectador: true, modoPadrao: 'auto' });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  assert.ok(pedirVista(m).pontos.every((p) => 'autorId' in p && 'rodadaAutor' in p), 'o Mestre recebe os campos novos');
  for (const chave of ['heroina', 'aliada', 'espectador']) {
    for (const msg of m.clientes[chave].msgs) {
      assert.equal(msg.pontos, undefined, `${chave} recebeu pontos em ${msg.type}`);
      assert.ok(!JSON.stringify(msg).includes('"rodadaAutor"'), `${chave} recebeu rodadaAutor em ${msg.type}`);
    }
  }
});
