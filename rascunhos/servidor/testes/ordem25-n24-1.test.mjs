// Ordem 25 do CM-000009, item 3 — N24-1: o carregador das fichas cumpre os limites de comprimento que o PRÓPRIO
// protocolo já tem escritos (protocolo/v2). Cada teste de correcção falhava com o carregar-fichas.js de 603e19e e
// passa depois; os de controlo passavam antes e continuam (limites que o protocolo NÃO escreve não se inventam).
//
// Onde cada campo da ficha sai e o limite escrito:
//   id da ficha              → fichaId (MASTER_PLACE, ROOM_SNAPSHOT bloco do Mestre, MASTER_LOBBY_SET)   ≤ 64
//   nomePublico              → comum.nomePublico (entrada, colocacao, snapshot da Party)                ≤ 80
//   nome da jogadora sem nomePublico (nomePublicoDe usa-o como nome público)                            ≤ 80
//   tecnicas[].id            → arma / tecnica (ROOM_OPTIONS, comum.acao, eventos ataque e cura)          ≤ 64
//   consumiveis[].itemId     → itemId (ROOM_OPTIONS.consumiveis, comum.acao, evento consumivel)          ≤ 64
//   tipos de dano da técnica → tipos do evento dano (tipos / tipo / componentes[].tipo)                  ≤ 32
//   expressaoAtaque/expressaoCura da técnica DA JOGADORA → expressao dos eventos ataque/cura próprios     ≤ 64
// Os comprimentos contam-se em caracteres (pontos de código), como o maxLength do JSON Schema.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { carregarFichas } from '../nucleo/carregar-fichas.js';
import { FIXTURE } from './ajudantes.mjs';

const copia = (x) => JSON.parse(JSON.stringify(x));
const ficha = (id) => copia(FIXTURE.fichas.find((f) => f.id === id));
const comFicha = (f) => {
  const lista = copia(FIXTURE.fichas).filter((x) => x.id !== f.id && x.id !== 'heroina-teste' && x.id !== 'orc-teste');
  lista.push(f);
  if (f.id !== 'heroina-teste') lista.push(ficha('heroina-teste'));
  if (f.id !== 'orc-teste') lista.push(ficha('orc-teste'));
  return carregarFichas(lista);
};
const recusada = (r, campo) => {
  assert.equal(r.ok, false, `devia ser recusada (${campo})`);
  assert.ok(r.erros.some((e) => e.campo === campo), JSON.stringify(r.erros));
};
const aceite = (r) => assert.equal(r.ok, true, JSON.stringify(r.erros));
// Expressões válidas com o comprimento pedido: '1d20' + '+1'×n (4+2n) ou com '+10' no fim (4+2n+3).
const expr = (n) => (n % 2 === 0 ? '1d20' + '+1'.repeat((n - 4) / 2) : '1d20' + '+1'.repeat((n - 7) / 2) + '+10');

test('N24-1: id da ficha com mais de 64 caracteres é recusado (fichaId ≤ 64)', () => {
  const f = ficha('orc-teste');
  f.id = 'o'.repeat(65);
  recusada(comFicha(f), 'id');
});

test('N24-1 controlo: id da ficha com 64 caracteres continua aceite', () => {
  const f = ficha('orc-teste');
  f.id = 'o'.repeat(64);
  aceite(comFicha(f));
});

test('N24-1: nomePublico com mais de 80 caracteres é recusado (comum.nomePublico ≤ 80), em qualquer papel', () => {
  for (const id of ['orc-teste', 'heroina-teste']) {
    const f = ficha(id);
    f.nomePublico = 'N'.repeat(81);
    recusada(comFicha(f), 'nomePublico');
  }
});

test('N24-1 controlo: nomePublico de 80 caracteres (também fora do ASCII) continua aceite', () => {
  for (const nome of ['N'.repeat(80), 'é'.repeat(80), '🐺'.repeat(80)]) {
    const f = ficha('orc-teste');
    f.nomePublico = nome;
    aceite(comFicha(f));
  }
});

test('N24-1: jogadora sem nomePublico com nome de mais de 80 caracteres é recusada (o nome é o nome público dela)', () => {
  const f = ficha('heroina-teste');
  delete f.nomePublico;
  f.nome = 'H'.repeat(81);
  recusada(comFicha(f), 'nome');
});

