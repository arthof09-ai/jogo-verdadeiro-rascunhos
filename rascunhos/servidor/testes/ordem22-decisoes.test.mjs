// Ordem 22 do CM-000009 — duas decisões do Mestre (11/11/2026). Cada teste de correcção falhava antes (conferido com o
// sala.js de 276e573) e passa depois; os de controlo passavam antes e continuam.
//
//  17-2  (Mestre, 14:27: «Uma batalha não pode acontecer sem mim; se entrar antes de mim, fica no lobby que criamos.»)
//        Sala restaurada a meio de um combate: quem entra antes do Mestre fica no LOBBY (sala de espera) — não vê a
//        batalha nem recebe opções; a batalha só retoma com o Mestre dentro. Substitui a pausa da ordem 18.
//  N21-1 (Mestre, 16:13: SIM) O aviso do motor (aviso_motor, N18-2) vai também na MASTER_VIEW (`avisoMotor`), para o
//        Mestre que entra de fresco (sem lastSeq: só recebe o snapshot, que não traz eventos).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import { despejar, montarMesa, exigirAplicada, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const CONFIG = () => ({
  roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
  lugares: [
    { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
    { papel: 'mestre', nome: 'Mestre', pin: PIN },
  ],
});

function criarDe(restaurarDe, { motor = criarMotorFalso() } = {}) {
  return criarSala({ motores: motor, fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config: CONFIG(), restaurarDe });
}

/** Sessão em combate, deixada na vez da heroína (para provar que as opções dela não saem na sala de espera). */
function sessao() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 12, y: 2 }]]);
  return m;
}

const lugarDe = (sala, papel) => Object.values(sala.depuracao.estado().lugares).find((s) => s.papel === papel);
const JOIN_HEROINA = { v: 2, type: 'ROOM_JOIN', papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina };
const JOIN_MESTRE = { v: 2, type: 'ROOM_JOIN', papel: 'mestre', pin: PIN };
const respostaA = (saidas, seatId) => saidas.filter((s) => s.seatId === seatId).map((s) => s.msg);
const reciboDe = (msgs) => msgs.find((x) => x.type === 'ROOM_RECEIPT' || x.type === 'ROOM_REJECT') ?? null;

function ligar(sala, join, ip) {
  const r = sala.entrar(join, { ip });
  assert.equal(r.ok, true, 'entrou');
  sala.conexaoAberta(r.seatId);
  return r;
}

/** O snapshot de lobby da sala de espera: nada da batalha. */
function eLobbyDeEspera(snap) {
  assert.ok(snap, 'há snapshot');
  despejar('sai', 'heroina', snap); // entra no tráfego conferido com o schema (job protocolo)
  assert.equal(snap.fase, 'lobby', 'fica no lobby');
  assert.deepEqual(snap.figuras, [], 'não vê as figuras da batalha');
  assert.deepEqual(snap.iniciativa, [], 'nem a ordem');
  assert.equal(snap.vezId, null, 'nem de quem é a vez');
  assert.equal(snap.rodada, 0, 'nem a rodada');
  // A ficha dela vem, como no lobby de sempre (é dela; o schema da jogadora exige-a), mas a figura não está no mapa.
  assert.ok(snap.propria?.ficha, 'a ficha dela, como no lobby');
  assert.equal(snap.ambiente.clima, null, 'nem o tempo da batalha');
  assert.deepEqual(snap.fogo?.casas ?? [], [], 'nem o fogo');
}

// ------------------------------------------------------------------ 17-2 (a): a jogadora antes do Mestre → lobby

