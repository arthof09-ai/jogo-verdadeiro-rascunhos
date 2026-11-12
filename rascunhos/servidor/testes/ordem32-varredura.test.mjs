// Ordem 32 do CM-000009 — varredura do servidor (V29+): a ressincronização pelo `lastSeq` (ROOM_JOIN de volta e
// ROOM_RESYNC) depois das transacções que mudam o mundo por SNAPSHOT e não por eventos. Os testes de correcção falhavam
// antes (conferido com o sala.js de 92b414b) e passam depois; os de controlo passavam antes e continuam.
//
//  V29  «Voltar», «Recomeçar» e «Mudar a escala» mudam o mundo inteiro de uma vez: o evento que fica no fluxo
//       (`revertido`, `recomeco`, `escala`) não leva campos à Party, e o mundo novo vai num ROOM_SNAPSHOT a todos
//       (finalizar, `snapshotsTodos`). Esse snapshot NÃO fica no fluxo. Quem o perdeu (estava em baixo, ou a ligação
//       caiu entre o evento e o snapshot) e volta com o `lastSeq` recebia só os eventos do fluxo: o `revertido` e o
//       `recomeco` sem nada dentro, e nenhum snapshot. O cliente (estado.gd: «revertido (o snapshot vem a seguir)»)
//       ficava com o mundo de antes: a figura onde estava antes do «voltar», a fase `fim` depois do «recomeçar», a
//       escala velha. O ROOM_RESYNC.schema diz «os eventos lastSeq+1 … atual, OU um ROOM_SNAPSHOT»: quando o intervalo
//       atravessa um destes pontos, a resposta tem de ser o snapshot.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import { jsonCanonico } from '../nucleo/util.js';
import { sha256Hex } from '../nucleo/sha256.js';
import { montarMesa, exigirAplicada, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

function sessao() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 9 }], ['lobo-teste', { x: 12, y: 2 }]]);
  return m;
}

/** Cliente mínimo como o estado.gd: snapshot substitui o mundo; eventos só mexem no que trazem. */
function espelho() {
  return { seq: 0, fase: '', figuras: {}, casaM: null, vidaPropria: null };
}
function aplicar(e, msg) {
  if (msg.type === 'ROOM_SNAPSHOT') {
    if (msg.seq < e.seq) return;
    e.seq = msg.seq;
    e.fase = msg.fase;
    e.casaM = msg.mapa?.casaM ?? null;
    e.figuras = Object.fromEntries(msg.figuras.map((f) => [f.id, { x: f.x, y: f.y }]));
    e.vidaPropria = msg.propria?.vidaActual ?? null;
    return;
  }
  if (msg.type !== 'ROOM_EVENT' || msg.seq !== e.seq + 1) return;
  e.seq = msg.seq;
  const d = msg.dados ?? {};
  if (msg.tipo === 'colocacao') e.figuras[d.figuraId] = { x: d.x, y: d.y };
  if (msg.tipo === 'movimento' && e.figuras[d.figuraId] && d.para) e.figuras[d.figuraId] = { x: d.para.x, y: d.para.y };
  if (msg.tipo === 'turno' && (e.fase === 'lobby' || e.fase === '')) e.fase = 'combate';
  if (msg.tipo === 'fim') e.fase = 'fim';
  if (msg.tipo === 'estado' && d.vidaActual !== undefined) e.vidaPropria = d.vidaActual;
}
/** O espelho do cliente a partir de tudo o que lhe chegou (até ao índice `ate`, exclusivo). */
function espelhoDe(msgs, ate = msgs.length) {
  const e = espelho();
  for (const m of msgs.slice(0, ate)) aplicar(e, m);
  return e;
}
/** O que o servidor diz que é a verdade para este lugar (snapshot fresco: JOIN sem lastSeq). */
function verdade(sala, papel, credenciais) {
  const r = sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel, ...credenciais }, { ip: '10.7.7.7' });
  assert.equal(r.ok, true);
  return espelhoDe(r.mensagens);
}
const semSeq = (e) => ({ fase: e.fase, figuras: e.figuras, casaM: e.casaM, vidaPropria: e.vidaPropria });

