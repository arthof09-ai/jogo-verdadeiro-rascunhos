// Ordem 7 do CM-000009: a acção `curar` com o aplicarCura do MOTOR REAL (vlab-completo.js do site, REF_31).
// Só a cura é real; o golpe que a deita e os testes de morte são do falso, para chegar à estabilizada sem sorte.
// Corre só no CI, no job motor-real (MOTOR_MJS).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import path from 'node:path';
import { carregarFichas } from '../nucleo/carregar-fichas.js';
import { criarMotorFalso } from '../testes/motor-falso.mjs';
import { montarMesa, listaDeFichas, exigirAplicada } from '../testes/ajudantes.mjs';

const MOTOR_MJS = process.env.MOTOR_MJS;

test('motor real: a estabilizada curada pelo aplicarCura do site fica com 1 + cura, levanta-se e age na vez dela', { skip: !MOTOR_MJS && 'MOTOR_MJS não definido (só corre no job motor-real)' }, async () => {
  const mod = await import(pathToFileURL(path.resolve(MOTOR_MJS)).href);
  assert.equal(typeof mod.Vlab.aplicarCura, 'function', 'o motor do site exporta aplicarCura');
  const falso = criarMotorFalso();
  const saidasCura = [];
  const Vlab = Object.create(mod.Vlab);
  Vlab.aplicarCura = (entrada) => {
    const s = mod.Vlab.aplicarCura(entrada);
    saidasCura.push({ entrada: JSON.parse(JSON.stringify(entrada)), saida: JSON.parse(JSON.stringify(s)) });
    return s;
  };
  Vlab.resolverAtaque = (entrada) => {
    const s = falso.Vlab.resolverAtaque(entrada);
    if (entrada.alvo?.id !== 'heroina-teste') return s;
    if (entrada.alvo?.estadoMorte?.fase) return { ...s, resultado: 'acerto', danoAplicado: 0, soDoMestre: {} };
    return { ...s, resultado: 'acerto', soDoMestre: { alvoDepois: { vidaActual: 0, estadoMorte: { fase: 'aMorrer', sucessos: 0, falhas: 0 } } } };
  };
  Vlab.resolverTesteDeMorte = () => {
    const estadoMorte = { fase: 'estabilizado', sucessos: 3, falhas: 0 };
    return { estadoMorte, estabilizado: true, morteAdjudicada: false, desfecho: 'estabilizado', publico: { recibo: 'x' }, soDoMestre: { estadoMorte } };
  };
  const motor = { Dmg: mod.Dmg, Vlab, MOTOR_SHA256: mod.MOTOR_SHA256, DMG_VERSAO: 'real', LEVELUP_SHA: null };

  const lista = listaDeFichas({ comAliada: true });
  lista.find((f) => f.id === 'aliada-teste').tecnicas.push({
    id: 'cura-teste', nome: 'Cura de Teste', expressaoAtaque: '1d20+1', expressaoDano: '1d4', tipo: 'cortante',
    expressaoCura: '1d8+2', custoPA: 3, alcanceM: 9, usaArma: false,
  });
  const r = carregarFichas(lista);
  assert.ok(r.ok, JSON.stringify(r.erros));
  const m = montarMesa({ motor, comAliada: true, fichas: r.fichas, casas: { aliada: { x: 8, y: 2 } } });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const h = m.clientes.heroina;
  const a = m.clientes.aliada;
  const her = h.figuraId;
  const orc = h.idPorNome('Orc');
  const fig = (id) => m.sala.depuracao.estado().figuras[id];
  const orcEncerra = () => exigirAplicada(m.enviar('mestre', {
    type: 'MASTER_ACT', intentId: m.novoId('act'), revision: m.clientes.mestre.revision, figuraId: orc, acao: { tipo: 'encerrar' },
  }), 'orc encerra');

  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  exigirAplicada(m.intencao('aliada', { tipo: 'encerrar' })); // o orc (auto) deita-a; a vez dela estabiliza-a
  assert.equal(fig(her).estadoMorte?.fase, 'estabilizado');
  assert.equal(fig(her).vidaActual, 1);
  exigirAplicada(m.mestre('MASTER_MODE', { figuraId: orc, modo: 'manual' }));
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));

  assert.deepEqual(a.opcoes.curas, [{ alvoId: her, tecnica: 'cura-teste' }]);
  exigirAplicada(m.intencao('aliada', { tipo: 'curar', alvoId: her, tecnica: 'cura-teste' }), 'curar (motor real)');
  assert.equal(saidasCura.length, 1);
  const { saida } = saidasCura[0];
  assert.equal(saida.erro, null, 'o motor real aceitou a cura da estabilizada a 1 de Vida');
  assert.equal(saida.curaRolada, null, 'o total não vem no topo (privacidade, bancada D3e)');
  const sm = saida.soDoMestre;
  assert.ok(Number.isInteger(sm.curaRolada) && sm.curaRolada >= 3 && sm.curaRolada <= 10, '1d8+2');
  assert.equal(sm.alvoDepois.vidaActual, 1 + sm.curaEfectiva, 'o motor soma a cura por cima do 1');
  assert.equal(fig(her).vidaActual, 1 + sm.curaRolada, 'Q4: 1 + cura');
  assert.equal(fig(her).estadoMorte, null, 'a marca sai (o motor só a limpa a partir de 0; a sala limpa-a, como o site)');
  assert.equal(fig(her).caido, false, 'levanta-se');
  const ev = a.eventos('cura').at(-1);
  assert.ok(Array.isArray(ev.dados.faces) && ev.dados.faces.length === 1, 'quem cura vê a face do recibo real: ' + JSON.stringify(ev.dados));
  assert.equal(ev.dados.faces[0] + 2, sm.curaRolada, 'a face do recibo real bate com o total');
  assert.equal(h.eventos('cura').at(-1).dados.faces, undefined, 'a curada não vê as faces de outra');

  exigirAplicada(m.intencao('aliada', { tipo: 'encerrar' }));
  orcEncerra();
  assert.equal(m.sala.depuracao.estado().vez?.figuraId, her, 'a vez volta a ela');
  assert.ok(h.opcoes.mover.length > 0 && h.opcoes.ataques.some((o) => o.alvoId === orc), 'pode andar e atacar');
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }), 'ela age na vez dela');
});
