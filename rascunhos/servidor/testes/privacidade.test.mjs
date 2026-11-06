// Canários de privacidade (protocolo §6, ERRATA E-P1..E-P14, v0.2.1; base da JV1.2).
// Um guião completo com duas jogadoras, um espectador e o Mestre. Depois, varre-se TUDO o que
// chegou à Party à procura de valores que só o Mestre pode ver.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada, procurarCanarios, recibo, PIN, SENHAS, INICIATIVA } from './ajudantes.mjs';
import { CAMPOS_PERMITIDOS } from '../nucleo/projecao.js';

const SEMENTE = 0xc0ffee11;

// Valores que NENHUM papel da Party pode ver.
const NUMEROS_MESTRE = [
  9137, 7777, 313, 41, 61, // orc: CA, Vida, PA, RD, bonusCD (errata)
  6601, // vidaActual do orc depois do golpe (7777 − 1176)
  4949, 4848, // lobo: defesaAplicavel, Vida
  6363, 6464, // bandido (nunca colocado)
  SEMENTE, // semente (0xC0FFEE11)
  ...Object.values(INICIATIVA), // valores de iniciativa (a Party vê só a ordem)
];
const TEXTOS_MESTRE = [
  'CANARIO-RAZAO-IA', 'CANARIO-DESGRACA', 'CANARIO-FANTASMA', 'raio 23:59 CANARIO', '23:59',
  PIN, SENHAS.heroina, SENHAS.aliada, SENHAS.espectador,
  'c0ffee11', 'C0FFEE11', String(SEMENTE),
  'Orc Verdadeiro', 'orc-teste', 'lobo-teste', 'bandido-teste', 'pagina-',
];
const CHAVES_MESTRE = [
  'soMestre', 'semente', 'journalSeq', 'recibo', 'modo', 'verificacaoCritico', 'proposta', 'razao', 'fichaId',
  'campoNovoDoMotor', 'reacaoDefensiva', 'desgracaProposta', 'mestre', 'contexto', 'iniciativaValor', 'tokenHash',
];
// Da heroína: só ela os vê. Da aliada: só ela.
const NUMEROS_HEROINA = [8642, 5551, 5150, 4040];
const NUMEROS_ALIADA = [2468, 3579, 1357];

function guiao() {
  const m = montarMesa({ comAliada: true, comEspectador: true, rngSemente: () => SEMENTE });
  m.entrarTodos();
  // Lobby com o bandido disponível, mas NUNCA colocado (CANARIO-FANTASMA).
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 12, y: 12 }]]);
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  const lobo = h.idPorNome('Lobo');

  // Ocultos: modo H10 e painel do ambiente.
  exigirAplicada(m.mestre('MASTER_MODE', { figuraId: lobo, modo: 'semi' }));
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { hora: '23:59', clima: 'tempestade', futuro: 'raio 23:59 CANARIO' }));
  m.mestre('MASTER_SEARCH', { texto: 'bandido' });

  // Heroína acerta o orc: 1176 de dano (ela vê o número), o orc fica com 6601 (ninguém da Party vê).
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }));
  // Recusas indistinguíveis: id oculto (fichaId do bandido), inexistente.
  m.intencao('heroina', { tipo: 'atacar', alvoId: 'bandido-teste', arma: 'chicote-teste' }, { intentId: 'oculto-1' });
  m.intencao('heroina', { tipo: 'atacar', alvoId: 'f0000000000000000', arma: 'chicote-teste' }, { intentId: 'oculto-2' });
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));

  // Aliada: falha crítica → cartão de desgraça ao Mestre (CANARIO-DESGRACA) → aprovado.
  m.motor.cfg.resultado = 'falha_critica';
  const r = m.intencao('aliada', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'aliada-fc' });
  assert.equal(recibo(r).estado, 'AGUARDANDO_MESTRE');
  const cartaoDesgraca = m.clientes.mestre.ultimo('MASTER_CARD');
  assert.equal(cartaoDesgraca.tipo, 'desgraca');
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartaoDesgraca.cartaoId, decisao: 'aprovar' }));
  m.motor.cfg.resultado = 'acerto';
  exigirAplicada(m.intencao('aliada', { tipo: 'encerrar' }));

  // Lobo em semi: o Mestre aprova as propostas (CANARIO-RAZAO-IA nos cartões) até a vez passar.
  for (let i = 0; i < 8; i++) {
    const c = m.clientes.mestre.ultimo('MASTER_CARD');
    if (!m.sala.depuracao.estado().cartoes.some((x) => x.cartaoId === c.cartaoId && x.estado === 'aberto')) break;
    exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: c.cartaoId, decisao: 'aprovar' }));
  }
  // O orc (auto) joga sozinho; a vez volta à heroína.
  assert.equal(h.opcoes?.vezId, h.figuraId, 'a vez voltou à heroína');

  // Reconexões: RESYNC desde o início e snapshot, para todos os papéis da Party.
  for (const k of ['heroina', 'aliada', 'espectador']) {
    m.enviar(k, { type: 'ROOM_RESYNC', lastSeq: 0 });
    m.enviar(k, { type: 'ROOM_RESYNC' });
    m.enviar(k, { type: 'RECEIPT_QUERY', intentIds: ['aliada-fc', 'oculto-1'] });
  }
  return m;
}