/** A heroína cai; o Mestre faz `acao`; ela volta com o token e o lastSeq dela. Devolve o espelho dela e a resposta. */
function quedaEVolta(m, acao) {
  const h = m.clientes.heroina;
  const espelhoAntes = espelhoDe(h.msgs);
  m.sair('heroina'); // (o ajudante continua a entregar-lhe as saídas; o que ela sabe é o espelhoAntes)
  acao(m);
  const r = m.sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', seatToken: h.token, lastSeq: espelhoAntes.seq }, { ip: '10.0.0.2' });
  assert.equal(r.ok, true, 'ela volta');
  const e = espelhoAntes;
  for (const msg of r.mensagens) aplicar(e, msg);
  return { e, resposta: r.mensagens };
}

function andarHeroina(m) {
  const h = m.clientes.heroina;
  const destino = h.opcoes.mover.find((c) => c.x !== 2 || c.y !== 2);
  exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: destino.x, y: destino.y } }), 'mover');
  return destino;
}

test('V29: volta pelo lastSeq depois de um «voltar» — recebe o mundo revertido (a figura volta à casa)', () => {
  const m = sessao();
  const ponto = m.sala.depuracao.journalSeq();
  andarHeroina(m);
  const { e, resposta } = quedaEVolta(m, (mm) => exigirAplicada(mm.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: ponto }), 'voltar'));
  assert.ok(resposta.some((x) => x.type === 'ROOM_SNAPSHOT'), 'a resposta traz o snapshot (o intervalo atravessa o «voltar»)');
  assert.deepEqual(semSeq(e), semSeq(verdade(m.sala, 'jogadora', { nome: 'Heroína Teste', senha: SENHAS.heroina })),
    'o espelho dela é o mundo do servidor');
});

test('V29: volta pelo lastSeq depois de um «recomeçar» — sai da fase fim e as figuras voltam às casas', () => {
  const m = sessao();
  andarHeroina(m);
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' }), 'terminar');
  const { e, resposta } = quedaEVolta(m, (mm) => exigirAplicada(mm.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar'));
  assert.ok(resposta.some((x) => x.type === 'ROOM_SNAPSHOT'), 'a resposta traz o snapshot (o intervalo atravessa o «recomeçar»)');
  assert.equal(e.fase, 'combate', 'não fica no fim');
  assert.deepEqual(semSeq(e), semSeq(verdade(m.sala, 'jogadora', { nome: 'Heroína Teste', senha: SENHAS.heroina })));
});

test('V29: volta pelo lastSeq depois de «mudar a escala» — recebe a escala nova', () => {
  const m = sessao();
  const { e, resposta } = quedaEVolta(m, (mm) => exigirAplicada(mm.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 2 }), 'escala'));
  assert.ok(resposta.some((x) => x.type === 'ROOM_SNAPSHOT'), 'a resposta traz o snapshot (o intervalo atravessa a escala)');
  assert.equal(e.casaM, 2);
});

test('V29: ligação que caiu entre o evento e o snapshot do «voltar» (lastSeq = seq do snapshot) — recebe-o outra vez', () => {
  const m = sessao();
  const ponto = m.sala.depuracao.journalSeq();
  andarHeroina(m);
  const h = m.clientes.heroina;
  const n = h.msgs.length;
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: ponto }), 'voltar');
  // O que chegou de facto: tudo até ao evento `revertido` (inclusive); o snapshot a seguir perdeu-se com a ligação.
  const iRev = h.msgs.findIndex((x, i) => i >= n && x.type === 'ROOM_EVENT' && x.tipo === 'revertido');
  assert.ok(iRev >= 0);
  const chegou = h.msgs.slice(0, iRev + 1);
  const e = espelhoDe(chegou);
  m.sair('heroina');
  const r = m.sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', seatToken: h.token, lastSeq: e.seq }, { ip: '10.0.0.2' });
  for (const msg of r.mensagens) aplicar(e, msg);
  assert.deepEqual(semSeq(e), semSeq(verdade(m.sala, 'jogadora', { nome: 'Heroína Teste', senha: SENHAS.heroina })));
});

test('V29: ROOM_RESYNC com um buraco que atravessa o «voltar» — responde com o snapshot', () => {
  const m = sessao();
  const ponto = m.sala.depuracao.journalSeq();
  andarHeroina(m);
  const h = m.clientes.heroina;
  const lastSeq = h.ultimoSeq;
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: ponto }), 'voltar');
  const out = m.enviar('heroina', { type: 'ROOM_RESYNC', lastSeq });
  assert.ok(out.some((x) => x.type === 'ROOM_SNAPSHOT'), 'snapshot: ' + out.map((x) => x.type + ':' + (x.tipo ?? '')).join(','));
});