test('N24-1 controlo: o nome verdadeiro de quem tem nomePublico (ou da criatura) não tem limite escrito', () => {
  const j = ficha('heroina-teste');
  j.nome = 'H'.repeat(200); // tem nomePublico: o nome verdadeiro só vai ao Mestre (sem maxLength)
  aceite(comFicha(j));
  const c = ficha('orc-teste');
  delete c.nomePublico; // criatura sem nomePublico: a Party vê «Criatura», não o nome
  c.nome = 'O'.repeat(200);
  aceite(comFicha(c));
  const j2 = ficha('heroina-teste');
  delete j2.nomePublico;
  j2.nome = 'H'.repeat(80);
  aceite(comFicha(j2));
});

test('N24-1: id de técnica com mais de 64 caracteres é recusado (arma/tecnica ≤ 64)', () => {
  for (const id of ['orc-teste', 'heroina-teste']) {
    const f = ficha(id);
    f.tecnicas[0].id = 't'.repeat(65);
    recusada(comFicha(f), 'tecnicas[0].id');
  }
});

test('N24-1 controlo: id de técnica com 64 caracteres continua aceite', () => {
  const f = ficha('heroina-teste');
  f.tecnicas[0].id = 't'.repeat(64);
  aceite(comFicha(f));
});

test('N24-1: itemId com mais de 64 caracteres é recusado (itemId ≤ 64)', () => {
  const f = ficha('heroina-teste');
  f.consumiveis = [{ itemId: 'i'.repeat(65), quantidade: 1 }];
  recusada(comFicha(f), 'consumiveis[0].itemId');
});

test('N24-1 controlo: itemId com 64 caracteres continua aceite', () => {
  const f = ficha('heroina-teste');
  f.consumiveis = [{ itemId: 'i'.repeat(64), quantidade: 1 }];
  aceite(comFicha(f));
});

test('N24-1: tipo de dano com mais de 32 caracteres é recusado (tipos do evento dano ≤ 32), pelas três formas', () => {
  const longo = 'x'.repeat(33);
  const a = ficha('orc-teste');
  delete a.tecnicas[0].tipo;
  a.tecnicas[0].tipos = [longo];
  recusada(comFicha(a), 'tecnicas[0].tipos[0]');
  const b = ficha('orc-teste');
  delete b.tecnicas[0].tipos;
  b.tecnicas[0].tipo = longo;
  recusada(comFicha(b), 'tecnicas[0].tipo');
  const c = ficha('orc-teste');
  const t = c.tecnicas[0];
  delete t.tipo;
  delete t.tipos;
  t.componentes = [{ tipo: longo, expressao: t.expressaoDano ?? '1d6' }];
  recusada(comFicha(c), 'tecnicas[0].componentes[0].tipo');
});

test('N24-1 controlo: tipo de dano com 32 caracteres continua aceite', () => {
  const f = ficha('orc-teste');
  delete f.tecnicas[0].tipos;
  f.tecnicas[0].tipo = 'x'.repeat(32);
  aceite(comFicha(f));
});

test('N24-1: expressão de ataque ou de cura da técnica da jogadora com mais de 64 caracteres é recusada (expressao ≤ 64)', () => {
  assert.equal(expr(65).length, 65);
  const a = ficha('heroina-teste');
  a.tecnicas[0].expressaoAtaque = expr(65);
  recusada(comFicha(a), 'tecnicas[0].expressaoAtaque');
  const c = ficha('heroina-teste');
  c.tecnicas[0].expressaoCura = expr(65);
  recusada(comFicha(c), 'tecnicas[0].expressaoCura');
});

test('N24-1 controlo: expressão de 64 na jogadora, e expressões longas de quem não é jogadora (não saem), continuam aceites', () => {
  assert.equal(expr(64).length, 64);
  const j = ficha('heroina-teste');
  j.tecnicas[0].expressaoAtaque = expr(64);
  j.tecnicas[0].expressaoCura = expr(64);
  aceite(comFicha(j));
  for (const id of ['orc-teste', 'bandido-teste']) {
    const f = ficha(id);
    f.tecnicas[0].expressaoAtaque = expr(84);
    f.tecnicas[0].expressaoDano = expr(84);
    aceite(comFicha(f));
  }
  // Na jogadora, as expressões que não saem nos eventos (dano, testes) não têm limite escrito.
  const d = ficha('heroina-teste');
  d.tecnicas[0].expressaoDano = expr(84);
  d.testes.fortitude = expr(84);
  aceite(comFicha(d));
});
