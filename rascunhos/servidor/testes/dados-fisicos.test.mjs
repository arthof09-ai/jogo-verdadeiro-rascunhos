// ORDEM-F4-PARCIAL (Plano 2, F4 ponto 3; JV1.3, M-28): os dados físicos validados por intervalo, no servidor.
// A jogadora declara as faces que lhe saíram; o servidor confere cada face contra o dado da técnica em que cai (pela
// ordem do motor: os conjuntos do ataque e depois o dano) ANTES de o cartão ir ao Mestre. Dentro do intervalo:
// AGUARDANDO_MESTRE (o Mestre confirma com um toque). Fora: RECUSADA, sem cartão, sem vez gasta, e o porquê só ao
// Mestre. O cliente Godot não confere nada: tudo isto é do servidor.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, recibo } from './ajudantes.mjs';
import { conferirFacesFisicas, dadosDaExpressao } from '../nucleo/dados-fisicos.js';

// A técnica da heroína fictícia (dados-exemplo/fichas-ficticias.json): ataque 1d20+4, dano 1d6+2.
const CHICOTE = { expressaoAtaque: '1d20+4', expressaoDano: '1d6+2', tipo: 'cortante' };

test('dados da expressão: a gramática do motor (NdM(+NdM)* com bónus; objecto decomposto)', () => {
  assert.deepEqual(dadosDaExpressao('1d20+4'), [20]);
  assert.deepEqual(dadosDaExpressao('2d6+1d4-1'), [6, 6, 4]);
  assert.deepEqual(dadosDaExpressao(' 1D8 + 3 '), [8]);
  assert.deepEqual(dadosDaExpressao({ qtd: 3, faces: 10, bonus: 2 }), [10, 10, 10]);
  for (const fora of ['d20', '1d1', '5', '1d20+1d', 'abc', '', null, 7, ['1d20']]) {
    assert.equal(dadosDaExpressao(fora), null, 'fora da gramática: ' + JSON.stringify(fora));
  }
});

test('intervalo face a face: d20 do ataque e d6 do dano', () => {
  for (const ok of [[1], [20], [17], [17, 1], [17, 6], [3, 19], [3, 19, 6]]) {
    assert.equal(conferirFacesFisicas(ok, CHICOTE), null, 'cabe: ' + JSON.stringify(ok));
  }
  // 21 não sai num d20, em nenhuma leitura (nem com 2 a 5 conjuntos de ataque).
  assert.match(conferirFacesFisicas([21], CHICOTE), /face 21 fora do intervalo 1\.\.20 \(posição 1\)/);
  assert.match(conferirFacesFisicas([100], CHICOTE), /fora do intervalo 1\.\.20/);
  assert.match(conferirFacesFisicas([0], CHICOTE), /fora do intervalo/);
  // 1 conjunto + 1d6 de dano + mais faces do que o dano tem → não cabe em leitura nenhuma.
  assert.match(conferirFacesFisicas([17, 17, 17, 17, 17, 17, 17], CHICOTE), /fora do intervalo|a mais/);
  assert.match(conferirFacesFisicas([], CHICOTE), /sem faces/);
});

test('o d100 da desgraça e o dano derivado (falha crítica) cabem; o resto dos dados segue o dano', () => {
  // 1 conjunto (d20) + o d100 da desgraça + o d6 do dano derivado.
  assert.equal(conferirFacesFisicas([1, 64, 5], CHICOTE), null);
  assert.match(conferirFacesFisicas([1, 64, 7], CHICOTE), /fora do intervalo 1\.\.6 \(posição 3\)/);
});

test('componentes, repartição e testes.ataque da ficha', () => {
  const mordida = { expressaoAtaque: '1d20+5', componentes: [{ tipo: 'perfurante', expressao: '1d8+3' }] };
  assert.equal(conferirFacesFisicas([12, 8], mordida), null);
  // [12, 9] cabe (o 9 lê-se como o d100 da desgraça); [12, 50, 9] não: o 9 cai no d8 do dano derivado.
  assert.equal(conferirFacesFisicas([12, 9], mordida), null);
  assert.match(conferirFacesFisicas([12, 50, 9], mordida), /1\.\.8 \(posição 3\)/);
  const mista = { expressaoAtaque: '1d20', expressaoDano: '3d6', tipos: ['fogo', 'cortante'], reparticao: ['1d4', '1d10'] };
  assert.equal(conferirFacesFisicas([5, 4, 10], mista), null);
  assert.match(conferirFacesFisicas([5, 50, 30], mista), /1\.\.4 \(posição 3\)/);
  const semAtaque = { expressaoDano: '1d6' };
  assert.equal(conferirFacesFisicas([12], semAtaque, { testes: { ataque: '1d12+1' } }), null);
  assert.match(conferirFacesFisicas([13], semAtaque, { testes: { ataque: '1d12+1' } }), /1\.\.12/);
  assert.match(conferirFacesFisicas([5], semAtaque), /sem expressão de ataque|não tem expressão de ataque/);
});