test('V29: o corte sobrevive ao restauro do journal (o servidor morreu depois do «voltar»)', () => {
  const m = sessao();
  const ponto = m.sala.depuracao.journalSeq();
  andarHeroina(m);
  const h = m.clientes.heroina;
  const espelhoAntes = espelhoDe(h.msgs);
  m.sair('heroina');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: ponto }), 'voltar');
  const config = {
    roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  const sala = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(3), agora: relogio(), config, restaurarDe: m.sala.exportar() });
  // Ordem 22 (17-2): a sala restaurada a meio da batalha espera pelo Mestre; ele entra primeiro.
  const rm = sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'mestre', pin: PIN, seatToken: m.clientes.mestre.token, lastSeq: m.clientes.mestre.ultimoSeq }, { ip: '10.0.0.9' });
  assert.equal(rm.ok, true);
  sala.conexaoAberta(rm.seatId);
  const r = sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', seatToken: h.token, lastSeq: espelhoAntes.seq }, { ip: '10.0.0.2' });
  assert.equal(r.ok, true);
  for (const msg of r.mensagens) aplicar(espelhoAntes, msg);
  assert.ok(r.mensagens.some((x) => x.type === 'ROOM_SNAPSHOT'), 'snapshot também depois do restauro');
  assert.deepEqual(semSeq(espelhoAntes), semSeq(verdade(sala, 'jogadora', { nome: 'Heroína Teste', senha: SENHAS.heroina })));
});

test('V29: journal gravado antes da ordem 32 (sem seqSnapshot) — o corte vem do evento no fluxo', () => {
  const m = sessao();
  const ponto = m.sala.depuracao.journalSeq();
  andarHeroina(m);
  const h = m.clientes.heroina;
  const espelhoAntes = espelhoDe(h.msgs);
  m.sair('heroina');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: ponto }), 'voltar');
  // A exportação como a escrevia o servidor de antes: os lugares sem `seqSnapshot` (sha256 sem chave, recalculado).
  const texto = m.sala.exportar().split(String.fromCharCode(10))[0];
  const corpo = JSON.parse(texto);
  for (const l of Object.values(corpo.estado.lugares)) delete l.seqSnapshot;
  const novoTexto = jsonCanonico(corpo);
  const antigo = `${novoTexto}${String.fromCharCode(10)}sha256:${sha256Hex(novoTexto)}${String.fromCharCode(10)}`;
  const config = {
    roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  const sala = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(3), agora: relogio(), config, restaurarDe: antigo });
  assert.ok(Object.values(sala.depuracao.estado().lugares).every((l) => l.seqSnapshot === undefined), 'sem o campo');
  const rm = sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'mestre', pin: PIN, seatToken: m.clientes.mestre.token, lastSeq: m.clientes.mestre.ultimoSeq }, { ip: '10.0.0.9' });
  sala.conexaoAberta(rm.seatId);
  const r = sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', seatToken: h.token, lastSeq: espelhoAntes.seq }, { ip: '10.0.0.2' });
  assert.equal(r.ok, true);
  for (const msg of r.mensagens) aplicar(espelhoAntes, msg);
  assert.ok(r.mensagens.some((x) => x.type === 'ROOM_SNAPSHOT'));
  assert.deepEqual(semSeq(espelhoAntes), semSeq(verdade(sala, 'jogadora', { nome: 'Heroína Teste', senha: SENHAS.heroina })));
});

// ------------------------------------------------------------------ controlos (passavam antes)

test('V29 controlo: volta pelo lastSeq sem nenhum destes pontos no intervalo — continua a receber os EVENTOS (a narração)', () => {
  const m = sessao();
  const ponto = m.sala.depuracao.journalSeq();
  andarHeroina(m);
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: ponto }), 'voltar'); // ela viu tudo, ligada
  andarHeroina(m); // e o fluxo dela passou do snapshot (com o lastSeq = seq do snapshot, recebe-o outra vez: teste acima)
  const { e, resposta } = quedaEVolta(m, (mm) => exigirAplicada(mm.mestre('MASTER_PLACE', { fichaId: 'bandido-teste', casa: { x: 15, y: 15 } }), 'colocar'));
  assert.ok(!resposta.some((x) => x.type === 'ROOM_SNAPSHOT'), 'sem snapshot: os eventos chegam');
  assert.ok(resposta.some((x) => x.type === 'ROOM_EVENT'), 'eventos do fluxo');
  assert.deepEqual(e.figuras, verdade(m.sala, 'jogadora', { nome: 'Heroína Teste', senha: SENHAS.heroina }).figuras);
});