test('ordem 22 (17-2 a): sala restaurada em combate — a jogadora entra antes do Mestre e fica no lobby', () => {
  const m = sessao();
  const exportado = m.sala.exportar();
  const sala2 = criarDe(exportado);
  assert.equal(sala2.depuracao.estado().fase, 'combate');
  const seqAntes = sala2.depuracao.journalSeq();

  const rh = ligar(sala2, JOIN_HEROINA, '10.0.1.1');
  assert.ok(rh.mensagens.some((x) => x.type === 'ROOM_WELCOME'));
  eLobbyDeEspera(rh.mensagens.find((x) => x.type === 'ROOM_SNAPSHOT'));
  assert.ok(!rh.mensagens.some((x) => x.type === 'ROOM_OPTIONS' || x.type === 'ROOM_EVENT'), 'sem opções nem eventos da batalha');
  assert.ok(!rh.mensagens.some((x) => x.type === 'ROOM_PAUSED'), 'não é a pausa da ordem 18');

  // A batalha não muda: nem pausa, nem nada escrito no journal.
  assert.equal(sala2.depuracao.estado().fase, 'combate', 'a batalha fica onde estava, à espera do Mestre');
  assert.equal(sala2.depuracao.journalSeq(), seqAntes, 'entrar na sala de espera não escreve nenhum evento');

  // Um RESYNC (mesmo com lastSeq) não lhe dá o fluxo da batalha: continua o lobby.
  const rs = respostaA(sala2.receber(rh.seatId, { v: 2, type: 'ROOM_RESYNC', lastSeq: 0 }), rh.seatId);
  eLobbyDeEspera(rs.find((x) => x.type === 'ROOM_SNAPSHOT'));
  assert.ok(!rs.some((x) => x.type === 'ROOM_EVENT' || x.type === 'ROOM_OPTIONS'));

  // A reentrada com token e lastSeq (aparelho que viu a batalha antes da queda) também fica no lobby.
  const rt = sala2.entrar({ v: 2, type: 'ROOM_JOIN', papel: 'jogadora', seatToken: rh.mensagens[0].seatToken, lastSeq: 1 }, { ip: '10.0.1.1', seatIdDaLigacao: rh.seatId });
  assert.equal(rt.ok, true);
  eLobbyDeEspera(rt.mensagens.find((x) => x.type === 'ROOM_SNAPSHOT'));
  assert.ok(!rt.mensagens.some((x) => x.type === 'ROOM_EVENT'));

  // Não age: a intenção é recusada como no lobby, e a batalha não anda.
  const rev = lugarDe(sala2, 'jogadora').revision;
  const resp = respostaA(sala2.receber(rh.seatId, { v: 2, type: 'ROOM_INTENT', intentId: 'it-o22-1', revision: rev, acao: { tipo: 'encerrar' } }), rh.seatId);
  assert.equal(reciboDe(resp)?.motivo, 'fora_da_vez', 'no lobby não há vez');
  assert.equal(sala2.depuracao.estado().vez?.figuraId, m.sala.depuracao.estado().vez?.figuraId, 'a vez não passou');
});

// ------------------------------------------------------------------ 17-2 (b): o Mestre entra a seguir → retoma

test('ordem 22 (17-2 b): o Mestre entra a seguir — a jogadora sai do lobby para a batalha, com as opções', () => {
  const m = sessao();
  const sala2 = criarDe(m.sala.exportar());
  const rh = ligar(sala2, JOIN_HEROINA, '10.0.2.1');
  eLobbyDeEspera(rh.mensagens.find((x) => x.type === 'ROOM_SNAPSHOT'));

  const rm = ligar(sala2, JOIN_MESTRE, '10.0.2.2');
  const paraEla = respostaA(rm.saidas, rh.seatId);
  const snap = paraEla.find((x) => x.type === 'ROOM_SNAPSHOT');
  assert.ok(snap, 'com o Mestre dentro, a jogadora recebe a batalha');
  assert.equal(snap.fase, 'combate');
  assert.ok(snap.figuras.length > 0);
  assert.ok(snap.propria, 'e a ficha dela');
  const vezDela = sala2.depuracao.estado().vez?.figuraId === lugarDe(sala2, 'jogadora').figuraId;
  assert.equal(paraEla.some((x) => x.type === 'ROOM_OPTIONS'), vezDela, 'as opções, se for a vez dela');
  assert.equal(sala2.depuracao.estado().fase, 'combate');
  assert.ok(!sala2.depuracao.eventos().some((e) => e.tipo === 'pausa' || e.tipo === 'retomada'), 'sem pausa nem retomada no journal');

  // Daqui em diante o RESYNC dela é o de sempre (fluxo da batalha).
  const rs = respostaA(sala2.receber(rh.seatId, { v: 2, type: 'ROOM_RESYNC', lastSeq: 0 }), rh.seatId);
  assert.ok(rs.some((x) => x.type === 'ROOM_EVENT'), 'o fluxo da batalha');

  // E a queda do Mestre volta a ser a E-C4 de sempre: pausa.
  sala2.conexaoFechada(rm.seatId);
  assert.equal(sala2.depuracao.estado().fase, 'pausa');
});

