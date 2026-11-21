// Ordem CAIXA-HUD-JOGADORA (20/11/2026): a caixa da ordem de turnos no HUD da jogadora.
// A escolha do Mestre (ligada, modo) chega à Party no ROOM_SNAPSHOT (`caixa`), com a ordem dinâmica DA PARTY — formada
// só pelos eventos tal como a Party os recebe. Nada do Mestre (vida, alma, valores de iniciativa, técnico) sai.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { montarMesa, exigirAplicada, procurarCanarios, PIN, SENHAS, fichasDeTeste, rngDeterministico, relogio, INICIATIVA } from './ajudantes.mjs';
import { criarSala } from '../nucleo/sala.js';
import { criarMotorFalso } from './motor-falso.mjs';
import { ordemDinamicaVazia, registarEvento } from '../nucleo/ordem-dinamica.js';

const PARTY = ['heroina', 'aliada', 'espectador'];

function mesaEmCombate() {
  const m = montarMesa({ comAliada: true, comEspectador: true, modoPadrao: 'manual' });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 8, y: 8 }], ['lobo-teste', { x: 12, y: 12 }]]);
  const H = m.clientes.heroina.figuraId;
  const A = m.clientes.aliada.figuraId;
  const orc = m.clientes.mestre.idPorNome('Orc');
  const lobo = m.clientes.mestre.idPorNome('Lobo');
  const estado = () => m.sala.depuracao.estado();
  const act = (figuraId, acao) => exigirAplicada(m.mestre('MASTER_ACT', { intentId: m.novoId('act'), figuraId, acao }), 'ACT');
  const caixa = (ligada, modo) => m.mestre('MASTER_SUPERVISOR', { op: 'caixa', caixa: { ligada, modo } });
  const vista = () => m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW');
  return { m, H, A, orc, lobo, estado, act, caixa, vista };
}

/** A ordem que a jogadora forma SÓ com o que recebeu (as mesmas regras do servidor e do cliente). */
function ordemPelosEventosRecebidos(cliente) {
  const od = ordemDinamicaVazia();
  for (const msg of cliente.msgs) {
    if (msg.type === 'ROOM_SNAPSHOT') Object.assign(od, ordemDinamicaVazia(), structuredClone(msg.caixa?.ordemDinamica ?? {}), { vezes: 0 });
    if (msg.type === 'ROOM_EVENT') registarEvento(od, { tipo: msg.tipo, dados: msg.dados });
  }
  return { ordem: od.ordem, fechada: od.fechada, ultimo: od.ultimo };
}

test('caixa no HUD da jogadora: o snapshot da Party traz a escolha do Mestre por omissão (ligada, dinâmico)', () => {
  const { m } = mesaEmCombate();
  for (const k of PARTY) {
    m.sair(k);
    m.entrar(k, k === 'espectador' ? { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador }
      : { papel: 'jogadora', nome: k === 'heroina' ? 'Heroína Teste' : 'Aliada Teste', senha: SENHAS[k] });
    const s = m.clientes[k].ultimo('ROOM_SNAPSHOT');
    assert.deepEqual(s.caixa, { ligada: true, ordemPor: 'dinamico', ordemDinamica: { ordem: [], fechada: false, ultimo: null } }, k);
    assert.equal(s.caixaMestre, undefined, 'a Party nunca recebe a caixaMestre da MASTER_VIEW');
  }
  // O Mestre não recebe `caixa` no snapshot dele (tem a caixaMestre na MASTER_VIEW).
  m.sair('mestre');
  m.entrar('mestre', { papel: 'mestre', pin: PIN });
  const sm = m.clientes.mestre.msgs.filter((x) => x.type === 'ROOM_SNAPSHOT').at(-1);
  if (sm) assert.equal(sm.caixa, undefined);
});