test('V29 controlo: um movimento perdido chega por evento (sem snapshot)', () => {
  const m = sessao();
  const { e, resposta } = quedaEVolta(m, () => {});
  assert.ok(!resposta.some((x) => x.type === 'ROOM_SNAPSHOT'));
  assert.equal(e.fase, 'combate');
});

// ------------------------------------------------------------------ V30
//  V30  A pausa e a retomada vão à Party em ROOM_PAUSED / ROOM_RESUMED (o `anuncio` do finalizar), que não são
//       ROOM_EVENT nem ficam no fluxo; o evento `pausa` é interno (só o Mestre). Quem estava em baixo quando a mesa
//       pausou ou retomou, e volta pelo lastSeq, recebia só os eventos (muitas vezes nenhum) e nada da pausa: ficava
//       a ver a mesa a correr com ela parada, ou — pior — presa no ecrã da pausa com a batalha já retomada (o
//       estado.gd só sai da pausa com um ROOM_RESUMED ou com um snapshot sem fase `pausa`).

/** O que o estado.gd faz com a pausa: o snapshot diz-a pela fase; os anúncios mudam-na. */
function pausadaDepois(antes, msgs) {
  let p = antes;
  for (const x of msgs) {
    if (x.type === 'ROOM_SNAPSHOT') p = x.fase === 'pausa';
    if (x.type === 'ROOM_PAUSED') p = true;
    if (x.type === 'ROOM_RESUMED') p = false;
  }
  return p;
}

test('V30: a mesa pausou enquanto ela estava em baixo — ao voltar pelo lastSeq, sabe que está em pausa', () => {
  const m = sessao();
  const h = m.clientes.heroina;
  const lastSeq = espelhoDe(h.msgs).seq;
  m.sair('heroina');
  exigirAplicada(m.mestre('MASTER_PAUSE'), 'pausa');
  const r = m.sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', seatToken: h.token, lastSeq }, { ip: '10.0.0.2' });
  assert.equal(r.ok, true);
  assert.equal(pausadaDepois(false, r.mensagens), true, r.mensagens.map((x) => x.type).join(','));
});

test('V30: a mesa retomou enquanto ela estava em baixo — ao voltar pelo lastSeq, sai da pausa', () => {
  const m = sessao();
  exigirAplicada(m.mestre('MASTER_PAUSE'), 'pausa');
  const h = m.clientes.heroina;
  assert.equal(pausadaDepois(false, h.msgs), true, 'ela viu a pausa, ligada');
  const lastSeq = espelhoDe(h.msgs).seq;
  m.sair('heroina');
  exigirAplicada(m.mestre('MASTER_RESUME'), 'retomar');
  const r = m.sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', seatToken: h.token, lastSeq }, { ip: '10.0.0.2' });
  assert.equal(r.ok, true);
  assert.equal(pausadaDepois(true, r.mensagens), false, r.mensagens.map((x) => x.type).join(','));
});

test('V30: a queda do Mestre pausou e a volta dele retomou, tudo com ela em baixo — fica a saber que a mesa corre', () => {
  const m = sessao();
  const h = m.clientes.heroina;
  const lastSeq = espelhoDe(h.msgs).seq;
  m.sair('heroina');
  m.sair('mestre'); // E-C4
  assert.equal(m.sala.depuracao.estado().fase, 'pausa');
  m.entrar('mestre', { papel: 'mestre', pin: PIN, seatToken: m.clientes.mestre.token, lastSeq: m.clientes.mestre.ultimoSeq });
  m.enviar('mestre', { type: 'ROOM_RESYNC', lastSeq: m.clientes.mestre.ultimoSeq }); // E-C4: a retomada sai do RESYNC dele
  assert.equal(m.sala.depuracao.estado().fase, 'combate');
  // Ela tinha visto a pausa? Não: caiu antes. O cliente dela diz «não pausada» e a mesa corre: tem de continuar assim.
  const r = m.sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', seatToken: h.token, lastSeq }, { ip: '10.0.0.2' });
  assert.equal(pausadaDepois(false, r.mensagens), false);
  // E se tivesse ficado com a pausa (caiu logo a seguir ao ROOM_PAUSED): sai dela.
  assert.equal(pausadaDepois(true, r.mensagens), false, r.mensagens.map((x) => x.type).join(','));
});

