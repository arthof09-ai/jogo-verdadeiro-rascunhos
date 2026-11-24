// ORDEM-PLANO-2-F1 (CM-000009, 23/11/2026), item 2 — D-AUD-12: as criaturas da mesma ficha ganham número.
// Ao colocar (MASTER_PLACE), a figura recebe um `ordinal` guardado nela; o nome público e o nome verdadeiro projectados
// passam a «Orc 1», «Orc 2», … (formato do Plano 2, F1 item 5) — no evento `colocacao`, no snapshot da Party, na vista
// do Mestre e, por eles, na lista, no tabuleiro, na caixa, no Registo e na exportação. Salas e journals de antes não têm
// o campo: o nome fica sem sufixo, como hoje. O «Recomeçar» e o «voltar» ficam com o número da figura.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import { ErroJournal } from '../nucleo/journal.js';
import { jsonCanonico } from '../nucleo/util.js';
import { sha256Hex } from '../nucleo/sha256.js';
import { figuraPublica, figuraDoMestre, comOrdinal } from '../nucleo/projecao.js';
import { carregarFichas } from '../nucleo/carregar-fichas.js';
import { montarMesa, exigirAplicada, listaDeFichas, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const estado = (m) => m.sala.depuracao.estado();
const vista = (m) => m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW');
const nomesColocados = (c) => c.eventos('colocacao').map((e) => e.dados.nomePublico);

function doisOrcsEUmLobo() {
  const m = montarMesa({ comEspectador: true });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['orc-teste', { x: 5, y: 6 }], ['lobo-teste', { x: 9, y: 9 }]]);
  return m;
}

test('D-AUD-12: dois orcs da mesma ficha — «Orc 1» e «Orc 2» na colocação e no snapshot da Party; o lobo é «Lobo 1»', () => {
  const m = doisOrcsEUmLobo();
  for (const chave of ['heroina', 'espectador']) {
    const c = m.clientes[chave];
    assert.deepEqual(nomesColocados(c), ['Heroína Teste', 'Orc 1', 'Orc 2', 'Lobo 1'], `${chave}: os nomes das colocações`);
  }
  // O snapshot seguinte (o do «Recomeçar», que vai a todos) leva os mesmos nomes.
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar');
  const h = m.clientes.heroina;
  const snap = h.ultimo('ROOM_SNAPSHOT');
  assert.deepEqual(snap.figuras.map((f) => f.nomePublico).sort(), ['Heroína Teste', 'Lobo 1', 'Orc 1', 'Orc 2']);
  // A Party só vê o número dentro do nome: nenhuma chave nova nas figuras dela.
  for (const f of snap.figuras) assert.deepEqual(Object.keys(f).sort(), ['id', 'lado', 'nomePublico', 'orientacao', 'visivel', 'x', 'y']);
  const orc2 = Object.values(estado(m).figuras).find((f) => f.fichaId === 'orc-teste' && f.ordinal === 2).id;
  assert.equal(h.idPorNome('Orc 2'), orc2, '«Orc 2» é a figura com o ordinal 2');
});

test('D-AUD-12: o Mestre vê o nome verdadeiro e o público com o número; o estado guarda o ordinal na figura', () => {
  const m = doisOrcsEUmLobo();
  const v = vista(m);
  const porNome = Object.fromEntries(v.mestre.figuras.map((f) => [f.nomePublico, f]));
  assert.equal(porNome['Orc 1'].nome, 'Orc Verdadeiro Teste 1');
  assert.equal(porNome['Orc 2'].nome, 'Orc Verdadeiro Teste 2');
  assert.equal(porNome['Lobo 1'].nome, 'Lobo Teste 1');
  assert.equal(porNome['Heroína Teste'].nome, 'Heroína Teste', 'a jogadora não ganha número');
  const figs = Object.values(estado(m).figuras);
  assert.deepEqual(figs.filter((f) => f.fichaId === 'orc-teste').map((f) => f.ordinal).sort(), [1, 2]);
  assert.equal(figs.find((f) => f.lado === 'jogadora').ordinal, undefined, 'a figura da jogadora não tem ordinal');
  // O journal (a exportação do Mestre) leva o nome com número no evento de cada colocação.
  const corpo = JSON.parse(m.sala.exportar().split('\n')[0]);
  const noJournal = corpo.eventos.filter((e) => e.tipo === 'colocacao').map((e) => e.dados.nomePublico);
  assert.deepEqual(noJournal, ['Heroína Teste', 'Orc 1', 'Orc 2', 'Lobo 1']);
});

test('D-AUD-12: duas fichas diferentes com o mesmo nome público contam juntas («Criatura 1», «Criatura 2») — a Party não fica a saber que são fichas diferentes', () => {
  const lista = listaDeFichas().map((f) => {
    if (f.id !== 'orc-teste' && f.id !== 'lobo-teste') return f;
    const g = structuredClone(f);
    delete g.nomePublico;
    return g;
  });
  const r = carregarFichas(lista);
  assert.ok(r.ok, JSON.stringify(r.erros));
  const m = montarMesa({ fichas: r.fichas });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 9, y: 9 }]]);
  assert.deepEqual(nomesColocados(m.clientes.heroina), ['Heroína Teste', 'Criatura 1', 'Criatura 2']);
});