test('caixa no HUD da jogadora: a escolha do Mestre segue para a Party num snapshot, sem mexer na revisão', () => {
  const { m, caixa, estado } = mesaEmCombate();
  const revAntes = Object.fromEntries(Object.values(estado().lugares).map((s) => [s.seatId, s.revision]));
  const antes = Object.fromEntries(PARTY.map((k) => [k, m.clientes[k].msgs.length]));
  const mestreAntes = m.clientes.mestre.msgs.length;
  exigirAplicada(caixa(true, 'iniciativa'), 'caixa iniciativa');
  for (const k of PARTY) {
    const novas = m.clientes[k].msgs.slice(antes[k]);
    assert.deepEqual(novas.map((x) => x.type), ['ROOM_SNAPSHOT'], k + ': só o snapshot novo');
    assert.equal(novas[0].caixa.ligada, true);
    assert.equal(novas[0].caixa.ordemPor, 'iniciativa');
  }
  const novasMestre = m.clientes.mestre.msgs.slice(mestreAntes).map((x) => x.type);
  assert.ok(!novasMestre.includes('ROOM_SNAPSHOT'), 'o Mestre não recebe snapshot por isto');
  const revDepois = Object.fromEntries(Object.values(estado().lugares).map((s) => [s.seatId, s.revision]));
  assert.deepEqual(revDepois, revAntes, 'nenhuma revisão mudou (a caixa é apresentação)');
  // Uma intenção feita com a revisão de antes da escolha continua a valer (nada de revisao_antiga).
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 3, y: 2 } }), 'mover depois da escolha');
  // Desligar: a Party vê desligada.
  exigirAplicada(caixa(false, 'iniciativa'), 'caixa desligada');
  for (const k of PARTY) assert.equal(m.clientes[k].ultimo('ROOM_SNAPSHOT').caixa.ligada, false, k);
});

test('caixa no HUD da jogadora: a ordem dinâmica da Party é a que ela forma com os eventos que recebe (o defender não conta)', () => {
  const { m, H, A, orc, lobo, act, vista, estado } = mesaEmCombate();
  const jogar = (id, destino) => {
    assert.equal(estado().vez?.figuraId, id);
    if (id === H || id === A) {
      const k = id === H ? 'heroina' : 'aliada';
      if (destino) exigirAplicada(m.intencao(k, { tipo: 'mover', destino }), 'mover');
      else exigirAplicada(m.intencao(k, { tipo: 'defender' }), 'defender');
      exigirAplicada(m.intencao(k, { tipo: 'encerrar' }), 'encerrar');
    } else { act(id, { tipo: 'mover', destino }); act(id, { tipo: 'encerrar' }); }
  };
  // A Aliada só DEFENDE (um `acao`, que não sai para a Party): entra na ordem do Mestre, não na da Party.
  const quem = [];
  for (const id of estado().ordem) quem.push(id);
  for (const id of quem) {
    if (id === A) jogar(A, null);
    else if (id === H) jogar(H, { x: 3, y: 2 });
    else if (id === orc) jogar(orc, { x: 8, y: 7 });
    else if (id === lobo) jogar(lobo, { x: 12, y: 11 });
  }
  const odMestre = vista().ordemDinamica;
  assert.ok(odMestre.ordem.includes(A), 'na ordem do Mestre a Aliada (defendeu) está');
  // A Party volta a entrar: o snapshot traz a ordem dela.
  m.sair('heroina');
  m.entrar('heroina', { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina });
  const od = m.clientes.heroina.ultimo('ROOM_SNAPSHOT').caixa.ordemDinamica;
  assert.ok(!od.ordem.includes(A), 'na ordem da Party a Aliada não está (o defender não lhe chega)');
  assert.deepEqual(od.ordem, odMestre.ordem.filter((id) => id !== A));
  // E é exactamente a que o espectador formou só com o que recebeu.
  assert.deepEqual(ordemPelosEventosRecebidos(m.clientes.espectador), od);
  // A jogadora que voltou a entrar (snapshot + eventos seguintes) chega à mesma ordem que o servidor guarda para a Party.
  const vez = estado().vez.figuraId;
  if (vez === H) exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 4, y: 2 } }), 'mover');
  else if (vez === A) exigirAplicada(m.intencao('aliada', { tipo: 'mover', destino: { x: 3, y: 4 } }), 'mover');
  else act(vez, { tipo: 'encerrar' });
  const p = estado().ordemDinamicaParty;
  assert.deepEqual(ordemPelosEventosRecebidos(m.clientes.heroina), { ordem: p.ordem, fechada: p.fechada, ultimo: p.ultimo });
});

test('caixa no HUD da jogadora: nada do Mestre na caixa da Party (canários)', () => {
  const { m, caixa } = mesaEmCombate();
  exigirAplicada(caixa(true, 'iniciativa'));
  exigirAplicada(caixa(true, 'dinamico'));
  for (const k of PARTY) {
    const caixas = m.clientes[k].msgs.filter((x) => x.type === 'ROOM_SNAPSHOT' && x.caixa).map((x) => x.caixa);
    assert.ok(caixas.length >= 2, k);
    for (const c of caixas) {
      assert.deepEqual(Object.keys(c).sort(), ['ligada', 'ordemDinamica', 'ordemPor']);
      assert.deepEqual(Object.keys(c.ordemDinamica).sort(), ['fechada', 'ordem', 'ultimo']);
    }
    const achados = procurarCanarios(caixas, { chaves: ['modo', 'vidaActual', 'vidaTotal', 'paGasto', 'paTotal', 'valor', 'vezes', 'soMestre', 'iniciativaValor'], numeros: [7777, 313, 5150, 3579, 4040, 1357, 4848, ...Object.values(INICIATIVA)] });
    assert.deepEqual(achados, [], k);
  }
});

