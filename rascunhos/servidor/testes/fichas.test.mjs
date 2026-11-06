// Carregador `fichas/1` (JV0.6a §5 Aceite + ERRATA v0.2).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { carregarFichas, carregarPacote, SCHEMA_FICHAS_1 } from '../nucleo/carregar-fichas.js';
import { sha256Hex } from '../nucleo/sha256.js';
import { FIXTURE } from './ajudantes.mjs';

const copia = (x) => JSON.parse(JSON.stringify(x));
const ficha = (id) => copia(FIXTURE.fichas.find((f) => f.id === id));

function recusaCom(r, campo, motivoRe = /./) {
  assert.equal(r.ok, false, 'devia recusar');
  assert.ok(
    r.erros.some((e) => e.campo === campo && motivoRe.test(e.motivo)),
    `esperava erro em "${campo}", veio ${JSON.stringify(r.erros)}`,
  );
}

test('aceite 1: a fixture fictícia valida (4 fichas)', () => {
  const r = carregarFichas(FIXTURE);
  assert.equal(r.ok, true, JSON.stringify(r.erros));
  assert.deepEqual(Object.keys(r.fichas).sort(), ['bandido-teste', 'heroina-teste', 'lobo-teste', 'orc-teste']);
});

test('aceite 2: cada campo obrigatório da ficha, removido, é recusado com o nome do campo', () => {
  for (const campo of SCHEMA_FICHAS_1.required) {
    const f = ficha('heroina-teste');
    delete f[campo];
    recusaCom(carregarFichas([f]), campo, /em falta/);
  }
});

test('aceite 2 b: cada campo obrigatório da técnica, removido, é recusado', () => {
  for (const campo of ['id', 'nome', 'expressaoAtaque', 'custoPA', 'alcanceM']) {
    const f = ficha('orc-teste');
    delete f.tecnicas[0][campo];
    recusaCom(carregarFichas([f]), `tecnicas[0].${campo}`, /em falta/);
  }
  // Sem expressaoDano nem componentes (E2: o 3.º ramo saiu).
  const f = ficha('orc-teste');
  delete f.tecnicas[0].expressaoDano;
  f.tecnicas[0].classificacao = 'Ouro';
  f.tecnicas[0].posicaoFIP = 'Media';
  recusaCom(carregarFichas([f]), 'tecnicas[0]', /expressaoDano/);
});

test('aceite 2 c: subcampos obrigatórios (rd, testes.fortitude, fonte, defesaAplicavel.valor)', () => {
  let f = ficha('orc-teste');
  delete f.rd.porTipo;
  recusaCom(carregarFichas([f]), 'rd.porTipo', /em falta/);
  f = ficha('orc-teste');
  delete f.testes.fortitude;
  recusaCom(carregarFichas([f]), 'testes.fortitude', /em falta/);
  f = ficha('orc-teste');
  delete f.fonte.origem;
  recusaCom(carregarFichas([f]), 'fonte.origem', /em falta/);
  f = ficha('lobo-teste');
  delete f.defesaAplicavel.valor;
  recusaCom(carregarFichas([f]), 'defesaAplicavel.valor', /em falta/);
});

test('um campo em falta nunca vira zero: null num inteiro é recusado', () => {
  const f = ficha('orc-teste');
  f.vidaTotal = null;
  recusaCom(carregarFichas([f]), 'vidaTotal', /tipo errado/);
});

test('aceite 3: componentes:[null] é recusado', () => {
  const f = ficha('lobo-teste');
  f.tecnicas[0].componentes = [null];
  recusaCom(carregarFichas([f]), 'tecnicas[0].componentes[0]', /tipo errado/);
});

test('E4: sem ca e sem defesaAplicavel é recusado; reacaoDefensiva saiu da ficha', () => {
  let f = ficha('orc-teste');
  delete f.ca;
  recusaCom(carregarFichas([f]), 'ca', /em falta/);
  f = ficha('orc-teste');
  f.reacaoDefensiva = { tipo: 'esquiva', valor: 1, origem: 'x' };
  recusaCom(carregarFichas([f]), 'reacaoDefensiva', /não permitido/);
});

test('E1: classificação da ficha em camelCase; testesDeMorteDesignado booleano', () => {
  let f = ficha('orc-teste');
  f.classificacao = 'Ouro Negro'; // forma da técnica, não da ficha
  recusaCom(carregarFichas([f]), 'classificacao', /fora da lista/);
  f = ficha('heroina-teste');
  f.testesDeMorteDesignado = 'sim';
  recusaCom(carregarFichas([f]), 'testesDeMorteDesignado', /tipo errado/);
});