test('ordem 22 (17-2 a, pausa): sala restaurada em combate já pausado — a jogadora antes do Mestre também fica no lobby', () => {
  const m = sessao();
  exigirAplicada(m.mestre('MASTER_PAUSE', {}), 'pausa');
  assert.equal(m.sala.depuracao.estado().fase, 'pausa');
  const sala2 = criarDe(m.sala.exportar());
  const rh = ligar(sala2, JOIN_HEROINA, '10.0.3.1');
  eLobbyDeEspera(rh.mensagens.find((x) => x.type === 'ROOM_SNAPSHOT'));
  const rm = ligar(sala2, JOIN_MESTRE, '10.0.3.2');
  const snap = respostaA(rm.saidas, rh.seatId).find((x) => x.type === 'ROOM_SNAPSHOT');
  assert.equal(snap?.fase, 'pausa', 'com o Mestre dentro vê a batalha, na pausa que o Mestre tinha dado');
});

// ------------------------------------------------------------------ 17-2 (c): o Mestre entra primeiro → nada muda

test('ordem 22 (17-2 c, controlo): o Mestre entra primeiro — a jogadora vê a batalha logo, nada no journal', () => {
  const m = sessao();
  const exportado = m.sala.exportar();
  const sala2 = criarDe(exportado);
  const seqAntes = sala2.depuracao.journalSeq();
  ligar(sala2, JOIN_MESTRE, '10.0.4.2');
  const rh = ligar(sala2, JOIN_HEROINA, '10.0.4.1');
  const snap = rh.mensagens.find((x) => x.type === 'ROOM_SNAPSHOT');
  assert.equal(snap.fase, 'combate');
  assert.ok(snap.figuras.length > 0);
  assert.ok(snap.propria);
  assert.equal(sala2.depuracao.estado().fase, 'combate');
  assert.equal(sala2.depuracao.journalSeq(), seqAntes, 'nenhum evento novo');
});

test('ordem 22 (17-2, controlo): sala restaurada no lobby ou no fim — a jogadora entra como sempre', () => {
  const lobby = montarMesa();
  lobby.entrarTodos();
  const s1 = criarDe(lobby.sala.exportar());
  const r1 = ligar(s1, JOIN_HEROINA, '10.0.5.1');
  assert.equal(r1.mensagens.find((x) => x.type === 'ROOM_SNAPSHOT').fase, 'lobby');
  assert.ok(r1.mensagens.find((x) => x.type === 'ROOM_SNAPSHOT').propria, 'o lobby de sempre traz a ficha dela');

  const fim = sessao();
  exigirAplicada(fim.mestre('MASTER_SUPERVISOR', { op: 'terminar' }), 'terminar');
  const s2 = criarDe(fim.sala.exportar());
  const r2 = ligar(s2, JOIN_HEROINA, '10.0.5.3');
  const snap = r2.mensagens.find((x) => x.type === 'ROOM_SNAPSHOT');
  assert.equal(snap.fase, 'fim');
  assert.ok(snap.figuras.length > 0, 'o fim não é batalha a decorrer: vê-se como antes');
});