test('caixa no HUD da jogadora: a ordem da Party sobrevive ao journal, recomeça com a batalha e journals de antes abrem', () => {
  const { m, H, estado } = mesaEmCombate();
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 3, y: 2 } }), 'mover');
  assert.deepEqual(estado().ordemDinamicaParty.ordem, [H]);
  const exportado = m.sala.exportar();
  const CONFIG = { roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'manual', depurar: true,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'jogadora', nome: 'Aliada Teste', senha: SENHAS.aliada, fichaId: 'aliada-teste', casa: { x: 2, y: 4 } },
      { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador },
      { papel: 'mestre', nome: 'Mestre', pin: PIN }] };
  const snapDaHeroina = (texto) => {
    const sala2 = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste({ comAliada: true }), rng: rngDeterministico(), agora: relogio(), config: CONFIG, restaurarDe: texto });
    // A sala reaberta espera o Mestre (sala de espera: nada da batalha, nem a caixa) — o Mestre entra primeiro.
    const rm = sala2.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'mestre', pin: PIN }, { ip: '10.9.9.9' });
    sala2.conexaoAberta(rm.seatId);
    const r = sala2.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina }, { ip: '10.9.9.8' });
    return r.mensagens.find((x) => x.type === 'ROOM_SNAPSHOT');
  };
  assert.deepEqual(snapDaHeroina(exportado).caixa.ordemDinamica.ordem, [H]);
  // Sala de espera (reaberta, sem o Mestre): nada da batalha — nem a caixa.
  const sala3 = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste({ comAliada: true }), rng: rngDeterministico(), agora: relogio(), config: CONFIG, restaurarDe: exportado });
  const re = sala3.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina }, { ip: '10.9.9.7' });
  const se = re.mensagens.find((x) => x.type === 'ROOM_SNAPSHOT');
  assert.ok(se, 'a jogadora recebe o snapshot da sala de espera');
  assert.equal(se.caixa, undefined, 'na sala de espera não há caixa');
  const [corpo] = exportado.split('\n');
  const assinar = (o) => { const t = JSON.stringify(o); return t + '\nsha256:' + createHash('sha256').update(t).digest('hex') + '\n'; };
  // Journal de antes desta ordem: sem o campo abre (ordem vazia na Party até ao próximo evento).
  const semCampo = JSON.parse(corpo);
  delete semCampo.estado.ordemDinamicaParty;
  const s0 = snapDaHeroina(assinar(semCampo));
  assert.deepEqual(s0.caixa, { ligada: true, ordemPor: 'dinamico', ordemDinamica: { ordem: [], fechada: false, ultimo: null } });
  // Campo estragado não abre.
  for (const mau of [{ ordem: 'x', fechada: false, ultimo: null, vezes: 0 }, { ordem: ['fantasma'], fechada: false, ultimo: null, vezes: 0 }]) {
    const c2 = JSON.parse(corpo); c2.estado.ordemDinamicaParty = mau;
    assert.throws(() => snapDaHeroina(assinar(c2)));
  }
  // «Recomeçar»: a ordem da Party limpa-se (o evento `recomeco` sai para a Party).
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomecar');
  assert.deepEqual(estado().ordemDinamicaParty.ordem, []);
});