test('E3: tipo e tipos divergentes; reparticao com comprimento errado', () => {
  let f = ficha('lobo-teste');
  f.tecnicas[0].tipo = 'cortante';
  recusaCom(carregarFichas([f]), 'tecnicas[0].tipo', /divergem/);
  f = ficha('lobo-teste');
  f.tecnicas[0].reparticao = ['1d4', '1d4'];
  recusaCom(carregarFichas([f]), 'tecnicas[0].reparticao', /comprimentos/);
});

test('E6: RD geral e por tipo ao mesmo tempo; chave de porTipo que nenhuma técnica usa', () => {
  let f = ficha('orc-teste');
  f.rd.porTipo = { cortante: 3 };
  recusaCom(carregarFichas([f]), 'rd', /EMPILHAMENTO/);
  f = ficha('lobo-teste');
  f.rd.porTipo = { Perfurante: 0 }; // grafia diferente
  recusaCom(carregarFichas([f]), 'rd.porTipo.Perfurante', /grafia/);
});

test('E7: testes.ataque só é obrigatório se alguma técnica não tiver expressaoAtaque', () => {
  const r = carregarFichas([ficha('lobo-teste')]); // o lobo não tem testes.ataque
  assert.equal(r.ok, true, JSON.stringify(r.erros));
});

test('ids repetidos e expressões não analisáveis são recusados', () => {
  recusaCom(carregarFichas([ficha('orc-teste'), ficha('orc-teste')]), 'id', /repetido/);
  const f = ficha('orc-teste');
  f.tecnicas[0].expressaoDano = '2d6+FOR';
  recusaCom(carregarFichas([f]), 'tecnicas[0].expressaoDano', /analisável/);
  // Com o verificador injetado (o motor real, na JV0.3), a decisão é dele.
  const r = carregarFichas([f], { verificarExpressao: () => true });
  assert.equal(r.ok, true);
});

test('aceite: Object.freeze profundo; o objeto do chamador não é congelado', () => {
  const entrada = copia(FIXTURE);
  const r = carregarFichas(entrada);
  const orc = r.fichas['orc-teste'];
  assert.ok(Object.isFrozen(r.fichas));
  assert.ok(Object.isFrozen(orc));
  assert.ok(Object.isFrozen(orc.tecnicas));
  assert.ok(Object.isFrozen(orc.tecnicas[0]));
  assert.ok(Object.isFrozen(orc.rd.porTipo));
  assert.throws(() => {
    orc.tecnicas[0].alcanceM = 99;
  }, TypeError);
  assert.equal(Object.isFrozen(entrada.fichas[0]), false);
});

test('aceite 4: o pacote recusa SHA errado, arquivo em falta e arquivo não listado', () => {
  const texto = JSON.stringify(ficha('orc-teste'));
  const certo = { formato: 'fichas/1', criadoEm: '2026-11-06', autor: 'teste', sha256: { 'fichas/orc-teste.json': sha256Hex(texto) } };
  const ok = carregarPacote({ pacote: certo, arquivos: { 'fichas/orc-teste.json': texto } });
  assert.equal(ok.ok, true, JSON.stringify(ok.erros));

  const errado = carregarPacote({ pacote: certo, arquivos: { 'fichas/orc-teste.json': texto + ' ' } });
  assert.equal(errado.ok, false);
  assert.ok(errado.erros.some((e) => e.arquivo === 'fichas/orc-teste.json' && /SHA-256/.test(e.motivo)));

  const falta = carregarPacote({ pacote: certo, arquivos: {} });
  assert.ok(falta.erros.some((e) => /em falta/.test(e.motivo)));

  const extra = carregarPacote({ pacote: certo, arquivos: { 'fichas/orc-teste.json': texto, 'fichas/x.json': '{}' } });
  assert.ok(extra.erros.some((e) => e.arquivo === 'fichas/x.json' && /não listado/.test(e.motivo)));

  const formato = carregarPacote({ pacote: { ...certo, formato: 'fichas/9' }, arquivos: {} });
  assert.ok(formato.erros.some((e) => e.campo === 'formato'));

  // Bytes também servem (Uint8Array).
  const bytes = new TextEncoder().encode(texto);
  assert.equal(carregarPacote({ pacote: certo, arquivos: { 'fichas/orc-teste.json': bytes } }).ok, true);
});

test('o erro diz qual arquivo e qual campo', () => {
  const f = ficha('orc-teste');
  delete f.tecnicas;
  const texto = JSON.stringify(f);
  const r = carregarPacote({
    pacote: { formato: 'fichas/1', sha256: { 'fichas/orc-teste.json': sha256Hex(texto) } },
    arquivos: { 'fichas/orc-teste.json': texto },
  });
  assert.equal(r.ok, false);
  assert.deepEqual(r.erros.find((e) => e.campo === 'tecnicas'), { arquivo: 'fichas/orc-teste.json', campo: 'tecnicas', motivo: 'em falta' });
});