test('V30 controlo: sem pausa nem retomada no intervalo, a volta continua por eventos', () => {
  const m = sessao();
  const h = m.clientes.heroina;
  const lastSeq = espelhoDe(h.msgs).seq;
  m.sair('heroina');
  exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'bandido-teste', casa: { x: 15, y: 15 } }), 'colocar');
  const r = m.sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', seatToken: h.token, lastSeq }, { ip: '10.0.0.2' });
  assert.ok(!r.mensagens.some((x) => x.type === 'ROOM_SNAPSHOT'));
  assert.ok(r.mensagens.some((x) => x.type === 'ROOM_EVENT' && x.tipo === 'colocacao'));
  assert.equal(pausadaDepois(false, r.mensagens), false);
});

// ------------------------------------------------------------------ V31
//  V31  Ordem 22 (17-2): na sala restaurada, quem entra antes do Mestre recebe o lobby de espera — um ROOM_SNAPSHOT
//       com o seq VERDADEIRO do lugar e sem nada da batalha. Quando o Mestre entra, a batalha (snapshot) vai só a quem
//       está ligado nesse instante. Quem recebeu o lobby, caiu, e volta depois do Mestre com esse lastSeq recebia os
//       eventos desde lá (nenhum) e ficava no lobby vazio com a batalha a correr — sem figuras, sem vez, sem a ficha
//       a meio da batalha.

test('V31: recebeu o lobby de espera, caiu, o Mestre entrou — ao voltar pelo lastSeq recebe a batalha', () => {
  const m = sessao();
  const config = {
    roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  const sala = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(5), agora: relogio(), config, restaurarDe: m.sala.exportar() });
  const h = m.clientes.heroina;
  const r1 = sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', seatToken: h.token, lastSeq: h.ultimoSeq }, { ip: '10.0.0.2' });
  assert.equal(r1.ok, true);
  sala.conexaoAberta(r1.seatId);
  const e = espelhoDe(r1.mensagens);
  assert.equal(e.fase, 'lobby', 'sala de espera');
  sala.conexaoFechada(r1.seatId); // caiu
  const rm = sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'mestre', pin: PIN, seatToken: m.clientes.mestre.token, lastSeq: m.clientes.mestre.ultimoSeq }, { ip: '10.0.0.9' });
  sala.conexaoAberta(rm.seatId);
  const tokenNovo = r1.mensagens.find((x) => x.type === 'ROOM_WELCOME').seatToken;
  const r2 = sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', seatToken: tokenNovo, lastSeq: e.seq }, { ip: '10.0.0.2' });
  assert.equal(r2.ok, true);
  for (const msg of r2.mensagens) aplicar(e, msg);
  assert.equal(e.fase, 'combate', r2.mensagens.map((x) => x.type).join(','));
  assert.deepEqual(semSeq(e), semSeq(verdade(sala, 'jogadora', { nome: 'Heroína Teste', senha: SENHAS.heroina })));
});

test('V31 controlo: ligada quando o Mestre entra — recebe a batalha logo (ordem 22) e depois segue por eventos', () => {
  const m = sessao();
  const config = {
    roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  const sala = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(5), agora: relogio(), config, restaurarDe: m.sala.exportar() });
  const h = m.clientes.heroina;
  const r1 = sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', seatToken: h.token, lastSeq: h.ultimoSeq }, { ip: '10.0.0.2' });
  sala.conexaoAberta(r1.seatId);
  const rm = sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'mestre', pin: PIN, seatToken: m.clientes.mestre.token, lastSeq: m.clientes.mestre.ultimoSeq }, { ip: '10.0.0.9' });
  sala.conexaoAberta(rm.seatId);
  const e = espelhoDe([...r1.mensagens, ...rm.saidas.filter((x) => x.seatId === r1.seatId).map((x) => x.msg)]);
  assert.equal(e.fase, 'combate');
  assert.deepEqual(semSeq(e), semSeq(verdade(sala, 'jogadora', { nome: 'Heroína Teste', senha: SENHAS.heroina })));
});