test('canários: nada do Mestre chega a nenhum papel da Party (jogadoras e espectador)', () => {
  const m = guiao();
  for (const k of ['heroina', 'aliada', 'espectador']) {
    const achados = procurarCanarios(m.clientes[k].msgs, { numeros: NUMEROS_MESTRE, textos: TEXTOS_MESTRE, chaves: CHAVES_MESTRE });
    assert.deepEqual(achados, [], `vazamento para ${k}: ${JSON.stringify(achados.slice(0, 5))}`);
  }
  // Sanidade: o Mestre recebeu os canários (o teste não está a varrer o vazio).
  const mestre = JSON.stringify(m.clientes.mestre.msgs);
  for (const t of ['CANARIO-RAZAO-IA', 'CANARIO-DESGRACA', 'CANARIO-FANTASMA', 'raio 23:59 CANARIO', '9137', '6601', String(SEMENTE)]) {
    assert.ok(mestre.includes(t), 'o Mestre vê ' + t);
  }
});

test('canários: "outra jogadora" e espectador não veem a ficha, a Vida nem o dano alheio', () => {
  const m = guiao();
  const cfg = (numeros) => ({ numeros, textos: [], chaves: [] });
  assert.deepEqual(procurarCanarios(m.clientes.aliada.msgs, cfg(NUMEROS_HEROINA)), [], 'a aliada não vê a heroína (perícia 8642)');
  assert.deepEqual(procurarCanarios(m.clientes.espectador.msgs, cfg(NUMEROS_HEROINA)), []);
  assert.deepEqual(procurarCanarios(m.clientes.heroina.msgs, cfg(NUMEROS_ALIADA)), [], 'a heroína não vê a aliada');
  assert.deepEqual(procurarCanarios(m.clientes.espectador.msgs, cfg(NUMEROS_ALIADA)), []);
  // Número do dano: a heroína vê o dela (1176 no orc); o espectador nunca vê números de dano.
  assert.ok(JSON.stringify(m.clientes.heroina.msgs).includes('1176'), 'v0.2.1: ela vê o dano que causa');
  assert.deepEqual(procurarCanarios(m.clientes.espectador.msgs, cfg([1176])), [], 'o espectador não vê o número');
  // A-2: a aliada não vê o número do golpe da heroína (só os dela).
  const danosVistosPelaAliada = m.clientes.aliada.eventos('dano');
  const h = m.clientes.heroina;
  for (const e of danosVistosPelaAliada) {
    if (e.dados.autorId === h.figuraId) assert.ok(!('valor' in e.dados), 'sem número do golpe alheio');
  }
  // A própria vê a sua ficha (com a perícia 8642).
  assert.ok(JSON.stringify(h.msgs).includes('1d20+8642'));
});

test('lista de campos permitidos: todo o ROOM_EVENT da Party só tem campos da lista do seu tipo', () => {
  const m = guiao();
  for (const k of ['heroina', 'aliada', 'espectador']) {
    for (const e of m.clientes[k].eventos()) {
      const regra = CAMPOS_PERMITIDOS[e.tipo];
      assert.ok(regra, `tipo ${e.tipo} chegou a ${k} sem estar na lista`);
      const permitidos = new Set([...regra.todos, ...regra.propria]);
      for (const campo of Object.keys(e.dados)) assert.ok(permitidos.has(campo), `${k}: campo ${e.tipo}.${campo} fora da lista`);
      if (k === 'espectador') for (const campo of Object.keys(e.dados)) assert.ok(regra.todos.includes(campo), `espectador: ${e.tipo}.${campo}`);
    }
  }
});