// ------------------------------------------------------------------ N21-1: o aviso do motor na MASTER_VIEW

function sessaoNoFim() {
  const m = sessao();
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' }), 'terminar');
  return m;
}

test('ordem 22 (N21-1): o Mestre entra de fresco numa sala restaurada no fim com outro motor — a vista traz o aviso', () => {
  const m = sessaoNoFim();
  const outro = criarMotorFalso();
  outro.MOTOR_SHA256 = 'e'.repeat(64);
  const gravado = m.sala.depuracao.estado().motores?.vlabSha ?? null;
  const sala2 = criarDe(m.sala.exportar(), { motor: outro });

  // Entrada de fresco: PIN, sem lastSeq → snapshot (sem eventos) + MASTER_VIEW.
  const rm = ligar(sala2, JOIN_MESTRE, '10.0.6.2');
  assert.ok(!rm.mensagens.some((x) => x.type === 'ROOM_EVENT'), 'sem lastSeq não chegam eventos');
  const vista = rm.mensagens.find((x) => x.type === 'MASTER_VIEW');
  assert.ok(vista, 'a vista do Mestre vem com a entrada');
  despejar('sai', 'mestre', vista); // entra no tráfego conferido com o schema (job protocolo)
  assert.deepEqual(vista.avisoMotor, {
    codigo: 'MOTOR_DIFERENTE', recomecar: 'recusado', motorGravado: gravado, motorAgora: 'e'.repeat(64),
  });
  // Igual ao soMestre do evento do journal.
  const ev = sala2.depuracao.eventos().find((e) => e.tipo === 'aviso_motor');
  assert.deepEqual(vista.avisoMotor, ev.soMestre);

  // O pedido MASTER_VIEW traz o mesmo.
  const pedida = respostaA(sala2.receber(rm.seatId, { v: 2, type: 'MASTER_VIEW' }), rm.seatId).find((x) => x.type === 'MASTER_VIEW');
  assert.deepEqual(pedida.avisoMotor, vista.avisoMotor);

  // A Party não recebe a vista nem o campo.
  const rh = ligar(sala2, JOIN_HEROINA, '10.0.6.1');
  assert.ok(!rh.mensagens.some((x) => x.type === 'MASTER_VIEW' || 'avisoMotor' in x));
});

test('ordem 22 (N21-1, controlo): o mesmo motor, ou sala não restaurada — avisoMotor null', () => {
  const m = sessaoNoFim();
  const sala2 = criarDe(m.sala.exportar());
  const rm = ligar(sala2, JOIN_MESTRE, '10.0.7.2');
  assert.equal(rm.mensagens.find((x) => x.type === 'MASTER_VIEW').avisoMotor, null);
  // Sala que nunca foi restaurada: o pedido MASTER_VIEW traz null.
  const seatM = lugarDe(m.sala, 'mestre').seatId;
  const vista = respostaA(m.sala.receber(seatM, { v: 2, type: 'MASTER_VIEW' }), seatM).find((x) => x.type === 'MASTER_VIEW');
  assert.equal(vista.avisoMotor, null);
});

test('ordem 22 (N21-1, controlo): em combate com outro motor fica a pausa de manutenção — sem avisoMotor', () => {
  const m = sessao();
  const outro = criarMotorFalso();
  outro.MOTOR_SHA256 = 'e'.repeat(64);
  const sala2 = criarDe(m.sala.exportar(), { motor: outro });
  assert.equal(sala2.depuracao.estado().fase, 'pausa');
  const rm = ligar(sala2, JOIN_MESTRE, '10.0.8.2');
  assert.equal(rm.mensagens.find((x) => x.type === 'MASTER_VIEW').avisoMotor, null);
});