test('D-AUD-12: o «Recomeçar» e o «voltar» ficam com o número da figura', () => {
  const m = doisOrcsEUmLobo();
  const antes = JSON.stringify(Object.values(estado(m).figuras).map((f) => [f.id, f.ordinal ?? null]));
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar');
  assert.equal(JSON.stringify(Object.values(estado(m).figuras).map((f) => [f.id, f.ordinal ?? null])), antes, 'recomeçar');
  const snap = m.clientes.heroina.ultimo('ROOM_SNAPSHOT');
  assert.deepEqual(snap.figuras.map((f) => f.nomePublico).sort(), ['Heroína Teste', 'Lobo 1', 'Orc 1', 'Orc 2'], 'o snapshot do recomeço');
  // O «voltar» até ao instante antes do 3.º orc: o número 3 sai com a figura e volta a ser dado à próxima (os números
  // contam as figuras que existem no estado, mortas incluídas: dentro da mesma história nunca se repetem).
  const ponto = m.sala.depuracao.journalSeq();
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'orc-teste', casa: { x: 12, y: 12 } }), 'o 3.º orc');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: ponto }), 'voltar');
  assert.equal(JSON.stringify(Object.values(estado(m).figuras).map((f) => [f.id, f.ordinal ?? null])), antes, 'voltar');
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'orc-teste', casa: { x: 13, y: 12 } }), 'outra vez o 3.º orc');
  assert.deepEqual(nomesColocados(m.clientes.heroina).slice(-1), ['Orc 3']);
});

// ---------------------------------------------------------------- journals: os de antes e os de agora

const CONFIG = () => ({
  roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
  lugares: [
    { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
    { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador },
    { papel: 'mestre', nome: 'Mestre', pin: PIN },
  ],
});
const criarDe = (restaurarDe) => criarSala({
  motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config: CONFIG(), restaurarDe,
});
const assinado = (corpo) => {
  const t = jsonCanonico(corpo);
  return t + '\n' + 'sha256:' + sha256Hex(t) + '\n';
};

test('D-AUD-12: o journal com o ordinal reabre igual (a conferência aceita o campo)', () => {
  const m = doisOrcsEUmLobo();
  const sala2 = criarDe(m.sala.exportar());
  assert.equal(sala2.depuracao.hashEstado(), m.sala.depuracao.hashEstado());
});

test('D-AUD-12: um journal de antes (sem ordinal) abre e as figuras ficam sem sufixo, como hoje', () => {
  const m = doisOrcsEUmLobo();
  const corpo = JSON.parse(m.sala.exportar().split('\n')[0]);
  for (const f of Object.values(corpo.estado.figuras)) delete f.ordinal;
  const sala2 = criarDe(assinado(corpo));
  const fichas = fichasDeTeste();
  const nomes = Object.values(sala2.depuracao.estado().figuras).map((f) => figuraPublica(f, fichas).nomePublico).sort();
  assert.deepEqual(nomes, ['Heroína Teste', 'Lobo', 'Orc', 'Orc']);
});

test('D-AUD-12: um ordinal que não é inteiro >= 1 não abre (ErroJournal com o caminho do campo)', () => {
  for (const mau of [0, -1, 1.5, '2', null]) {
    const m = doisOrcsEUmLobo();
    const corpo = JSON.parse(m.sala.exportar().split('\n')[0]);
    const [id, f] = Object.entries(corpo.estado.figuras).find(([, x]) => x.ordinal === 2);
    f.ordinal = mau;
    assert.throws(() => criarDe(assinado(corpo)), (e) => e instanceof ErroJournal && e.caminho === `figuras.${id}.ordinal`, `ordinal ${JSON.stringify(mau)}`);
  }
});

test('D-AUD-12: a projecção — sem ordinal, nada; com ordinal, « N» no público e no verdadeiro', () => {
  const fichas = fichasDeTeste();
  const base = { id: 'f9', fichaId: 'orc-teste', lado: 'criatura', x: 1, y: 1, orientacao: 'S', vivo: true };
  assert.equal(figuraPublica(base, fichas).nomePublico, 'Orc');
  assert.equal(figuraDoMestre(base, fichas).nome, 'Orc Verdadeiro Teste');
  assert.equal(figuraPublica({ ...base, ordinal: 4 }, fichas).nomePublico, 'Orc 4');
  assert.equal(figuraDoMestre({ ...base, ordinal: 4 }, fichas).nome, 'Orc Verdadeiro Teste 4');
  assert.equal(comOrdinal(null, { ordinal: 2 }), null, 'sem nome não se inventa um');
  assert.equal(comOrdinal('Orc', { ordinal: 0 }), 'Orc');
});
