// Ordem 24 do CM-000009 — varredura do servidor (o espírito das V1-V16), pelas áreas ainda não lidas: o carregador das
// fichas e do pacote (carregar-fichas.js), a projecção (projecao.js) e os utilitários. Cada teste de correcção falhava
// antes (conferido com o carregar-fichas.js de 444ebef) e passa depois; os de controlo passavam antes e continuam.
//
//  V17  `visual.alturaM` declara `exclusiveMinimum: 0, maximum: 15` no SCHEMA_FICHAS_1, mas o validador próprio não
//       conhecia essas duas palavras: 0, −2 ou 1000 metros passavam e iam ao Mestre (figuraDoMestre.alturaM) como a
//       altura do marcador. Agora o validador lê `exclusiveMinimum`/`maximum` e a ficha é recusada.
//  V18  `carregarPacote` lançava TypeError (do sha256) em vez de devolver {ok:false, erros}: (a) quando o PACOTE.json
//       lista um caminho com o nome de uma propriedade herdada (`toString`, `constructor`…) — o `in` via o protótipo
//       e dava o pacote por presente; (b) quando o conteúdo de um ficheiro não é texto nem bytes. Agora: «em falta no
//       pacote» e «conteúdo não é texto nem bytes».
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { carregarFichas, carregarPacote } from '../nucleo/carregar-fichas.js';
import { sha256Hex } from '../nucleo/sha256.js';
import { FIXTURE } from './ajudantes.mjs';

const copia = (x) => JSON.parse(JSON.stringify(x));
const comAltura = (h) => {
  const lista = copia(FIXTURE.fichas);
  lista[0].visual = { marcador: 'marcador', alturaM: h };
  return carregarFichas(lista);
};

test('V17: visual.alturaM fora de ]0, 15] é recusada (o schema da ficha já o dizia)', () => {
  for (const h of [0, -2, 15.01, 1000]) {
    const r = comAltura(h);
    assert.equal(r.ok, false, `alturaM ${h} devia ser recusada`);
    assert.ok(r.erros.some((e) => e.campo === 'visual.alturaM'), JSON.stringify(r.erros));
  }
});

test('V17 controlo: alturas dentro de ]0, 15] continuam aceites', () => {
  for (const h of [0.01, 2.25, 15]) {
    const r = comAltura(h);
    assert.equal(r.ok, true, `alturaM ${h}: ${JSON.stringify(r.erros)}`);
  }
});

test('V18: caminho com nome do protótipo no PACOTE.json → erro, não excepção', () => {
  for (const nome of ['toString', 'constructor', 'hasOwnProperty']) {
    let r;
    assert.doesNotThrow(() => {
      r = carregarPacote({ pacote: { formato: 'fichas/1', sha256: { [nome]: 'ab' } }, arquivos: {} });
    }, nome);
    assert.equal(r.ok, false);
    assert.ok(r.erros.some((e) => e.arquivo === nome && /em falta/.test(e.motivo)), JSON.stringify(r.erros));
  }
});

test('V18: conteúdo que não é texto nem bytes → erro, não excepção', () => {
  for (const conteudo of [42, null, { a: 1 }]) {
    let r;
    assert.doesNotThrow(() => {
      r = carregarPacote({ pacote: { formato: 'fichas/1', sha256: { 'fichas/x.json': 'ab' } }, arquivos: { 'fichas/x.json': conteudo } });
    }, String(conteudo));
    assert.equal(r.ok, false);
    assert.ok(r.erros.some((e) => e.arquivo === 'fichas/x.json'), JSON.stringify(r.erros));
  }
});

test('V18 controlo: pacote certo (texto e bytes) continua a abrir', () => {
  const f = copia(FIXTURE.fichas.find((x) => x.id === 'orc-teste'));
  const texto = JSON.stringify(f);
  const pacote = { formato: 'fichas/1', sha256: { 'fichas/orc-teste.json': sha256Hex(texto) } };
  assert.equal(carregarPacote({ pacote, arquivos: { 'fichas/orc-teste.json': texto } }).ok, true);
  assert.equal(carregarPacote({ pacote, arquivos: { 'fichas/orc-teste.json': new TextEncoder().encode(texto) } }).ok, true);
});