// Ordem CAIXA-TESTES (21/11/2026, correcção B5-a): a escolha da caixa é só do Mestre. A jogadora (e o espectador) que
// tentam o op `caixa` levam ERRO proibido «Só o Mestre.» e nada muda: nem a escolha, nem o journal, nem a Party.
test('caixa no HUD da jogadora: a jogadora que envia MASTER_SUPERVISOR op caixa recebe ERRO proibido «Só o Mestre.» e a caixa fica inalterada', () => {
  const { m, estado, vista } = mesaEmCombate();
  const caixaAntes = structuredClone(estado().caixaMestre);
  const vistaAntes = vista();
  const revAntes = Object.fromEntries(Object.values(estado().lugares).map((s) => [s.seatId, s.revision]));
  for (const k of ['heroina', 'espectador']) {
    const antes = Object.fromEntries([...PARTY, 'mestre'].map((x) => [x, m.clientes[x].msgs.length]));
    const r = m.enviar(k, { type: 'MASTER_SUPERVISOR', cmdId: m.novoId('cmd'), revision: m.clientes[k].revision, op: 'caixa', caixa: { ligada: false, modo: 'iniciativa' } });
    assert.equal(r.length, 1, k + ': uma só resposta');
    assert.equal(r[0].type, 'ERRO', k);
    assert.equal(r[0].codigo, 'proibido', k);
    assert.equal(r[0].texto, 'Só o Mestre.', k);
    // Ninguém recebeu nada por isto (nenhum snapshot novo à Party, nada ao Mestre); só quem tentou levou o ERRO.
    // (Conferido antes de pedir a MASTER_VIEW abaixo, que é o próprio teste a perguntar.)
    for (const x of [...PARTY, 'mestre']) {
      const novas = m.clientes[x].msgs.slice(antes[x]).map((y) => y.type);
      assert.deepEqual(novas, x === k ? ['ERRO'] : [], x + ' depois da tentativa de ' + k);
    }
    // A caixa fica como estava, no estado da sala e na MASTER_VIEW.
    assert.deepEqual(estado().caixaMestre, caixaAntes, k + ': a escolha do Mestre não mudou');
    assert.deepEqual(vista().caixaMestre, vistaAntes.caixaMestre, k);
    assert.equal(vista().journalSeq, vistaAntes.journalSeq, k + ': nada entrou no journal');
  }
  const revDepois = Object.fromEntries(Object.values(estado().lugares).map((s) => [s.seatId, s.revision]));
  assert.deepEqual(revDepois, revAntes, 'nenhuma revisão mudou');
  // A caixa que a Party conhece continua a de sempre (ligada, dinâmico).
  m.sair('heroina');
  m.entrar('heroina', { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina });
  const s = m.clientes.heroina.ultimo('ROOM_SNAPSHOT');
  assert.equal(s.caixa.ligada, true);
  assert.equal(s.caixa.ordemPor, 'dinamico');
});

// Ordem CAIXA-TESTES (21/11/2026, correcção B5-c): o «voltar» repõe a ordemDinamicaParty do checkpoint (CHAVES_MUNDO) e o
// snapshot que segue leva-a à Party — não a ordem de depois do ponto, nem uma ordem vazia.
test('caixa no HUD da jogadora: o «voltar» repõe a ordemDinamicaParty do checkpoint e o snapshot seguinte leva-a à Party', () => {
  const { m, H, A, estado, vista } = mesaEmCombate();
  assert.equal(estado().vez?.figuraId, H, 'a batalha começa na heroína');
  // Agir: a heroína anda — o ponto a que se vai voltar (a ordem da Party é [H]).
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: 3, y: 2 } }), 'mover heroína');
  const ateSeq = vista().journalSeq;
  const odNoPonto = structuredClone(estado().ordemDinamicaParty);
  assert.deepEqual(odNoPonto.ordem, [H]);
  // Depois do ponto: a heroína encerra e a aliada anda — a ordem da Party muda para [H, A].
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }), 'encerrar heroína');
  assert.equal(estado().vez?.figuraId, A);
  exigirAplicada(m.intencao('aliada', { tipo: 'mover', destino: { x: 3, y: 4 } }), 'mover aliada');
  assert.deepEqual(estado().ordemDinamicaParty.ordem, [H, A], 'depois do ponto a ordem da Party mudou');
  assert.ok(vista().pontos.some((p) => p.journalSeq === ateSeq), 'o ponto está entre os pontos do «voltar»');
  // Voltar.
  const antes = Object.fromEntries(PARTY.map((k) => [k, m.clientes[k].msgs.length]));
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq }), 'voltar');
  // No estado da sala: a do checkpoint.
  assert.deepEqual(estado().ordemDinamicaParty, odNoPonto, 'a ordemDinamicaParty é a do checkpoint');
  // No snapshot seguinte de cada membro da Party: a ordem do checkpoint, na forma da Party.
  const esperada = { ordem: odNoPonto.ordem, fechada: odNoPonto.fechada, ultimo: odNoPonto.ultimo };
  for (const k of PARTY) {
    const snap = m.clientes[k].msgs.slice(antes[k]).find((x) => x.type === 'ROOM_SNAPSHOT');
    assert.ok(snap, k + ': recebeu o snapshot do «voltar»');
    assert.deepEqual(snap.caixa.ordemDinamica, esperada, k + ': a ordem dinâmica da Party é a do checkpoint');
    assert.ok(!snap.caixa.ordemDinamica.ordem.includes(A), k + ': a aliada (andou depois do ponto) já não está');
  }
  // E quem volta a entrar depois do «voltar» recebe a mesma.
  m.sair('aliada');
  m.entrar('aliada', { papel: 'jogadora', nome: 'Aliada Teste', senha: SENHAS.aliada });
  assert.deepEqual(m.clientes.aliada.ultimo('ROOM_SNAPSHOT').caixa.ordemDinamica, esperada);
});
