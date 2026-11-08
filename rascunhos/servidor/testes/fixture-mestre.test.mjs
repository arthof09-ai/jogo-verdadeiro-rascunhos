// Fixture do ecrã do Mestre para o cliente Godot (I0004, 08/11/2026), tirada do servidor de verdade.
// O cliente (rascunhos/cliente/testes/abrir_mestre.gd e canario_privacidade.gd) lê este ficheiro; assim
// os testes do ecrã usam mensagens reais e não mensagens escritas à mão.
//
// Sem ESCREVER_FIXTURE, este teste confere que o ficheiro guardado é igual ao que o servidor gera hoje
// (falha se alguém mudar o servidor e se esquecer de o gerar outra vez). Para gerar:
//   ESCREVER_FIXTURE=1 node --test testes/fixture-mestre.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, writeFileSync } from 'node:fs';
import { montarMesa, exigirAplicada, recibo } from './ajudantes.mjs';

const CAMINHO = new URL('../dados-exemplo/mesa-mestre.json', import.meta.url);

function cenarioDesgraca() {
  const m = montarMesa({ comAliada: true, comEspectador: true });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }], ['lobo-teste', { x: 9, y: 9 }]]);
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { hora: '03:33', clima: 'nevoeiro', futuro: 'CANARIO-FUTURO' }));
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  m.motor.cfg.resultado = 'falha_critica';
  const r = m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'fc-1' });
  assert.equal(recibo(r).estado, 'AGUARDANDO_MESTRE');
  m.motor.cfg.resultado = 'acerto';
  const vista = m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW');
  return {
    vista,
    cartao: m.clientes.mestre.ultimo('MASTER_CARD'),
    snapshotMestre: m.clientes.mestre.ultimo('ROOM_SNAPSHOT'),
    jogadora: h.msgs,
  };
}

function cenarioIA() {
  // Como o T-IA-07: o lobo à distância, em semi, propõe com a razão-canário.
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['lobo-teste', { x: 10, y: 2 }]]);
  exigirAplicada(m.mestre('MASTER_MODE', { figuraId: m.clientes.heroina.idPorNome('Lobo'), modo: 'semi' }));
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  return m.clientes.mestre.ultimo('MASTER_CARD');
}

function cenarioDados() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const orc = m.clientes.heroina.idPorNome('Orc');
  const r = m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' },
    { intentId: 'dados-1', dadosFisicos: { faces: [17] } });
  assert.equal(recibo(r).estado, 'AGUARDANDO_MESTRE');
  return m.clientes.mestre.ultimo('MASTER_CARD');
}

// Lobby: a mesa montada pelo Mestre, antes do START, e a pesquisa de fichas.
function cenarioLobby() {
  const m = montarMesa();
  m.entrarTodos();
  exigirAplicada(m.mestre('MASTER_LOBBY_SET', {
    mapaId: 'arena-teste', criaturasDisponiveis: ['orc-teste', 'lobo-teste'], npcsDisponiveis: ['bandido-teste'],
  }));
  const resultados = m.enviar('mestre', { type: 'MASTER_SEARCH', texto: '' }).find((x) => x.type === 'MASTER_RESULTS');
  const vista = m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW');
  return { vista, resultados };
}

// Agir: o orc em «manual» na vez dele — o Mestre recebe as opções e joga à mão.
function cenarioAgir() {
  const m = montarMesa({ modoPadrao: 'manual' });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]); // ao lado dela: há ataque nas opções
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  const opcoes = m.clientes.mestre.ultimo('ROOM_OPTIONS');
  const vista = m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW');
  assert.equal(opcoes?.vezId, vista.vezId, 'as opções são da criatura da vez');
  return { vista, opcoes };
}

function gerar() {
  const d = cenarioDesgraca();
  const ia = cenarioIA();
  const dados = cenarioDados();
  assert.equal(d.cartao?.tipo, 'desgraca');
  assert.equal(ia?.tipo, 'ia');
  assert.equal(dados?.tipo, 'dados');
  return {
    origem: 'Gerado por rascunhos/servidor/testes/fixture-mestre.test.mjs (servidor real, motor falso). Não editar à mão.',
    canarios: ['Orc Verdadeiro', '7777', '313', '03:33', 'CANARIO-FUTURO', 'CANARIO-DESGRACA', 'CANARIO-RAZAO-IA'],
    // (O clima «nevoeiro» NÃO é canário: o efeito presente do clima é público, E-P12.)
    mestre: { vista: d.vista, snapshot: d.snapshotMestre, cartoes: { desgraca: d.cartao, ia, dados } },
    lobby: cenarioLobby(),
    agir: cenarioAgir(),
    jogadora: { mensagens: d.jogadora },
  };
}

test('fixture do ecrã do Mestre: o ficheiro guardado é o que o servidor gera hoje', () => {
  const texto = JSON.stringify(gerar(), null, 1) + '\n';
  if (process.env.ESCREVER_FIXTURE) writeFileSync(CAMINHO, texto);
  const guardado = readFileSync(CAMINHO, 'utf8');
  assert.equal(guardado, texto, 'mesa-mestre.json desactualizado: ESCREVER_FIXTURE=1 node --test testes/fixture-mestre.test.mjs');
});

test('fixture do ecrã do Mestre: a jogadora nunca recebeu nenhum dos canários do Mestre', () => {
  const f = gerar();
  const texto = JSON.stringify(f.jogadora.mensagens);
  for (const c of f.canarios) assert.ok(!texto.includes(c), `a jogadora recebeu «${c}»`);
  const doMestre = JSON.stringify(f.mestre);
  for (const c of ['Orc Verdadeiro', '7777', '03:33', 'CANARIO-FUTURO', 'CANARIO-DESGRACA', 'CANARIO-RAZAO-IA']) {
    assert.ok(doMestre.includes(c), `controlo positivo: o Mestre tem «${c}»`);
  }
});