function mesaEmCombate() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  return { m, orc: m.clientes.heroina.idPorNome('Orc') };
}

test('na sala: um valor físico DENTRO do intervalo passa — o cartão de dados vai ao Mestre', () => {
  for (const faces of [[1], [20], [17, 6]]) {
    const { m, orc } = mesaEmCombate();
    const r = m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'df-ok', dadosFisicos: { faces } });
    assert.equal(recibo(r).estado, 'AGUARDANDO_MESTRE', 'faces ' + JSON.stringify(faces));
    const cartao = m.clientes.mestre.ultimo('MASTER_CARD');
    assert.ok(cartao, 'o Mestre recebe o cartão');
    assert.deepEqual(JSON.stringify(cartao).includes(JSON.stringify(faces)), true, 'o cartão traz as faces declaradas');
  }
});

test('na sala: um valor físico FORA do intervalo é recusado — sem cartão, sem vez gasta, o porquê só ao Mestre', () => {
  for (const faces of [[21], [100], [17, 17, 17, 17, 17, 17, 17]]) {
    const { m, orc } = mesaEmCombate();
    const antesCartoes = m.clientes.mestre.msgs.filter((x) => x.type === 'MASTER_CARD').length;
    const mestreAntes = m.clientes.mestre.msgs.length;
    const heroinaAntes = m.clientes.heroina.msgs.length;
    const r = m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'df-fora', dadosFisicos: { faces } });
    const rec = recibo(r);
    assert.equal(rec.type, 'ROOM_REJECT', 'faces ' + JSON.stringify(faces));
    assert.equal(rec.motivo, 'acao_invalida');
    assert.equal(m.clientes.mestre.msgs.filter((x) => x.type === 'MASTER_CARD').length, antesCartoes, 'nenhum cartão abre');
    // O porquê vai só ao Mestre, no evento interno `recusa`.
    const recusa = m.clientes.mestre.msgs.slice(mestreAntes).find((x) => x.type === 'ROOM_EVENT' && x.tipo === 'recusa');
    assert.match(recusa?.dados?.soMestre?.detalhe ?? '', /^DADOS_FISICOS_FORA_DO_INTERVALO: /);
    const daJogadora = JSON.stringify(m.clientes.heroina.msgs.slice(heroinaAntes));
    assert.ok(!daJogadora.includes('DADOS_FISICOS'), 'a jogadora não vê o detalhe');
    // A vez continua dela e o ataque continua nas opções: a recusa não gastou nada.
    assert.ok(m.clientes.heroina.opcoes.ataques.some((o) => o.alvoId === orc), 'o ataque continua disponível');
    const r2 = m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'df-depois', dadosFisicos: { faces: [12] } });
    assert.equal(recibo(r2).estado, 'AGUARDANDO_MESTRE', 'depois da recusa, um valor dentro passa');
  }
});

test('na sala: a recusa fica gravada (o mesmo intentId devolve a mesma recusa, e a consulta dá RECUSADA)', () => {
  const { m, orc } = mesaEmCombate();
  const acao = { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' };
  const rev = m.clientes.heroina.revision;
  const r1 = recibo(m.intencao('heroina', acao, { intentId: 'df-dup', dadosFisicos: { faces: [25] }, revision: rev }));
  const r2 = recibo(m.intencao('heroina', acao, { intentId: 'df-dup', dadosFisicos: { faces: [25] }, revision: rev }));
  assert.equal(r1.type, 'ROOM_REJECT');
  assert.deepEqual(r2, r1, 'a repetição devolve a mesma recusa');
  const q = m.enviar('heroina', { type: 'RECEIPT_QUERY', intentIds: ['df-dup'] });
  assert.ok(JSON.stringify(q).includes('RECUSADA'), 'a consulta diz RECUSADA: ' + JSON.stringify(q));
});
