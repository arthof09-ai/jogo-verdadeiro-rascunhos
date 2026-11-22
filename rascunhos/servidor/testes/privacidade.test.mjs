// Canários de privacidade (protocolo §6, ERRATA E-P1..E-P14, v0.2.1; base da JV1.2).
// Um guião completo com duas jogadoras, um espectador e o Mestre. Depois, varre-se TUDO o que
// chegou à Party à procura de valores que só o Mestre pode ver.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  montarMesa, exigirAplicada, procurarCanarios, recibo, varrer, PIN, SENHAS,
  SEMENTE, NUMEROS_SO_MESTRE, TEXTOS_SO_MESTRE, CHAVES_SO_MESTRE, NUMEROS_HEROINA, NUMEROS_ALIADA, TEXTOS_HEROINA,
} from './ajudantes.mjs';
import { CAMPOS_PERMITIDOS } from '../nucleo/projecao.js';

// Ordem CAIXA-TESTES-CORRECOES-3 (B7): as listas vêm de ajudantes.mjs (uma só fonte com caixa-hud-jogadora.test.mjs).
// Valores que NENHUM papel da Party pode ver.
const NUMEROS_MESTRE = NUMEROS_SO_MESTRE;
// Os textos de qualquer mesa + os canários deste guião (cartões da IA e da desgraça, o bandido-fantasma, o ambiente).
const TEXTOS_MESTRE = [
  'CANARIO-RAZAO-IA', 'CANARIO-DESGRACA', 'CANARIO-FANTASMA', 'raio 23:59 CANARIO', '23:59',
  ...TEXTOS_SO_MESTRE,
];
const CHAVES_MESTRE = CHAVES_SO_MESTRE;
// Da heroína: só ela os vê. Da aliada: só ela. (NUMEROS_HEROINA / NUMEROS_ALIADA, de ajudantes.mjs.)

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

  // Ordem CAIXA-TESTES (21/11/2026, correcção B5-b): o Mestre muda a caixa (escolherCaixa) a meio da batalha, com a
  // ordem dinâmica já formada — a Party recebe um ROOM_SNAPSHOT com a `caixa` dela, e esse caminho também é varrido.
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'caixa', caixa: { ligada: true, modo: 'iniciativa' } }), 'caixa iniciativa');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'caixa', caixa: { ligada: false, modo: 'iniciativa' } }), 'caixa desligada');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'caixa', caixa: { ligada: true, modo: 'dinamico' } }), 'caixa dinâmico');

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
  // Sanidade (B5-b): o caminho do escolherCaixa correu e foi varrido — cada papel da Party recebeu os snapshots da caixa,
  // com a ordem dinâmica já formada (não vazia); o Mestre recebeu a escolha dele na MASTER_VIEW.
  for (const k of ['heroina', 'aliada', 'espectador']) {
    const caixas = m.clientes[k].msgs.filter((x) => x.type === 'ROOM_SNAPSHOT' && x.caixa).map((x) => x.caixa);
    assert.ok(caixas.some((c) => c.ligada === true && c.ordemPor === 'iniciativa'), k + ': snapshot da caixa em iniciativa');
    assert.ok(caixas.some((c) => c.ligada === false), k + ': snapshot da caixa desligada');
    assert.ok(caixas.some((c) => c.ordemDinamica.ordem.length > 0), k + ': a caixa varrida traz a ordem dinâmica da Party');
    // B2 (CAIXA-TESTES-CORRECOES-2): o VALOR da ordem nos snapshots do escolherCaixa (os únicos em `iniciativa`) é o da
    // ordemDinamicaParty do servidor (nada mexe nela depois das escolhas), com 2+ figuras para uma ordem trocada se ver.
    const odParty = m.sala.depuracao.estado().ordemDinamicaParty.ordem;
    assert.ok(odParty.length >= 2, 'a ordem da Party tem 2+ figuras');
    for (const c of caixas.filter((x) => x.ordemPor === 'iniciativa')) assert.deepEqual(c.ordemDinamica.ordem, odParty, k + ': a ordem no snapshot do escolherCaixa');
    // B6 (CAIXA-TESTES-CORRECOES): as chaves exactas da caixa da Party em todos os snapshots — nada a mais, nada a menos.
    for (const c of caixas) {
      assert.deepEqual(Object.keys(c).sort(), ['ligada', 'ordemDinamica', 'ordemPor'], k + ': as chaves da caixa');
      assert.deepEqual(Object.keys(c.ordemDinamica).sort(), ['fechada', 'ordem', 'ultimo'], k + ': as chaves da ordem dinâmica');
    }
  }
  const vistaMestre = m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW');
  assert.deepEqual(vistaMestre.caixaMestre, { ligada: true, modo: 'dinamico' }, 'o Mestre vê a escolha dele');
  // Sanidade: o Mestre recebeu os canários (o teste não está a varrer o vazio).
  const mestre = JSON.stringify(m.clientes.mestre.msgs);
  // CAIXA-TESTES-CORRECOES-3 (B3): também o nome verdadeiro do lobo e os verbos do orc e do lobo.
  for (const t of ['CANARIO-RAZAO-IA', 'CANARIO-DESGRACA', 'CANARIO-FANTASMA', 'raio 23:59 CANARIO', '9137', '6601', String(SEMENTE),
    'Lobo Teste', 'desferiu o machado', 'tentou desferir o machado', 'deu uma patada', 'tentou dar uma patada']) {
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
  // Ordem CAIXA-TESTES-CORRECOES-4 (B2): a perícia 8642 também como TEXTO ('1d20+8642' na ficha). NUMEROS_HEROINA só a
  // apanha como número; a aliada e o espectador não a podem ver em string nenhuma. (A heroína fica de fora: é dela.)
  const txt = (textos) => ({ numeros: [], textos, chaves: [] });
  assert.deepEqual(procurarCanarios(m.clientes.aliada.msgs, txt(TEXTOS_HEROINA)), [], 'a aliada não vê a perícia da heroína em texto');
  assert.deepEqual(procurarCanarios(m.clientes.espectador.msgs, txt(TEXTOS_HEROINA)), [], 'o espectador não vê a perícia da heroína em texto');
});

