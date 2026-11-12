// Ordem 31 do CM-000009 — varredura do servidor (V28+): o servidor real morto a meio (kill) e reaberto do journal em
// disco. Os testes de correcção falhavam antes (conferido com o sala.js de facae6c) e passam depois; os de controlo
// passavam antes e continuam.
//
//  V28  O journal grava o estado em JSON canónico (chaves por ordem); ao restaurar, `estado.figuras` volta noutra ordem
//       e a lista de figuras da vista (snapshot da Party e bloco do Mestre) sai noutra ordem. O hash da vista (E-P5)
//       mudava sem nada ter mudado, e a PRIMEIRA transacção depois do restauro (a própria entrada do Mestre) subia a
//       revisão de todos os lugares sem mensagem que a levasse (o ROOM_WELCOME e a MASTER_VIEW não trazem revisão).
//       O Mestre ficava com todos os comandos recusados por `revisao_antiga` (o ROOM_REJECT também não a traz): numa
//       sala restaurada em pausa pela queda do Mestre, o MASTER_RESUME nunca passava e a mesa ficava parada.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import { montarMesa, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const CONFIG = () => ({
  roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
  lugares: [
    { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
    { papel: 'mestre', nome: 'Mestre', pin: PIN },
  ],
});
const criarDe = (restaurarDe) => criarSala({
  motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config: CONFIG(), restaurarDe,
});

function sessao() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 12, y: 2 }]]);
  return m;
}

/** O que um cliente sabe da sua revisão: a maior que lhe chegou (como o Godot: revisao_vista e afins). */
const revisaoVista = (msgs, antes) => msgs.reduce((r, x) => (Number.isInteger(x.revision) && x.revision > r ? x.revision : r), antes);
const lugarDe = (sala, papel) => Object.values(sala.depuracao.estado().lugares).find((s) => s.papel === papel);
const respostaA = (saidas, seatId) => saidas.filter((s) => s.seatId === seatId).map((s) => s.msg);

/** Volta do Mestre à sala restaurada com o token e o lastSeq dele; devolve o que ele sabe e o que recebeu. */
function voltarMestre(sala, cliente) {
  const r = sala.entrar({ v: 2, type: 'ROOM_JOIN', papel: 'mestre', pin: PIN, seatToken: cliente.token, lastSeq: cliente.ultimoSeq }, { ip: '10.9.9.9' });
  assert.equal(r.ok, true, 'o Mestre entra');
  sala.conexaoAberta(r.seatId);
  return { seatId: r.seatId, revision: revisaoVista(r.mensagens, cliente.revision) };
}

function comandoMestre(sala, seatId, type, revision, cmdId) {
  const out = respostaA(sala.receber(seatId, { v: 2, type, roomId: 'sala-teste', cmdId, revision }), seatId);
  return out.find((x) => x.type === 'ROOM_RECEIPT' || x.type === 'ROOM_REJECT');
}

test('V28: o restauro muda a ordem das figuras (pré-condição dos testes abaixo)', () => {
  const m = sessao();
  const antes = Object.keys(m.sala.depuracao.estado().figuras);
  const depois = Object.keys(criarDe(m.sala.exportar()).depuracao.estado().figuras);
  assert.deepEqual([...depois].sort(), [...antes].sort(), 'as mesmas figuras');
  assert.notDeepEqual(depois, antes, 'noutra ordem (o JSON canónico do journal ordena as chaves)');
});

test('V28: a entrada do Mestre na sala restaurada não sobe revisões sem as entregar', () => {
  const m = sessao();
  const sala = criarDe(m.sala.exportar());
  const antes = Object.fromEntries(Object.values(sala.depuracao.estado().lugares).map((s) => [s.seatId, s.revision]));
  voltarMestre(sala, m.clientes.mestre);
  for (const s of Object.values(sala.depuracao.estado().lugares)) {
    assert.equal(s.revision, antes[s.seatId], `revisão do lugar ${s.papel} igual: a vista não mudou`);
  }
});

test('V28: sala restaurada em pausa pela queda do Mestre — ao voltar, o MASTER_RESUME passa', () => {
  const m = sessao();
  m.sair('mestre'); // E-C4: pausa mestre_desconectado (o evento fica no fluxo dele; o lastSeq já o conta)
  assert.equal(m.sala.depuracao.estado().fase, 'pausa');
  const sala = criarDe(m.sala.exportar()); // o servidor morreu e voltou do journal
  const mestre = voltarMestre(sala, m.clientes.mestre);
  const r = comandoMestre(sala, mestre.seatId, 'MASTER_RESUME', mestre.revision, 'cmd-v28-retomar');
  assert.equal(r?.type, 'ROOM_RECEIPT', 'não é ROOM_REJECT revisao_antiga: ' + JSON.stringify(r));
  assert.equal(r.estado, 'APLICADA');
  assert.equal(sala.depuracao.estado().fase, 'combate', 'a mesa retoma');
});

test('V28: a jogadora entra antes do Mestre (sala de espera) e o Mestre ainda manda com a revisão que conhece', () => {
  const m = sessao();
  const sala = criarDe(m.sala.exportar());
  const h = sala.entrar({ v: 2, type: 'ROOM_JOIN', papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, seatToken: m.clientes.heroina.token, lastSeq: m.clientes.heroina.ultimoSeq }, { ip: '10.9.9.8' });
  assert.equal(h.ok, true);
  sala.conexaoAberta(h.seatId);
  const mestre = voltarMestre(sala, m.clientes.mestre);
  const r = comandoMestre(sala, mestre.seatId, 'MASTER_PAUSE', mestre.revision, 'cmd-v28-pausar');
  assert.equal(r?.type, 'ROOM_RECEIPT', 'não é ROOM_REJECT revisao_antiga: ' + JSON.stringify(r));
  assert.equal(r.estado, 'APLICADA');
});

test('controlo V28: sem restauro, a volta do Mestre e o MASTER_RESUME já passavam', () => {
  const m = sessao();
  m.sair('mestre');
  const mestre = voltarMestre(m.sala, m.clientes.mestre);
  const r = comandoMestre(m.sala, mestre.seatId, 'MASTER_RESUME', mestre.revision, 'cmd-v28-c1');
  assert.equal(r?.type, 'ROOM_RECEIPT');
  assert.equal(r.estado, 'APLICADA');
});

test('controlo V28: depois do restauro, uma mudança de verdade continua a subir a revisão e a entregá-la', () => {
  const m = sessao();
  const sala = criarDe(m.sala.exportar());
  const mestre = voltarMestre(sala, m.clientes.mestre);
  const antes = lugarDe(sala, 'mestre').revision;
  const out = respostaA(sala.receber(mestre.seatId, { v: 2, type: 'MASTER_PAUSE', roomId: 'sala-teste', cmdId: 'cmd-v28-c2', revision: antes }), mestre.seatId);
  assert.equal(out.find((x) => x.type === 'ROOM_RECEIPT')?.estado, 'APLICADA');
  const depois = lugarDe(sala, 'mestre').revision;
  assert.ok(depois > antes, 'a pausa muda a vista: a revisão sobe');
  assert.equal(revisaoVista(out, 0), depois, 'e a revisão nova chega ao Mestre');
});