test('E-P7: id oculto e id inexistente dão a MESMA recusa, byte a byte (tirando o intentId)', () => {
  const m = guiao();
  const rej = m.clientes.heroina.msgs.filter((x) => x.type === 'ROOM_REJECT' && (x.intentId === 'oculto-1' || x.intentId === 'oculto-2'));
  assert.equal(rej.length, 2);
  const semId = rej.map((x) => JSON.stringify({ ...x, intentId: 'X' }));
  assert.equal(semId[0], semId[1]);
  assert.equal(rej[0].motivo, 'acao_invalida');
});

test('seatToken: cada um só vê o seu; a exportação leva só o hash; PIN e senhas nunca entram', () => {
  const m = guiao();
  const tokens = Object.fromEntries(Object.entries(m.clientes).map(([k, c]) => [k, c.token]));
  for (const [k, c] of Object.entries(m.clientes)) {
    const texto = JSON.stringify(c.msgs);
    for (const [outro, tok] of Object.entries(tokens)) {
      if (outro !== k) assert.ok(!texto.includes(tok), `${k} viu o token de ${outro}`);
    }
  }
  const exp = m.sala.exportar();
  assert.ok(exp.includes('MESTRE-ONLY'));
  for (const tok of Object.values(tokens)) assert.ok(!exp.includes(tok), 'token na exportação');
  for (const s of [PIN, SENHAS.heroina, SENHAS.aliada, SENHAS.espectador]) assert.ok(!exp.includes(s), 'segredo na exportação');
});

test('E-P9: 5 ROOM_JOIN errados bloqueiam e avisam o Mestre; papel mestre sem PIN é recusado', () => {
  const m = montarMesa();
  m.entrarTodos();
  const mestre = m.clientes.mestre;
  const ip = '192.0.2.7';
  for (let i = 0; i < 5; i++) {
    const r = m.entrar('intrusa', { papel: 'jogadora', nome: 'Heroína Teste', senha: 'errada-' + i }, ip);
    assert.equal(r.ok, false);
  }
  assert.ok(mestre.msgs.some((x) => x.type === 'MASTER_ALERTA' && x.motivo === 'bloqueio_join'), 'alerta ao Mestre');
  const sexta = m.entrar('intrusa', { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina }, ip);
  assert.equal(sexta.ok, false, 'bloqueado mesmo com a senha certa');
  assert.equal(sexta.r.mensagens[0].codigo, 'bloqueado');
  // O alerta não leva o IP nem a senha tentada.
  assert.ok(!JSON.stringify(mestre.msgs).includes('errada-'));

  const semPin = m.entrar('falso-mestre', { papel: 'mestre' }, '192.0.2.8');
  assert.equal(semPin.ok, false);
  const pinErrado = m.entrar('falso-mestre', { papel: 'mestre', pin: '000000' }, '192.0.2.8');
  assert.equal(pinErrado.ok, false);
});

test('E-P9: a recusa do JOIN é a mesma para nome inexistente e para senha errada', () => {
  const m = montarMesa();
  m.entrarTodos();
  const a = m.entrar('x', { papel: 'jogadora', nome: 'Ninguém', senha: 'x' }, '192.0.2.9');
  const b = m.entrar('y', { papel: 'jogadora', nome: 'Heroína Teste', senha: 'x' }, '192.0.2.10');
  assert.equal(a.ok, false);
  assert.equal(b.ok, false);
  assert.deepEqual(a.r.mensagens, b.r.mensagens);
});

test('Mestre ausente: ROOM_PAUSED, intenções recusadas, nenhum cartão se aprova sozinho; RESUMED só após o RESYNC', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate();
  const h = m.clientes.heroina;
  m.sair('mestre');
  assert.equal(h.ultimo('ROOM_PAUSED')?.motivo, 'mestre_desconectado');
  const r = m.intencao('heroina', { tipo: 'encerrar' });
  assert.equal(recibo(r).motivo, 'sala_pausada');
  // O Mestre volta: só o JOIN não retoma.
  m.entrar('mestre', { papel: 'mestre', pin: PIN });
  assert.equal(h.ultimo('ROOM_RESUMED'), null);
  m.enviar('mestre', { type: 'ROOM_RESYNC', lastSeq: m.clientes.mestre.ultimoSeq });
  assert.equal(h.ultimo('ROOM_RESUMED')?.motivo, 'mestre_desconectado');
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
});