// Ordem CAIXA-TESTES-CORRECOES-4 (B1): a Vida VARIÁVEL. NUMEROS_HEROINA/NUMEROS_ALIADA só têm a Vida máxima (5150/3579):
// a `vidaActual` de uma jogadora ferida (no guião, a aliada fica com 2403 = 3579 − 1176) posta no snapshot da outra
// passava calada. Duas guardas: (1) o VALOR — cada Vida actual que cada jogadora teve no guião (CORRECOES-5, B4: o
// histórico, não só a do fim), não chega à outra nem ao espectador, em mensagem nenhuma; (2) a FORMA — cada ROOM_SNAPSHOT da Party mostra só as
// `vidaActual` que esse papel pode ver (a própria, em `propria`; nenhuma ao espectador) e as figuras públicas têm as
// chaves exactas de projecao.js figuraPublica (sem Vida de ninguém). A figura não tem `vidaTotal` (sala.js novaFigura):
// a Vida máxima vem da ficha.
test('canários: a Vida actual (variável) de uma jogadora ferida não chega à outra jogadora nem ao espectador', () => {
  const m = guiao();
  const est = m.sala.depuracao.estado();
  const figuraDe = { heroina: m.clientes.heroina.figuraId, aliada: m.clientes.aliada.figuraId };
  const vidaActual = (k) => est.figuras[figuraDe[k]].vidaActual;
  const vidaTotal = (k) => m.fichas[est.figuras[figuraDe[k]].fichaId].vidaTotal;
  // Sanidade: o canário variável está vivo — a aliada está ferida (Vida actual ≠ a máxima das listas fixas).
  assert.ok(vidaActual('aliada') < vidaTotal('aliada'), `a aliada está ferida (${vidaActual('aliada')}/${vidaTotal('aliada')})`);
  // Ordem CAIXA-TESTES-CORRECOES-5 (B4): a guarda (1) varre TODOS os valores que a Vida actual de cada jogadora teve no
  // guião, não só o do fim. Hoje a aliada fere-se num só passo (3579 → 2403), e aí o valor final é o único intermédio;
  // mas um segundo golpe (ou uma cura) depois de um snapshot com fuga deixava o valor que fugiu ≠ o do fim, e uma guarda
  // só com o do fim passava calada. O histórico vem de: a Vida máxima (o valor de partida, da ficha), cada evento
  // `estado` do journal com a `vidaActual` dessa figura (é o evento que regista cada mudança da Vida), a `propria` de
  // cada snapshot que a própria recebeu, e o valor final do estado da sala. Valores < 100 ficam de fora: não são
  // canários (colidem com contadores, coordenadas e o 0 de quem cai) — a Vida das fichas de teste fica toda acima.
  const historicoVida = (k) => {
    const fig = figuraDe[k];
    const v = new Set([vidaTotal(k), vidaActual(k)]);
    for (const e of m.sala.depuracao.eventos()) {
      if (e.tipo === 'estado' && e.dados?.figuraId === fig && typeof e.dados.vidaActual === 'number') v.add(e.dados.vidaActual);
    }
    for (const s of m.clientes[k].msgs) if (s.type === 'ROOM_SNAPSHOT' && typeof s.propria?.vidaActual === 'number') v.add(s.propria.vidaActual);
    return [...v].filter((x) => x >= 100).sort((a, b) => a - b);
  };
  // Sanidade do histórico: a fonte não está morta — a aliada passou pela máxima e pela ferida (hoje [2403, 3579]).
  assert.ok(historicoVida('aliada').includes(vidaActual('aliada')) && historicoVida('aliada').includes(vidaTotal('aliada')),
    `o histórico da Vida da aliada tem a de partida e a do fim (${historicoVida('aliada')})`);
  assert.ok(m.sala.depuracao.eventos().some((e) => e.tipo === 'estado' && e.dados?.figuraId === figuraDe.aliada && e.dados.vidaActual === vidaActual('aliada')),
    'o journal regista a Vida ferida da aliada num evento `estado` (a fonte dos intermédios)');
  // (1) O valor — cada valor do histórico —, em tudo o que chegou (snapshots e eventos).
  const cfg = (numeros) => ({ numeros, textos: [], chaves: [] });
  for (const [dona, outros] of [['heroina', ['aliada', 'espectador']], ['aliada', ['heroina', 'espectador']]]) {
    for (const k of outros) {
      assert.deepEqual(procurarCanarios(m.clientes[k].msgs, cfg(historicoVida(dona))), [], `${k} viu uma Vida actual de ${dona} (${historicoVida(dona)})`);
    }
  }
  // (2) A forma, snapshot a snapshot.
  const CHAVES_FIGURA_PUBLICA = ['id', 'lado', 'nomePublico', 'orientacao', 'visivel', 'x', 'y'];
  for (const k of ['heroina', 'aliada', 'espectador']) {
    const snaps = m.clientes[k].msgs.filter((x) => x.type === 'ROOM_SNAPSHOT');
    assert.ok(snaps.length >= 2, k + ': snapshots varridos');
    for (const s of snaps) {
      const vidas = [];
      varrer(s, ({ chave, valor, ehChave }) => { if (!ehChave && chave === 'vidaActual') vidas.push(valor); });
      if (k === 'espectador') {
        assert.equal(s.propria, undefined, 'o espectador não tem `propria`');
        assert.deepEqual(vidas, [], 'o espectador não vê Vida actual nenhuma');
      } else {
        assert.equal(s.propria?.figuraId, figuraDe[k], k + ': a `propria` é a dela');
        assert.deepEqual(vidas, [s.propria.vidaActual], k + ': só a Vida actual dela, em `propria`');
      }
      for (const f of s.figuras) assert.deepEqual(Object.keys(f).sort(), CHAVES_FIGURA_PUBLICA, k + ': as chaves da figura pública');
    }
    // Sanidade da exclusão: no último snapshot (o do RESYNC no fim do guião) a jogadora vê a Vida actual DELA — a ferida
    // vê o 2403.
    if (k !== 'espectador') assert.equal(snaps.at(-1).propria.vidaActual, vidaActual(k), k + ': vê a Vida actual dela');
  }
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
